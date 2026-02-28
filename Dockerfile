# 1. 베이스 이미지: 5090(sm_120) 지원 CUDA 12.8
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# 2. 환경 변수: 드라이버 인식 및 경로 최적화
ENV PATH=/usr/local/cuda/bin:/usr/local/nvidia/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV DEBIAN_FRONTEND=noninteractive

# 3. 시스템 필수 도구 설치
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    git wget ffmpeg libgl1-mesa-glx libglib2.0-0 build-essential libopengl0 aria2 \
    && rm -rf /var/lib/apt/lists/*

# 4. [핵심] 시작 스크립트: 노드 자동 설치 로직 포함
RUN printf '#!/bin/bash\n\
echo "=== 🚀 RTX 5090 개척 모드 가동 ==="\n\
\n\
mkdir -p /workspace/tmp\n\
export TMPDIR=/workspace/tmp\n\
\n\
# 가상환경 구축 및 입장\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    python3.11 -m venv /workspace/my_env --system-site-packages\n\
fi\n\
source /workspace/my_env/bin/activate\n\
python -m ensurepip --upgrade\n\
\n\
# 💎 5090 전용 심장 이식 (Nightly 2.7.0.dev)\n\
pip install --no-cache-dir --pre torch==2.7.0.dev20250310+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu124\n\
\n\
# 🛠️ 자네가 요청했던 필수 패키지들 일괄 설치\n\
pip install --no-cache-dir sqlalchemy aiohttp pillow ollama gdown open-clip-torch ftfy wcwidth==0.2.13\n\
\n\
# 📂 ComfyUI 본체 및 커스텀 노드 관리\n\
cd /workspace\n\
if [ ! -d "ComfyUI" ]; then\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git\n\
fi\n\
cd /workspace/ComfyUI\n\
\n\
# 🔗 [자동화] 필수 커스텀 노드들 설치\n\
mkdir -p custom_nodes\n\
cd custom_nodes\n\
\n\
# 노드 목록 (여기에 더 추가하고 싶은 깃허브 주소를 넣게나)\n\
nodes=(\n\
    "https://github.com/ltdrdata/ComfyUI-Manager"\n\
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"\n\
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack"\n\
    "https://github.com/jags111/efficiency-nodes-comfyui"\n\
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus"\n\
)\n\
\n\
for node in "${nodes[@]}"; do\n\
    dir_name=$(basename "$node")\n\
    if [ ! -d "$dir_name" ]; then\n\
        git clone "$node"\n\
    fi\n\
done\n\
\n\
# 📦 모든 노드의 의존성 자동 설치\n\
find . -maxdepth 2 -name "requirements.txt" -exec pip install --no-cache-dir -r {} \\;\n\
\n\
cd /workspace/ComfyUI\n\
echo "=== ✨ 모든 뒤틀림 정화 완료! 5090 출격 ==="\n\
# 5090 성능 극대화를 위한 옵션들 (--highvram)\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

WORKDIR /workspace
CMD ["/bin/bash", "/start.sh"]
