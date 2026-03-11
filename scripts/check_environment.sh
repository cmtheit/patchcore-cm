#!/bin/bash
# ============================================================================
# 环境检查脚本
# ============================================================================
# 检查运行 PatchCore 所需的环境和依赖
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

echo "=========================================="
echo "PatchCore 环境检查"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# 检查 Python
echo -n "检查 Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "✓ 找到 Python $PYTHON_VERSION"
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 7) else 1)"; then
        echo "  ✓ Python 版本 >= 3.7"
    else
        echo "  ✗ Python 版本过低，需要 >= 3.7"
        ((ERRORS++))
    fi
else
    echo "✗ 未找到 Python3"
    ((ERRORS++))
fi

# 检查 PyTorch
echo -n "检查 PyTorch... "
if python3 -c "import torch" 2>/dev/null; then
    TORCH_VERSION=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null)
    echo "✓ 找到 PyTorch $TORCH_VERSION"
    
    # 检查 CUDA
    if python3 -c "import torch; print(torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
        CUDA_VERSION=$(python3 -c "import torch; print(torch.version.cuda)" 2>/dev/null)
        GPU_COUNT=$(python3 -c "import torch; print(torch.cuda.device_count())" 2>/dev/null)
        echo "  ✓ CUDA 可用 (版本: $CUDA_VERSION)"
        echo "  ✓ 检测到 $GPU_COUNT 个 GPU"
    else
        echo "  ⚠ CUDA 不可用，将使用 CPU（会很慢）"
        ((WARNINGS++))
    fi
else
    echo "✗ 未找到 PyTorch"
    echo "  请运行: pip install torch"
    ((ERRORS++))
fi

# 检查必要的 Python 包
echo -n "检查 Python 依赖... "
REQUIRED_PACKAGES=("numpy" "tqdm" "click" "timm" "torchvision")
MISSING_PACKAGES=()
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! python3 -c "import $package" 2>/dev/null; then
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo "✓ 所有依赖包已安装"
else
    echo "✗ 缺少以下包: ${MISSING_PACKAGES[*]}"
    echo "  请运行: pip install -r requirements.txt"
    ((ERRORS++))
fi

# 检查 FAISS
echo -n "检查 FAISS... "
if python3 -c "import faiss" 2>/dev/null; then
    echo "✓ FAISS 已安装"
else
    echo "⚠ FAISS 未安装"
    echo "  如果使用 GPU，需要安装 faiss-gpu"
    echo "  如果使用 CPU，需要安装 faiss-cpu"
    echo "  请运行: pip install faiss-gpu 或 pip install faiss-cpu"
    ((WARNINGS++))
fi

# 检查数据路径
echo -n "检查数据路径... "
if [ -f "$PROJECT_ROOT/config.sh" ]; then
    source "$PROJECT_ROOT/config.sh"
    if [ -d "$DATAPATH" ]; then
        echo "✓ 数据路径存在: $DATAPATH"
        
        # 检查是否有数据集
        DATASET_COUNT=$(find "$DATAPATH" -maxdepth 1 -type d -name "mvtec_*" 2>/dev/null | wc -l)
        if [ "$DATASET_COUNT" -gt 0 ]; then
            echo "  ✓ 找到 $DATASET_COUNT 个数据集目录"
        else
            # 检查 MVTec 格式
            DATASET_COUNT=$(find "$DATAPATH" -maxdepth 1 -type d \( -name "bottle" -o -name "cable" -o -name "pill" \) 2>/dev/null | wc -l)
            if [ "$DATASET_COUNT" -gt 0 ]; then
                echo "  ✓ 找到数据集（MVTec 格式）"
            else
                echo "  ⚠ 数据路径存在，但未找到数据集"
                echo "    请确保数据已下载并解压到: $DATAPATH"
                ((WARNINGS++))
            fi
        fi
    else
        echo "⚠ 数据路径不存在: $DATAPATH"
        echo "  请检查 config.sh 中的 DATAPATH 设置"
        ((WARNINGS++))
    fi
else
    echo "⚠ 未找到 config.sh"
    echo "  请先运行: ./scripts/setup_config.sh"
    ((WARNINGS++))
fi

# 检查 src 目录
echo -n "检查源代码... "
if [ -d "$PROJECT_ROOT/src/patchcore" ]; then
    echo "✓ 源代码目录存在"
else
    echo "✗ 源代码目录不存在"
    ((ERRORS++))
fi

# 检查脚本权限
echo -n "检查脚本权限... "
SCRIPTS=("scripts/quick_start.sh" "scripts/setup_config.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$PROJECT_ROOT/$script" ] && [ ! -x "$PROJECT_ROOT/$script" ]; then
        echo "⚠ $script 没有执行权限，正在修复..."
        chmod +x "$PROJECT_ROOT/$script"
    fi
done
echo "✓ 脚本权限正常"

# 总结
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ 环境检查通过！可以开始使用 PatchCore"
elif [ $ERRORS -eq 0 ]; then
    echo "⚠ 环境检查完成，有 $WARNINGS 个警告"
    echo "  建议修复警告，但不影响基本使用"
else
    echo "✗ 环境检查失败，发现 $ERRORS 个错误"
    echo "  请先修复这些错误"
fi
echo "=========================================="

exit $ERRORS
