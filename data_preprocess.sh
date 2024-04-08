source lib_config.sh
export PATH=$conda_path/envs/pnc/bin/:$PATH
export PYTHONPATH=$conda_path/envs/pnc/lib/python3.8/site-packages/
data_organise()
{
    source organise_config.sh
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
    subset_num=$1
    init_group=-1
    subs=`ls $data_path`
    endvalues=$(expr ${#subs[@]} - 1)
    for i in `seq 0 $endvalues`
    do
        group=$(expr $i / $subset_num)
        if [ $group -eq $init_group ];then
            mv $data_path/${subs[$i]} $data_path/subset_${init_group}
        else
            init_group=$group
            mkdir d$ata_path/subset_${init_group}
            mv $data_path/${subs[$i]} $data_path/subset_${init_group}
        fi
    done
}
data_preprocess()
{
    source preprocess_config.sh
    subset=$1
    mkdir -p $preprocessing_path/$subset
    mkdir -p $working_path/$subset
    singularity run fmriprep.simg --skip_bids_validation --fs-license-file ./freesurfer/license.txt --fs-no-reconall $raw_path/$subset $preprocessing_path/$subset -w $working_path/$subset
    for sub in `ls $preprocessing_path/$subset`
    do
        singularity run afni.simg 3dDespike -prefix $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-despike_bold.nii.gz $preprocessing_path/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-despike_bold.nii.gz

        python -c "from preprocess import clean_data,clean_data(\'$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz\',\'$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz\',\'$preprocessing_path/$subset/$sub/func/${sub}_task-rest_desc-confounds_timeseries.tsv\',2,o\'$preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-reg_bold.nii.gz\')"

        singularity run afni.simg 3dBlurToFWHM -prefix $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-smooth_bold.nii.gz -mask preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -FWHM 8 $preprocessing_path/$subset/$sub/func/${sub}_task-rest_space-MNI152NLin2009cAsym_desc-reg_bold.nii.gz
    done
}
#14:07 14:35 15:19 15:47
#data_organise
#data_preprocess $subset
