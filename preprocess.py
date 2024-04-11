from nilearn import image as nimg
import pandas as pd
import numpy as np
import nibabel as nib
import os

def clean_data(fmri_image,mask_file,head_param,tr,output_fmri):
    if os.path.exists(fmri_image):
        raw_func_img=nimg.load_img(fmri_image)
        brain_mask=nimg.load_img(mask_file)
        confounds=["global_signal","global_signal_derivative1","global_signal_power2","global_signal_derivative1_power2","csf","csf_derivative1","csf_power2","csf_derivative1_power2","white_matter","white_matter_derivative1","white_matter_derivative1_power2","white_matter_power2","trans_x","trans_x_derivative1","trans_x_derivative1_power2","trans_x_power2","trans_y","trans_y_derivative1","trans_y_power2","trans_y_derivative1_power2","trans_z","trans_z_derivative1","trans_z_power2","trans_z_derivative1_power2","rot_x","rot_x_derivative1","rot_x_power2","rot_x_derivative1_power2","rot_y","rot_y_derivative1","rot_y_power2","rot_y_derivative1_power2","rot_z","rot_z_derivative1","rot_z_derivative1_power2","rot_z_power2"]
        confounds_df=pd.read_csv(head_param,sep="\t",engine="python")
        print(confounds_df.columns)
        confounds_df=confounds_df[confounds]
        func_img=raw_func_img.slicer[:,:,:,4:]
        confound_matrix=confounds_df.iloc[4:].values
        clean_img=nimg.clean_img(func_img,confounds=confound_matrix,detrend=True,standardize=True,low_pass=0.08,high_pass=0.01,t_r=tr, mask_img=brain_mask)

        hd=nib.load(fmri_image)
        #hd.header['sizeof_hdr']=540
        #hd.header['dim']=[4,88,88,64,486,1,1,1]
        clean_image=nib.Nifti1Image(np.asanyarray(clean_img.dataobj),hd.affine,header=hd.header)
        nib.save(clean_image,output_fmri)
    else:
        print("Filese missing!!!")
