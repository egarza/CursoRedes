# Practica de BIDS

## Instalar DCM2BIDS

[DCM2BIDS](https://unfmontreal.github.io/Dcm2Bids)

Instalar MINICONDA

[Miniconda](https://docs.anaconda.com/miniconda/)

Dentro de tu proyecto:

`touch environment.yml`

Editar esto dentro:

```
name: dcm2bids
channels:
  - conda-forge
dependencies:
  - python>=3.8
  - dcm2niix
  - dcm2bids
  ```

Crear el ambiente CONDA

```
conda env create --file environment.yml
```

Activate environment DCM2BIDS

```
conda activate dcm2bids
```

Correr

```
dcm2bids --help
```

Creamos un boceto de nuestro folder de proyecto.

```
dcm2bids_scaffold -o bids_project
```

Creamos un archivo temporal `config.json` para poder extraer los nombres de las secuencias que buscamos. Esto lo hacemos en un solo sujeto. 

```
dcm2bids_helper -d sourcedata/020
```

Revisamos los archivos que encontró, en este caso son 2 NIFTI y 2 JSON.

```
ls tmp_dcm2bids/helper
```

Revisar diferencias entre archivos JSON

```
diff --side-by-side tmp_dcm2bids/helper/"301_020_19010101000000.json" tmp_dcm2bids/helper/"601_020_19010101000000.json"
```

```
{                                                               {
        "Modality": "MR",                                               "Modality": "MR",
        "MagneticFieldStrength": 3,                                     "MagneticFieldStrength": 3,
        "ImagingFrequency": 127.766722,                       |         "ImagingFrequency": 127.766815,
        "Manufacturer": "Philips",                                      "Manufacturer": "Philips",
        "ImageType": ["ORIGINAL", "PRIMARY", "M", "FFE", "M",           "ImageType": ["ORIGINAL", "PRIMARY", "M", "FFE", "M",
        "SeriesNumber": 301,                                  |         "SeriesNumber": 601,
        "SliceThickness": 3,                                  |         "SliceThickness": 1,
        "SpacingBetweenSlices": 3,                            |         "SpacingBetweenSlices": 1,
        "SAR": 0.114973,                                      |         "SAR": 0.0382114,
        "EchoTime": 0.030001,                                 |         "EchoTime": 0.003501,
        "RepetitionTime": 2,                                  |         "RepetitionTime": 0.007,
        "FlipAngle": 75,                                      |         "FlipAngle": 8,
        "PercentPhaseFOV": 100,                                         "PercentPhaseFOV": 100,
        "PercentSampling": 100,                                         "PercentSampling": 100,
        "EchoTrainLength": 39,                                |         "EchoTrainLength": 240,
        "PhaseEncodingSteps": 78,                             |         "PhaseEncodingSteps": 240,
        "AcquisitionMatrixPE": 78,                            |         "AcquisitionMatrixPE": 240,
        "ReconMatrixPE": 80,                                  |         "ReconMatrixPE": 240,
        "AcquisitionDuration": 611.937,                       |         "AcquisitionDuration": 199.748,
        "PixelBandwidth": 2070,                               |         "PixelBandwidth": 310,
        "ImageOrientationPatientDICOM": [                               "ImageOrientationPatientDICOM": [
                0.994359,                                     |                 0.071907,
                -0.0763894,                                   |                 0.997403,
                0.0735906,                                    |                 0.00419276,
                0.0789394,                                    |                 0.043179,
                0.996353,                                     |                 0.0010868,
                -0.0323859      ],                            |                 -0.999067       ],
        "ConversionSoftware": "dcm2niix",                               "ConversionSoftware": "dcm2niix",
        "ConversionSoftwareVersion": "v1.0.20240202"                    "ConversionSoftwareVersion": "v1.0.20240202"
}
```

En este caso, el único diferenciador entre ambas secuencias parece ser "SeriesNumber". Usaremos ese criterio.

Creamos el `config.json` para poder generar las secuencias correctas. De preferencia dentro del folder `code`. 

Como pueden ver, tenemos el criterio de inclusion "in" como 
```
{
    "descriptions": [
        {
            "datatype": "anat",
            "suffix": "T1w",
            "criteria": {
                "SeriesNumber": "601"
            }
        },
        {
            "id": "id_task-rest",
            "datatype": "func",
            "suffix": "bold",
            "custom_entities": "task-rest",
            "criteria": {
                "SeriesNumber": "301*"
            },
            "sidecar_changes": {
        "TaskName": "rest"
      }
	}
    ]
}
```
Corremos ahora todo para ver si funciona.

dcm2bids -d sourcedata/020/ -p 020 -c code/config.json --auto_extract_entities

Debemos ver los folders del sujeto `sub_20` ahí.





