import torch
import numpy as np
import nibabel as nib
import os
import sys

from WM_learning_Model import UNet3D

def main(T1_file,output_dir):
    tract_ID_file = 'tractSegID.txt'
    model_dir = '/MODEL'

    use_cuda = torch.cuda.is_available()
    device = torch.device("cuda" if use_cuda else "cpu")
    tract_ID = np.loadtxt(tract_ID_file,dtype=str)

    for i in range(5):
        for j in range(5):
            for k in range(5):
                T1_tile_tensor = prep_T1_tensor(i,j,k,T1_file)
                model = prep_tile_model(i,j,k,model_dir)
                model = model.to(device)

                model.eval()

                with torch.no_grad():
                    output = model(T1_tile_tensor.unsqueeze(0).to(device))
                    output = torch.nn.Sigmoid()(output)
                    for count in range(output.shape[1]):
                        save_tract_dir = os.path.join(output_dir,tract_ID[count])
                        if (not os.path.isdir(save_tract_dir)):
                            os.mkdir(save_tract_dir)
                        save_path = os.path.join(save_tract_dir,'{}{}{}_{}.nii.gz'.format(i,j,k,tract_ID[count]))
                        img = np.around(output[0,count,:,:,:].cpu().detach().numpy(),decimals=4).astype(np.float16)
                        img[img<0.01] = 0
                        save_nifti(img,save_path,T1_file)

    merge(T1_file,output_dir,tract_ID)


def merge(T1_file,output_dir,tract_ID):
    
    xz_index = [0, 24, 49, 73, 97]
    y_index = [0, 33, 66, 100,133]
    for tract in sorted(tract_ID):
        print('We begin to merge {}'.format(tract))
        tract_dir = os.path.join(output_dir,tract)
        image = np.zeros([193,229,193])
        template = np.zeros([193,229,193])
        for i in range(5):
            for j in range(5):
                for k in range(5):
                    prefix = str(i)  +str(j) + str(k)
                    tile_file = os.path.join(tract_dir,prefix + '_' + os.path.basename(tract_dir) + '.nii.gz')
                    img = np.zeros([193,229,193])
                    tmp = np.zeros([193,229,193])

                    img[xz_index[i]:xz_index[i]+96,y_index[j]:y_index[j]+96,xz_index[k]:xz_index[k]+96] = nib.load(tile_file).get_fdata()
                    tmp[xz_index[i]:xz_index[i]+96,y_index[j]:y_index[j]+96,xz_index[k]:xz_index[k]+96] = 1

                    image += img
                    template += tmp

        final = np.around(image/template,decimals=4).astype(np.float16)
        final[final<0.01] = 0
        save_path = os.path.join(output_dir, tract + '.nii.gz')
        save_nifti(final,save_path,T1_file)
        os.system('rm -rf {}'.format(tract_dir))
                            

def save_nifti(img,save_path,ref_path):
    ref_nii = nib.load(ref_path)
    save_nii = nib.Nifti1Image(img,ref_nii.affine,ref_nii.header)
    nib.save(save_nii,save_path)


def prep_tile_model(i,j,k,model_dir):
    model_file = os.path.join(model_dir,'tractSeg_{}{}{}'.format(i,j,k))
    model = UNet3D(1,72)

    checkpoint = torch.load(model_file)
    model.load_state_dict(checkpoint)

    return model

def prep_T1_tensor(i,j,k,T1_file):
    xz_index = [0, 24, 49, 73, 97]
    y_index = [0, 33, 66, 100,133]

    T1_img = nib.load(T1_file).get_fdata()
    T1_tensor = torch.from_numpy(nib.load(T1_file).get_fdata()).type(torch.FloatTensor).unsqueeze(0)
    T1_tensor_tile = T1_tensor[:,xz_index[i]:xz_index[i] + 96, y_index[j]:y_index[j] + 96, xz_index[k]:xz_index[k] + 96]

    return T1_tensor_tile

if __name__ == '__main__':
    T1_file    = sys.argv[1]
    output_dir = sys.argv[2]
    main(T1_file,output_dir)





    
