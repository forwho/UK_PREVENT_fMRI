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
        mkdir -p $target_path/$subname/anat
        mkdir -p $target_path/$subname/bold
        cp $sub $target_path/$subname/bold/sub-${subname}_bold.nii.gz
        cp ${sub%%.*}.json $target_path/$subname/bold/sub-${subname}_bold.json
        t1file=`ls $raw_path/MRI/T1w_MR*${subname}*.nii`
        cp $t1file $target_path/$subname/anat/sub-${subname}_t1w.nii
    done
}
data_organise
