def modules = params.modules.clone()
params.options = [:]

include { FEATURES_PROCESSING       } from '../modules/data_analysis/features_processing'
include { EXPLORATORY_DATA_ANALYSIS } from '../modules/data_analysis/exploratory_data_analysis'
include { UNIVARIATE_ANALYSIS      } from '../modules/data_analysis/univariate_analysis'
include { MULTIVARIATE_ANALYSIS    } from '../modules/data_analysis/multivariate_analysis'

workflow DATA_ANALYSIS {
    take:
        metabolites
        metadata_column
    main:
        FEATURES_PROCESSING(metabolites, metadata_column)
        EXPLORATORY_DATA_ANALYSIS(FEATURES_PROCESSING.out.fd, metadata_column)
        UNIVARIATE_ANALYSIS(FEATURES_PROCESSING.out.fd, metadata_column)
        MULTIVARIATE_ANALYSIS(FEATURES_PROCESSING.out.fd, metadata_column)

    emit:
        univariate = UNIVARIATE_ANALYSIS.out.univariate
        multivariate = MULTIVARIATE_ANALYSIS.out.multivariate
}
