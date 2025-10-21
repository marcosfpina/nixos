alias tgi="docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g ghcr.io/huggingface/text-generation-inference:latest"
alias pytorch=="docker run --rm --device=nvidia.com/gpu=all --ipc=host --ulimit stack=67108864 --shm-size=8g nvcr.io/nvidia/pytorch:25.09-py3"
alias jup-ml="docker run --rm \
            --device=nvidia.com/gpu=all \
            --ipc=host \
            --ulimit stack=67108864 \
            --shm-size=8g \
"
