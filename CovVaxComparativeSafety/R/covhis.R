# create covid-19 history attr tables 

################# CovidHistoryAttr

createCovHis <- function(connectionDetails,
                          cdmDatabaseSchema,
                          cohortDatabaseSchema,
                         study_cohort_table,
                         VAX_definition_ids = c(101,102,103,104,201, 202, 203, 204, 205, 206, 207),
                          outputFolder) {
  
conn <- DatabaseConnector::connect(connectionDetails)
# 
# sql<-SqlRender::readSql("./inst/sql/sql_server/CovidHistoryAttr.sql")
# sql<-SqlRender::translate(sql, targetDialect = "postgresql")
# DatabaseConnector::renderTranslateExecuteSql(conn=conn,
#                                              sql,
#                                              cdm_database_schema = cdmDatabaseSchema,
#                                              vocabulary_database_schema = cdmDatabaseSchema,
#                                              cohort_database_schema = cohortDatabaseSchema,
#                                              study_cohort_table = study_cohort_table,
#                                              VAX_definition_ids = VAX_definition_ids,
#                                              cohort_attribute_table = "covhis_cohort_attr",
#                                              attribute_definition_table = "covhis_attr_def"
# )


sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "CovidHistoryAttr.sql",
                                         packageName = "CovVaxComparativeSafety",
                                         dbms = attr(conn, "dbms"),
                                         #  tempEmulationSchema = tempEmulationSchema,
                                         cdm_database_schema = cdmDatabaseSchema,
                                         vocabulary_database_schema = cdmDatabaseSchema,
                                         cohort_database_schema = cohortDatabaseSchema,
                                         study_cohort_table = study_cohort_table,
                                         VAX_definition_ids = VAX_definition_ids,
                                         cohort_attribute_table = "covhis_cohort_attr",
                                         attribute_definition_table = "covhis_attr_def")

DatabaseConnector::executeSql(conn, sql, progressBar = FALSE, reportOverallTime = FALSE)

rm(sql)

sql <- "select cohort_definition_id,value_as_number, count(*) as COUNT_N, count(distinct subject_id) as COUNT_PT from @cohort_database_schema.covhis_cohort_attr group by cohort_definition_id, value_as_number ;"

CovHis_table <- DatabaseConnector::renderTranslateQuerySql(conn, sql,cohort_database_schema = cohortDatabaseSchema )
rm(sql)
write.csv(CovHis_table, file.path(outputFolder, "CovHis_table.csv"), row.names = FALSE)

DatabaseConnector::disconnect(conn)
}