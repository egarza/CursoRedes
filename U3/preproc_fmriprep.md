# fMRIprep Preprocesamiento

Este ejemplo es el Cluster C13, pero puede hacerse localmente aunque toma mucho tiempo. Localmente recomiendo seguir el tutorial del mismo `fmriprep`.

Don Clusterio no tiene disponible el módulo, y eso puede deberse a las tantas versiones que existen de fmriprep y su constante mantenimiento. Sin embargo no es un impedimento para trabajar con este pipeline.

Hay varios pasos previos al poder lanzar el script para preprocesar

1. Conseguir la version de fmriprep que deseamos usar.
2. Conseguir la licencia de freesurfer.
3. Tener los datos de la secuencia funcional, la anatomica y si lo tienes el fmap o el revpe de tu secuencia funcional para corregir las inhomogeneidades del campo.

## Bajar fmriprep

En [fmriprep](https://fmriprep.org/en/stable/) existen las instrucciones para bajar y correr `fmriprep`. Pero para usarlo en el cluster es igual que MRIQC, usando apptainer o singularity.

Carga primero apptainer 

`module load apptainer`

Ya en el directorio donde vayas a trabajar (recuerda que nunca en home) vas a escribir el comando segun la version que quieras descargar. Solo quieres la última versión, puedes usar el siguiente comando:

`apptainer build fmriprep.sif docker://nipreps/fmriprep`

## Conseguir la licencia de freesurfer

Necesitas el archivo de licencia de freesurfer, más adelante en el script sabrás por qué. [Aquí](https://surfer.nmr.mgh.harvard.edu/registration.html) la puedes conseguir, conservala simplemente con el nombre de _license.txt_. Ya que la tengas, ponla en el directorio donde vas a trabajar con fmriprep o donde quieras.

## Revisar que todo este en BIDS

Resulta que fmriprep espera encontrar los datos con esta estructura: 

**sub-020**

> anat

> > sub-020_ses-01_T1w.nii.gz

> > sub-020_ses-01_T1w.json

> func

> > sub-020_ses-01_task-rest_bold.nii.gz

> > sub-020_ses-01_task-rest_bold.json

Esto dentro de un directorio que se llama **raw20**

En el directorio scans, tambien espera encontrarse con un archivo que se llama **dataset_description.json**. Ese json tiene ni más ni menos que información sobre el estudio y la version de BIDS que se uso para ordenar los datos. 

Tienes que ya haber usado el BIDS validator para validar tu estructura BIDS.

## Correr fmriprep

Hay muchas formas de correrlo, esta es una pero tu puedes crear tu propia forma.

* Creas un script `sh`.

 `touch fmriprep.sh` 

Es importante tener bien definidos los paths o direcciones de tus diferentes directorios de trabajo, pero sobre todo TemplateFlow y la Licencia Freesurfer. Después es importante agregar estos paths a `apptainer` usando el flag `-B`. 

```
#!/bin/bash
#$ -S /bin/bash
#$ -N fmriprep

# Leer el nombre del sujeto desde la primera línea de comandos.
SUBJ=$1

#Se cargan los modulos necesarios
module load freesurfer
module load fsl
module load apptainer

#Aqui van los paths de tus directorios de trabajo, importante templateflow y freesurfer license.
path=/misc/tezca/egarza/Curso_Redes2026
input=${path}/raw20
output=${path}/derivatives/fmriprep_20
container=/misc/tezca/egarza/apps/fmriprep.sif
templateflow=/misc/tezca/egarza/templateflow
fs_license=/misc/tezca/egarza/freesurferLicense/license.txt
export APPTAINER_BINDPATH=/misc/tezca/egarza/Curso_Redes2026
export APPTAINERENV_TEMPLATEFLOW_HOME=${templateflow}
export FS_LICENSE=${fs_license}

if [ -d ${output} ];
then 
    echo "$output directory exists"
else
        mkdir $output
fi

# Crear un directorio de trabajo específico para cada sujeto.
workdir=${output}/work_${SUBJ}
mkdir -p ${output}
mkdir -p ${workdir}

# Ejecutar fmriprep dentro del contenedor Apptainer usando fsl_sub para enviar el trabajo al cluster.
fsl_sub -N fmriprep apptainer run --cleanenv -B ${path},${templateflow},${fs_license} ${container} \
${input} ${output} participant \
 --participant_label ${SUBJ} \
 --skip_bids_validation \
 --output-spaces MNI152NLin6Asym:res-2 \
 --fs-license-file ${fs_license} \
 --work-dir ${workdir}
```

* Someter el `job`

Esto puede ser de muchas formas. 

Por ejemplo si quieres someter un solo sujeto de tu folder bids:

`bash fmriprep.sh 020`

Si quieres someter a todos, puedes hacer una lista con los codigos de sujeto:

```
for subj_dir in /misc/tezca/egarza/Curso_Redes2026/raw20/sub-*/; do
    # Extract just the ID (e.g., "001" from "sub-001/")
    subj=$(basename ${subj_dir} | sed 's/sub-//')
    echo ${subj}
done
```

`bash fmripreptest.sh > subjects`

Esto crea un archivo de texto con la lista de sujetos.

Después solo creas un loop

 `cat subjects | while read i; do bash fmriprep.sh ${i}; done`

y puedes ver su estado escribiendo 

`qstat`

## Revisar resultados

Los resultados van a estar dentro del folder `output` que escogiste, con un folder y html con el nombre del sujeto. Se abre el HTML para hacer el control de calidad. 

Dentro del folder `/sub-020/func/` estara un archivo `sub-020_task-rest_desc-confounds_timeseries.tsv` en donde estarán todas las variables extraídas de tu sujeto (Primer Nivel) y que puedes usar para realizar `denoising`.

## Denoise usando AFNI

Puedes usar cualquier programa para hacer denoising. En este caso veremos el ejemplo con AFNI.

Primero hay que crear un script `fmiprep_denoise.sh`

En este ejemplo, usaremos un sujeto de la base de datos `raw20`. 
Es necesario primero revisar el archivo `confounds_timeseries.tsv` de fmriprep de un sujeto para decidir cuales columnas tomar para denoising.
Para hacer una matriz que pueda usar AFNI, tendremos que usar R para crearla, y después hacer la regresión y por último un smoothing.
Como `fmriprep` usa `n/a` para cuando no hay números, tenemos que cambiar esos valores a `0`.
En el caso de CENSORING, es importante mencionar que `fmriprep` usa varias columnas igual al número de volúmenes censurados, donde 1=censurar 0=bien. AFNI por el contrario usa una sola columna en donde 1=bien 0=censurar. Por lo que es necesario colapsar las columnas en una sola, y cambiar la codificación a lo opuesto.

```
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
```
Correr por ejemplo

`./fmriprep_denoise.sh 020`

o en loop en el cluster

`cat subjects | while read i; do fsl_sub -N denoise bash fmriprep_denoise.sh ${i}; done`

Con este script, nos debe arrojar un archivo `errts` que es el volumen en 3D (serie de tiempo) residual, y un achivo final con smoothing.



