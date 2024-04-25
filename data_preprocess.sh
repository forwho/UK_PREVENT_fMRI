#!/bin/bash
#SBATCH --time=96:00:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
config_path=/mnt/parscratch/users/md1weih/UK_PREVENT_fMRI/code/UK_PREVENT_fMRI/
source $config_path/lib_config.sh
export PATH=$conda_path/envs/prv/bin/:$PATH
export PYTHONPATH=$conda_path/envs/prv/lib/python3.8/site-packages/:$PYTHONPATH
data_organise()
{
    source /mnt/parscratch/users/md1weih/UK_PREVENT_fMRI/code/UK_PREVENT_fMRI//organise_config.sh
    if [ ! -e $target_path ];then
        mkdir -p $target_path
    fi
    fmris=(`ls $raw_path/fMRI/*.nii.gz`)
    endvalue=$(expr ${#fmris[@]} - 1)
    for i in `seq 0 $endvalue`
    do
        sub=${fmris[$i]}
        tmp_sub=${sub##*/}
        subname=${tmp_sub:3:5}
        t1file=`ls $raw_path/MRI/T1w_MR*${subname}*.nii`
        if [ ! "$t1file" == "" ];then
            mkdir -p $target_path/sub-$subname/anat
            mkdir -p $target_path/sub-$subname/func
            cp $sub $target_path/sub-$subname/func/sub-${subname}_task-rest_bold.nii.gz
            cp ${sub%%.*}.json $target_path/sub-$subname/func/sub-${subname}_task-rest_bold.json
            cp $t1file $target_path/sub-$subname/anat/sub-${subname}_T1w.nii
            echo '{"modality": "t1w"}' > $target_path/sub-$subname/anat/sub-${subname}_T1w.json
        else
            echo $subname
        fi
    done
}
data_reorganise()
{
    source $config_path/reorganise_config.sh
    subset_num=$1
    init_group=-1
    subs=(`ls $data_path`)
    endvalues=$(expr ${#subs[@]} - 1)
    for i in `seq 0 $endvalues`
    do
        group=$(expr $i / $subset_num)
        if [ $group -eq $init_group ];then
            mv $data_path/${subs[$i]} $data_path/subset_${init_group}
        else
            init_group=$group
            mkdir $data_path/subset_${init_group}
            echo '{"Name": "Example dataset", "BIDSVersion": "1.0.2"}' > $data_path/subset_${init_group}/dataset_description.json
            mv $data_path/${subs[$i]} $data_path/subset_${init_group}
            echo '{"dataset": "uk prefent"}' > $data_path/subset_${init_group}/dataset_description.json
        fi
    done
}
data_reorganise2()
{
    source $config_path/preprocess_config.sh
    for subset in `ls $preprocessing_path`
    do
        for sub in `ls $preprocessing_path/$subset`
        do
            if [ ! -e "$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-smooth_bold.nii.gz" ];then
                if [ -e "$preprocessing_path/$subset/$sub/func/" ];then
                    #ls $preprocessing_path/$subset/$sub/func
                    rm -r $preprocessing_path/$subset/$sub
                fi
            fi  
        done
    done
}
data_check()
{
    source $config_path/preprocess_config.sh
    for subset in `ls $raw_path/`
    do
        for sub in `ls $raw_path/$subset/sub* -d`
        do
            subname=${sub##*/}
            if [ ! -e "$preprocessing_path/$subset/$subname/func/${subname}_task-rest_space-MNI152NLin2009cAsym_desc-smooth_bold.nii.gz" ];then
                ls $sub/*
            fi
        done
    done
}
data_preprocess()
{
    echo "Start preprocessing"
    source $config_path/preprocess_config.sh
    subset=$1
    mkdir -p $preprocessing_path/$subset
    mkdir -p $working_path/$subset
    echo $raw_path/$subset
    singularity run $simg_path/fmriprep.simg --skip_bids_validation --fs-license-file $simg_path/freesurfer/license.txt --fs-no-reconall -w $working_path/$subset $raw_path/$subset $preprocessing_path/$subset participant
    for sub in `ls $preprocessing_path/$subset`
    do
        singularity run $simg_path/afni.simg 3dDespike -prefix $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-despike_bold.nii.gz $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz

        python -c "from preprocess import clean_data;clean_data(\"$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-despike_bold.nii.gz\",\"$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz\",\"$preprocessing_path/$subset/$sub/func/${sub}_task-rest_desc-confounds_timeseries.tsv\",2,\"$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-reg_bold.nii.gz\")"

        singularity run $simg_path/afni.simg 3dBlurToFWHM -prefix $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-smooth_bold.nii.gz -mask $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -FWHM 8 $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-reg_bold.nii.gz
    done
}
#14:07 14:35 15:19 15:47
#data_organise
#data_reorganise 11
#subset=subset_52
data_preprocess $subset
#data_reorganise2
#data_check
