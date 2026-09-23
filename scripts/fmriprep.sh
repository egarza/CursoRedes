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
