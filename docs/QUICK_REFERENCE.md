# PatchCore 快速参考卡片

## 🚀 快速开始（3步）

```bash
# 1. 检查环境
./scripts/check_environment.sh

# 2. 配置参数
./scripts/setup_config.sh

# 3. 训练和评估
./scripts/quick_start.sh train
./scripts/quick_start.sh eval
```

## 📝 脚本速查

| 脚本 | 功能 | 用法 |
|------|------|------|
| `scripts/check_environment.sh` | 环境检查 | `./scripts/check_environment.sh` |
| `scripts/setup_config.sh` | 配置生成 | `./scripts/setup_config.sh` |
| `scripts/quick_start.sh` | 训练/评估 | `./scripts/quick_start.sh train/eval` |
| `scripts/run_all_datasets.sh` | 批量训练 | `./scripts/run_all_datasets.sh` |

## ⚙️ 常用参数

### 快速测试配置
```bash
IMAGE_SIZE=224
BACKBONE=wideresnet50
CORESET_PERCENTAGE=0.1
EMBED_DIM=1024
DATASETS=('pill')
```

### 最佳性能配置
```bash
IMAGE_SIZE=320
BACKBONE=wideresnet50
CORESET_PERCENTAGE=0.01
EMBED_DIM=1024
DATASETS=('pill' 'cable' 'bottle')
```

## 📂 输出位置

- **训练结果**：`results/$LOG_PROJECT/$LOG_GROUP/`
- **评估结果**：`evaluated_results/$LOG_GROUP/`
- **模型文件**：`results/.../models/mvtec_<dataset>/`

## 🔧 常用命令

```bash
# 查看配置
cat config.sh

# 修改配置
nano config.sh

# 重新配置
./scripts/setup_config.sh

# 查看帮助
./scripts/quick_start.sh help
```

## 📚 文档

- **使用指南**：`USAGE.md`
- **参数说明**：`PARAMETERS.md`
- **脚本说明**：`SCRIPTS_README.md`

## ⚠️ 常见问题

| 问题 | 解决方案 |
|------|----------|
| 缺少依赖 | `pip install -r requirements.txt` |
| 内存不足 | 降低 `CORESET_PERCENTAGE` 或 `EMBED_DIM` |
| 找不到数据 | 检查 `config.sh` 中的 `DATAPATH` |
| 脚本无权限 | `chmod +x *.sh` |
