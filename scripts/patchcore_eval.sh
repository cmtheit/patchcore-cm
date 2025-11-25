source ./scripts/env.sh

loadpath="$PWD/results/MVTecAD_Results"
# loadpath="$PWD/models"
modelfolder="$LOG_GROUP"_"${modeln:-5}"
# modelfolder="IM224_Ensemble_L2-3_P001_D1024-384_PS-3_AN-1"
savefolder=evaluated_results'/'$modelfolder

model_flags=($(for dataset in "${datasets[@]}"; do echo '-p '$loadpath'/'$modelfolder'/models/mvtec_'$dataset; done))

python bin/load_and_evaluate_patchcore.py --gpu 0 --seed 0 $savefolder \
patch_core_loader "${model_flags[@]}" --faiss_on_gpu \
dataset --resize 366 --imagesize 320 "${dataset_flags[@]}" mvtec $datapath
