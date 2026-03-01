# 1. 베이스 이미지: 5090(sm_120) 지원 CUDA 12.8
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# 2. 환경 변수: 드라이버 인식 및 경로 고정
ENV PATH=/usr/local/cuda/bin:/usr/local/nvidia/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV DEBIAN_FRONTEND=noninteractive

# 3. 시스템 필수 도구 & Python 3.12 설치 (커뮤니티 템플릿 스펙 이식)
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && apt-get install -y \
    python3.12 python3.12-dev python3.12-venv python3-pip \
    git wget ffmpeg libgl1-mesa-glx libglib2.0-0 build-essential libopengl0 aria2 \
    && rm -rf /var/lib/apt/lists/*

# 4. 시작 스크립트: Python 3.12 기반 + 자동 치료 탑재
RUN printf '#!/bin/bash\n\
echo "=== 🚀 RTX 5090 네트워크 볼륨 모드 가동 (Python 3.12 적용) ==="\n\
mkdir -p /workspace/tmp\n\
export TMPDIR=/workspace/tmp\n\
\n\
# 💡 꼬여있는 예전 폴더를 피하기 위해 my_env_312 라는 새 이름으로 가상환경 생성\n\
if [ ! -d "/workspace/my_env_312" ]; then\n\
    echo "새로운 Python 3.12 가상환경을 생성합니다..."\n\
    python3.12 -m venv /workspace/my_env_312 --system-site-packages\n\
fi\n\
source /workspace/my_env_312/bin/activate\n\
\n\
# 🪐 주피터랩 실행 (포트 8888 유지)\n\
echo "🪐 주피터랩을 준비합니다..."\n\
pip install --no-cache-dir jupyterlab\n\
nohup jupyter lab --ip=0.0.0.0 --port=8888 --allow-root --no-browser --NotebookApp.token="" --NotebookApp.password="" > /workspace/jupyterlab.log 2>&1 &\n\
echo "✅ 주피터랩이 8888 포트에서 백그라운드 실행 중입니다."\n\
\n\
# 💎 5090 엔진 무결성 검사 및 설치\n\
if python -c "import torch; import torchaudio; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then\n\
    echo "✅ 5090 엔진(Python 3.12)이 건강하게 살아있네! 바로 기동하겠네."\n\
else\n\
    echo "⚠️ 엔진 설치를 시작합니다..." \n\
    python -m ensurepip --upgrade\n\
    pip install --no-cache-dir --pre --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128\n\
    pip install --no-cache-dir sqlalchemy aiohttp pillow ollama gdown open-clip-torch ftfy wcwidth==0.2.13\n\
fi\n\
\n\
# 🩺 ComfyUI 본체 자동 치료 (좀비 에러 방지)\n\
cd /workspace\n\
if [ ! -d "ComfyUI" ]; then\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git\n\
fi\n\
cd /workspace/ComfyUI\n\
git reset --hard HEAD\n\
git pull\n\
\n\
# 순정 코어 의존성 꽉꽉 채워넣기\n\
pip install --no-cache-dir -r requirements.txt\n\
\n\
# 커스텀 노드 관리\n\
mkdir -p custom_nodes && cd custom_nodes\n\
nodes=(\n\
    "https://github.com/ltdrdata/ComfyUI-Manager"\n\
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"\n\
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"\n\
    "https://github.com/jags111/efficiency-nodes-comfyui"\n\
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"\n\
    "https://github.com/fillthefill/comfyui_fill-nodes"\n\
)\n\
for node in "${nodes[@]}"; do\n\
    dir_name=$(basename "$node")\n\
    if [ ! -d "$dir_name" ]; then git clone "$node"; fi\n\
done\n\
\n\
find . -maxdepth 2 -name "requirements.txt" -exec pip install --no-cache-dir -r {} \\;\n\
\n\
cd /workspace/ComfyUI\n\
# 🎨 포트 8188 유지\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

WORKDIR /workspace
CMD ["/bin/bash", "/start.sh"]
    echo "✅ 5090 엔진이 건강하게 살아있네! 바로 기동하겠네."\n\
else\n\
    echo "⚠️ 엔진이 뒤틀렸구만. 강제 정화 의식을 시작하지..." \n\
    python -m ensurepip --upgrade\n\
    # 💡 RTX 5090(sm_120) 완벽 인식을 위해 cu128 개발 버전으로 세팅 (핵심 수정 부분)\n\
    pip install --no-cache-dir --pre --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128\n\
    pip install --no-cache-dir sqlalchemy aiohttp pillow ollama gdown open-clip-torch ftfy wcwidth==0.2.13\n\
fi\n\
\n\
# ComfyUI 및 노드 관리\n\
cd /workspace\n\
if [ ! -d "ComfyUI" ]; then git clone https://github.com/comfyanonymous/ComfyUI.git; fi\n\
cd /workspace/ComfyUI\n\
mkdir -p custom_nodes && cd custom_nodes\n\
\n\
nodes=(\n\
    "https://github.com/ltdrdata/ComfyUI-Manager"\n\
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"\n\
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"\n\
    "https://github.com/jags111/efficiency-nodes-comfyui"\n\
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"\n\
    "https://github.com/fillthefill/comfyui_fill-nodes"\n\
)\n\
for node in "${nodes[@]}"; do\n\
    dir_name=$(basename "$node")\n\
    if [ ! -d "$dir_name" ]; then git clone "$node"; fi\n\
done\n\
\n\
find . -maxdepth 2 -name "requirements.txt" -exec pip install --no-cache-dir -r {} \\;\n\
\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

WORKDIR /workspace
CMD ["/bin/bash", "/start.sh"]
