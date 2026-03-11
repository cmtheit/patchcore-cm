#!/bin/bash
# ============================================================================
# PatchCore 一键运行脚本
# ============================================================================
# 使用方法：
#   ./scripts/quick_start.sh train    # 训练模型
#   ./scripts/quick_start.sh eval     # 评估模型
#   ./scripts/quick_start.sh help     # 显示帮助信息
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# 初始化 pyenv（如果存在）
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
    # 初始化 pyenv（如果 shell 支持）
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

# 设置 Python 路径
export PYTHONPATH=src

# 设置 CUDA 环境变量（如果存在 CUDA）
# 优先使用 cuda-13.1，如果没有则尝试其他版本
# 同时添加 PyTorch 自带的 CUDA 库路径（如果使用 pyenv）
if [ -d "/usr/local/cuda-13.1" ]; then
    export CUDA_HOME=/usr/local/cuda-13.1
    export LD_LIBRARY_PATH=/usr/local/cuda-13.1/lib64:/usr/local/cuda-13.1/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/cuda-13.1/bin:$PATH
elif [ -d "/usr/local/cuda-13" ]; then
    export CUDA_HOME=/usr/local/cuda-13
    export LD_LIBRARY_PATH=/usr/local/cuda-13/lib64:/usr/local/cuda-13/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/cuda-13/bin:$PATH
elif [ -d "/usr/local/cuda" ]; then
    export CUDA_HOME=/usr/local/cuda
    export LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/cuda/bin:$PATH
fi

# 添加 PyTorch 自带的 CUDA 库路径（如果存在）
# PyTorch 自带了 CUDA 运行时库，需要添加到 LD_LIBRARY_PATH
if [ -d "$HOME/.pyenv/versions" ]; then
    PYENV_PYTHON_VERSION=$(pyenv version-name 2>/dev/null || echo "")
    if [ -n "$PYENV_PYTHON_VERSION" ]; then
        TORCH_LIB_PATH="$HOME/.pyenv/versions/$PYENV_PYTHON_VERSION/lib/python3.9/site-packages/torch/lib"
        NVIDIA_CUDA_RUNTIME="$HOME/.pyenv/versions/$PYENV_PYTHON_VERSION/lib/python3.9/site-packages/nvidia/cuda_runtime/lib"
        NVIDIA_CUBLAS="$HOME/.pyenv/versions/$PYENV_PYTHON_VERSION/lib/python3.9/site-packages/nvidia/cublas/lib"
        NVIDIA_CUDNN="$HOME/.pyenv/versions/$PYENV_PYTHON_VERSION/lib/python3.9/site-packages/nvidia/cudnn/lib"
        
        if [ -d "$TORCH_LIB_PATH" ]; then
            export LD_LIBRARY_PATH=$TORCH_LIB_PATH:$LD_LIBRARY_PATH
        fi
        if [ -d "$NVIDIA_CUDA_RUNTIME" ]; then
            export LD_LIBRARY_PATH=$NVIDIA_CUDA_RUNTIME:$LD_LIBRARY_PATH
        fi
        if [ -d "$NVIDIA_CUBLAS" ]; then
            export LD_LIBRARY_PATH=$NVIDIA_CUBLAS:$LD_LIBRARY_PATH
        fi
        if [ -d "$NVIDIA_CUDNN" ]; then
            export LD_LIBRARY_PATH=$NVIDIA_CUDNN:$LD_LIBRARY_PATH
        fi
    fi
fi

# 确保 CUDA_VISIBLE_DEVICES 未设置（除非用户明确设置）
# 这可以避免某些环境变量冲突问题
if [ -z "$CUDA_VISIBLE_DEVICES" ]; then
    unset CUDA_VISIBLE_DEVICES
fi

# 检测并显示使用的 Python 版本
PYTHON_CMD=$(command -v python3)
if [ -n "$PYTHON_CMD" ]; then
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
    # 只在非静默模式下显示
    if [ "${QUIET:-0}" != "1" ]; then
        echo "使用 Python: $PYTHON_CMD ($PYTHON_VERSION)"
    fi
fi

# 检测CUDA是否可用
check_cuda_available() {
    eval "$(pyenv init -)" 2>/dev/null || true
    python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null
    return $?
}

# 显示参数信息
show_params() {
    echo "=========================================="
    echo "当前配置参数："
    echo "=========================================="
    echo "数据路径: $DATAPATH"
    echo "GPU ID: $GPU_ID"
    echo "数据集: ${DATASETS[@]}"
    echo "骨干网络: $BACKBONE"
    echo "特征层: ${LAYERS[@]}"
    echo "嵌入维度: $EMBED_DIM"
    echo "核心集采样比例: $CORESET_PERCENTAGE"
    echo "图像大小: $IMAGE_SIZE"
    
    # 检测CUDA可用性
    if check_cuda_available; then
        echo "CUDA状态: 可用 ✓"
    else
        echo "CUDA状态: 不可用 ✗ (将使用CPU模式)"
    fi
    echo "=========================================="
}

# 训练函数
train() {
    echo "=========================================="
    echo "开始训练 PatchCore 模型"
    echo "=========================================="
    show_params
    
    # 构建数据集标志
    dataset_flags=()
    for dataset in "${DATASETS[@]}"; do
        dataset_flags+=("-d" "$dataset")
    done
    
    # 构建层标志
    layer_flags=()
    for layer in "${LAYERS[@]}"; do
        layer_flags+=("-le" "$layer")
    done
    
    # 根据CUDA可用性决定是否使用faiss_on_gpu
    faiss_gpu_flag=""
    if check_cuda_available; then
        faiss_gpu_flag="--faiss_on_gpu"
        echo "检测到CUDA可用，将使用GPU加速FAISS"
    else
        echo "警告: CUDA不可用，将使用CPU模式（包括FAISS）"
    fi
    
    # 运行训练（使用检测到的 python3）
    ${PYTHON_CMD:-python3} scripts/run_patchcore.py \
        --gpu $GPU_ID \
        --seed $SEED \
        --save_patchcore_model \
        --log_group "$LOG_GROUP" \
        --log_project "$LOG_PROJECT" \
        results \
        patch_core \
        -b $BACKBONE \
        "${layer_flags[@]}" \
        $faiss_gpu_flag \
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
        "${dataset_flags[@]}" \
        "$DATAPATH"
    
    if [ $? -eq 0 ]; then
        echo "=========================================="
        echo "训练完成！"
        echo "模型保存在: results/$LOG_PROJECT/$LOG_GROUP"
        echo "=========================================="
    else
        echo "=========================================="
        echo "训练失败，请检查错误信息"
        echo "=========================================="
        exit 1
    fi
}

# 评估函数
eval_model() {
    echo "=========================================="
    echo "开始评估 PatchCore 模型"
    echo "=========================================="
    
    # 检查模型是否存在
    model_path="results/$LOG_PROJECT/$LOG_GROUP"
    if [ ! -d "$model_path" ]; then
        echo "错误: 找不到模型目录 $model_path"
        echo "请先运行训练: ./scripts/quick_start.sh train"
        exit 1
    fi
    
    show_params
    
    # 构建数据集和模型标志
    dataset_flags=()
    model_flags=()
    for dataset in "${DATASETS[@]}"; do
        dataset_flags+=("-d" "$dataset")
        model_flags+=("-p" "$model_path/models/mvtec_$dataset")
    done
    
    # 根据CUDA可用性决定是否使用faiss_on_gpu
    faiss_gpu_flag=""
    if check_cuda_available; then
        faiss_gpu_flag="--faiss_on_gpu"
    fi
    
    savefolder="evaluated_results/$LOG_GROUP"
    
    # 运行评估（使用检测到的 python3）
    ${PYTHON_CMD:-python3} scripts/load_and_evaluate_patchcore.py \
        --save_segmentation_images \
        --gpu $GPU_ID \
        --seed $SEED \
        $savefolder \
        patch_core_loader \
        "${model_flags[@]}" \
        $faiss_gpu_flag \
        dataset \
        --resize $RESIZE_SIZE \
        --imagesize $IMAGE_SIZE \
        "${dataset_flags[@]}" \
        mvtec \
        "$DATAPATH"
    
    if [ $? -eq 0 ]; then
        echo "=========================================="
        echo "评估完成！"
        echo "结果保存在: $savefolder"
        echo "=========================================="
    else
        echo "=========================================="
        echo "评估失败，请检查错误信息"
        echo "=========================================="
        exit 1
    fi
}

# 帮助信息
show_help() {
    echo "=========================================="
    echo "PatchCore 一键运行脚本"
    echo "=========================================="
    echo ""
    echo "使用方法:"
    echo "  ./scripts/quick_start.sh train    # 训练模型"
    echo "  ./scripts/quick_start.sh eval      # 评估模型"
    echo "  ./scripts/quick_start.sh help     # 显示此帮助"
    echo ""
    echo "配置参数:"
    echo "  所有参数都在 config.sh 文件中配置"
    echo "  运行 ./scripts/setup_config.sh 可以创建或修改配置"
    echo ""
    echo "参数说明文档:"
    echo "  查看 docs/PARAMETERS.md 了解详细参数说明"
    echo ""
}

# 主逻辑
case "$1" in
    train)
        train
        ;;
    eval|evaluate)
        eval_model
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "错误: 未知命令 '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac
