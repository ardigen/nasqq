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
        FEATURES_PROCESSING(metabolites, metadata_column, params.zeronan_threshold)
        EXPLORATORY_DATA_ANALYSIS(FEATURES_PROCESSING.out.fd, metadata_column)
        UNIVARIATE_ANALYSIS(FEATURES_PROCESSING.out.fd, metadata_column, params.pvalue_shapiro)
        MULTIVARIATE_ANALYSIS(FEATURES_PROCESSING.out.fd, metadata_column, params.test_size, params.cross_val_fold)

    emit:
        univariate = UNIVARIATE_ANALYSIS.out.univariate
        multivariate = MULTIVARIATE_ANALYSIS.out.multivariate
}
