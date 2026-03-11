# PatchCore 使用指南

本指南将帮助你快速上手使用 PatchCore 进行异常检测。

## 📋 目录

1. [快速开始](#快速开始)
2. [脚本说明](#脚本说明)
3. [使用流程](#使用流程)
4. [常见问题](#常见问题)

## 🚀 快速开始

### 第一步：环境检查

```bash
./scripts/check_environment.sh
```

这个脚本会检查：
- Python 环境
- PyTorch 和 CUDA
- 必要的依赖包
- 数据路径
- 源代码完整性

### 第二步：配置参数

首次使用需要创建配置文件：

```bash
./scripts/setup_config.sh
```

脚本会交互式地询问你各项参数，你也可以直接回车使用默认值。

### 第三步：训练模型

```bash
./scripts/quick_start.sh train
```

### 第四步：评估模型

```bash
./scripts/quick_start.sh eval
```

## 📝 脚本说明

### 1. `scripts/check_environment.sh` - 环境检查

**功能**：检查运行环境是否配置正确

**使用方法**：
```bash
./scripts/check_environment.sh
```

**检查内容**：
- Python 版本（需要 >= 3.7）
- PyTorch 安装和 CUDA 支持
- 必要的 Python 包
- FAISS 库
- 数据路径
- 源代码完整性

### 2. `scripts/setup_config.sh` - 配置生成器

**功能**：交互式创建配置文件 `config.sh`

**使用方法**：
```bash
./scripts/setup_config.sh
```

**配置项**：
- 数据路径
- GPU ID
- 数据集列表
- 骨干网络
- 特征层
- 嵌入维度
- 核心集采样比例
- 图像大小
- 其他训练参数

**生成的配置文件**：`config.sh`

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

**功能说明**：
- `train`：使用 `config.sh` 中的参数训练模型
- `eval`：评估已训练的模型
- `help`：显示帮助信息

**输出**：
- 训练：模型保存在 `results/$LOG_PROJECT/$LOG_GROUP/`
- 评估：结果保存在 `evaluated_results/$LOG_GROUP/`

### 4. `scripts/run_all_datasets.sh` - 批量训练

**功能**：在所有数据集上依次训练模型

**使用方法**：
```bash
./scripts/run_all_datasets.sh
```

**说明**：
- 会遍历所有 15 个 MVTec AD 数据集
- 每个数据集使用相同的配置参数
- 每个数据集有独立的日志组名

**注意**：这会花费较长时间（1-3 小时），建议先用单个数据集测试。

## 🔄 使用流程

### 完整工作流程

```bash
# 1. 检查环境
./scripts/check_environment.sh

# 2. 配置参数（首次使用）
./scripts/setup_config.sh

# 3. 训练模型
./scripts/quick_start.sh train

# 4. 评估模型
./scripts/quick_start.sh eval
```

### 修改配置

如果你想修改参数，有两种方式：

**方式 1：重新运行配置脚本**
```bash
./scripts/setup_config.sh
```

**方式 2：直接编辑配置文件**
```bash
nano config.sh  # 或使用其他编辑器
```

然后重新运行训练或评估。

### 使用不同的配置

你可以创建多个配置文件：

```bash
# 创建快速测试配置
cp config.sh config_fast.sh
# 编辑 config_fast.sh，修改参数
# 使用新配置
source config_fast.sh
./scripts/quick_start.sh train
```

## 📊 参数说明

详细的参数说明请查看 [PARAMETERS.md](PARAMETERS.md)

### 常用参数快速参考

| 参数 | 说明 | 推荐值 |
|------|------|--------|
| `DATAPATH` | 数据路径 | `$PWD/data` |
| `GPU_ID` | GPU 编号 | `0` |
| `BACKBONE` | 骨干网络 | `wideresnet50` |
| `IMAGE_SIZE` | 图像大小 | `224`（快速）或 `320`（最佳） |
| `EMBED_DIM` | 嵌入维度 | `1024` |
| `CORESET_PERCENTAGE` | 核心集采样 | `0.1`（224）或 `0.01`（320） |

## ❓ 常见问题

### Q1: 运行 `scripts/check_environment.sh` 时提示缺少依赖

**解决方案**：
```bash
pip install -r requirements.txt
```

如果使用 GPU，还需要安装 FAISS：
```bash
pip install faiss-gpu
```

如果使用 CPU：
```bash
pip install faiss-cpu
```

### Q2: 训练时提示找不到数据

**解决方案**：
1. 检查 `config.sh` 中的 `DATAPATH` 是否正确
2. 确保数据已下载并解压
3. 数据目录结构应该是：
   ```
   data/
     ├── bottle/
     ├── cable/
     ├── pill/
     └── ...
   ```

### Q3: 训练时内存不足

**解决方案**：
修改 `config.sh` 中的参数：
- 降低 `CORESET_PERCENTAGE`（如 0.1 → 0.05）
- 降低 `EMBED_DIM`（如 1024 → 512）
- 降低 `IMAGE_SIZE`（如 320 → 224）
- 减少数据集数量

### Q4: 如何查看训练进度？

训练过程中会显示进度条，包括：
- 特征提取进度
- 核心集采样进度
- 模型保存状态

### Q5: 训练完成后如何查看结果？

训练完成后：
1. 查看 `results/$LOG_PROJECT/$LOG_GROUP/results.csv` 了解性能指标
2. 运行评估脚本生成详细结果：
   ```bash
   ./scripts/quick_start.sh eval
   ```
3. 评估结果在 `evaluated_results/$LOG_GROUP/`

### Q6: 如何复现论文中的结果？

使用以下配置（在 `scripts/setup_config.sh` 中设置）：
- `IMAGE_SIZE=320`
- `BACKBONE=wideresnet50`
- `CORESET_PERCENTAGE=0.01`
- `EMBED_DIM=1024`
- 其他参数使用默认值

### Q7: 可以使用多个 GPU 吗？

当前脚本只支持单个 GPU。如果要使用多个 GPU，需要修改训练脚本，使用 PyTorch 的 `DataParallel` 或 `DistributedDataParallel`。

### Q8: 训练中断了怎么办？

训练过程中会定期保存模型，如果中断：
1. 检查 `results/$LOG_PROJECT/$LOG_GROUP/models/` 目录
2. 如果有保存的模型，可以直接用于评估
3. 如果想继续训练，需要重新运行训练脚本（会从头开始，但可以使用已保存的模型进行评估）

## 📁 文件结构

```
patchcore-inspection/
├── scripts/
│   ├── quick_start.sh      # 主运行脚本
│   ├── setup_config.sh    # 配置生成器
│   ├── check_environment.sh # 环境检查
│   ├── run_all_datasets.sh # 批量训练
│   ├── patchcore_train.sh
│   ├── patchcore_eval.sh
│   └── ...
├── config.sh               # 配置文件（由 scripts/setup_config.sh 生成）
├── docs/
│   ├── PARAMETERS.md       # 参数说明文档
│   └── USAGE.md            # 本使用指南
├── results/                # 训练结果
└── evaluated_results/      # 评估结果
```

## 🔗 相关文档

- [PARAMETERS.md](PARAMETERS.md) - 详细参数说明
- [README.md](README.md) - 项目概述
- [scripts/sample_training.sh](../scripts/sample_training.sh) - 训练示例
- [scripts/sample_evaluation.sh](../scripts/sample_evaluation.sh) - 评估示例

## 💡 提示

1. **首次使用**：建议先用单个小数据集（如 `pill`）测试，确保环境配置正确
2. **参数调优**：根据你的硬件和需求调整参数，参考 `PARAMETERS.md`
3. **保存配置**：建议为不同的实验保存不同的配置文件
4. **查看日志**：训练和评估过程中的输出信息很有用，注意查看

## 🆘 获取帮助

如果遇到问题：
1. 查看本文档的常见问题部分
2. 查看 `PARAMETERS.md` 了解参数含义
3. 查看原始 `README.md` 了解项目详情
4. 检查 `scripts/check_environment.sh` 的输出

祝使用愉快！🎉
