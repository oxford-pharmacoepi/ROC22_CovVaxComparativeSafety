library(remotes)
#remotes::install_github("Xintong-Li-ZnCu/CohortMethod")
library(CohortMethod)

# renv::snapshot()
# renv::restore()
library(CompareToNonVaxCohorts)

# Optional: specify where the temporary files (used by the Andromeda package) will be created:
options(andromedaTempFolder = "/home/xli/CompareToNonVaxCohorts/andromedaTemp")

# Maximum number of cores to be used:
# maxCores <- parallel::detectCores()
maxCores <- 4
# The folder where the study intermediate and result files will be written:
outputFolder <- "/home/xli/CompareToNonVaxCohorts/output"

# Details for connecting to the server:
server<-Sys.getenv("DB_SERVER_p20_000211_cdm_aurum")
#server_dbi<-Sys.getenv("DB_SERVER_p20_000211_cdm_aurum_dbi")
db.name<-"CPRD AURUM_vaccinated"

user<-Sys.getenv("DB_USER")
password<- Sys.getenv("DB_PASSWORD")
port<-Sys.getenv("DB_PORT")
host<-Sys.getenv("DB_HOST")
connectionDetails <-DatabaseConnector::downloadJdbcDrivers("postgresql", "/home/xli/CompareToNonVaxCohorts")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                                                server = Sys.getenv("DB_SERVER_p20_000211_cdm_aurum"),
                                                                user = !!Sys.getenv("DB_USER"),
                                                                password = Sys.getenv("DB_PASSWORD"),
                                                                port = Sys.getenv("DB_PORT") ,
                                                                pathToDriver = "/home/xli/CompareToNonVaxCohorts")

# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- "public"

# The name of the database schema and table where the study-specific cohorts will be instantiated:
cohortDatabaseSchema <- "results"
cohortTable <- "CompareToNonVax_cohorts_TEST"
oracleTempSchema <- NULL
# Some meta-information that will be used by the export function:
databaseId <- "CPRD_Aurum"
databaseName <- "CPRD_Aurum"
databaseDescription <- "CPRD Aurum UK primary care data"
# For some database platforms (e.g. Oracle): define a schema that can be used to emulate temp tables:
options(sqlRenderTempEmulationSchema = NULL)

CompareToNonVaxCohorts::execute(connectionDetails = connectionDetails,
        cdmDatabaseSchema = cdmDatabaseSchema,
        cohortDatabaseSchema = cohortDatabaseSchema,
        cohortTable = cohortTable,
        oracleTempSchema = oracleTempSchema,
        outputFolder = outputFolder,
        databaseId = databaseId,
        databaseName = databaseName,
        databaseDescription = databaseDescription,
        verifyDependencies = TRUE,
        createCohorts = FALSE,   ###################
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


############################ 
covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                useDemographicsAgeGroup = TRUE,
                                                                useConditionGroupEraLongTerm = TRUE,
                                                                useDrugGroupEraMediumTerm = TRUE,
                                                                useDistinctIngredientCountMediumTerm = TRUE,
                                                                useProcedureOccurrenceMediumTerm = TRUE,
                                                                useMeasurementMediumTerm = TRUE,
                                                                useObservationMediumTerm = TRUE,
                                                                useDistinctObservationCountMediumTerm = TRUE,
                                                                useDistinctProcedureCountMediumTerm = TRUE, 
                                                                useDistinctMeasurementCountMediumTerm =TRUE,
                                                                useVisitCountMediumTerm = TRUE,
                                                                useVisitConceptCountMediumTerm = TRUE,
                                                                useChads2Vasc = TRUE,
                                                                useCharlsonIndex = TRUE, 
                                                                longTermStartDays = -9999,
                                                                endDays = -4)
cmData <- CohortMethod::getDbCohortMethodData(connectionDetails = connectionDetails, 
                                              cdmDatabaseSchema = cdmDatabaseSchema, 
                                              targetId = 101,
                                              comparatorId = 402, 
                                              outcomeIds = 0, 
                                              exposureDatabaseSchema = cohortDatabaseSchema,
                                              exposureTable = cohortTable,
                                              outcomeDatabaseSchema = cohortDatabaseSchema,
                                              outcomeTable = cohortTable, 
                                              cdmVersion = 5,
                                              removeDuplicateSubjects = FALSE,
                                           #   maxCohortSize = 10000,
                                              covariateSettings = covariateSettings)

cmData <- CohortMethod::loadCohortMethodData( "./test/full/cmData.zip")

library(dplyr)
cohorts <- as.data.frame(cmData$cohorts)
length(unique(cohorts$personId))
length(unique(cohorts$personSeqId))
length(unique(cohorts$rowId))
cohorts %>% group_by(treatment) %>% count()

studyPop <- CohortMethod::createStudyPopulation(cohortMethodData = cmData,outcomeId = 0,
                                                removeDuplicateSubjects = FALSE,
                                                censorAtNewRiskWindow = TRUE)

studyPop %>% group_by(treatment) %>% summarise(n=n(), event=sum(outcomeCount))


CohortMethod::computeMdrr(population = studyPop,
            modelType = "cox",
            alpha = 0.05,
            power = 0.8,
            twoSided = TRUE)  

CovVaxRelatedIDs <-  c(37003516, 37003436, 37003518, 35894915, 35897994, 1230962, 35895095, 35895096, 35891709, 35895097, 35891603, 35895098, 37003432, 724905, 702866, 766236, 766237, 766239, 766234, 766240, 766231, 766235, 766233, 766232, 766241, 766238, 724906, 724907, 35895192, 1227568, 1230963, 42796343, 35891522, 35895099, 35891864, 35895100, 35891906, 35895190, 35895191, 35891484, 35891695, 35891649, 35895193, 35891890, 35895194, 35891433, 42639778, 42639775, 42639779, 42639776, 42639780, 42639777, 36391504, 42796198, 1219271, 42797615, 724904, 829421, 36388974, 37003431, 37003435, 37003434, 37003517, 37003433, 42797616, 4150252, 37310267, 3657627, 3657634, 3657629)
CovVaxRelatedIDs.covar <- paste0(CovVaxRelatedIDs,"411")
instrIds <- c(44791414503,37310267803,4150252803,46272951803)

psData <- CohortMethod::createPs(cohortMethodData = cmData,
                             population = studyPop,
                             maxCohortSizeForFitting = 100000,
                             excludeCovariateIds = c(CovVaxRelatedIDs.covar,instrIds ),
                             control = createControl(threads = 4))   # 25 hours

CohortMethod::plotPs(psData,
                     scale = "preference",
                     showCountsLabel = TRUE,
                   #  showAucLabel = TRUE,
                     showEquiposeLabel = TRUE)

psModel <- CohortMethod::getPsModel(psData, cmData)

attributes(psData)$metaData$psModelPriorVariance  # 0.02863681


CohortMethod::saveCohortMethodData(cmData, "./test/full/cmData.zip")
saveRDS(studyPop, file = "./test/full/studyPop.rds")
saveRDS(psData, file = "./test/full/psData.rds")
saveRDS(psModel, file = "./test/full/psModel.rds")
write.csv(psModel, "./test/full/psModel.csv")

cmData <- CohortMethod::loadCohortMethodData("./test/full/cmData.zip")

matchedPop <- CohortMethod::matchOnPs(psData, caliper = 0.2, caliperScale = "standardized logit", maxRatio = 1)
CohortMethod::plotPs(matchedPop, psData)

CohortMethod::getAttritionTable(matchedPop)

CohortMethod::drawAttritionDiagram(matchedPop)

length(unique(matchedPop$personSeqId)) #3071081
length(unique(matchedPop$rowId))
length(unique(matchedPop$stratumId))


library(reshape2)
pairs2 <- dcast(matchedPop,  stratumId ~ treatment,  value.var = "personSeqId")
names(pairs2) <- c("stratumId","comparator","target")
pairs2$self.match <- ifelse(pairs2$comparator == pairs2$target,1,0)
sum(pairs2$self.match)*100/length(pairs2$self.match)

target.co <- matchedPop %>% filter(treatment==1) %>% select(stratumId, cohortStartDate) 

edit.co <- matchedPop %>% left_join(rename(target.co,  cohortStartDateVAX = cohortStartDate), by="stratumId") %>% 
  mutate(days.idx.move = cohortStartDateVAX - cohortStartDate) %>% 
  left_join(pairs2, by = "stratumId")

edit.co <- edit.co %>% mutate(daysToEvent.new = if_else(treatment==0 & outcomeCount != 0 , daysToEvent - days.idx.move, 28)) %>%
  mutate(riskEnd.new.offset = if_else(treatment==0 & outcomeCount != 0 & riskEnd.new >28, 28, ))


balance <- CohortMethod::computeCovariateBalance(matchedPop, cmData)  # 3 h
CohortMethod::plotCovariateBalanceScatterPlot(balance, showCovariateCountLabel = TRUE, showMaxLabel = TRUE)

CohortMethod::plotCovariateBalanceOfTopVariables(balance)

match_table <- CohortMethod::createCmTable1(balance)

write.csv(balance, "./test/full/balance_table.csv")
write.csv(match_table, "./test/full/match_table.csv")



#########

cmData_t101_c402_o211 <- CohortMethod::getDbCohortMethodData(connectionDetails = connectionDetails, 
                                              cdmDatabaseSchema = cdmDatabaseSchema, 
                                              targetId = 101,
                                              comparatorId = 402, 
                                              outcomeIds = 211, 
                                              exposureDatabaseSchema = cohortDatabaseSchema,
                                              exposureTable = cohortTable,
                                              outcomeDatabaseSchema = cohortDatabaseSchema,
                                              outcomeTable = cohortTable, 
                                              cdmVersion = 5,
                                              removeDuplicateSubjects = FALSE,
                                              #   maxCohortSize = 10000,
                                              covariateSettings = covariateSettings)

CohortMethod::saveCohortMethodData(cmData_t101_c402_o211, "./test/full/cmData_t101_c402_o211.zip")
cmData_t101_c402_o211 <- CohortMethod::loadCohortMethodData("./test/full/cmData_t101_c402_o211.zip")


library(dplyr)
cohorts2 <- as.data.frame(cmData_t101_c402_o211$cohorts)
length(unique(cohorts2$personId)) # 4 548 366
length(unique(cohorts2$personSeqId)) # 4 548 366
length(unique(cohorts2$rowId)) # 6 698 795
cohorts2 %>% group_by(treatment) %>% summarise(countSeq = n_distinct(personSeqId), countPerson = n_distinct(personSeqId), count = n())

studyPop_t101_c402_o211<- CohortMethod::createStudyPopulation(cohortMethodData = cmData_t101_c402_o211,outcomeId = 211,
                                                removeDuplicateSubjects = FALSE,
                                                censorAtNewRiskWindow = TRUE)

saveRDS(studyPop_t101_c402_o211, file = "./test/full/studyPop_t101_c402_o211.rds")
studyPop_t101_c402_o211 <- readRDS("./test/full/studyPop_t101_c402_o211.rds")

studyPop_t101_c402_o211 %>% group_by(treatment) %>% summarise(n=n(), event=sum(outcomeCount))


CohortMethod::computeMdrr(population = studyPop_t101_c402_o211,
                          modelType = "cox",
                          alpha = 0.05,
                          power = 0.8,
                          twoSided = TRUE)    # 1.099605 

psData <- readRDS("~/CompareToNonVaxCohorts/test/full/psData.rds")
psData2 <- psData %>% 
  select(rowId,personSeqId,treatment,propensityScore, preferenceScore) %>% 
  inner_join(studyPop_t101_c402_o211, by=c('rowId','personSeqId','treatment'))   ## the previous fitting of Ps didn't incude any outcome.. this is the fix.

matchedPop2 <- CohortMethod::matchOnPs(psData2, caliper = 0.2, caliperScale = "standardized logit", maxRatio = 1)
CohortMethod::drawAttritionDiagram(matchedPop2)

CohortMethod::computeMdrr(population = matchedPop2,
                          modelType = "cox",
                          alpha = 0.05,
                          power = 0.8,
                          twoSided = TRUE)  # 1.135697

CohortMethod::getFollowUpDistribution(population = matchedPop2)

CohortMethod::plotFollowUpDistribution(population = matchedPop2)

#crude model 
outcomeModel <- CohortMethod::fitOutcomeModel(population = studyPop_t101_c402_o211,
                                modelType = "poisson",
                                control = Cyclops::createControl(threads = 4))
outcomeModel

# matched Ps, original 
outcomeMode_matched <- CohortMethod::fitOutcomeModel(population = matchedPop2,
                                       modelType = "poisson",
                                       stratified = TRUE,
                                       control = Cyclops::createControl(threads = 4))
outcomeMode_matched

## change index date of comparator cohort 

library(reshape2)
pairs2 <- dcast(matchedPop2,  stratumId ~ treatment,  value.var = "personSeqId")
names(pairs2) <- c("stratumId","comparator","target")
pairs2$self.match <- ifelse(pairs2$comparator == pairs2$target,1,0)
sum(pairs2$self.match)*100/length(pairs2$self.match)    # 6%

#seprate the target cohort
target.co <- matchedPop2 %>% dplyr::filter(treatment==1) %>% dplyr::select(stratumId, cohortStartDate) 
# vaccine date as index date
edit.co <- matchedPop2 %>% left_join(rename(target.co,  cohortStartDateVAX = cohortStartDate), by="stratumId") %>% 
  mutate(days.idx.move = cohortStartDateVAX - cohortStartDate) %>% 
  left_join(pairs2, by = "stratumId")

# edit.co <- edit.co %>% mutate(daysToEvent.new = if_else(treatment==0 & outcomeCount != 0 , daysToEvent - days.idx.move, 28)) %>%
#   mutate(riskEnd.new.offset = if_else(treatment==0 & outcomeCount != 0 & riskEnd.new >28, 28, ))
# 
# elig.event <- edit.co %>% filter(treatment==0 & cohortStartDateVAX < cohortStartDate + daysToEvent)


elig.comp <-  edit.co %>% 
              filter(treatment==0) %>% 
              mutate( co.end.before.vax = if_else(cohortStartDateVAX >= cohortStartDate + daysToCohortEnd,1,0),
                      event.before.vax = if_else(outcomeCount != 0 & cohortStartDateVAX >= cohortStartDate + daysToEvent , 1, 0)) 

with(elig.comp, table(co.end.before.vax,event.before.vax, self.match))
with(elig.comp, table(co.end.before.vax,event.before.vax, self.match,outcomeCount))

elig.comp.all <- elig.comp %>% filter(self.match ==0 & co.end.before.vax ==0 & event.before.vax==0)

sum(elig.comp.all$outcomeCount !=0) #187

# edit the index date and other covars 

elig.comp.all.edit <- elig.comp.all %>% mutate(cohortStartDate.new = cohortStartDateVAX,
                                               daysFromObsStart.new = daysFromObsStart + days.idx.move,
                                               daysToObsEnd.new = daysToObsEnd - days.idx.move,
                                               daysToCohortEnd.new = pmin(28,daysToCohortEnd - days.idx.move),
                                               daysToEvent.new = case_when(outcomeCount != 0 & event.before.vax != 1 ~ as.integer(daysToEvent - days.idx.move))) %>%
                                        mutate(
                                               
                                               riskEnd.new = pmin(28,daysToObsEnd.new, daysToCohortEnd.new),
                                               timeAtRisk.new = riskEnd.new - riskStart + 1,
                                               survivalTime.new = if_else(is.na(daysToEvent.new),timeAtRisk.new, pmin(timeAtRisk.new,daysToEvent.new + 1)))
                                                 

elig.target <- edit.co %>% filter(treatment ==1 )%>% inner_join(select(elig.comp.all.edit, stratumId),by="stratumId")

elig.comp.final <-  elig.comp.all.edit %>% mutate(cohortStartDate = cohortStartDate.new,
                                                  daysFromObsStart = daysFromObsStart.new,
                                                  daysToObsEnd = daysToObsEnd.new,
                                                  daysToCohortEnd = daysToCohortEnd.new,
                                                  daysToEvent = daysToEvent.new,
                                                  riskEnd = riskEnd.new,
                                                  timeAtRisk = timeAtRisk.new,
                                                  survivalTime = survivalTime.new)

matchedPop.final <- bind_rows(elig.comp.final,elig.target)
attributes(matchedPop.final)$metaData$attrition 

outcomeMode_matched_edit <- CohortMethod::fitOutcomeModel(population = matchedPop.final,
                                                     modelType = "poisson",
                                                     stratified = TRUE,
                                                     control = Cyclops::createControl(threads = 4))
summary(outcomeMode_matched_edit)
outcomeMode_matched_edit
outcomeMode_matched_edit$attrition

matchedPop_self <- edit.co %>% filter(self.match==1)
outcomeMode_self<- CohortMethod::fitOutcomeModel(population = matchedPop_self,
                                                          modelType = "poisson",
                                                          stratified = TRUE,
                                                          control = Cyclops::createControl(threads = 4))
outcomeMode_self   # no events in comparator, as we require first event 


# test the attributes 
final_test <- matchedPop.final
attributes(final_test)$metaData$outcomeIds <- 211 
model_test <- CohortMethod::fitOutcomeModel(population = final_test,
                                                          modelType = "poisson",
                                                          stratified = TRUE,
                                                          control = Cyclops::createControl(threads = 4))
model_test


targetDist <- quantile(matchedPop2$survivalTime[matchedPop2$treatment == 1],
                       c(0, 0.1, 0.25, 0.5, 0.85, 0.9, 1))

targetDist_edit <- quantile(matchedPop.final$survivalTime[matchedPop.final$treatment == 1],
                       c(0, 0.1, 0.25, 0.5, 0.85, 0.9, 1))


##########################################################
ps <- matchedPop2
pairs <- dcast(ps,  stratumId ~ treatment,  value.var = "personSeqId")
names(pairs) <- c("stratumId","comparator","target")
pairs$self.match <- ifelse(pairs2$comparator == pairs2$target,1,0)
# sum(pairs$self.match)*100/length(pairs$self.match)    # 6%

#seprate the target cohort
target.co <- ps %>% filter(treatment==1) %>% select(stratumId, cohortStartDate) 
# vaccine date as index date
edit.co <- ps %>% 
  left_join(rename(target.co,  cohortStartDateVAX = cohortStartDate), by="stratumId") %>% 
  mutate(days.idx.move = cohortStartDateVAX - cohortStartDate) %>% 
  left_join(pairs, by = "stratumId")

elig.comp <-  edit.co %>% 
  filter(treatment==0) %>% 
  mutate( co.end.before.vax = if_else(cohortStartDateVAX >= cohortStartDate + daysToCohortEnd,1,0),
          event.before.vax = if_else(outcomeCount != 0 & cohortStartDateVAX >= cohortStartDate + daysToEvent , 1, 0)) 

# with(elig.comp, table(co.end.before.vax,event.before.vax, self.match))
# with(elig.comp, table(co.end.before.vax,event.before.vax, self.match,outcomeCount))

elig.comp.all <- elig.comp %>% 
  filter(self.match ==0 & co.end.before.vax ==0 & event.before.vax==0)

# sum(elig.comp.all$outcomeCount !=0) #187

# edit the index date and other covars 

elig.comp.all <- elig.comp.all %>% 
  mutate(cohortStartDate.new = cohortStartDateVAX,
         daysFromObsStart.new = daysFromObsStart + days.idx.move,
         daysToObsEnd.new = daysToObsEnd - days.idx.move,
         daysToCohortEnd.new = pmin(28,daysToCohortEnd - days.idx.move),
         daysToEvent.new = case_when(outcomeCount != 0 & event.before.vax != 1 ~ as.integer(daysToEvent - days.idx.move))) %>%
  mutate(
    riskEnd.new = pmin(28,daysToObsEnd.new, daysToCohortEnd.new),
    timeAtRisk.new = riskEnd.new - riskStart + 1,
    survivalTime.new = if_else(is.na(daysToEvent.new),timeAtRisk.new, pmin(timeAtRisk.new,daysToEvent.new + 1)))%>% 
  mutate(cohortStartDate = cohortStartDate.new,
         daysFromObsStart = daysFromObsStart.new,
         survivalTime = survivalTime.new,
         timeAtRisk = timeAtRisk.new)

elig.target <- edit.co %>% filter(treatment ==1 )%>% 
  inner_join(select(elig.comp.all, stratumId),by="stratumId")

matchedPop.final <- bind_rows(elig.comp.all,elig.target)
matchedPop.final <- matchedPop.final[, names(matchedPop.final) %in% names(ps) ]
#attributes(matchedPop.final)$metaData$attrition 
ps <- matchedPop.final 

model_new <- CohortMethod::fitOutcomeModel(population = matchedPop.final,
                                           modelType = "poisson",
                                           stratified = TRUE,
                                           control = Cyclops::createControl(threads = 4))
model_new

##########################################################

