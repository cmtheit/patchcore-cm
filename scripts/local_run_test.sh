#!/bin/bash
# 在项目根目录运行测试
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

env PYTHONPATH=./src python3 -m pytest -v
