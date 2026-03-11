# pyenv 配置问题解决方案

## 问题描述

如果遇到 "pyenv 似乎复写不了 python 版本" 的问题，通常是因为 pyenv 的 shims 目录没有在 PATH 的最前面。

## 快速修复

### 方法 1：使用修复脚本（推荐）

```bash
./fix_pyenv.sh
```

这个脚本会：
1. 检查 pyenv 是否安装
2. 自动检测你的 shell 配置文件（.bashrc 或 .zshrc）
3. 添加必要的 pyenv 配置
4. 备份原配置文件

### 方法 2：手动修复

#### 步骤 1：检查 pyenv 是否安装

```bash
ls -la ~/.pyenv
```

#### 步骤 2：添加配置到 shell 配置文件

**对于 bash**，编辑 `~/.bashrc`：
```bash
nano ~/.bashrc
```

**对于 zsh**，编辑 `~/.zshrc`：
```bash
nano ~/.zshrc
```

添加以下内容：
```bash
# pyenv 配置
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

#### 步骤 3：使配置生效

```bash
source ~/.bashrc  # 或 source ~/.zshrc
```

或者重新打开终端。

#### 步骤 4：验证

```bash
# 检查 pyenv 版本
pyenv version

# 检查 python3 路径
which python3

# 应该显示类似：/home/username/.pyenv/shims/python3
```

## 脚本已自动支持 pyenv

我已经更新了所有脚本（`scripts/quick_start.sh`、`scripts/run_all_datasets.sh`、`scripts/check_environment.sh`），它们现在会：

1. **自动检测 pyenv**：如果检测到 `~/.pyenv` 目录存在
2. **自动初始化**：在脚本开始时初始化 pyenv
3. **优先使用 pyenv**：确保 pyenv 的 shims 在 PATH 最前面

这意味着即使你的 shell 配置文件中没有配置 pyenv，脚本也会自动使用 pyenv 管理的 Python 版本。

## 验证脚本是否使用 pyenv

运行脚本时，你会看到类似这样的输出：

```
使用 Python: /home/cm/.pyenv/shims/python3 (Python 3.9.18)
```

如果显示的是系统 Python（如 `/usr/bin/python3`），说明 pyenv 没有正确初始化。

## 常见问题

### Q: 为什么脚本中还要初始化 pyenv？

A: 因为脚本可能在非交互式 shell 中运行，或者用户的 shell 配置文件中没有正确配置 pyenv。脚本中的初始化确保无论环境如何，都能使用 pyenv。

### Q: 如何强制使用系统 Python？

A: 如果你想使用系统 Python 而不是 pyenv 管理的版本，可以：

1. 临时禁用：在运行脚本前设置环境变量
   ```bash
   export PATH="/usr/bin:$PATH"
   ./scripts/quick_start.sh train
   ```

2. 或者直接指定 Python 路径（需要修改脚本）

### Q: pyenv 版本和系统版本不一致怎么办？

A: 脚本会自动使用 pyenv 管理的版本（如果 pyenv 已初始化）。你可以通过以下命令查看和切换版本：

```bash
# 查看所有版本
pyenv versions

# 查看当前版本
pyenv version

# 设置全局版本
pyenv global 3.9.18

# 设置本地版本（当前目录）
pyenv local 3.9.18
```

### Q: 如何检查 pyenv 是否正常工作？

运行以下命令：

```bash
# 1. 检查 pyenv 命令
pyenv --version

# 2. 检查已安装的版本
pyenv versions

# 3. 检查当前使用的版本
pyenv version

# 4. 检查 python3 路径（应该指向 pyenv shims）
which python3

# 5. 检查 Python 版本
python3 --version
```

如果 `which python3` 显示的是 `/usr/bin/python3` 而不是 `~/.pyenv/shims/python3`，说明 pyenv 没有正确配置。

## 测试修复

运行环境检查脚本验证：

```bash
./scripts/check_environment.sh
```

这个脚本会检查 Python 环境，并显示使用的 Python 版本和路径。

## 更多信息

- pyenv 官方文档：https://github.com/pyenv/pyenv
- 如果问题仍然存在，请检查：
  1. pyenv 是否正确安装
  2. shell 配置文件是否正确
  3. PATH 环境变量中 pyenv shims 是否在最前面
