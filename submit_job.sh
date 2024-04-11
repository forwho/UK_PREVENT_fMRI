#!/bin/bash
batch_preprocess()
{
source preprocess_config.sh
for subset in `ls $raw_path`
#for subset in subset_0
do
 echo $subset
 sbatch --export=subset="$subset" --job-name=$subset -o ../logs/preprocess_${subset}.log data_preprocess.sh
done
}
batch_preprocess
