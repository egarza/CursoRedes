#!/bin/bash
# fmriprep_denoise.sh
# This script runs fmriprep with denoising options for a given subject.
# Usage: ./fmriprep_denoise.sh <subject_id>

SUBJ=$1

# 1. Load necessary modules
module load fsl
module load afni

# Define FWHM for spatial smoothing
FWHM=6  # Full Width at Half Maximum in mm

# 2. Define paths
path="/misc/tezca/egarza/Curso_Redes2026/derivatives/fmriprep_20/sub-${SUBJ}/func"
func_data="${path}/sub-${SUBJ}_task-rest_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz"
brain_mask="${path}/sub-${SUBJ}_task-rest_space-MNI152NLin6Asym_res-2_desc-brain_mask.nii.gz"
confounds_tsv="${path}/sub-${SUBJ}_task-rest_desc-confounds_timeseries.tsv"
func_final_smoothed="${path}/sub-${SUBJ}_task-rest_space-MNI152NLin6Asym_res-2_desc-denoised_smoothed${FWHM}_bold.nii.gz"

out_1D="${path}/sub-${SUBJ}_nuisance.1D"
censor_1D="${path}/sub-${SUBJ}_censor.1D"
out_errts="${path}/sub-${SUBJ}_errts.nii.gz"
out_stats="${path}/sub-${SUBJ}_stats.nii.gz"

# 3. Extract Confounds using R

Rscript -e "
# Read fMRIPrep TSV and set n/a to NA
df <- read.table('${confounds_tsv}', header=TRUE, sep='\t', na.strings=c('n/a', 'NA'))

# Replace NAs with 0 (necessary for the first volume of derivative regressors)
df[is.na(df)] <- 0

# Select the regressors you want to extract
cols_to_keep <- c('trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z', 'tcompcor', 'w_comp_cor_00', 'w_comp_cor_01', 'w_comp_cor_02', 'w_comp_cor_03', 'w_comp_cor_04', 'w_comp_cor_05', 'c_comp_cor_00', 'c_comp_cor_01', 'c_comp_cor_02', 'c_comp_cor_03', 'c_comp_cor_04', 'c_comp_cor_05')

# Write out a headerless, tab-separated .1D file for AFNI
write.table(df[, cols_to_keep], file='${out_1D}', row.names=FALSE, col.names=FALSE, sep='\t')


# Censor File (Motion Outliers)
# Find all columns that start with 'motion_outlier'
outlier_cols <- grep('motion_outlier', colnames(df), value=TRUE)

if (length(outlier_cols) > 0) {
    # Sum the outlier columns for each volume. If sum > 0, it is a bad volume.
    # We assign 0 to bad volumes (to drop) and 1 to good volumes (to keep) for AFNI.
    outlier_sum <- rowSums(df[, outlier_cols, drop=FALSE])
    censor_vec <- ifelse(outlier_sum > 0, 0, 1)
} else {
    # If no outliers were found, create a column of all 1s (keep everything)
    censor_vec <- rep(1, nrow(df))
}

write.table(censor_vec, file='${censor_1D}', row.names=FALSE, col.names=FALSE, sep='\t')
"

# 4. Denoise using 3dDeconvolve
#3dDeconvolve \
#    -input ${func_data} \
#    -polort A \
#    -ortvec ${out_1D} nuisance_regressors \
#    -x1D ${deriv_dir}/sub-${SUBJ}_X.xmat.1D \
#    -xjpeg ${deriv_dir}/sub-${SUBJ}_Xmat.jpg \
#    -fout -tout -rout \
#    -bucket ${out_stats} \
#    -errts ${out_errts}

# 4. Denoise using 3dTproject, especially if you want to apply bandpass filtering and censoring.

3dTproject \
    -input ${func_data} \
    -mask ${brain_mask} \
    -censor ${censor_1D} \
    -ort ${out_1D} \
    -polort 2 \
    -passband 0.01 0.1 \
    -prefix ${out_errts}

# 5. Spatial Smoothing (applied to the clean residuals)
3dBlurInMask \
    -input ${out_errts} \
    -mask ${brain_mask} \
    -FWHM ${FWHM} \
    -prefix ${func_final_smoothed}