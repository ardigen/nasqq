def modules = params.modules.clone()
params.options = [:]

include { LOAD_FIDS                   } from '../modules/spectral_preprocessing/load_fids'
include { RAW_FIDS_VISUALIZATION      } from '../modules/spectral_preprocessing/raw_fids_visualization'
include { GROUP_DELAY_CORRECTION      } from '../modules/spectral_preprocessing/group_delay_correction'
include { SOLVENT_SUPPRESSION         } from '../modules/spectral_preprocessing/solvent_suppression'
include { APODIZATION                 } from '../modules/spectral_preprocessing/apodization'
include { ZERO_FILLING                } from '../modules/spectral_preprocessing/zero_filling'
include { FOURIER_TRANSFORMATION      } from '../modules/spectral_preprocessing/fourier_transformation'
include { ZERO_ORDER_PHASE_CORRECTION } from '../modules/spectral_preprocessing/zero_order_phase_correction'
include { INTERNAL_REFERENCING        } from '../modules/spectral_preprocessing/internal_referencing'
include { BASELINE_CORRECTION         } from '../modules/spectral_preprocessing/baseline_correction'
include { NEGATIVE_VALUES_ZEROING     } from '../modules/spectral_preprocessing/negative_values_zeroing'
include { WARPING                     } from '../modules/spectral_preprocessing/warping'
include { WINDOW_SELECTION            } from '../modules/spectral_preprocessing/window_selection'
include { BUCKETING                   } from '../modules/spectral_preprocessing/bucketing'
include { NORMALIZATION               } from '../modules/spectral_preprocessing/normalization'

workflow SPECTRAL_PREPROCESSING {
    take:
        samples
    main:
        LOAD_FIDS(samples, params.check_pulse_samples)
        RAW_FIDS_VISUALIZATION(LOAD_FIDS.out.flow)
        GROUP_DELAY_CORRECTION(LOAD_FIDS.out.flow)
        SOLVENT_SUPPRESSION(GROUP_DELAY_CORRECTION.out.flow)
        APODIZATION(SOLVENT_SUPPRESSION.out.flow, params.check_pulse_samples)
        ZERO_FILLING(APODIZATION.out.flow)
        FOURIER_TRANSFORMATION(ZERO_FILLING.out.flow)
        ZERO_ORDER_PHASE_CORRECTION(FOURIER_TRANSFORMATION.out.flow)
        INTERNAL_REFERENCING(ZERO_ORDER_PHASE_CORRECTION.out.flow, params.reverse_axis_samples)
        BASELINE_CORRECTION(INTERNAL_REFERENCING.out.flow)
        NEGATIVE_VALUES_ZEROING(BASELINE_CORRECTION.out.flow)

        if (params.run_warping) {
            WARPING(NEGATIVE_VALUES_ZEROING.out.flow)
            WINDOW_SELECTION(WARPING.out.flow)
        } else {
            WINDOW_SELECTION(NEGATIVE_VALUES_ZEROING.out.flow)
        }

        if (params.run_bucketing) {
            BUCKETING(WINDOW_SELECTION.out.flow)
            NORMALIZATION(BUCKETING.out.flow)
        } else {
            NORMALIZATION(WINDOW_SELECTION.out.flow)
        }

    emit:
        normalized_metabolites = NORMALIZATION.out.flow
}
