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

  CovVaxRelatedIDs <-  c(37003431, 37003516, 37003436, 37003435, 37003518, 37003434, 35894915, 35897994, 1230962, 35895095, 35895096, 35891709, 35895097, 35891603, 35895098, 37003432, 37003517, 37003433, 724905, 702866, 766236, 766237, 766239, 766234, 766240, 766231, 766235, 766233, 766232, 766241, 766238, 724906, 724907, 35895192, 1227568, 36388974, 1230963, 42796343, 35891522, 35895099, 35891864, 35895100, 35891906, 35895190, 35895191, 35891484, 35891695, 35891649, 35895193, 35891890, 35895194, 35891433, 42639778, 42639775, 42639779, 42639776, 42639780, 42639777, 36391504, 42796198, 1219271, 42797615, 42797616, 724904, 829421, 739906, 739905, 739904, 739903, 739902, 739901, 35896177, 35896124, 35896164, 1226309, 2041351575, 2042141476, 2042126947, 2042117210, 2041379169, 2042067388, 2039314825, 2042084532, 2042072935, 2042056360, 2042082398, 2042134310, 2042132123, 2042127203, 2042118832, 2042100234, 2041378979, 2042121545, 2042119233, 2042058418, 2042138459, 2042109538, 2042087353, 2041377069, 2039142356, 2016979850, 2062184284, 2061206806, 2016980743, 2062184306, 2061206784, 2052924536, 2016993837, 2052934701, 2052925508, 2016979966, 2052924528, 2062184276, 2061207748, 2061206776
                         )


    covhisCovSet <- FeatureExtraction::createCohortAttrCovariateSettings(attrDatabaseSchema = cohortDatabaseSchema,
                                                                       cohortAttrTable = "covhis_cohort_attr",
                                                                       attrDefinitionTable = "covhis_attr_def",
                                                                       includeAttrIds = c(),
                                                                       isBinary = FALSE,
                                                                       missingMeansZero = FALSE)
  
 
    covarSettingsWithVax <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
                                                                     useDemographicsAgeTenGroup = TRUE,
                                                                     useDemographicsIndexYear =  TRUE, 
                                                                     useDemographicsIndexMonth = TRUE,
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
                                                                        useDemographicsIndexYear =  TRUE, 
                                                                        useDemographicsIndexMonth = TRUE,
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
  
  covarSettingsWithVaxList <- list(covarSettingsWithVax,covhisCovSet )
  covarSettingsWithoutVaxList <- list(covarSettingsWithoutVax,covhisCovSet)
   
  getDbCmDataArgsWithCovVax <- CohortMethod::createGetDbCohortMethodDataArgs(
                                                                   restrictToCommonPeriod = FALSE,
                                                                   firstExposureOnly = TRUE,
                                                                   removeDuplicateSubjects = "remove all",
                                                                   studyStartDate = "",
                                                                   studyEndDate = "",
                                                                   excludeDrugsFromCovariates = FALSE,
                                                                   # maxCohortSize = 100000 , #########
                                                                   covariateSettings = covarSettingsWithVaxList)
  
  getDbCmDataArgsWithoutCovVax <- CohortMethod::createGetDbCohortMethodDataArgs(
                                                                    restrictToCommonPeriod = FALSE,
                                                                    firstExposureOnly = TRUE,
                                                                    removeDuplicateSubjects = "remove all",
                                                                    studyStartDate = "",
                                                                    studyEndDate = "",
                                                                    excludeDrugsFromCovariates = FALSE,
                                                                    # maxCohortSize = 100000 , #########
                                                                    covariateSettings = covarSettingsWithoutVaxList)
                                                                  
    createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(removeSubjectsWithPriorOutcome = TRUE,
                                                                      minDaysAtRisk = 1,
                                                                      riskWindowStart = 1,
                                    																	startAnchor = "cohort start",
                                    																	riskWindowEnd = 28,
                                    																	endAnchor = "cohort start")
 
    fixedPsVariance <-  1  
    makeCovariateIdsToInclude <- function(includeIndexYear = FALSE) {
      ageGroupIds <- unique(
        floor(c(18:110) / 10) * 1000 + 12
      )
      # Index month
      monthIds <-c(1:12) * 1000 + 7
      # Gender
      genderIds <- c(8507, 8532) * 1000 + 1
      # diseases
      cond.general <- c(4006969210,438409210,4212540210,255573210,201606210,4182210210,440383210,201820210,318800210,192671210,439727210,432867210,316866210,4104000210,433736210,80180210,255848210,140168210,4030518210,80809210,435783210,4279309210,81893210,81902210,197494210,4134440210)
      cond.cvd <- c(313217210,381591210,317576210,321588210,316139210,4185932210,321052210,440417210,444247210)
      cond.neoplasms <- c(4044013210,432571210,40481902210,443392210,4112853210,4180790210,443388210,197508210,200962210)
      # medication use 
      medsIds <- c(21602796411,21604686411,21604389411,21603932411,21601387411,21602028411,21600960411,21601461411,21600046411,21603248411,21600712411,21603890411,21601853411,21604254411,21604489411,21604752411)
      # covid-19 history
      covid.covar.id <- 1
      
      return(c(covid.covar.id, ageGroupIds,monthIds,genderIds,cond.general,cond.cvd,cond.neoplasms, medsIds))
    }
    
    createMinPsArgs  <- CohortMethod::createCreatePsArgs(stopOnError = FALSE,
                                                          maxCohortSizeForFitting = 250000,
                                                          includeCovariateIds = makeCovariateIdsToInclude(),
                                                         prior = Cyclops::createPrior(priorType = "normal",
                                                                                      variance = fixedPsVariance,
                                                                                      useCrossValidation = FALSE))
    instrIds <- c(4150252, 3657627, 37310267, 44791414, 46272951, 44791497, 4073186, 4085788, 44806111, 37310271, 4628638, 3657634, 3657629, 37310272)
    instr.CovarIds <- c(paste0(instrIds,"403"),paste0(instrIds,"411"),paste0(instrIds,"703"),paste0(instrIds,"803"))
    instr.CovarIds <- as.numeric(instr.CovarIds)
    
    createLargeScalePsArgs  <- CohortMethod::createCreatePsArgs(
                                              stopOnError = FALSE,
                                              maxCohortSizeForFitting = 250000,
                                              excludeCovariateIds = c(instr.CovarIds),
                                              prior = Cyclops::createPrior(priorType = "laplace",
                                                                           useCrossValidation = FALSE,
                                                                           variance = 0.2),
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

  # fitPsOutcomeModelArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
  #                                                                 modelType = "poisson",
  #                                                                 stratified = TRUE,
  #                                                                 profileGrid = NULL)
 
  fitPsOutcomeModelRegularArgs <- CohortMethod::createFitOutcomeModelArgs(useCovariates = FALSE,
                                                                          modelType = "poisson",
                                                                          stratified = TRUE,
                                                                          profileGrid = NULL,
                                                                          prior = Cyclops::createPrior(priorType = "normal",
                                                                                                       variance = 2,
                                                                                                       useCrossValidation = FALSE))
  
#  matchOnPsArgs1 <- CohortMethod::createMatchOnPsArgs(maxRatio = 1)
  
  matchOnPsArgs2 <- CohortMethod::createMatchOnPsArgs(maxRatio = 4)
  matchOnPsArgs2$allowReverseMatch <- TRUE
  
  
  #interaction terms to stratify model outcome 
  
  makeInteraCovariateIdsToInclude <- function() {
    ageGroupIds <- unique(
      floor(c(18:110) / 10) * 1000 + 12
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
                                                                  interactionCovariateIds = makeInteraCovariateIdsToInclude(),
                                                                  profileGrid = NULL,
                                                                  prior = Cyclops::createPrior(priorType = "normal",
                                                                                               variance = 2,
                                                                                               useCrossValidation = FALSE))
  
# ANALYSES  
  # Analysis 1 -- crude/unadjusted    
  cmAnalysis1 <- CohortMethod::createCmAnalysis(analysisId = 1,
                                                description = "Crude/unadjusted",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = FALSE,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitUnadjustedOutcomeModelArgs)
  
  # Analysis 2 --  minimal PS matching 
  cmAnalysis2 <- CohortMethod::createCmAnalysis(analysisId = 2,
                                                description = "One-to-four minimal Ps matching",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createMinPsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs2,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitPsOutcomeModelRegularArgs)


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
                                                fitOutcomeModelArgs = fitPsOutcomeModelRegularArgs)
 
   # Analysis 4 --  large scale PS matching, stratify results on age, sex, index month.
  cmAnalysis4 <- CohortMethod::createCmAnalysis(analysisId = 4,
                                                description = "One-on- four matching and result stratification",
                                                getDbCohortMethodDataArgs = getDbCmDataArgsWithoutCovVax,
                                                createStudyPopArgs = createStudyPopArgs,
                                                createPs = TRUE,
                                                createPsArgs = createLargeScalePsArgs,
                                                matchOnPs = TRUE,
                                                matchOnPsArgs = matchOnPsArgs2,
                                                fitOutcomeModel = TRUE,
                                                fitOutcomeModelArgs = fitPsInteractOutcomeModelArgs)
  

  cmAnalysisList <- list(cmAnalysis1, 
                         cmAnalysis2, 
                         cmAnalysis3, cmAnalysis4) #, cmAnalysis5)
  
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

