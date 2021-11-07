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

createAnalysesDetails <- function(workFolder) {

  CovVaxRelatedIDs <-  c(37003516, 37003436, 37003518, 35894915, 35897994, 1230962, 35895095, 35895096, 35891709, 35895097, 35891603, 35895098, 37003432, 724905, 702866, 766236, 766237, 766239, 766234, 766240, 766231, 766235, 766233, 766232, 766241, 766238, 724906, 724907, 
                         35895192, 1227568, 1230963, 42796343, 35891522, 35895099, 35891864, 35895100, 35891906, 35895190, 35895191, 35891484, 35891695, 35891649, 35895193, 35891890, 
                         35895194, 35891433, 42639778, 42639775, 42639779, 42639776, 42639780, 42639777, 36391504, 42796198, 1219271, 42797615, 724904, 829421, 36388974, 37003431, 37003435, 37003434, 37003517, 37003433, 42797616, 4150252, 37310267, 3657627, 3657634, 3657629,
                         44791414,37310267,4150252,46272951)
  
  covarSettingsWithVax <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                     useDemographicsAgeTenGroup = TRUE,
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
  
  
  
  covarSettingsWithoutVax <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                        useDemographicsAgeTenGroup = TRUE,
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
                                                                     endDays = -4,
                                                                     excludedCovariateConceptIds = CovVaxRelatedIDs, 
                                                                     addDescendantsToExclude = TRUE)
  
  
  getDbCmDataArgsWithCovVax <- CohortMethod::createGetDbCohortMethodDataArgs(
                                                                   restrictToCommonPeriod = FALSE,
                                                                   firstExposureOnly = TRUE,
                                                                   # removeDuplicateSubjects = "remove all",
                                                                   removeDuplicateSubjects = FALSE,
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covarSettingsWithVax,
                                                                   maxCohortSize = 100000)
  
  getDbCmDataArgsWithoutCovVax <- CohortMethod::createGetDbCohortMethodDataArgs(
                                                                    restrictToCommonPeriod = FALSE,
                                                                    firstExposureOnly = TRUE,
                                                                    # removeDuplicateSubjects = "remove all",
                                                                    removeDuplicateSubjects = FALSE,
                                                                    studyStartDate = "",
                                                                    studyEndDate = "",
                                                                    excludeDrugsFromCovariates = FALSE,
                                                                    covariateSettings = covarSettingsWithoutVax,
                                                                    maxCohortSize = 100000)
                                                                  
    createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                        priorOutcomeLookback = 365,
                                                                      minDaysAtRisk = 1,
                                                                      riskWindowStart = 1,
                                                                      startAnchor = "cohort start",
                                                                      riskWindowEnd = 0,	
                                                                      endAnchor = "cohort end",
                                                                      censorAtNewRiskWindow = TRUE,
                                                                      removeDuplicateSubjects = FALSE)
  
    #exclude covariates on: index month and year.
    # makeCovariateIdsToExclude <- function(){
    #   # Index month
    #   monthIds <-c(1:12) * 1000 + 7
    #   
    #   # Index year
    #   yearIds <- c(2020:2021) * 1000 + 6
    #   
    #   # insturement ids
    #   instrIds <- c(46273935504 , 44788635804, 44805294804,4085788804, 44791414504, 703447212, 44806111804, 4085475804, 703430802, 703446212, 4063579704, 37310271802, 46284832804, 44806912504, 46286388504, 439676210, 4154097804, 703424802, 37394694804, 44809297804, 44789367804, 4208082804, 4204498802, 4085781802, 44788959802, 44809259504, 4085922704, 44790917804, 44811250804, 4081597802, 44803642802)
    #   
    #   return(c(monthIds,yearIds, instrIds))
    # }
    
    CovVaxRelatedIDs.covar <- paste0(CovVaxRelatedIDs,"411")
    instrIds <- c(44791414503,37310267803,4150252803,46272951803)
    
    createLargeScalePsArgs  <- CohortMethod::createCreatePsArgs(
                  stopOnError = FALSE,
                  maxCohortSizeForFitting = 100000,
                  excludeCovariateIds = c(CovVaxRelatedIDs.covar,instrIds),
                  prior = Cyclops::createPrior(priorType = "laplace",
                                               variance = 0.0286,
                                               useCrossValidation = FALSE),
                  control = Cyclops::createControl(cvType = "auto",
                                                   startingVariance = 0.01,
                                                   noiseLevel = "quiet",
                                                   tolerance = 2e-07,
                                                   cvRepetitions = 10,
                                                   maxIterations = 1000))
                
  fitUnadjustedOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(
      useCovariates = FALSE,
      modelType = "poisson",
      stratified = FALSE,
      profileGrid = NULL)


  
  fitPsOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                  modelType = "poisson",
                                                                  stratified = TRUE,
                                                                  profileGrid = NULL)
 
  fitPsOutcomeModelRegularArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                   modelType = "poisson",
                                                                   stratified = TRUE,
                                                                   profileGrid = NULL,
                                                                   prior = Cyclops::createPrior(priorType = "normal",
                                                                                                variance = 2,
                                                                                                useCrossValidation = FALSE))
  
  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs(maxRatio = 1)
  
  matchOnPsArgs2 <- CohortMethod::createMatchOnPsArgs(maxRatio = 4)
  matchOnPsArgs2$allowReverseMatch <- TRUE
  
  
  #interaction terms to stratify model outcome 
  
  makeCovariateIdsToInclude <- function() {
    ageGroupIds <- unique(
      floor(c(18:110) / 10) * 1000 + 12
    )
    # Index month
    # monthIds <-c(1:12) * 1000 + 7
    # Gender
    genderIds <- c(8507, 8532) * 1000 + 1
    return(c(ageGroupIds
             # ,monthIds
             ,genderIds))
  }

  # interactionCovariateIds <- c(8532001, 201826210, 21600960413) # Female, T2DM, concurent use of antithrombotic agents
  
  fitPsInteractOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(modelType = "poisson",
                                                                  stratified = TRUE,
                                                                  useCovariates = FALSE,
                                                                  interactionCovariateIds = makeCovariateIdsToInclude(),
                                                                  profileGrid = NULL)
  
# ANALYSES  
  # Analysis 1 -- crude/unadjusted    
  cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                description = "Crude/unadjusted",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = FALSE,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitUnadjustedOutcomeModelArgs)
  
  # Analysis 2 --  large scale PS matching 
  cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                description = "One-on-one full Ps matching",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createLargeScalePsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs1,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitPsOutcomeModelArgs)
  
  # # Analysis 3 --  large scale PS matching 1 to 4 
  # cmAnalysis3 <- CohortMethod::createCmAnalysis(analysisId = 3,
  #                                               description = "One-to-four full Ps matching",
  #                                               getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
  #                                               createStudyPopArgs = createStudyPopArgs,
  #                                               createPs = TRUE,
  #                                               createPsArgs = createLargeScalePsArgs,
  #                                               matchOnPs = TRUE,
  #                                               matchOnPsArgs = matchOnPsArgs2,
  #                                               fitOutcomeModel = TRUE,
  #                                               fitOutcomeModelArgs = fitPsOutcomeModelArgs)
  # 
  #  # Analysis 4 --  large scale PS matching, stratify results on age, sex, index month.
  # cmAnalysis4 <- CohortMethod::createCmAnalysis(analysisId = 4,
  #                                               description = "One-on-one matching and result stratification",
  #                                               getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
  #                                               createStudyPopArgs = createStudyPopArgs,
  #                                               createPs = TRUE,
  #                                               createPsArgs = createLargeScalePsArgs,
  #                                               matchOnPs = TRUE,
  #                                               matchOnPsArgs = matchOnPsArgs1,
  #                                               fitOutcomeModel = TRUE,
  #                                               fitOutcomeModelArgs = fitPsInteractOutcomeModelArgs)

  # Analysis 5 --  large scale PS matching , regulization on results 
  cmAnalysis5 <- CohortMethod::createCmAnalysis(analysisId = 5,
                                                description = "One-on-one full Ps matching regulize results",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createLargeScalePsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs1,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitPsOutcomeModelRegularArgs)
  

  cmAnalysisList <- list(cmAnalysis1, cmAnalysis2
                         # , cmAnalysis3, cmAnalysis4
                         #
                         , cmAnalysis5)
  
  CohortMethod::saveCmAnalysisList(cmAnalysisList, file.path(workFolder, "cmAnalysisList.json"))
}

# createPositiveControlSynthesisArgs <- function(workFolder) {
#   settings <- list(
#     outputIdOffset = 10000,
#     firstExposureOnly = TRUE,
#     firstOutcomeOnly = TRUE,
#     removePeopleWithPriorOutcomes = TRUE,
#     modelType = "survival",
#     washoutPeriod = 183,
#     riskWindowStart = 0,
#     riskWindowEnd = 30,
#     addExposureDaysToEnd = TRUE,
#     effectSizes = c(1.5, 2, 4),
#     precision = 0.01,
#     prior = Cyclops::createPrior("laplace", exclude = 0, useCrossValidation = TRUE),
#     control = Cyclops::createControl(cvType = "auto",
#                                      startingVariance = 0.01,
#                                      noiseLevel = "quiet",
#                                      cvRepetitions = 1,
#                                      threads = 1),
#     maxSubjectsForModel = 250000,
#     minOutcomeCountForModel = 50,
#     minOutcomeCountForInjection = 25,
#     covariateSettings = FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = TRUE,
#                                                                    useDemographicsGender = TRUE,
#                                                                    useDemographicsIndexYear = TRUE,
#                                                                    useDemographicsIndexMonth = TRUE,
#                                                                    useConditionGroupEraLongTerm = TRUE,
#                                                                    useDrugGroupEraLongTerm = TRUE,
#                                                                    useProcedureOccurrenceLongTerm = TRUE,
#                                                                    useMeasurementLongTerm = TRUE,
#                                                                    useObservationLongTerm = TRUE,
#                                                                    useCharlsonIndex = TRUE,
#                                                                    useDcsi = TRUE,
#                                                                    useChads2Vasc = TRUE,
#                                                                    longTermStartDays = -365,
#                                                                    endDays = 0) 
#   )
#   ParallelLogger::saveSettingsToJson(settings, file.path(workFolder, "positiveControlSynthArgs.json"))
# }

