# renv::snapshot()
# renv::restore()
library(CovVaxComparativeSafety)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "./andromedaTemp")

# Maximum number of cores to be used:
maxCores <- 4

# The folder where the study intermediate and result files will be written:
outputFolder <- "./output"

# Details for connecting to the server:
server<-Sys.getenv("...")
db.name<-"..."

user<-Sys.getenv("DB_USER")
password<- Sys.getenv("DB_PASSWORD")
port<-Sys.getenv("DB_PORT")
host<-Sys.getenv("DB_HOST")
connectionDetails <-DatabaseConnector::downloadJdbcDrivers("postgresql", "./CovVaxComparativeSafety")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = Sys.getenv("server"),
                                                                user = Sys.getenv("DB_USER"),
                                                                password = Sys.getenv("DB_PASSWORD"),
                                                                port = Sys.getenv("DB_PORT") ,
                                                                pathToDriver = "./CovVaxComparativeSafety")

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "public"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "results"
cohortTable <- "CovVaxCompare_cohorts"
oracleTempSchema <- NULL
# Some meta-information that will be used by the export function:
databaseId <- "..."
databaseName <- "..."
databaseDescription <- "..."
# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)

execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        verifyDependencies = TRUE,
        createCohorts = TRUE,
        synthesizePositiveControls = FALSE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, 
                    #   blind = TRUE, 
                       launch.browser = FALSE)

# Upload the results to the OHDSI SFTP server:
privateKeyFileName <- ""
userName <- ""
uploadResults(outputFolder, privateKeyFileName, userName)
