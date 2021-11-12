# Copyright 2021 Observational Health Data Sciences and Informatics
#
# This file is part of CompareToNonVaxCohorts
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

runCohortMethod <- function(connectionDetails,
                            cdmDatabaseSchema,
                            cohortDatabaseSchema,
                            cohortTable,
                            tempEmulationSchema,
                            outputFolder,
                            maxCores) {

# functions for copy results file
  copyCmDataFiles <- function(exposures, source, destination) {
    lapply(1:nrow(exposures), function(i) {
      fileName <- file.path(source,
                            sprintf("CmData_l1_t%s_c%s.zip",
                                    exposures[i,]$targetId,
                                    exposures[i,]$comparatorId))
      success <- file.copy(fileName, destination, overwrite = TRUE,
                           copy.date = TRUE)
      if (!success) {
        stop("Error copying file: ", fileName)
      }
    })
  }
  
  deleteCmDataFiles <- function(exposures, source) {
    lapply(1:nrow(exposures), function(i) {
      fileName <- file.path(source,
                            sprintf("CmData_l1_t%s_c%s.zip",
                                    exposures[i,]$targetId,
                                    exposures[i,]$comparatorId))
      file.remove(fileName)
      
    })
  }
  
##  
  ParallelLogger::logInfo("Executing CohortMethod for the original cohorts ")
  
  cmFolderOrig <- file.path(outputFolder, "cmOutputOrig")
  if (!file.exists(cmFolderOrig)) {
    dir.create(cmFolderOrig)
  }
    
  cmAnalysisListFile <- system.file("settings",
                                    "cmAnalysisList.json",
                                    package = "CompareToNonVaxCohorts")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
  tcosList <- createTcos(outputFolder = outputFolder)
  outcomesOfInterest <- getOutcomesOfInterest()
  results <- CohortMethod::runCmAnalyses(connectionDetails = connectionDetails,
                                         cdmDatabaseSchema = cdmDatabaseSchema,
                                         exposureDatabaseSchema = cohortDatabaseSchema,
                                         exposureTable = cohortTable,
                                         outcomeDatabaseSchema = cohortDatabaseSchema,
                                         outcomeTable = cohortTable,
                                         outputFolder = cmFolderOrig,
                                         tempEmulationSchema = tempEmulationSchema,
                                         cmAnalysisList = cmAnalysisList,
                                         targetComparatorOutcomesList = tcosList,
                                         getDbCohortMethodDataThreads = min(3, maxCores),
                                         createStudyPopThreads = min(3, maxCores),
                                         createPsThreads = max(1, round(maxCores/10)),
                                         psCvThreads = min(10, maxCores),
                                         trimMatchStratifyThreads = min(10, maxCores),
                                         fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                         outcomeCvThreads = min(4, maxCores),
                                         refitPsForEveryOutcome = FALSE,
                                         outcomeIdsOfInterest = outcomesOfInterest)
  
  ParallelLogger::logInfo("Summarizing results for original cohorts")
  analysisSummary <- CohortMethod::summarizeAnalyses(referenceTable = results, 
                                                     outputFolder = cmFolderOrig)
  analysisSummary <- addCohortNames(analysisSummary, "targetId", "targetName")
  analysisSummary <- addCohortNames(analysisSummary, "comparatorId", "comparatorName")
  analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
  analysisSummary <- addAnalysisDescription(analysisSummary, "analysisId", "analysisDescription")
  write.csv(analysisSummary, file.path(cmFolderOrig, "analysisSummary_orig.csv"), row.names = FALSE)
  
  ParallelLogger::logInfo("Computing covariate balance for original cohorts") 
  balanceFolder <- file.path(outputFolder, "balanceOrig")
  if (!file.exists(balanceFolder)) {
    dir.create(balanceFolder)
  }
  subset <- results[results$outcomeId %in% outcomesOfInterest,]
  subset <- subset[subset$strataFile != "", ]
  if (nrow(subset) > 0) {
    subset <- split(subset, seq(nrow(subset)))
    cluster <- ParallelLogger::makeCluster(min(3, maxCores))
    ParallelLogger::clusterApply(cluster, subset, computeCovariateBalance, cmOutputFolder = cmFolderOrig, balanceFolder = balanceFolder)
    ParallelLogger::stopCluster(cluster)
  }


# change index date and pairs selection 
ParallelLogger::logInfo("Change index date and select eligile comparasion cohorts using the original cohorts ")

# copy files to new cohrot folder. 
cmFolderModi <- file.path(outputFolder, "cmOutputModi")
if (!file.exists(cmFolderModi)) {
  dir.create(cmFolderModi)
}

rm(results)

# re-use the stratified file (after matching) 
stratFileList <- list.files(file.path(outputFolder, "cmOutputOrig"),
                         # "^Ps_l1_s1_p2_t.*rds",  # copies both shared and outcome-specific populations
                         # "^Ps_l2_s1_p2_t\\d*_c\\d*.rds", # copies just shared ps model
                         "^StratPop_l2_s1_p2_t.*rds", 
                         full.names = TRUE, ignore.case = TRUE)
file.copy(from = stratFileList,
          to = file.path(outputFolder, "cmOutputModi"),
          copy.date = TRUE)

stratFileListCopied <- list.files(file.path(outputFolder, "cmOutputModi"),
                            "^StratPop_l2_s1_p2_t.*rds",
                            full.names = TRUE, ignore.case = TRUE)


## add by XL, change index date and corresponding variables for comparator cohort 
##########################################################
ModiSelectPairs<- function(matchedFile){
  TargetId <-  sub("_c.*", "", sub(".*_t", "", matchedFile))
  ComparatorId <- sub("_.*", "",(sub(".rds", "", sub(".*_c", "", matchedFile))))
  OutcomeId <- sub(".rds", "", sub(".*_o", "", matchedFile))
  
  matchedPop <-   readRDS(matchedFile)
  pairs <- reshape2::dcast(matchedPop,  stratumId ~ treatment,  value.var = "personSeqId")
  names(pairs) <- c("stratumId","comparator","target")
  pairs$self.match <- ifelse(pairs$comparator == pairs$target,1,0)
  # sum(pairs$self.match)*100/length(pairs$self.match)    # 6%
  
  #seprate the target cohort
  target.co <- matchedPop %>% dplyr::filter(treatment==1) %>% dplyr::select(stratumId, cohortStartDate) 
  # vaccine date as index date
  edit.co <- matchedPop %>% 
    dplyr::left_join(rename(target.co,  cohortStartDateVAX = cohortStartDate), by="stratumId") %>% 
    dplyr::mutate(days.idx.move = cohortStartDateVAX - cohortStartDate) %>% 
    dplyr::left_join(pairs, by = "stratumId")
  
  elig.comp <-  edit.co %>% 
    dplyr::filter(treatment==0) %>% 
    dplyr::mutate( co.end.before.vax = if_else(cohortStartDateVAX >= cohortStartDate + daysToCohortEnd,1,0),
                   event.before.vax = if_else(outcomeCount != 0 & cohortStartDateVAX >= cohortStartDate + daysToEvent , 1, 0)) 
  
  # with(elig.comp, table(co.end.before.vax,event.before.vax, self.match))
  # with(elig.comp, table(co.end.before.vax,event.before.vax, self.match,outcomeCount))
  # pair.include <- list()
  #pair.include <- data.frame()
  pair.include <- elig.comp %>% count(co.end.before.vax,event.before.vax, self.match)
  pair.include <- pair.include %>% mutate( TargetId = TargetId,
                                           ComparatorId = ComparatorId, 
                                           OutcomeId  = OutcomeId,
                                           Stratafile = matchedFile)
  # pair.include <- as_tibble(pair.include)
  # pair.include.wide <- reshape2::dcast(pair.include,
  #                                      Stratafile+TargetId+ ComparatorId+OutcomeId  ~ co.end.before.vax +event.before.vax +self.match,
  #                                      value.var = "n")
  # names(pair.include.wide) <- c( "Stratafile","TargetId","ComparatorId","OutcomeId",
  #                                "elig_flg","Event_before_vax_only","Co_end_before_vax_only","Co_end_before_vax_Self_match","Event_before_vax_Self_match")
  pair.include.wide <- tibble::tibble(TargetId = TargetId,
                                      ComparatorId = ComparatorId, 
                                      OutcomeId  = OutcomeId,
                                      Stratafile = matchedFile,
                                      all_elig_num = pair.include$n[pair.include$co.end.before.vax==0 & pair.include$event.before.vax==0 & pair.include$self.match==0],
                                      Event_before_vax_only = pair.include$n[pair.include$co.end.before.vax==0 & pair.include$event.before.vax==1 & pair.include$self.match==0],
                                      Co_end_before_vax_only = pair.include$n[pair.include$co.end.before.vax==1 & pair.include$event.before.vax==0 & pair.include$self.match==0],
                                      Co_end_before_vax_Self_match = pair.include$n[pair.include$co.end.before.vax==1 & pair.include$event.before.vax==0 & pair.include$self.match==1],
                                      Event_before_vax_Co_end_before_vax = pair.include$n[pair.include$co.end.before.vax==1 & pair.include$event.before.vax==1 & pair.include$self.match==0]
  )
  
  elig.comp.all <- elig.comp %>% 
    dplyr::filter(self.match ==0 & co.end.before.vax ==0 & event.before.vax==0)
  
  # sum(elig.comp.all$outcomeCount !=0) #187
  
  # edit the index date and other covars 
  
  elig.comp.all <- elig.comp.all %>% 
    dplyr::mutate(cohortStartDate.new = cohortStartDateVAX,
                  daysFromObsStart.new = daysFromObsStart + days.idx.move,
                  daysToObsEnd.new = daysToObsEnd - days.idx.move,
                  daysToCohortEnd.new = pmin(28,daysToCohortEnd - days.idx.move),
                  daysToEvent.new = case_when(outcomeCount != 0 & event.before.vax != 1 ~ as.integer(daysToEvent - days.idx.move))) %>%
    dplyr::mutate(
      riskEnd.new = pmin(28,daysToObsEnd.new, daysToCohortEnd.new),
      timeAtRisk.new = riskEnd.new - riskStart + 1,
      survivalTime.new = if_else(is.na(daysToEvent.new),timeAtRisk.new, pmin(timeAtRisk.new,daysToEvent.new + 1)))%>% 
    dplyr::mutate(cohortStartDate = cohortStartDate.new,
                  daysFromObsStart = as.numeric(daysFromObsStart.new),
                  survivalTime = survivalTime.new,
                  timeAtRisk = timeAtRisk.new)
  
  elig.target <- edit.co %>% dplyr::filter(treatment ==1 )%>% 
    dplyr::inner_join(select(elig.comp.all, stratumId),by="stratumId")
  
  matchedPop.final <- bind_rows(elig.comp.all,elig.target)
  matchedPop.final <- matchedPop.final[, names(matchedPop.final) %in% names(matchedPop) ]
  #attributes(matchedPop.final)$metaData$attrition 
  #ps <- matchedPop.final 
  #FinalFile <- matchedFile
  saveRDS(matchedPop.final,file = matchedFile)
  # print(paste0("rows are", nrow(pair.include)))
  return(pair.include.wide)
  # print(pair.include.wide)
  #return(pair.include)
}

# ModiSelectPairs(stratFileListCopied)
lapply(stratFileListCopied, ModiSelectPairs)
##########################################################

# copy other files to new cmOutput folder 

PsFileList <- list.files(file.path(outputFolder, "cmOutputOrig"),
                            # "^Ps_l1_s1_p2_t.*rds",  # copies both shared and outcome-specific populations
                            # "^Ps_l2_s1_p2_t\\d*_c\\d*.rds", # copies just shared ps model
                            "^Ps_l2_s1_p2_t.*rds", 
                            full.names = TRUE, ignore.case = TRUE)
file.copy(from = PsFileList,
          to = file.path(outputFolder, "cmOutputModi"),
          copy.date = TRUE)

StudyPopFileList <- list.files(file.path(outputFolder, "cmOutputOrig"),
                         # "^Ps_l1_s1_p2_t.*rds",  # copies both shared and outcome-specific populations
                         # "^Ps_l2_s1_p2_t\\d*_c\\d*.rds", # copies just shared ps model
                         "^StudyPop_.*rds", 
                         full.names = TRUE, ignore.case = TRUE)
file.copy(from = StudyPopFileList,
          to = file.path(outputFolder, "cmOutputModi"),
          copy.date = TRUE)

cmDataFileList <- list.files(file.path(outputFolder, "cmOutputOrig"),
                               # "^Ps_l1_s1_p2_t.*rds",  # copies both shared and outcome-specific populations
                               # "^Ps_l2_s1_p2_t\\d*_c\\d*.rds", # copies just shared ps model
                               "^CmData_l2.*zip", 
                               full.names = TRUE, ignore.case = TRUE)
file.copy(from = cmDataFileList,
          to = file.path(outputFolder, "cmOutputModi"),
          copy.date = TRUE)



## 
ParallelLogger::logInfo("Executing CohortMethod for the modified and selected cohorts")

cmFolderModi <- file.path(outputFolder, "cmOutputModi")
if (!file.exists(cmFolderModi)) {
  dir.create(cmFolderModi)
}

cmAnalysisListFile <- system.file("settings",
                                  "cmAnalysisList.json",
                                  package = "CompareToNonVaxCohorts")
cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
tcosList <- createTcos(outputFolder = outputFolder)
outcomesOfInterest <- getOutcomesOfInterest()
results <- CohortMethod::runCmAnalyses(connectionDetails = NULL,
                                       cdmDatabaseSchema = NULL,
                                       exposureDatabaseSchema = NULL,
                                       exposureTable = NULL,
                                       outcomeDatabaseSchema = NULL,
                                       outcomeTable = NULL,
                                       # connectionDetails = connectionDetails,
                                       # cdmDatabaseSchema = cdmDatabaseSchema,
                                       # exposureDatabaseSchema = cohortDatabaseSchema,
                                       # exposureTable = cohortTable,
                                       # outcomeDatabaseSchema = cohortDatabaseSchema,
                                       # outcomeTable = cohortTable,
                                       outputFolder = cmFolderModi,
                                       tempEmulationSchema = tempEmulationSchema,
                                       cmAnalysisList = cmAnalysisList,
                                       targetComparatorOutcomesList = tcosList,
                                       getDbCohortMethodDataThreads = min(3, maxCores),
                                       createStudyPopThreads = min(3, maxCores),
                                       createPsThreads = max(1, round(maxCores/10)),
                                       psCvThreads = min(10, maxCores),
                                       trimMatchStratifyThreads = min(10, maxCores),
                                       fitOutcomeModelThreads = max(1, round(maxCores/4)),
                                       outcomeCvThreads = min(4, maxCores),
                                       refitPsForEveryOutcome = FALSE,
                                       outcomeIdsOfInterest = outcomesOfInterest)

ParallelLogger::logInfo("Summarizing results for modified and selected cohorts")
analysisSummary <- CohortMethod::summarizeAnalyses(referenceTable = results, 
                                                   outputFolder = cmFolderModi)
analysisSummary <- addCohortNames(analysisSummary, "targetId", "targetName")
analysisSummary <- addCohortNames(analysisSummary, "comparatorId", "comparatorName")
analysisSummary <- addCohortNames(analysisSummary, "outcomeId", "outcomeName")
analysisSummary <- addAnalysisDescription(analysisSummary, "analysisId", "analysisDescription")
write.csv(analysisSummary, file.path(cmFolderModi, "analysisSummary_modi.csv"), row.names = FALSE)

ParallelLogger::logInfo("Computing covariate balance for modified and selected cohorts") 
balanceFolderModi <- file.path(outputFolder, "balanceModi")
if (!file.exists(balanceFolderModi)) {
  dir.create(balanceFolderModi)
}
subset <- results[results$outcomeId %in% outcomesOfInterest,]
subset <- subset[subset$strataFile != "", ]
if (nrow(subset) > 0) {
  subset <- split(subset, seq(nrow(subset)))
  cluster <- ParallelLogger::makeCluster(min(3, maxCores))
  ParallelLogger::clusterApply(cluster, subset, computeCovariateBalance, cmOutputFolder = cmFolderModi, balanceFolder = balanceFolderModi)
  ParallelLogger::stopCluster(cluster)
}
}




### functions 
computeCovariateBalance <- function(row, cmOutputFolder, balanceFolder) {
  outputFileName <- file.path(balanceFolder,
                              sprintf("bal_t%s_c%s_o%s_a%s.rds", row$targetId, row$comparatorId, row$outcomeId, row$analysisId))
  if (!file.exists(outputFileName)) {
    ParallelLogger::logTrace("Creating covariate balance file ", outputFileName)
    cohortMethodDataFile <- file.path(cmOutputFolder, row$cohortMethodDataFile)
    cohortMethodData <- CohortMethod::loadCohortMethodData(cohortMethodDataFile)
    strataFile <- file.path(cmOutputFolder, row$strataFile)
    strata <- readRDS(strataFile)
    balance <- CohortMethod::computeCovariateBalance(population = strata, cohortMethodData = cohortMethodData)
    saveRDS(balance, outputFileName)
  }
}

addAnalysisDescription <- function(data, IdColumnName = "analysisId", nameColumnName = "analysisDescription") {
  cmAnalysisListFile <- system.file("settings",
                                    "cmAnalysisList.json",
                                    package = "CompareToNonVaxCohorts")
  cmAnalysisList <- CohortMethod::loadCmAnalysisList(cmAnalysisListFile)
  idToName <- lapply(cmAnalysisList, function(x) data.frame(analysisId = x$analysisId, description = as.character(x$description)))
  idToName <- do.call("rbind", idToName)
  names(idToName)[1] <- IdColumnName
  names(idToName)[2] <- nameColumnName
  data <- merge(data, idToName, all.x = TRUE)
  # Change order of columns:
  idCol <- which(colnames(data) == IdColumnName)
  if (idCol < ncol(data) - 1) {
    data <- data[, c(1:idCol, ncol(data) , (idCol + 1):(ncol(data) - 1))]
  }
  return(data)
}

createTcos <- function(outputFolder) {
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "CompareToNonVaxCohorts")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  allControls <- getAllControls(outputFolder)
  tcs <- unique(rbind(tcosOfInterest[, c("targetId", "comparatorId")],
                      allControls[, c("targetId", "comparatorId")]))
  createTco <- function(i) {
    targetId <- tcs$targetId[i]
    comparatorId <- tcs$comparatorId[i]
    outcomeIds <- as.character(tcosOfInterest$outcomeIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    outcomeIds <- as.numeric(strsplit(outcomeIds, split = ";")[[1]])
    outcomeIds <- c(outcomeIds, allControls$outcomeId[allControls$targetId == targetId & allControls$comparatorId == comparatorId])
    excludeConceptIds <- as.character(tcosOfInterest$excludedCovariateConceptIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    if (length(excludeConceptIds) == 1 && is.na(excludeConceptIds)) {
      excludeConceptIds <- c()
    } else if (length(excludeConceptIds) > 0) {
      excludeConceptIds <- as.numeric(strsplit(excludeConceptIds, split = ";")[[1]])
    }
    includeConceptIds <- as.character(tcosOfInterest$includedCovariateConceptIds[tcosOfInterest$targetId == targetId & tcosOfInterest$comparatorId == comparatorId])
    if (length(includeConceptIds) == 1 && is.na(includeConceptIds)) {
      includeConceptIds <- c()
    } else if (length(includeConceptIds) > 0) {
      includeConceptIds <- as.numeric(strsplit(includeConceptIds, split = ";")[[1]])
    }
    tco <- CohortMethod::createTargetComparatorOutcomes(targetId = targetId,
                                                        comparatorId = comparatorId,
                                                        outcomeIds = outcomeIds,
                                                        excludedCovariateConceptIds = excludeConceptIds,
                                                        includedCovariateConceptIds = includeConceptIds)
    return(tco)
  }
  tcosList <- lapply(1:nrow(tcs), createTco)
  return(tcosList)
}

getOutcomesOfInterest <- function() {
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "CompareToNonVaxCohorts")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE) 
  outcomeIds <- as.character(tcosOfInterest$outcomeIds)
  outcomeIds <- do.call("c", (strsplit(outcomeIds, split = ";")))
  outcomeIds <- unique(as.numeric(outcomeIds))
  return(outcomeIds)
}

getAllControls <- function(outputFolder) {
  allControlsFile <- file.path(outputFolder, "AllControls.csv")
  if (file.exists(allControlsFile)) {
    # Positive controls must have been synthesized. Include both positive and negative controls.
    allControls <- read.csv(allControlsFile)
  } else {
    # Include only negative controls
    pathToCsv <- system.file("settings", "NegativeControls.csv", package = "CompareToNonVaxCohorts")
    allControls <- read.csv(pathToCsv)
    allControls$oldOutcomeId <- allControls$outcomeId
    allControls$targetEffectSize <- rep(1, nrow(allControls))
  }
  return(allControls)
}
