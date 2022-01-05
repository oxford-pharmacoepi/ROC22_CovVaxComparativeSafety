# install.packages("remotes")
# library(remotes)
# remotes::install_github("ohdsi/DatabaseConnector")
# install.packages("DatabaseConnector")
# library(DatabaseConnector)
# install.packages("renv")
# restart R after installation
# renv::restore(packages = "renv")
renv::restore()
library(CovVaxComparativeSafety)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "./andromedaTemp")

# Maximum number of cores to be used:
maxCores <- 4

# The folder where the study intermediate and result files will be written:

# The folder where the study intermediate and result files will be written:
outputFolder <- "./CovVaxComparativeSafety/output"

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = "....",
                                                                user = !!"...",
                                                                password = "...",
                                                                port = 0000 ,
                                                                pathToDriver = "...")
# conn <-  DatabaseConnector::connect(connectionDetails)
# disconnect(conn)

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "..."

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "..."
cohortTable <- "CovVaxCompare_cohorts"
oracleTempSchema <- NULL
# Some meta-information that will be used by the export function:
databaseId <- "..."
databaseName <- "..."
databaseDescription <- "..."
# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)

# Create analysis details ------------
source("extras/CreateStudyAnalysisDetails.R")
createAnalysesDetails("inst/settings/")

# NOW, PLEASE DO: ---------------------------------------
# 1. "BUILD, INSTALL AND RESTART" THE PACKAGE. 
# 2. RE-RUN ALL LINE ABOVE " Create analysis details", SKIP THAT TWO LINES, AND 
# 3. RUN THE "CovVaxComparativeSafety::execute"
#--------------------------------------------------------

CovVaxComparativeSafety::execute(connectionDetails = connectionDetails,
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
                                 createCovHis = TRUE,  #########################
                                 synthesizePositiveControls = FALSE,
                                 runAnalyses = TRUE,
                                 packageResults = TRUE,
                                 maxCores = maxCores)

resultsZipFile <- file.path(outputFolder, "export", paste0("Results_", databaseId, ".zip"))
dataFolder <- file.path(outputFolder, "shinyData")

# You can inspect the results if you want:
prepareForEvidenceExplorer(resultsZipFile = resultsZipFile, dataFolder = dataFolder)
launchEvidenceExplorer(dataFolder = dataFolder, 
                      blind = FALSE,
                       launch.browser = FALSE)

# Upload the results to the OHDSI SFTP server:
privateKeyFileName <- ""
userName <- ""
uploadResults(outputFolder, privateKeyFileName, userName)
