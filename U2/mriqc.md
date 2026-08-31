# Usando MRIQC

Revisar el video de la clase práctica [Clase Practica 5](https://youtu.be/SyqWGyHzMeU?si=jgNJup7tboJMv-SX).

## Instalar Docker

Se intala primero Docker Engine para Ubuntu Terminal en este [link](https://docs.docker.com/engine/install/ubuntu/). Importante que no estoy instalando Docker Desktop, pero pueden hacerlo.

## Instalar MRIQC en Docker

En esta pagina podemos ver todo lo relacionado a MRIQC y otros programas en Docker, [link](https://www.nipreps.org/apps/docker/).
Ya teniendo Docker instalado, se usa el siguiente comando para instalar MRIQC

```sudo docker pull nipreps/mriqc```

## Correr MRIQC en un sujeto


```
sudo docker run -ti --rm \
-v $curso/afni/data_00_basic:/data:ro \
-v $curso/derivatives/mriqc:/out \
nipreps/mriqc \
/data /out \
participant --participant_label 112 115 206 310 417 516 603 607
```

## Correr MRIQC en muchos grupo

```
sudo docker run -ti --rm \
-v $curso/data_00_basic:/data:ro \
-v $curso/derivatives/mriqc:/out \
nipreps/mriqc \
/data /out \
group
```

## Correr MRIQC en Don Clusterio usando apptainer

Se debe activar el modulo apptainer

`module load apptainer`

Despues se debe crear una imagen de MRIQC importada de docker

`apptainer build mriqc.sif docker://nipreps/mriqc`

Esta se guarda en el folder donde estas. Una vez creada la imagen, ahora si podemos usar apptainer, por ejemplo:

```
fsl_sub -N mriqc apptainer run --cleanenv \
--bind /misc/tezca/egarza/Curso_Redes2026/afni/data_00_basic:/bids \
--bind /misc/tezca/egarza/Curso_Redes2026/derivatives/mriqc:/output \
/misc/tezca/egarza/apps/mriqc.sif \
/bids /output participant
```