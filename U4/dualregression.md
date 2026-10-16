# Group ICA y Dual Regression

En este ejemplo usaremos FSL para realizar ICA usando Melodic y después hacer análisis estadístico de las redes usando Dual Regression.

## Bajar FSL

Esto se hace por medio de su página oficial: [FSL](https://fsl.fmrib.ox.ac.uk/fsl/docs/install/index.html)

## Estructura de los datos

FSL no usa formato BIDS, por lo que se recomienda copiar todos los archivos funcionales en un solo folder, así como los anatómicos.

Por ejemplo, yo hice una carpeta `fsl`.

> fsl

> > data
> > > anat

> > > > sub-020_ses-01_T1w.nii.gz
> > > > sub-021_ses-01_T1w.nii.gz
..

> > > func

> > > > sub-020_ses-01_task-rest_bold.nii.gz
> > > > sub-021_ses-01_task-rest_bold.nii.gz

## Realizar Skull Stripping

Pueden hacerlo con cualquier programa, `FSL` utiliza `BET`.
Se guardan los nuevos cerebros dentro del folder `anat` con el sufijo `_brain.nii.gz`.

## GUI

Para todo se utiliza la interfase gráfica ya que `MELODIC` es diferente en comandos. 

## MELODIC

Para realizar **Group ICA** se utiliza la herramienta [MELODIC](https://fsl.fmrib.ox.ac.uk/fsl/docs/resting_state/melodic.html) de `FSL`.

# GUI de Melodic

Para abrir la GUI de MELODIC, escriba `Melodic` en una terminal (escriba `Melodic_gui` en Mac), o ejecute `fsl` y presione el botón **MELODIC**.

## Misc

El botón del observador de progreso (**Progress watcher**) le permite indicar a Melodic que no inicie un navegador web para observar el avance del análisis. Si está ejecutando muchos análisis, probablemente querrá desactivar esta opción; en su lugar, puede ver la misma información consultando los archivos `report_log.html` o `log.txt` en cualquiera de los directorios de MELODIC.

## Datos

Primero, establezca el nombre del archivo de la imagen de entrada 4D (por ejemplo, `sub-020_ses-01_task-rest_bold.nii.gz`) presionando **Select 4D data** (Seleccionar datos 4D). Puedes seleccionar varios archivos si deseas que MELODIC realice un análisis de grupo o si deseas ejecutar ICA separados con la misma configuración. Los resultados de cada archivo de entrada se guardarán en directorios `.ica` separados, cuyo nombre se basará en el nombre del archivo de los datos de entrada (a menos que introduzca un nombre en el directorio de salida / *Output directory*).

**Delete volumes** (Eliminar volúmenes) controla el número de volúmenes iniciales de fMRI que se eliminarán antes de cualquier procesamiento adicional.

**TR** controla el tiempo (en segundos) entre el escaneo de volúmenes de fMRI sucesivos. Los cambios aquí no afectarán el análisis y solo cambiarán las unidades del eje X en los gráficos finales de series temporales.

El punto de corte del filtro de pasa altas (**High pass filter cutoff**) controla el período temporal más largo que se permitirá.

## Pre-Estadísticas (Pre-Stats)

Las derivas de baja frecuencia y el movimiento en los datos pueden afectar negativamente la descomposición. En la mayoría de los casos, es recomendable corregir el movimiento de los datos, eliminar estas derivas primero o realizar otros tipos de preprocesamiento típico antes de ejecutar el análisis. Esto se puede hacer desde la sección **Pre-stats** de la GUI de Melodic.

## Registro (Registration)

Antes de poder llevar a cabo cualquier análisis multisesión o multisujeto, las diferentes sesiones deben registrarse entre sí. Esto se facilita dentro de MELODIC, que realiza el registro en los datos de entrada como parte de un análisis utilizando la funcionalidad de FEAT. A diferencia del paso de registro en FEAT, aquí debe realizarse antes del análisis estadístico para que los datos funcionales filtrados se transformen al espacio estándar. Para obtener información sobre el uso del registro en múltiples etapas, consulta el manual de FEAT.

Recomiendo usar transformación No Lineal al espacio estandar además del Lineal.

El espacio estándar (**Standard space**) se refiere a la imagen estándar (de referencia); debe ser una imagen que ya esté en el espacio estándar, idealmente con las estructuras no cerebrales ya eliminadas.

La resolución de remuestreo en mm (**Resampling resolution (mm)**) se refiere a la dimensión de vóxel isotrópico deseada para los datos remuestreados. Con el fin de ahorrar espacio en disco y memoria requerida durante el análisis, es aconsejable remuestrear los datos filtrados al espacio estándar pero manteniendo la resolución remuestreada igual a la resolución de la fMRI (típicamente 4 mm o 5 mm).

## Estadísticas (Stats)

La sección de Estadísticas (**Stats**) le permite controlar algunas de las opciones para la descomposición. Lo más probable es que la configuración predeterminada ya esté ajustada a lo que deseará la mayor parte del tiempo.

Por defecto, MELODIC normalizará la varianza de los cursos temporales.

Por defecto, Melodic estimará automáticamente el número de componentes a partir de los datos; puede desactivar esta opción y luego especificar el número de componentes explícitamente. Por ejemplo: 10, 20, 30, etc.

Ahora puede seleccionar el tipo de análisis. Actualmente, MELODIC ofrece tres opciones, pero para  `Dual Regression` usaremos solo `Multi-session temporal concatenation`

### Multi-session temporal concatenation

Esto realizará una única ejecución de ICA 2D sobre la matriz de datos concatenada (obtenida apilando todas las matrices de datos 2D de cada conjunto de datos individual una encima de la otra). Se recomienda utilizar este enfoque en los casos en que se buscan patrones espaciales comunes, pero no se puede asumir que la respuesta temporal asociada sea consistente entre sesiones/sujetos. Los ejemplos incluyen estudios de activación en los que el diseño se aleatorizó entre sesiones, o el análisis de datos adquiridos sin estimulación (resting state fMRI).

Este enfoque no asume que el patrón de respuesta temporal sea el mismo en toda la población, aunque el informe web final contendrá el primer vector propio (*Eigenvector*) de todas las diferentes respuestas temporales como un curso temporal resumido.

El acceso a todos los cursos temporales está disponible: el gráfico de series temporales está enlazado a un archivo de texto (`tXX.txt`) que contiene el primer vector propio, el mejor ajuste del modelo (en caso de que se haya especificado un diseño de series temporales) y todos los diferentes cursos temporales específicos de cada sujeto/sesión en forma de columnas. Para cada componente, la matriz de mezcla final `melodic_mix` contiene la respuesta temporal de todos los diferentes conjuntos de datos concatenados en un único vector columna. El curso temporal reportado finalmente será la mejor aproximación de rango 1 (*rank-1*) a estas diferentes respuestas.

## Post-Estadísticas (Post-Stats)

Por defecto, MELODIC también llevará a cabo inferencia en los mapas estimados utilizando un modelo de mezcla (*mixture model*) y un enfoque de prueba de hipótesis alternativa. Un nivel de umbral de 0.5 en el caso de la prueba de hipótesis alternativa significa que un vóxel 'sobrevive' a la umbralización tan pronto como la probabilidad de estar en la clase 'activa' (como se modela por las densidades Gamma) supera la probabilidad de estar en la clase de ruido de 'fondo' (*background*). Este nivel de umbral asume que se asigna una pérdida igual a los falsos positivos y a los falsos negativos. Sin embargo, si considera, por ejemplo, que los falsos positivos son el doble de malos que los falsos negativos, debería cambiar este valor a 0.66.

Puede seleccionar la imagen de fondo utilizada para la generación de las imágenes superpuestas del mapa espacial.

Si seleccionas la opción de salida de la carpeta de estadísticas completas (**Output full stats folder**), MELODIC guardará los mapas umbralizados y los mapas de probabilidad en un subdirectorio `/stats` dentro de su carpeta de salida.

Si tienes tareas (tasks), puedes especificar una matriz de diseño temporal (y, en el caso de un análisis de grupo, también una matriz de diseño de sesión/sujeto), así como las matrices de contraste correspondientes. Si estas matrices se configuran en la GUI, MELODIC realizará un análisis de regresión *post-hoc* sobre los cursos temporales estimados y los modos de sesión/sujeto. Esta puede ser una herramienta útil para identificar si un componente determinado está o no relacionado con la tarea. Las matrices en sí pueden crearse fácilmente utilizando la GUI de GLM.

## Fila inferior de botones

Cuando haya terminado de configurar MELODIC, presione **Go** (Ejecutar) para iniciar el análisis. Una vez que MELODIC esté en ejecución, puede salir (**Exit**) de la GUI o configurar análisis adicionales.

Los botones de guardar (**Save**) y cargar (**Load**) le permiten guardar y cargar la configuración completa de MELODIC hacia y desde un archivo.
Recomiendo guardarlo.

## Salida del informe de MELODIC

Melodic generará entonces los resultados y la ventana de su terminal les indicará dónde encontrar el informe web. Cada página web `IC_XX.html` muestra un mapa espacial umbralizado y renderizado sobre una imagen de fondo, seguido por el curso temporal relevante de la descomposición ICA y el espectro de potencia del curso temporal. Si haces clic en el mapa umbralizado, puedes inspeccionar la salida en bruto de los Componentes Independientes (IC) junto con los mapas de probabilidad y el ajuste del modelo de mezcla (*Mixture Model*).

Puedes revisar todos los componentes o redes y visualmente determinar cuales son de tu interés.

# Dual Regression

Ya que tienes MELODIC realizado, el archivo `melodic.gica/groupmelodic.ica/melodic_IC.nii.gz` tendrá todas las redes o componentes que sacó. Si no quieres correr Dual Regression en todos, puedes reducir el archivo a los componentes que tu quieras. Por ejemplo usando la herramienta `fslroi` extraeré solo el componente 28:

`fslroi melodic_IC.nii.gz melodic_IC_28.nii.gz 27 1`

Usa `Glm` (o cualquier otro método) para crear tu matriz de diseño multisujeto y los archivos de contraste (`design.mat` / `design.con`).

Ejecuta `dual_regression`. Simplemente escribe `dual_regression` para ver cómo se usa:

```text
Uso: dual_regression <group_IC_maps> <des_norm> <design.mat> <design.con> <n_perm> [--thr] <output_directory> <input1> <input2> <input3> .........
ej.  dual_regression groupICA.gica/groupmelodic.ica/melodic_IC 1 design.mat design.con 500 0 grot `cat groupICA.gica/.filelist`

```

* `<group_IC_maps_4D>`: Imagen 4D que contiene los mapas espaciales IC (`melodic_IC`) del análisis ICA de todo el grupo.
* `<des_norm>`: `0` o `1` (se recomienda `1`). Indica si quieres normalizar la varianza de los cursos temporales utilizados como regresores en la etapa 2.
* `<design.mat>`: Matriz de diseño para el modelado final entre sujetos (cross-subject) con `randomise`.
* `<design.con>`: Contrastes de diseño para el modelado final entre sujetos con `randomise`.
* `<n_perm>`: Número de permutaciones para `randomise`; ponlo en `1` para obtener solo la salida cruda tstat, o ponlo en `0` si no quieres ejecutar `randomise` en lo absoluto.
* `[--thr]`: Realiza una regresión dual con umbral para obtener series temporales no sesgadas para análisis de conectómica (ej. con FSLnets).
* `<output_directory>`: Este directorio se creará para guardar todos los archivos de salida y registros (*logfiles*).
* `<input1> <input2> ...`: Enumera todos los conjuntos de datos 4D preprocesados y en espacio estándar de los sujetos.

`<design.mat>` y `<design.con>` se pueden reemplazar simplemente con `-1` para un modelado de media de grupo (prueba t de un grupo).

La opción `des_norm` determina si normalizarás la varianza de los cursos temporales creados por la etapa 1 de la regresión dual; estos son los que se utilizan como regresores en la etapa 2. Si no los normalizas, entonces solo estarás evaluando la "forma" de las RSN (*Resting State Networks* o Redes en Estado de Reposo) en tus pruebas entre sujetos. Si los normalizas, estarás evaluando tanto la "forma" como la "amplitud" de las RSN.

Una forma fácil de obtener la lista de entradas (todos los archivos de series temporales 4D en espacio estándar de los sujetos) al final del comando es usar lo siguiente (en lugar de listar los archivos explícitamente, a mano), para obtener la lista de archivos que introdujiste en tu ICA de grupo: ``cat melodic.gica/.filelist``

Este es un ejemplo de mi script usando los datos **raw20**. En este ejemplo no corrí  `randomise` por lo que las permutaciones quedaron en `1`. Si quiers realizar `randomise` entonces agrega 500 o 1000 permutaciones. Este script corre todas las redes que se encontraron.

```
dual_regression ../melodic.gica/groupmelodic.ica/melodic_IC.nii.gz 1 ../design_dualreg.mat ../design_dualreg.con 1 test \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-020_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-021_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-022_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-023_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-024_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-025_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-026_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-027_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-028_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-029_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-030_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-031_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-032_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-033_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-034_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-035_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-036_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-038_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-091_task-rest_bold_melodic.ica/reg_standard/filtered_func_data \
/mnt/c/Trabajo/Academia/Docencia/Cursos/2026/CursoRedes_2026/fsl/data/func/sub-093_task-rest_bold_melodic.ica/reg_standard/filtered_func_data
```
Dentro de tu folder, en este caso `test`, estaran tus resultados.
Si corriste solo `1` permutacion, solo habrá archivos Stage 3 `tstat`.
Si corriste `randomise`, habrá archivos Stage 3 `corrp` que son los resultados estadísticos de tu modelo. 

Para visualizar puedes usar el Template que usaste en el analisis y uno de los resultados del Stage 3. Recuerda que FSLEyes usa 0.95 y no 0.05 como threshold.

### Explicación de los resultados

* `dr_stage1_subject[#SUB].txt` - los resultados de series temporales de la etapa 1 de la regresión dual. Un archivo de texto por sujeto, cada uno conteniendo columnas de series temporales: una serie temporal por componente del ICA de grupo. Estas series temporales pueden usarse en modelos de redes adicionales, por ejemplo, tomando las N series temporales y generando una matriz de correlación NxN.
* `dr_stage2_subject[#SUB].nii.gz` - los resultados de mapas espaciales de la etapa 2 de la regresión dual. Un archivo de imagen 4D por sujeto, y dentro de cada uno, un punto temporal (imagen 3D) por cada componente original del ICA de grupo. Estas son las imágenes de "estimación de parámetros" (PE) del GLM, es decir, no están normalizadas por el ruido residual intrasujeto. Por defecto, te recomendamos que sean estas las que introduzcas en la etapa 3 (el modelado final entre sujetos).
* `dr_stage2_subject[#SUB]_Z.nii.gz` - la versión de estadística Z de lo anterior, que podrías usar en el modelado entre sujetos, pero en general no parece funcionar tan bien como usar las PE.
* `dr_stage2_ic[#ICA].nii.gz` - lo mismo que las imágenes PE descritas arriba, pero reorganizadas para ser un archivo de imagen 4D por componente del ICA de grupo, y, dentro de cada uno, tener un punto temporal (imagen 3D) por sujeto. Esta reorganización es para permitir la etapa 3, el modelado entre sujetos para cada componente del ICA de grupo, así que estos son los archivos que normalmente introducirías en `randomise`.
* `dr_stage3_ic[#ICA]_tstat[#CON].nii.gz` - el resultado de la "etapa 3", es decir, archivos creados al ejecutar `randomise`, haciendo estadísticas entre sujetos por separado para cada componente del ICA de grupo. Obtendrás un conjunto de archivos de salida estadísticos por cada componente del ICA de grupo y, dentro de ese conjunto, un t-stat (etc.) por cada contraste en el archivo de contrastes entre sujetos (`design.con`). Las imágenes correspondientes de valores p corregidos (1-p) se llaman `*corrp*`.

### Corrección por comparaciones múltiples en todas las RSN

**La necesidad de corrección, y la corrección mediante Bonferroni**

> **Advertencia:** Los valores p corregidos que genera el `randomise` final (`corrp`) están completamente corregidos por comparaciones múltiples entre vóxeles, pero solo para cada RSN por sí misma, y solo haciendo pruebas de una cola (para contrastes t especificados en `design.con`).

Esto significa que si evalúas (con `randomise`) todos los componentes encontrados por el ICA de grupo inicial, y no tienes una razón previa para considerar solo uno de ellos, debes corregir tus valores p corregidos por un factor adicional.

Por ejemplo, digamos que tu ICA de grupo encontró 30 componentes, y decidiste ignorar 18 de ellos por ser artefactos. Por lo tanto, solo consideraste 12 RSN como de interés potencial, y miraste los resultados de `randomise` para estas 12, siendo tu modelo una prueba de dos grupos (controles y pacientes). Sin embargo, no sabías si estabas buscando aumentos o disminuciones en la conectividad de las RSN, por lo que ejecutaste el contraste de dos grupos en ambas direcciones para cada RSN. En este caso, en lugar de que tus valores p corregidos deban ser `< 0.05` para tener significancia completa, ¡realmente necesitan ser `< 0.05 / (12 * 2) = 0.002`.




