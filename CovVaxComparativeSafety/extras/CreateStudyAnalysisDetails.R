# Copyright 2021 Observational Health Data Sciences and Informatics
#
# This file is part of CovVaxComparativeSafety
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

  CovVaxRelatedIDs <-  c(37003516, 37003436, 37003518, 35894915, 35897994, 1230962, 35895095, 35895096, 35891709, 35895097, 35891603, 35895098, 37003432, 724905, 702866, 766236, 766237, 766239, 766234, 766240, 766231, 766235, 766233, 766232, 766241, 766238, 724906, 724907, 35895192, 1227568, 1230963, 42796343, 35891522, 35895099, 35891864, 35895100, 35891906, 35895190, 35895191, 35891484, 35891695, 35891649, 35895193, 35891890, 35895194, 35891433, 42639778, 42639775, 42639779, 42639776, 42639780, 42639777, 36391504, 42796198, 1219271, 42797615, 724904, 829421, 36388974, 37003431, 37003435, 37003434, 37003517, 37003433, 42797616, 4150252, 37310267, 3657627, 3657634, 3657629)
  
  covarSettingsWithVax <- FeatureExtraction::createDefaultCovariateSettings()
  covarSettingsWithVax[["DrugGroupEraLongTerm"]] <- FALSE
  covarSettingsWithVax[["MeasurementLongTerm"]] <- FALSE
  covarSettingsWithVax[["longTermStartDays"]] <- -9999
  covarSettingsWithVax[["mediumTermStartDays"]] <-  -365
  covarSettingsWithVax[["shortTermStartDays"]] <-  -180
  covarSettingsWithVax[["endDays"]] <- -4

  covarSettingsWithoutVax <- FeatureExtraction::createDefaultCovariateSettings(
    excludedCovariateConceptIds = CovVaxRelatedIDs, 
    addDescendantsToExclude = TRUE)
  
  covarSettingsWithoutVax[["DrugGroupEraLongTerm"]] <- FALSE
  covarSettingsWithoutVax[["MeasurementLongTerm"]] <- FALSE
  covarSettingsWithoutVax[["longTermStartDays"]] <- -9999
  covarSettingsWithoutVax[["mediumTermStartDays"]] <-  -365
  covarSettingsWithoutVax[["shortTermStartDays"]] <-  -180
  covarSettingsWithoutVax[["endDays"]] <- -4
  
   
  getDbCmDataArgsWithCovVax <- CohortMethod::createGetDbCohortMethodDataArgs(
                                                                   restrictToCommonPeriod = FALSE,
                                                                   firstExposureOnly = TRUE,
                                                                   removeDuplicateSubjects = "remove all",
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   covariateSettings = covarSettingsWithVax)
  
  getDbCmDataArgsWithoutCovVax <- CohortMethod::createGetDbCohortMethodDataArgs(
    restrictToCommonPeriod = FALSE,
    firstExposureOnly = TRUE,
    removeDuplicateSubjects = "remove all",
    studyStartDate = "",
    studyEndDate = "",
    excludeDrugsFromCovariates = FALSE,
    covariateSettings = covarSettingsWithoutVax)
  
    createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                      minDaysAtRisk = 1,
                                                                      riskWindowStart = 1,
																	startAnchor = "cohort start",
																	riskWindowEnd = 28,
																	endAnchor = "cohort start")
  
    createLargeScalePsArgs  <- CohortMethod::createCreatePsArgs(
                  stopOnError = FALSE,
                  maxCohortSizeForFitting = 150000,
                  prior = Cyclops::createPrior(priorType = "laplace",
                                               useCrossValidation = TRUE),
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
  
  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs(maxRatio = 1)
  
  matchOnPsArgs2 <- CohortMethod::createMatchOnPsArgs(maxRatio = 4)
  matchOnPsArgs2$allowReverseMatch <- TRUE
  
  
  #interaction terms to stratify model outcome 
  
  makeCovariateIdsToInclude <- function() {
    ageGroupIds <- unique(
      floor(c(18:110) / 5) * 1000 + 3
    )
    # Index month
    monthIds <-c(1:12) * 1000 + 7
    # Gender
    genderIds <- c(8507, 8532) * 1000 + 1
    return(c(ageGroupIds,monthIds,genderIds))
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
  
  # Analysis 3 --  large scale PS matching 1 to 4 
  cmAnalysis3 <- CohortMethod::createCmAnalysis(analysisId = 3,
                                                description = "One-to-four full Ps matching",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createLargeScalePsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs2,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitPsOutcomeModelArgs)
 
   # Analysis 4 --  large scale PS matching, stratify results on age, sex, index month.
  cmAnalysis4 <- CohortMethod::createCmAnalysis(analysisId = 4,
                                                description = "One-on-one matching and result stratification",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createLargeScalePsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs1,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitPsInteractOutcomeModelArgs)
  

  cmAnalysisList <- list(cmAnalysis1, cmAnalysis2, cmAnalysis3, cmAnalysis4) #, cmAnalysis5)
  
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

