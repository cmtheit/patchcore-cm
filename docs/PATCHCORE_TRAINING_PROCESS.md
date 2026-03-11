# PatchCore 训练流程说明

PatchCore 是一种基于记忆库的异常检测方法，无需监督学习即可识别图像中的异常区域。该方法由 Roth 等人于 2021 年提出，在工业异常检测任务中取得了优异的性能。本文档概述了 PatchCore 的完整训练和评估流程。

## 核心原理

PatchCore 的核心思想是：利用在 ImageNet 上预训练的卷积神经网络提取图像特征，从正常样本中构建一个紧凑的记忆库（Memory Bank），然后通过比较测试样本与记忆库的相似度来检测异常。异常样本的特征与正常样本差异较大，因此可以通过最近邻搜索识别出来。这种方法避免了传统异常检测需要大量标注数据的缺点，只需要正常样本即可训练。

## 训练流程

1. 初始化和配置：加载配置参数（数据路径、网络类型、特征层等），检测是否能使用GPU加速，不能的话就用CPU运行。

2. 加载数据集和网络：加载异常检测数据集（训练集只有正常图片，测试集有正常和异常图片），加载已经训练好的网络模型（如 WideResNet50）。

3. 提取图像特征：用网络模型对训练集中的正常图片提取特征，从网络的中间层（如第2层和第3层）获取包含丰富信息特征的表示。

4. 图像切块处理：把特征图切成小块（比如3x3的小块），每个小块对应图片的一个局部区域，然后把这些小块的特征提取出来。

5. 核心集采样：从所有图片小块的特征中，选择出最有代表性的10%左右的特征，这样既能保持检测效果，又能大大减少需要存储的特征数量。

6. 建立记忆库：把选出来的核心特征存入搜索索引中，形成记忆库，这样后续查找相似特征时速度会很快。


### 1. 初始化和配置

首先加载配置参数，包括数据路径、骨干网络（如 WideResNet50）、特征层（如 layer2 和 layer3）、嵌入维度（如 1024）、核心集采样比例（如 10%）等。系统会自动检测 CUDA 可用性，如果不可用则回退到 CPU 模式。

```python
# 检测CUDA可用性
device = set_torch_device(gpu_ids)
if not torch.cuda.is_available():
    LOGGER.warning("CUDA不可用，回退到CPU模式")
```

### 2. 加载数据集和骨干网络

加载 MVTec AD 等异常检测数据集，数据集通常包含训练集（仅正常样本）和测试集（正常和异常样本）。同时加载预训练的骨干网络，如 WideResNet50、ResNet50 或 Swin Transformer 等。

```python
# 加载数据集
dataloaders = get_dataloaders(seed)
training_data = dataloaders["training"]  # 仅正常样本
testing_data = dataloaders["testing"]    # 正常+异常样本

# 加载骨干网络
backbone = patchcore.backbones.load("wideresnet50")
```

### 3. 特征提取

对训练集中的每张正常图像，使用骨干网络提取多层特征。PatchCore 通常从网络的中间层（如 layer2 和 layer3）提取特征，这些层既包含足够的细节信息，又具有较好的语义表达能力。提取的特征会经过预处理和维度统一，最终得到固定维度的特征向量（如 1024 维）。

```python
# 特征提取
feature_aggregator = NetworkFeatureAggregator(
    backbone, layers_to_extract_from, device
)
features = feature_aggregator(images)  # 提取layer2和layer3的特征
```

### 4. Patch 化和特征聚合

将特征图切分成小的 patch（通常为 3x3），每个 patch 对应图像的一个局部区域。这种方法可以捕获图像的局部细节，有助于精确定位异常位置。对每个 patch 提取特征向量，并聚合来自多个层的特征。如果使用了多个特征层（如 layer2 和 layer3），需要对这些层的特征进行尺寸对齐和融合。

```python
# Patch化
patch_maker = PatchMaker(patchsize=3, stride=1)
patches, patch_shapes = patch_maker.patchify(features)

# 特征预处理和聚合
features = preprocessing(features)  # 统一维度
features = preadapt_aggregator(features)  # 聚合到目标维度
```

### 5. 核心集采样（Coreset Sampling）

这是 PatchCore 的关键步骤。由于从大量图像中提取的 patch 特征数量巨大（可能数万个），直接存储所有特征会占用大量内存。核心集采样通过近似贪心算法选择最具代表性的特征子集（通常为原始特征的 10%），这些特征能够最大程度地覆盖原始特征空间。

```python
# 核心集采样
sampler = ApproximateGreedyCoresetSampler(percentage=0.1)
coreset_features = sampler.sample(features)  # 保留10%的特征
```

### 6. 构建记忆库（Memory Bank）

将采样后的核心集特征存入 FAISS 索引中，形成记忆库。FAISS 提供了高效的最近邻搜索功能，支持 CPU 和 GPU 加速。

```python
# 构建FAISS索引
nn_method = FaissNN(faiss_on_gpu=True)
nn_method.fit(coreset_features)  # 将核心集特征加入索引
```

## 评估流程

### 7. 测试数据特征提取

对测试集中的每张图像（包括正常和异常样本）提取特征，过程与训练阶段相同。

### 8. 异常分数计算

对测试图像的每个 patch 特征，在记忆库中搜索最近的 k 个邻居（通常 k=1），计算 L2 距离作为异常分数。距离越大，说明该 patch 越偏离正常模式，异常可能性越高。图像级的异常分数通常是该图像所有 patch 异常分数的最大值或平均值。

```python
# 计算异常分数
def predict(test_features):
    distances, indices = nn_method.run(
        n_nearest_neighbours=1, 
        query_features=test_features
    )
    anomaly_scores = distances.mean(axis=1)  # 平均距离作为异常分数
    return anomaly_scores
```

### 9. 异常定位

通过异常分数生成像素级的异常分割图。将 patch 级的异常分数上采样到原始图像尺寸，得到每个像素的异常分数。

```python
# 生成分割图
segmentor = RescaleSegmentor(target_size=input_shape)
segmentation_map = segmentor.convert_to_segmentation(patch_scores)
```

### 10. 评估指标计算

使用 sklearn 计算多种评估指标：图像级 AUROC（判断整张图像是否异常）、像素级 AUROC（定位异常像素位置）、PRO 分数（像素级召回率）等。

```python
# 计算AUROC
from sklearn.metrics import roc_auc_score
instance_auroc = roc_auc_score(anomaly_labels, image_scores)
pixel_auroc = roc_auc_score(mask_flat, segmentation_flat)
```

## 优势特点

PatchCore 的优势在于：仅需正常样本训练，无需标注的异常样本，降低了数据收集和标注的成本；利用在 ImageNet 上预训练的模型的特征提取能力，无需从头训练，大大缩短了开发周期；核心集采样大幅降低内存占用，将特征数量从数万个减少到数千个，同时保持检测性能，提高了推理速度；通过 FAISS 的最近邻搜索实现高效的异常检测，支持大规模数据。这些特点使得 PatchCore 在工业异常检测场景中具有很好的实用价值，在 MVTec AD 数据集上可以达到 99.6% 的图像级 AUROC 和 98.4% 的像素级 AUROC。
