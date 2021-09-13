# renv::snapshot()
# renv::restore()
library(CovVaxComparativeSafety)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "/home/xli/CovVaxComparativeSafety/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# The folder where the study intermediate and result files will be written:
outputFolder <- "/home/xli/CovVaxComparativeSafety/output"

# Details for connecting to the server:
server<-Sys.getenv("DB_SERVER_p20_000211_cdm_aurum")
#server_dbi<-Sys.getenv("DB_SERVER_p20_000211_cdm_aurum_dbi")
db.name<-"CPRD AURUM_vaccinated"

user<-Sys.getenv("DB_USER")
password<- Sys.getenv("DB_PASSWORD")
port<-Sys.getenv("DB_PORT")
host<-Sys.getenv("DB_HOST")
connectionDetails <-DatabaseConnector::downloadJdbcDrivers("postgresql", "/home/xli/CovVaxComparativeSafety")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = Sys.getenv("DB_SERVER_p20_000211_cdm_aurum"),
                                                                user = Sys.getenv("DB_USER"),
                                                                password = Sys.getenv("DB_PASSWORD"),
                                                                port = Sys.getenv("DB_PORT") ,
                                                                pathToDriver = "/home/xli/CovVaxComparativeSafety")

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "public"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "results"
cohortTable <- "CovVaxCompare_cohorts"
oracleTempSchema <- NULL
# Some meta-information that will be used by the export function:
databaseId <- "CPRD_Aurum"
databaseName <- "CPRD_Aurum"
databaseDescription <- "CPRD Aurum UK primary care data"
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
        createCohorts = FALSE,
        synthesizePositiveControls = FALSE,
        runAnalyses = TRUE,
        packageResults = TRUE,
        maxCores = maxCores)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, blind = TRUE, launch.browser = FALSE)

# Upload the results to the OHDSI SFTP server:
privateKeyFileName <- ""
userName <- ""
uploadResults(outputFolder, privateKeyFileName, userName)
