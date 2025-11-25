export datapath="$PWD/data"
export datasets=(
      # 'bottle'
      # 'cable'
      # 'capsule'
      # 'carpet'
      # 'grid'
      # 'hazelnut'
      # 'leather'
      # 'metal_nut'
      'pill'
      # 'screw'
      # 'tile'
      # 'toothbrush'
      # 'transistor'
      # 'wood'
      # 'zipper'
)
export dataset_flags=($(for dataset in "${datasets[@]}"; do echo '-d '$dataset; done))

export PYTHONPATH=src
export LOG_GROUP=IM224_WR50_L2-3_P01_D1024-1024_PS-3_AN-1_S0