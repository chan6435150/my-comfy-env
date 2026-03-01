# syntax=docker/dockerfile:1.4
# 1. 베이스 이미지: 5090(sm_120) 지원 CUDA 12.8
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# 2. 환경 변수 세팅
ENV PATH=/usr/local/cuda/bin:/usr/local/nvidia/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV DEBIAN_FRONTEND=noninteractive

# 3. 시스템 필수 도구 & Python 3.12 설치
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install -y \
    python3.12 python3.12-dev python3.12-venv python3-pip \
    git wget ffmpeg libgl1-mesa-glx libglib2.0-0 build-essential libopengl0 aria2 \
    && rm -rf /var/lib/apt/lists/*

# 4. 시작 스크립트 작성
COPY <<"EOF" /start.sh
#!/bin/bash
echo "=== 🚀 RTX 5090 네트워크 볼륨 모드 가동 (Python 3.12 적용) ==="
mkdir -p /workspace/tmp
export TMPDIR=/workspace/tmp

# 💡 가상환경 생성 및 신규 생성 여부 플래그 세팅
if [ ! -d "/workspace/my_env_312" ]; then
    echo "새로운 Python 3.12 가상환경을 생성합니다..."
    python3.12 -m venv /workspace/my_env_312 --system-site-packages
    VENV_NEW=1
else
    VENV_NEW=0
fi
source /workspace/my_env_312/bin/activate

# 🪐 주피터랩 설치 및 터미널 에러 수정 (핫픽스 적용)
echo "🪐 주피터랩 및 터미널 환경을 준비합니다..."
pip install --no-cache-dir jupyterlab
# 🚨 주피터 터미널 'Launcher Error' 방지를 위한 강제 업데이트
pip install --no-cache-dir --upgrade jupyter-server-terminals terminado

nohup jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token="" --NotebookApp.password="" > /workspace/jupyterlab.log 2>&1 &
echo "✅ 주피터랩이 8888 포트에서 실행 중입니다."

# 💎 5090 엔진 무결성 검사 및 설치
if python -c "import torch; import torchaudio; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
    echo "✅ 5090 엔진이 건강합니다."
else
    echo "⚠️ 엔진 설치를 시작합니다..." 
    python -m ensurepip --upgrade
    pip install --no-cache-dir --pre --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
    pip install --no-cache-dir sqlalchemy aiohttp pillow ollama gdown open-clip-torch ftfy wcwidth==0.2.13
fi

# 🩺 ComfyUI 본체 자동 치료
cd /workspace
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd /workspace/ComfyUI
git reset --hard HEAD
git pull

# 순정 코어 의존성 설치
pip install --no-cache-dir -r requirements.txt

# 커스텀 노드 클론
mkdir -p custom_nodes && cd custom_nodes
nodes=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"
    "https://github.com/jags111/efficiency-nodes-comfyui"
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"
    "https://github.com/fillthefill/comfyui_fill-nodes"
)
for node in "${nodes[@]}"; do
    dir_name=$(basename "$node")
    if [ ! -d "$dir_name" ]; then git clone "$node"; fi
done

# 🚀 부팅 속도 최적화: 가상환경이 처음이거나 완료 마커가 없을 때만 설치
if [ "$VENV_NEW" -eq 1 ] || [ ! -f "/workspace/my_env_312/.custom_nodes_installed" ]; then
    echo "📦 커스텀 노드 의존성을 설치합니다... (최초 1회 실행)"
    find . -maxdepth 2 -name "requirements.txt" -exec pip install --no-cache-dir -r {} \;
    touch /workspace/my_env_312/.custom_nodes_installed
else
    echo "✅ 커스텀 노드 의존성 설치가 완료된 상태입니다. (스킵)"
fi

# 🚨 RTX 5090 완벽 지원 (SageAttention 에러 방지 및 최신화)
echo "🔧 Triton 및 SageAttention 최신 버전 세팅 중..."
pip install --no-cache-dir -U triton
pip install --no-cache-dir sageattention==2.2.0 --no-build-isolation

cd /workspace/ComfyUI
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto
EOF

RUN chmod +x /start.sh
WORKDIR /workspace
CMD ["/bin/bash", "/start.sh"]
