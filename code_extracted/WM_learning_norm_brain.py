import numpy as np
import nibabel as nib
import os
import sys


def main(T1_linear_file,T1_mask_file,save_img_file):
    thre = get_thre_mask(T1_mask_file)

    T1_nii = nib.load(T1_linear_file)
    T1_img = T1_nii.get_fdata()
    T1_img[T1_img > thre] = thre
    T1_img = T1_img / thre
    T1_dst_nii = nib.Nifti1Image(T1_img,T1_nii.affine)

    nib.save(T1_dst_nii,save_img_file)



def get_thre_mask(T1_mask_file):
    T1_mask_nii = nib.load(T1_mask_file)
    T1_mask_img = T1_mask_nii.get_fdata()
    T1_mask_img = T1_mask_img[T1_mask_img > 0]

    return np.percentile(T1_mask_img,98)


if __name__ == '__main__':
    T1_linear_file = sys.argv[1]
    T1_mask_file   = sys.argv[2]
    save_img_file  = sys.argv[3]

    main(T1_linear_file,T1_mask_file,save_img_file)
