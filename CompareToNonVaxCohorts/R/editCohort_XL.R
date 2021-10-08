
# edit the cohorts from CohortDiagnostics for running

library(SqlRender)
#pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "CovVaxComparativeSafety")
cohortsToCreate <- read.csv("~/CovVaxComparativeSafety/inst/settings/CohortsToCreate.csv")

for (i in 1:nrow(cohortsToCreate)) {
  writeLines(paste("Editing cohort:", cohortsToCreate$name[i]))
  sql<-SqlRender::readSql(paste0("~/CovVaxComparativeSafety/inst/sql/sql_server/",cohortsToCreate$name[i], ".sql" )) 
  sql <- sub("BEGIN: Inclusion Impact Analysis - event.*END: Inclusion Impact Analysis - person", "", sql)
  SqlRender::writeSql(sql, paste0("~/CovVaxComparativeSafety/inst/sql/sql_server/",cohortsToCreate$name[i], ".sql"))
} 
