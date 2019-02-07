#!/bin/bash
DIR=$1
Rscript generateSampleTSV.R $DIR/sample_info.csv $DIR/experimental_setup.csv $DIR/
Rscript setupPipelines.R $DIR/pipelines.csv /genesis/shahlab/bhewitson/$DIR
python check_bams.py $DIR/sample_info.csv $DIR/sample_info_checked.csv
