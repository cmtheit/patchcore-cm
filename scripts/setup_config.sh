#!/bin/bash
# ============================================================================
# PatchCore 配置脚本生成器
# ============================================================================
# 此脚本会创建一个 config.sh 配置文件
# 你可以直接编辑 config.sh 来修改参数
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

CONFIG_FILE="$PROJECT_ROOT/config.sh"

echo "=========================================="
echo "PatchCore 配置脚本生成器"
echo "=========================================="
echo ""

# 检查是否已存在配置文件
if [ -f "$CONFIG_FILE" ]; then
    read -p "配置文件已存在，是否覆盖? (y/n): " overwrite
    if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
        echo "已取消，保留现有配置"
        exit 0
    fi
fi

# 获取用户输入
echo "请输入配置参数（直接回车使用默认值）:"
echo ""

# 数据路径
read -p "数据路径 [默认: $PROJECT_ROOT/data]: " datapath
datapath=${datapath:-$PROJECT_ROOT/data}

# GPU ID
read -p "GPU ID [默认: 0]: " gpu_id
gpu_id=${gpu_id:-0}

# 数据集选择
echo ""
echo "可用数据集: bottle cable capsule carpet grid hazelnut leather metal_nut pill screw tile toothbrush transistor wood zipper"
read -p "要使用的数据集（用空格分隔，默认: pill）: " datasets_input
datasets_input=${datasets_input:-pill}
IFS=' ' read -ra datasets_array <<< "$datasets_input"

# 骨干网络
echo ""
echo "可用骨干网络: wideresnet50 wideresnet101 resnet50 resnet101 resnext101 densenet201 vit_swin_base"
read -p "骨干网络 [默认: wideresnet50]: " backbone
backbone=${backbone:-wideresnet50}

# 根据骨干网络自动设置默认层名称
case "$backbone" in
    vit_swin_base|vit_swin_large)
        default_layers="layers.1 layers.2"
        layer_note="注意: Swin Transformer 使用 'layers.1' 和 'layers.2'（或 'layers.2' 和 'layers.3'）"
        ;;
    densenet*)
        default_layers="features.denseblock2 features.denseblock3"
        layer_note="注意: DenseNet 使用 'features.denseblock2' 和 'features.denseblock3'"
        ;;
    *)
        default_layers="layer2 layer3"
        layer_note="注意: ResNet/WideResNet 使用 'layer2' 和 'layer3'"
        ;;
esac

# 特征层
echo ""
echo "$layer_note"
read -p "特征层（用空格分隔，默认: $default_layers）: " layers_input
layers_input=${layers_input:-$default_layers}
IFS=' ' read -ra layers_array <<< "$layers_input"

# 嵌入维度
read -p "嵌入维度 [默认: 1024]: " embed_dim
embed_dim=${embed_dim:-1024}

# 核心集采样比例
read -p "核心集采样比例 [默认: 0.1 (10%)]: " coreset_percentage
coreset_percentage=${coreset_percentage:-0.1}

# 图像大小
read -p "图像大小 [默认: 224]: " image_size
image_size=${image_size:-224}

# 计算 resize 大小（通常是图像大小的 1.5 倍左右）
resize_size=$((image_size * 366 / 320))
if [ $image_size -eq 224 ]; then
    resize_size=256
elif [ $image_size -eq 320 ]; then
    resize_size=366
else
    resize_size=$((image_size * 366 / 320))
fi

# 其他参数
read -p "随机种子 [默认: 0]: " seed
seed=${seed:-0}

read -p "最近邻数量 [默认: 1]: " num_nn
num_nn=${num_nn:-1}

read -p "Patch 大小 [默认: 3]: " patch_size
patch_size=${patch_size:-3}

# 日志组名（根据参数自动生成）
coreset_pct_int=$(python3 -c "print(int($coreset_percentage * 1000))")
log_group="IM${image_size}_${backbone}_L$(IFS='-'; echo "${layers_array[*]}")_P$(printf "%03d" $coreset_pct_int)_D${embed_dim}-${embed_dim}_PS-${patch_size}_AN-${num_nn}_S${seed}"

read -p "日志组名 [默认: $log_group]: " log_group_input
log_group=${log_group_input:-$log_group}

read -p "日志项目名 [默认: MVTecAD_Results]: " log_project
log_project=${log_project:-MVTecAD_Results}

# 生成配置文件
cat > "$CONFIG_FILE" << EOF
#!/bin/bash
# ============================================================================
# PatchCore 配置文件
# 生成时间: $(date)
# ============================================================================
# 此文件由 setup_config.sh 自动生成
# 你可以直接编辑此文件来修改参数
# ============================================================================

# 数据路径
export DATAPATH="$datapath"

# GPU 设置
export GPU_ID=$gpu_id

# 数据集列表
export DATASETS=(
$(for ds in "${datasets_array[@]}"; do echo "    '$ds'"; done)
)

# 骨干网络
export BACKBONE="$backbone"

# 特征层
export LAYERS=(
$(for layer in "${layers_array[@]}"; do echo "    '$layer'"; done)
)

# 嵌入维度
export EMBED_DIM=$embed_dim

# 核心集采样比例 (0.1 = 10%)
export CORESET_PERCENTAGE=$coreset_percentage

# 图像大小
export IMAGE_SIZE=$image_size
export RESIZE_SIZE=$resize_size

# 其他参数
export SEED=$seed
export NUM_NN=$num_nn
export PATCH_SIZE=$patch_size

# 日志设置
export LOG_GROUP="$log_group"
export LOG_PROJECT="$log_project"
EOF

chmod +x "$CONFIG_FILE"

echo ""
echo "=========================================="
echo "配置文件已生成: $CONFIG_FILE"
echo "=========================================="
echo ""
echo "配置摘要:"
echo "  骨干网络: $backbone"
echo "  特征层: ${layers_array[*]}"
echo "  数据集: ${datasets_array[*]}"
echo ""
if [[ "$backbone" == *"vit_swin"* ]]; then
    echo "提示: 你使用的是 Swin Transformer"
    echo "     确保层名称为 'layers.1' 和 'layers.2'（或 'layers.2' 和 'layers.3'）"
    echo ""
fi
echo "现在你可以运行:"
echo "  ./scripts/quick_start.sh train    # 训练模型"
echo "  ./scripts/quick_start.sh eval     # 评估模型"
echo ""
echo "要修改配置，请编辑 $CONFIG_FILE 文件"
echo "=========================================="
