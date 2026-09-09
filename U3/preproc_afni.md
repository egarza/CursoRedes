# AFNI Preprocesamiento

Este ejemplo es el Cluster C13, pero puede hacerse localmente aunque toma mucho tiempo.

Si queremos que se haga la extracción de cerebro con freesurfer, se debe hacer de la manera siguiente.
Si no se quiere hacer con freesurfer, podemos saltarnos este paso hasta Correr AFNI PROC.

## Primero correr cada sujeto en Freesurfer

Se corre un N4 correction para mejorar el contraste antes de correr Freesurfer

```fsl_sub -N N4afni N4BiasFieldCorrection -d 3 -i sub-112_T1w.nii -o sub-112_T1w_N4.nii```

Ejemplo de script en Cluster C13:

```
module load freesurfer/7.4.1 fsl/6.0.7.4 afni/25.2.13 ANTs/2.4.4

export data=/misc/tezca/egarza/afni_practice/data_00_basic

for suj in sub-112 sub-115;
do

fsl_sub -N N4afni${suj} N4BiasFieldCorrection -d 3 -i $data/$suj/anat/${suj}_T1w.nii.gz -o $data/$suj/anat/${suj}_T1w_N4.nii.gz

done
```

`bash 01_runN4`

Cargar el modulo Freesurfer y correr sujeto para extraer cerebro.

```module load freesurfer/7.4.1```

```export SUBJECTS_DIR=/path/to/data/derivatives/freesurfer```

```fsl_sub -N sub-112 recon-all -subject sub-112 -i /path/sub-112_T1w_N4.nii -all```

Ejemplo de script en Cluster C13:

```
module load freesurfer/7.4.1 fsl/6.0.7.4 afni/25.2.13 ANTs/2.4.4

export SUBJECTS_DIR=/misc/tezca/egarza/afni_practice/derivatives/fs
export data=/misc/tezca/egarza/afni_practice/data_00_basic


for suj in sub-112 sub-115;

do

fsl_sub -N fs${suj} recon-all -all -subject ${suj}	\
-i $data/$suj/anat/${suj}_T1w_N4.nii.gz

done
```
Correr script 

`bash 02_runfs`

Va a tardar muchas horas así que pueden dejarlo y regresar después.

## Convertir de Freesurfer a SUMA AFNI

Se debe convertir ya que usaremos AFNI y las superficies no las lee directo de Freesurfer.

```@SUMA_Make_Spec_FS -sid sub-112 -NIFTI```

Ejemplo de script en Cluster C13:

```
#!/bin/bash

module load freesurfer/7.4.1 fsl/6.0.7.4 afni/25.2.13 ANTs/2.4.4

export data=/misc/tezca/egarza/afni_practice2025/derivatives/fs

for suj in sub-112 sub-115;

do

cd ${data}/${suj}

fsl_sub -N FS2SUMA_$suj @SUMA_Make_Spec_FS -sid ${suj} -NIFTI

done
```

`bash 03_runFS2SUMA`

## Revisa los resultados de Freesurfer con SUMA

Dentro del folder de SUMA donde convertiste todo de Freesurfer>

```
afni -niml & suma -spec std.141.sub-112_both.spec -sv sub-112_SurfVolcopy.nii
```

Me salía un error por usar AFNI viejo del cluster C13. Tuve que convertir el NIFTI para que no tuviera un problema de header.

```
3drefit -newid sub-111_SurfVol.nii
```
o

```
3dcopy sub-112_SurfVol.nii sub-112_SurfVolcopy.nii
```

# Correr un SSWarper

Antes de correr afni_proc.py correr este SSWarper para obtener transformaciones y cerebro T1w sin craneo.
Se corre con el comando siguiente, se puede hacer como script.

```tcsh SSwarper```

Primero creo un folder dentro de `derivatives_raw20` llamado `afniproc`.
Dentro, creo un folder llamado `AFNI_01_SSWarp`

Script

```
#!/bin/bash

module load freesurfer/7.4.1 fsl/6.0.7.4 afni/25.2.13 ANTs/2.4.4

export data=/misc/tezca/egarza/afni_practice/data_00_basic
export output=/misc/tezca/egarza/afni_practice/derivatives/afniproc/AFNI_01_SSWarp

for suj in sub-112 sub-115;

do

fsl_sub -N SSWarper_${suj} @SSwarper -input ${data}/${suj}/anat/${suj}_T1w_N4.nii.gz	\
                    -subid ${output}/${suj}	\
                    -odir  ${output}/${suj}_anat_warped	\
                    -base  MNI152_2009_template_SSW.nii.gz

done
```

`bash 04_runSSWarper`

## Correr AFNI PROC

Al correr `afni_proc.py` se corre automaticamente el Quality Control.

Se tiene que estar seguro donde estan los archivos, ya sea ponerlos todos en el mismo folder o solo dar los paths correctos.

Primero se crea un script. Hay muchos ejemplos en la página de AFNI, este script lo modifiqué de este: [https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/programs/alpha/afni_proc.py_sphx.html#example-11-resting-state-analysis-now-even-more-modern](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/programs/alpha/afni_proc.py_sphx.html#example-11-resting-state-analysis-now-even-more-modern)

Si no se quiere usar Freesurfer al inicio, hay ejemplos de scripts sin Freesurfer dentro de la página de AFNI.

Creo un folder dentro de `afniproc` llamado `AFNI_02_rest` y copio dentro el siguiente script:

```
#!/bin/tcsh

#module load freesurfer/7.4.1 fsl/6.0.7.4 afni/25.2.13 ANTs/2.4.4

# --------------------------------------------------
# note fixed top-level directories

set SUMA=/misc/tezca/egarza/afni_practice/derivatives/fs/
set warp=/misc/tezca/egarza/afni_practice/derivatives/afniproc/AFNI_01_SSWarp/
set data_root = /misc/tezca/egarza/afni_practice/
set input_root = $data_root/data_00_basic
set output_root = $data_root/derivatives/afniproc/AFNI_02_rest

set subjects = (sub-112 sub-115)

# process all subjects

foreach suj ($subjects)

#sub-112 sub-115

# --------------------------------------------------
   # note input and output directories
   set subj_indir = $input_root/$suj/func
   set subj_outdir = $output_root/$suj

# --------------------------------------------------
   # if output dir exists, this subject has already been processed
   if ( -d $subj_outdir ) then
      echo "** results dir already exists, skipping subject $suj"
      continue
   endif

# --------------------------------------------------
   # otherwise create the output directory, write an afni_proc.py
   # command to it, and fire it up

   mkdir -p $subj_outdir
   cd $subj_outdir

# create a run.afni_proc script in this directory
   cat > run.afni_proc << EOF

afni_proc.py                                                         \
    -subj_id                  ${suj}.rest                             \
    -blocks                   despike tshift align tlrc volreg blur  \
                              mask scale regress                     \
    -radial_correlate_blocks  tcat volreg regress                    \
    -copy_anat                $warp/${suj}_anat_warped/anatSS.${suj}.nii                          \
    -anat_has_skull           no                                     \
    -anat_follower            anat_w_skull anat $warp/${suj}_anat_warped/anatU.${suj}.nii         \
    -anat_follower_ROI        aaseg anat                             \
                              $SUMA/${suj}/SUMA/aparc.a2009s+aseg_REN_all.nii.gz       \
    -anat_follower_ROI        aeseg epi                              \
                              $SUMA/${suj}/SUMA/aparc.a2009s+aseg_REN_all.nii.gz       \
    -anat_follower_ROI        FSvent epi $SUMA/${suj}/SUMA/fs_ap_latvent.nii.gz        \
    -anat_follower_ROI        FSWe epi $SUMA/${suj}/SUMA/fs_ap_wm.nii.gz               \
    -anat_follower_erode      FSvent FSWe                            \
    -dsets                    $subj_indir/${suj}_task-rest_bold.nii.gz                    \
    -align_unifize_epi        local                                  \
    -align_opts_aea           -cost lpc+ZZ                           \
                              -giant_move                            \
                              -check_flip                            \
    -tlrc_base                MNI152_2009_template_SSW.nii.gz        \
    -tlrc_NL_warp                                                    \
    -tlrc_NL_warped_dsets     $warp/${suj}_anat_warped/anatQQ.${suj}.nii $warp/${suj}_anat_warped/anatQQ.${suj}.aff12.1D       \
                              $warp/${suj}_anat_warped/anatQQ.${suj}_WARP.nii                     \
    -volreg_align_to          MIN_OUTLIER                            \
    -volreg_align_e2a                                                \
    -volreg_tlrc_warp                                                \
    -mask_epi_anat            yes                                    \
    -blur_size                4                                      \
    -regress_apply_mot_types  demean deriv                           \
    -regress_motion_per_run                                          \
    -regress_anaticor_fast                                           \
    -regress_anaticor_label   FSWe                                   \
    -regress_ROI_PC           FSvent 3                               \
    -regress_ROI_PC_per_run   FSvent                                 \
    -regress_censor_motion    0.2                                    \
    -regress_censor_outliers  0.05                                   \
    -regress_make_corr_vols   aeseg FSvent                           \
    -regress_est_blur_epits                                          \
    -regress_est_blur_errts                                          \
    -html_review_style        pythonic

EOF
# EOF terminates the 'cat > run.afni_proc' command, above
# (it must not be indented in the script)

   # now run the analysis (generate proc and execute)
   tcsh run.afni_proc

# end loop over subjects
end
```

Después se corre el script así:

```tcsh afniproc```

## Correr Preprocesamiento

Este script crea el script final para correr el preprocesamiento completo en una computadora personal

```
fsl_sub -N sub112afniproc tcsh -xef proc.sub-112.rest |& tee output.proc.sub-112.rest
```

o puedes hacerlo en forma de script para muchos sujetos en paralelo en el cluster Don Clusterio:

```
for suj in sub-112 sub-115; do fsl_sub -N afniproc_$suj tcsh -xef $suj/proc.$suj.rest 2>&1 | tee $suj/output.proc.$suj.rest; done
```

# Quality Control

Para entender el QC, pueden revisar esta página: [https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/tutorials/apqc_html/apqc_ex1.html](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/tutorials/apqc_html/apqc_ex1.html)


```
open_apqc.py -infiles QC_*/index.html
```

