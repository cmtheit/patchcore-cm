source ./scripts/env.sh
export loadpath="$PWD/results/MVTecAD_Results"
# loadpath="$PWD/models"
export modelfolder="$LOG_GROUP"_"${modeln:-5}"
# modelfolder="IM224_Ensemble_L2-3_P001_D1024-384_PS-3_AN-1"
export savefolder=evaluated_results'/'$modelfolder

export model_flags=($(for dataset in "${datasets[@]}"; do echo '-p '$loadpath'/'$modelfolder'/models/mvtec_'$dataset; done))

export params=(
  scripts/load_and_evaluate_patchcore.py 
    --save_segmentation_images 
    --gpu 0 
    $savefolder
  patch_core_loader 
    "${model_flags[@]}" 
    --faiss_on_gpu
  dataset 
    --resize 366 
    --imagesize 320 
    "${dataset_flags[@]}" 
    mvtec 
    $datapath
)