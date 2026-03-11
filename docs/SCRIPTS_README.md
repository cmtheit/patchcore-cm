# PatchCore 脚本说明文档

本文档列出了所有可用的脚本及其功能、参数和使用方法。

## 📜 脚本列表

### 1. `scripts/check_environment.sh` - 环境检查脚本

**功能**：检查运行环境是否配置正确

**使用方法**：
```bash
./scripts/check_environment.sh
```

**检查内容**：
- ✅ Python 版本（>= 3.7）
- ✅ PyTorch 安装和 CUDA 支持
- ✅ 必要的 Python 包（numpy, tqdm, click, timm, torchvision）
- ✅ FAISS 库
- ✅ 数据路径存在性
- ✅ 源代码完整性
- ✅ 脚本执行权限

**输出**：
- 显示每个检查项的状态（✓/✗/⚠）
- 如果有错误，会显示错误数量
- 如果有警告，会显示警告数量

**参数**：无

---

### 2. `scripts/setup_config.sh` - 配置生成器

**功能**：交互式创建配置文件 `config.sh`

**使用方法**：
```bash
./scripts/setup_config.sh
```

**交互式配置项**：

| 配置项 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| 数据路径 | MVTec AD 数据集路径 | `$PWD/data` | `/home/user/data` |
| GPU ID | 使用的 GPU 编号 | `0` | `0`, `1` |
| 数据集 | 要使用的数据集（空格分隔） | `pill` | `pill cable bottle` |
| 骨干网络 | 特征提取器 | `wideresnet50` | `wideresnet50`, `resnet50` |
| 特征层 | 提取特征的层（空格分隔） | `layer2 layer3` | `layer2 layer3` |
| 嵌入维度 | 特征向量维度 | `1024` | `512`, `1024`, `2048` |
| 核心集采样比例 | 采样比例（0.1=10%） | `0.1` | `0.01`, `0.1`, `0.2` |
| 图像大小 | 输入图像尺寸 | `224` | `224`, `320`, `384` |
| 随机种子 | 随机种子 | `0` | `0`, `42`, `123` |
| 最近邻数量 | 异常评分使用的最近邻数 | `1` | `1`, `3`, `5` |
| Patch 大小 | 局部聚合的 patch 大小 | `3` | `3`, `5`, `7` |
| 日志组名 | 训练日志组名 | 自动生成 | 自定义名称 |
| 日志项目名 | 日志项目名 | `MVTecAD_Results` | 自定义名称 |

**生成的配置文件**：`config.sh`

**参数**：无

---

### 3. `scripts/quick_start.sh` - 主运行脚本

**功能**：一键训练或评估模型

**使用方法**：
```bash
# 训练模型
./scripts/quick_start.sh train

# 评估模型
./scripts/quick_start.sh eval

# 显示帮助
./scripts/quick_start.sh help
```

**子命令**：

#### `train` - 训练模型
- 使用 `config.sh` 中的参数训练 PatchCore 模型
- 自动构建数据集标志和层标志
- 保存模型到 `results/$LOG_PROJECT/$LOG_GROUP/`

**输出位置**：
- 模型文件：`results/$LOG_PROJECT/$LOG_GROUP/models/mvtec_<dataset>/`
- 结果文件：`results/$LOG_PROJECT/$LOG_GROUP/results.csv`

#### `eval` - 评估模型
- 加载已训练的模型
- 在测试集上评估性能
- 生成异常分割图像（如果启用）

**输出位置**：
- 评估结果：`evaluated_results/$LOG_GROUP/`
- 分割图像：`evaluated_results/$LOG_GROUP/segmentations/`

#### `help` - 显示帮助
- 显示脚本使用说明

**依赖**：
- 需要 `config.sh` 配置文件（由 `scripts/setup_config.sh` 生成）

**使用的参数**（从 `config.sh` 读取）：
- `DATAPATH` - 数据路径
- `GPU_ID` - GPU 编号
- `DATASETS` - 数据集列表
- `BACKBONE` - 骨干网络
- `LAYERS` - 特征层
- `EMBED_DIM` - 嵌入维度
- `CORESET_PERCENTAGE` - 核心集采样比例
- `IMAGE_SIZE` - 图像大小
- `RESIZE_SIZE` - 预处理大小
- `SEED` - 随机种子
- `NUM_NN` - 最近邻数量
- `PATCH_SIZE` - Patch 大小
- `LOG_GROUP` - 日志组名
- `LOG_PROJECT` - 日志项目名

---

### 4. `scripts/run_all_datasets.sh` - 批量训练脚本

**功能**：在所有 MVTec AD 数据集上依次训练模型

**使用方法**：
```bash
./scripts/run_all_datasets.sh
```

**功能说明**：
- 遍历所有 15 个数据集：bottle, cable, capsule, carpet, grid, hazelnut, leather, metal_nut, pill, screw, tile, toothbrush, transistor, wood, zipper
- 每个数据集使用相同的配置参数（从 `config.sh` 读取）
- 每个数据集有独立的日志组名（格式：`${LOG_GROUP}_${dataset}`）
- 如果某个数据集训练失败，会询问是否继续

**依赖**：
- 需要 `config.sh` 配置文件

**使用的参数**（从 `config.sh` 读取）：
- 所有训练相关参数

**输出位置**：
- 每个数据集的模型：`results/$LOG_PROJECT/${LOG_GROUP}_${dataset}/models/`

**注意事项**：
- ⏱️ 训练时间较长（1-3 小时）
- 💾 需要足够的磁盘空间
- 🔄 建议先用单个数据集测试

---

## 📋 脚本使用流程

### 首次使用流程

```bash
# 1. 检查环境
./scripts/check_environment.sh

# 2. 配置参数
./scripts/setup_config.sh

# 3. 训练模型（单个数据集）
./scripts/quick_start.sh train

# 4. 评估模型
./scripts/quick_start.sh eval
```

### 批量训练流程

```bash
# 1. 确保环境配置正确
./scripts/check_environment.sh

# 2. 配置参数（如果还没配置）
./scripts/setup_config.sh

# 3. 批量训练所有数据集
./scripts/run_all_datasets.sh
```

### 修改配置后重新训练

```bash
# 方式 1：重新运行配置脚本
./scripts/setup_config.sh

# 方式 2：直接编辑配置文件
nano config.sh  # 或使用其他编辑器

# 然后重新训练
./scripts/quick_start.sh train
```

## 🔧 脚本参数详解

### 配置文件参数（`config.sh`）

所有参数都在 `config.sh` 中定义，详细说明请查看 [PARAMETERS.md](PARAMETERS.md)

**快速参考**：

```bash
# 数据相关
DATAPATH="/path/to/data"           # 数据路径
DATASETS=('pill' 'cable')          # 数据集列表

# 硬件相关
GPU_ID=0                           # GPU 编号

# 模型架构
BACKBONE="wideresnet50"            # 骨干网络
LAYERS=('layer2' 'layer3')        # 特征层

# 特征提取
EMBED_DIM=1024                     # 嵌入维度
CORESET_PERCENTAGE=0.1             # 核心集采样比例

# 图像处理
IMAGE_SIZE=224                     # 图像大小
RESIZE_SIZE=256                    # 预处理大小

# 异常检测
NUM_NN=1                           # 最近邻数量
PATCH_SIZE=3                       # Patch 大小

# 训练设置
SEED=0                             # 随机种子

# 日志设置
LOG_GROUP="IM224_WR50_..."         # 日志组名
LOG_PROJECT="MVTecAD_Results"      # 日志项目名
```

## 📊 输出文件说明

### 训练输出

```
results/
└── MVTecAD_Results/
    └── IM224_WR50_L2-3_P01_D1024-1024_PS-3_AN-1_S0/
        ├── models/
        │   └── mvtec_pill/
        │       ├── nnscorer_search_index.faiss  # FAISS 索引
        │       └── patchcore_params.pkl          # 模型参数
        └── results.csv                           # 性能指标
```

### 评估输出

```
evaluated_results/
└── IM224_WR50_L2-3_P01_D1024-1024_PS-3_AN-1_S0/
    ├── segmentations/                            # 分割图像（如果启用）
    └── results.csv                                # 详细评估结果
```

## ⚙️ 高级用法

### 使用不同的配置文件

```bash
# 创建多个配置
cp config.sh config_fast.sh
cp config.sh config_best.sh

# 编辑不同配置
nano config_fast.sh   # 快速测试配置
nano config_best.sh   # 最佳性能配置

# 使用特定配置
source config_fast.sh
./scripts/quick_start.sh train
```

### 自定义训练参数

如果需要使用脚本中未包含的参数，可以：

1. **直接使用原始脚本**：
```bash
python scripts/run_patchcore.py [参数...]
```

2. **修改 `scripts/quick_start.sh`**：
在 `train()` 函数中添加额外的参数

### 调试模式

如果遇到问题，可以：

1. **检查环境**：
```bash
./scripts/check_environment.sh
```

2. **查看详细输出**：
脚本会显示所有执行的命令和参数

3. **使用原始脚本**：
```bash
bash scripts/patchcore_train.sh
bash scripts/patchcore_eval.sh
```

## 🐛 故障排除

### 脚本无法执行

```bash
# 添加执行权限
chmod +x *.sh
```

### 找不到配置文件

```bash
# 运行配置生成器
./scripts/setup_config.sh
```

### 参数错误

检查 `config.sh` 中的参数格式是否正确，特别是：
- 数组格式：`('item1' 'item2')`
- 路径格式：使用引号 `"/path/to/data"`
- 数值格式：不要有引号 `1024` 而不是 `"1024"`

## 📚 相关文档

- [USAGE.md](USAGE.md) - 详细使用指南
- [PARAMETERS.md](PARAMETERS.md) - 参数详细说明
- [README.md](README.md) - 项目概述

## 💡 提示

1. **首次使用**：建议先运行 `scripts/check_environment.sh` 确保环境正确
2. **参数调优**：参考 `PARAMETERS.md` 了解每个参数的影响
3. **保存配置**：为不同实验保存不同的配置文件
4. **查看日志**：注意训练和评估过程中的输出信息

---

**最后更新**：2024年

如有问题，请查看相关文档或检查脚本输出。
