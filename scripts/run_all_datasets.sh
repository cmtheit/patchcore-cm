#!/bin/bash
# ============================================================================
# 批量训练所有数据集的脚本
# ============================================================================
# 此脚本会依次在所有数据集上训练 PatchCore 模型
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 初始化 pyenv（如果存在）
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)" 2>/dev/null || true
    fi
fi

# 加载配置
if [ -f "$PROJECT_ROOT/config.sh" ]; then
    source "$PROJECT_ROOT/config.sh"
else
    echo "错误: 找不到 config.sh 配置文件"
    echo "请先运行 ./scripts/setup_config.sh 创建配置文件"
    exit 1
fi

export PYTHONPATH=src

# 检测 Python 命令
PYTHON_CMD=$(command -v python3)

# 所有可用的数据集
ALL_DATASETS=(
    'bottle'
    'cable'
    'capsule'
    'carpet'
    'grid'
    'hazelnut'
    'leather'
    'metal_nut'
    'pill'
    'screw'
    'tile'
    'toothbrush'
    'transistor'
    'wood'
    'zipper'
)

echo "=========================================="
echo "批量训练所有数据集"
echo "=========================================="
echo "配置信息:"
echo "  骨干网络: $BACKBONE"
echo "  图像大小: $IMAGE_SIZE"
echo "  嵌入维度: $EMBED_DIM"
echo "  核心集采样: $CORESET_PERCENTAGE"
echo "=========================================="
echo ""

# 构建层标志
layer_flags=()
for layer in "${LAYERS[@]}"; do
    layer_flags+=("-le" "$layer")
done

# 遍历所有数据集
for dataset in "${ALL_DATASETS[@]}"; do
    echo "=========================================="
    echo "正在训练数据集: $dataset"
    echo "=========================================="
    
    # 为每个数据集创建单独的日志组
    dataset_log_group="${LOG_GROUP}_${dataset}"
    
    # 运行训练
    ${PYTHON_CMD:-python3} scripts/run_patchcore.py \
        --gpu $GPU_ID \
        --seed $SEED \
        --save_patchcore_model \
        --log_group "$dataset_log_group" \
        --log_project "$LOG_PROJECT" \
        results \
        patch_core \
        -b $BACKBONE \
        "${layer_flags[@]}" \
        --faiss_on_gpu \
        --pretrain_embed_dimension $EMBED_DIM \
        --target_embed_dimension $EMBED_DIM \
        --anomaly_scorer_num_nn $NUM_NN \
        --patchsize $PATCH_SIZE \
        sampler \
        -p $CORESET_PERCENTAGE \
        approx_greedy_coreset \
        dataset \
        --resize $RESIZE_SIZE \
        --imagesize $IMAGE_SIZE \
        -d $dataset \
        "$DATAPATH"
    
    if [ $? -eq 0 ]; then
        echo "数据集 $dataset 训练完成！"
    else
        echo "数据集 $dataset 训练失败！"
        read -p "是否继续训练下一个数据集? (y/n): " continue_train
        if [ "$continue_train" != "y" ] && [ "$continue_train" != "Y" ]; then
            echo "已取消批量训练"
            exit 1
        fi
    fi
    echo ""
done

echo "=========================================="
echo "所有数据集训练完成！"
echo "结果保存在: results/$LOG_PROJECT/"
echo "=========================================="
