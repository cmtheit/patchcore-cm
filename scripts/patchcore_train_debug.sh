source ./scripts/env_train.sh
python -m debugpy --listen 5678 --wait-for-client ${params[@]}
