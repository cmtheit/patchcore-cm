# PatchCore 参数说明文档

本文档详细说明 PatchCore 项目中所有可配置参数的含义和使用方法。

## 快速开始

1. **首次使用**：运行 `./scripts/setup_config.sh` 创建配置文件
2. **训练模型**：运行 `./scripts/quick_start.sh train`
3. **评估模型**：运行 `./scripts/quick_start.sh eval`

## 参数分类

### 1. 数据相关参数

#### `DATAPATH`
- **说明**：MVTec AD 数据集路径
- **默认值**：`$PWD/data`
- **示例**：`/home/user/data/mvtec_anomaly_detection`
- **注意**：确保数据已下载并解压到该路径

#### `DATASETS`
- **说明**：要使用的数据集列表
- **可选值**：
  - `bottle` - 瓶子
  - `cable` - 电缆
  - `capsule` - 胶囊
  - `carpet` - 地毯
  - `grid` - 网格
  - `hazelnut` - 榛子
  - `leather` - 皮革
  - `metal_nut` - 金属螺母
  - `pill` - 药丸
  - `screw` - 螺丝
  - `tile` - 瓷砖
  - `toothbrush` - 牙刷
  - `transistor` - 晶体管
  - `wood` - 木材
  - `zipper` - 拉链
- **默认值**：`pill`
- **示例**：`('pill' 'cable' 'bottle')`

### 2. 硬件相关参数

#### `GPU_ID`
- **说明**：使用的 GPU 编号
- **默认值**：`0`
- **示例**：`0`, `1`, `2`
- **注意**：如果有多个 GPU，可以指定使用哪个

### 3. 模型架构参数

#### `BACKBONE`
- **说明**：骨干网络（特征提取器）
- **可选值**：
  - `wideresnet50` - WideResNet50（推荐，默认）
  - `wideresnet101` - WideResNet101
  - `resnet50` - ResNet50
  - `resnet101` - ResNet101
  - `resnext101` - ResNeXt101
  - `densenet201` - DenseNet201
  - `vit_swin_base` - Swin Transformer Base
  - `vit_swin_large` - Swin Transformer Large
- **默认值**：`wideresnet50`
- **性能对比**：
  - `wideresnet50`：速度快，性能好（推荐）
  - `wideresnet101`：性能更好，但更慢
  - `vit_swin_base`：Transformer 架构，性能优秀

#### `LAYERS`
- **说明**：从骨干网络提取特征的层
- **默认值**：`layer2 layer3`
- **可选值**（取决于骨干网络）：
  - ResNet/WideResNet: `layer1`, `layer2`, `layer3`, `layer4`
  - DenseNet: `features.denseblock1`, `features.denseblock2`, `features.denseblock3`
  - Swin Transformer: `layers.0`, `layers.1`, `layers.2`
- **建议**：
  - 使用 `layer2` 和 `layer3` 的组合（平衡细节和语义）
  - 只使用 `layer3` 可以获得更好的语义特征
  - 使用 `layer2` 和 `layer4` 可以获得更大的感受野范围

### 4. 特征提取参数

#### `EMBED_DIM`
- **说明**：特征嵌入维度
- **默认值**：`1024`
- **可选值**：`256`, `512`, `768`, `1024`, `1536`, `2048`
- **影响**：
  - 维度越高：特征越丰富，但计算量越大
  - 维度越低：计算更快，但可能丢失信息
- **建议**：
  - 单模型：使用 `1024`
  - 集成模型：可以使用 `384` 或 `512` 以平衡性能

#### `CORESET_PERCENTAGE`
- **说明**：核心集采样比例（用于减少内存使用）
- **默认值**：`0.1`（10%）
- **可选值**：`0.01`, `0.05`, `0.1`, `0.2`
- **影响**：
  - 比例越高：保留更多特征，性能可能更好，但内存占用更大
  - 比例越低：内存占用更小，但可能影响性能
- **建议**：
  - 图像 224x224：使用 `0.1`（10%）
  - 图像 320x320：使用 `0.01`（1%）
  - 内存不足时：降低到 `0.05` 或 `0.01`

### 5. 图像处理参数

#### `IMAGE_SIZE`
- **说明**：输入图像大小（正方形）
- **默认值**：`224`
- **可选值**：`224`, `320`, `384`, `512`
- **影响**：
  - 尺寸越大：检测精度可能更高，但计算量更大
  - 尺寸越小：计算更快，但可能丢失细节
- **建议**：
  - 快速测试：使用 `224`
  - 最佳性能：使用 `320`
  - 高精度需求：使用 `384` 或 `512`

#### `RESIZE_SIZE`
- **说明**：图像预处理时的 resize 大小
- **默认值**：根据 `IMAGE_SIZE` 自动计算
  - `IMAGE_SIZE=224` → `RESIZE_SIZE=256`
  - `IMAGE_SIZE=320` → `RESIZE_SIZE=366`
- **计算规则**：通常是 `IMAGE_SIZE * 366 / 320`
- **注意**：一般不需要手动修改

### 6. 异常检测参数

#### `NUM_NN`
- **说明**：用于异常评分的最近邻数量
- **默认值**：`1`
- **可选值**：`1`, `3`, `5`, `9`
- **影响**：
  - 数量越多：评分更稳定，但计算量更大
  - 数量为 1：计算最快，通常性能也很好
- **建议**：
  - 检测任务：使用 `1`
  - 分割任务：可以使用 `3` 或 `5`

#### `PATCH_SIZE`
- **说明**：局部聚合的 patch 大小
- **默认值**：`3`
- **可选值**：`3`, `5`, `7`
- **影响**：
  - 尺寸越大：捕获更大的局部区域，但可能模糊细节
  - 尺寸越小：保留更多细节，但可能过于敏感
- **建议**：
  - 检测任务：使用 `3`
  - 分割任务：可以使用 `5`

### 7. 训练相关参数

#### `SEED`
- **说明**：随机种子（用于可复现性）
- **默认值**：`0`
- **可选值**：任意整数
- **注意**：使用相同种子可以复现相同结果

### 8. 日志相关参数

#### `LOG_GROUP`
- **说明**：日志组名（用于组织不同的训练运行）
- **默认值**：根据其他参数自动生成
- **格式**：`IM{IMAGE_SIZE}_{BACKBONE}_L{LAYERS}_P{PERCENTAGE}_D{DIM}_PS-{PATCH_SIZE}_AN-{NUM_NN}_S{SEED}`
- **示例**：`IM224_WR50_L2-3_P01_D1024-1024_PS-3_AN-1_S0`
- **注意**：一般不需要手动修改

#### `LOG_PROJECT`
- **说明**：日志项目名
- **默认值**：`MVTecAD_Results`
- **用途**：用于组织不同项目的训练结果

## 参数组合建议

### 快速测试配置
```bash
IMAGE_SIZE=224
BACKBONE=wideresnet50
CORESET_PERCENTAGE=0.1
EMBED_DIM=1024
NUM_NN=1
PATCH_SIZE=3
```

### 最佳性能配置
```bash
IMAGE_SIZE=320
BACKBONE=wideresnet50
CORESET_PERCENTAGE=0.01
EMBED_DIM=1024
NUM_NN=1
PATCH_SIZE=3
```

### 集成模型配置（更高性能）
```bash
IMAGE_SIZE=320
BACKBONE=wideresnet101  # 需要修改脚本支持多个backbone
CORESET_PERCENTAGE=0.01
EMBED_DIM=384
NUM_NN=1
PATCH_SIZE=3
```

### 内存受限配置
```bash
IMAGE_SIZE=224
BACKBONE=wideresnet50
CORESET_PERCENTAGE=0.05
EMBED_DIM=512
NUM_NN=1
PATCH_SIZE=3
```

## 常见问题

### Q: 如何选择合适的数据集？
A: 根据你的应用场景选择。如果是测试，建议先用 `pill` 或 `bottle`，这两个数据集相对简单。

### Q: 训练需要多长时间？
A: 取决于数据集大小和硬件：
- 单个数据集（如 pill）：约 5-15 分钟（GPU）
- 所有数据集：约 1-3 小时（GPU）

### Q: 如何提高检测精度？
A: 
1. 增加 `IMAGE_SIZE`（如 224 → 320）
2. 降低 `CORESET_PERCENTAGE`（如 0.1 → 0.01）
3. 使用更强的骨干网络（如 wideresnet101）
4. 使用集成模型

### Q: 内存不足怎么办？
A:
1. 降低 `CORESET_PERCENTAGE`（如 0.1 → 0.05 或 0.01）
2. 降低 `EMBED_DIM`（如 1024 → 512）
3. 降低 `IMAGE_SIZE`（如 320 → 224）
4. 减少数据集数量

### Q: 如何复现论文中的结果？
A: 使用论文中的配置：
- `IMAGE_SIZE=320`
- `BACKBONE=wideresnet50` 或集成模型
- `CORESET_PERCENTAGE=0.01`
- `EMBED_DIM=1024`（单模型）或 `384`（集成）
- 其他参数使用默认值

## 参数文件位置

- **配置文件**：`config.sh`（由 `scripts/setup_config.sh` 生成）
- **主脚本**：`scripts/quick_start.sh`
- **训练脚本**：`scripts/patchcore_train.sh`
- **评估脚本**：`scripts/patchcore_eval.sh`

## 更多信息

- 查看 `README.md` 了解项目概述
- 查看 `sample_training.sh` 查看更多训练示例
- 查看 `sample_evaluation.sh` 查看评估示例
