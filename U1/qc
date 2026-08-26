# Quality Control (Control de Calidad) Sencillo

## Revisar control de calidad con AFNI

Además del control de calidad visual que muestro en los videos del curso, cuando tenemos bases grandes es importante correr algunos comandos de AFNI.

Anatomia

```gtkyd_check.py -infiles data_00_basic/sub-*/ses-*/anat/*.nii.gz -outdir check_all_epi```

Funcional
```gtkyd_check.py -infiles data_00_basic/sub-*/ses-*/func/*.nii.gz -outdir check_all_epi```

The top row shows the things checked:
n3     : matrix size in 3 dimensions
nv     : number of volumes (AKA number of time points)
orient : dataset orientation on the disk
ad3    : voxel dimensions in 3D
tr     : TR (repetition time)
is slice_timing_nz : is there nonzero slice timing present? (1=yes, 0=no)
space  : what is the space of the dataset (ORIG for original, TLRC for template)
... and lots more properties, including NIFTI fields

