#!/bin/bash

INPUT_DIR=$1
OUTPUT_DIR=$2

T1_name=$(ls $INPUT_DIR)
T1_file=$INPUT_DIR/$T1_name
OUTPUT_TRACT_DIR=$OUTPUT_DIR/tractSeg
REF_file='/SUPPLY/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz'
REF_name=$(basename $REF_file)
PYTHON_DIR='/CODE/'
mkdir $OUTPUT_TRACT_DIR

echo '**********************input******************'
echo $T1_file
echo "OUTPUT directory $OUTPUT_TRACT_DIR"
echo '**********************input******************'

echo '****************Registration****************'
echo "We will use ANTs to register T1 to atlas template $REF_name"
ANTS_OUT=$OUTPUT_TRACT_DIR/ANTS
ANTS_CMD="antsRegistrationSyN.sh -d 3 -f $REF_file -t a -m $T1_file -o $ANTS_OUT"
echo $ANTS_CMD
eval $ANTS_CMD
mkdir $OUTPUT_TRACT_DIR/reg
mv ${ANTS_OUT}* $OUTPUT_TRACT_DIR/reg
echo "****************Finish Registration****************"

echo '****************apply transform********'
mkdir $OUTPUT_TRACT_DIR/anat/
T1_LIN_ATLAS_PATH=$OUTPUT_TRACT_DIR/anat/T1_linear.nii.gz
APPLYTRANSFORM_CMD="antsApplyTransforms -d 3 -i $T1_file -r $REF_file -n BSpline -t "$OUTPUT_TRACT_DIR/reg/ANTS"0GenericAffine.mat -o $T1_LIN_ATLAS_PATH"
echo $APPLYTRANSFORM_CMD
eval $APPLYTRANSFORM_CMD
echo '****************Finish apply transform********'

echo '****************skull strip*****************'
T1_MASK_PATH=$OUTPUT_TRACT_DIR/anat/T1_mask.nii.gz
BET_CMD="bet $T1_LIN_ATLAS_PATH $T1_MASK_PATH -f .4 -R -m"
echo $BET_CMD
eval $BET_CMD
echo '************Finish skull strip**************'

echo '****************T1 max *********************'
T1_MAX_PATH=$OUTPUT_TRACT_DIR/anat/T1_max.nii.gz
AFFINE_DIR=$OUTPUT_TRACT_DIR/affine

python3 $PYTHON_DIR/WM_learning_norm_brain.py $T1_LIN_ATLAS_PATH $T1_MASK_PATH $T1_MAX_PATH
echo '**************Finish T1 max*****************'

echo '*****************Perform inference**********'
mkdir $AFFINE_DIR
python3 $PYTHON_DIR/WM_learning_inferScan_tractSeg.py $T1_MAX_PATH $AFFINE_DIR
echo '*****************Finish inference*************'

echo '***********moving image to orig**************'
AFFINE_FILES=$(ls $AFFINE_DIR)
ORIG_DIR=$OUTPUT_TRACT_DIR/orig

mkdir $ORIG_DIR
for file in $AFFINE_FILES
do
    INPUT_PATHWAY=$AFFINE_DIR/$file
    OUTPUT_PATHWAY=$ORIG_DIR/$file
    APPLYINV_CMD="antsApplyTransforms -d 3 -i $INPUT_PATHWAY -r $T1_file -n BSpline -t ["$OUTPUT_TRACT_DIR/reg/ANTS"0GenericAffine.mat,1] -o $OUTPUT_PATHWAY --float" 
    echo $APPLYINV_CMD
    eval $APPLYINV_CMD

done


echo '*********Finish moving image to orig*********'

 












