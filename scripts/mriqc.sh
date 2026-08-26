sudo docker run -ti --rm \
-v $curso/afni/data_00_basic:/data:ro \
-v $curso/derivatives/mriqc:/out \
nipreps/mriqc \
/data /out \
participant --participant_label 112 115 206 310 417 516 603 607
