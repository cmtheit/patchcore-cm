#!/bin/bash
# ============================================================================
# PatchCore 配置文件
# 生成时间: 2026年  3月 12日 木曜日 00:27:30 JST
# ============================================================================
# 此文件由 setup_config.sh 自动生成
# 你可以直接编辑此文件来修改参数
# ============================================================================

# 数据路径
export DATAPATH="/home/cm/c/Users/Lenovo/毕业设计/patchcore-inspection/data"

# GPU 设置
export GPU_ID=0

# 数据集列表
export DATASETS=(
    'grid'
)

# 骨干网络
export BACKBONE="wideresnet50"

# 特征层
export LAYERS=(
    'layer2'
    'layer3'
)

# 嵌入维度
export EMBED_DIM=1024

# 核心集采样比例 (0.1 = 10%)
export CORESET_PERCENTAGE=0.1

# 图像大小
export IMAGE_SIZE=224
export RESIZE_SIZE=256

# 其他参数
export SEED=10
export NUM_NN=1
export PATCH_SIZE=3

# 日志设置
export LOG_GROUP="IM224_wideresnet50_Llayer2-layer3_P100_D1024-1024_PS-3_AN-1_S10"
export LOG_PROJECT="MVTecAD_Results"
