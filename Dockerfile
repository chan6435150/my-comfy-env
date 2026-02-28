# 1. 베이스 이미지: 5090(sm_120) 지원을 위한 최신 CUDA 12.8 환경
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# 2. 환경 변수 설정: "nvidia-smi" 및 드라이버 인식 오류 원천 봉쇄
ENV PATH=/usr/local/cuda/bin:/usr/local/nvidia/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV DEBIAN_FRONTEND=noninteractive

# 3. 필수 시스템 도구 및 Python 3.11 설치 (가상환경 도구 포함)
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3.11-venv python3-pip \
    git wget ffmpeg libgl1-mesa-glx libglib2.0-0 build-essential libopengl0 \
    && rm -rf /var/lib/apt/lists/*

# 4. uv 설치 (고속 패키지 관리)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# 5. [핵심] 시작 스크립트 작성: 가상환경 재건 및 5090 심장 이식
RUN printf '#!/bin/bash\n\
echo "=== RTX 5090 신성 검증 및 부팅 시작 ==="\n\
\n\
# 🚀 임시 폴더를 넉넉한 workspace로 변경하여 용량 부족 방지\n\
mkdir -p /workspace/tmp\n\
export TMPDIR=/workspace/tmp\n\
\n\
# 주피터랩 가동\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.token="" --ServerApp.password="" &\n\
\n\
# 가상환경(my_env) 구축 (반드시 Python 3.11 사용)\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    python3.11 -m venv /workspace/my_env --system-site-packages\n\
fi\n\
source /workspace/my_env/bin/activate\n\
python -m ensurepip --upgrade\n\
\n\
# 💎 [5090 전용 의존성 해결] 강제 조립 방식\n\
# 서버에 실존하는 최신 2.7.0.dev 빌드를 사용하여 충돌 방지\n\
pip install --no-cache-dir --pre torch==2.7.0.dev20250310+cu124 --index-url https://download.pytorch.org/whl/nightly/cu124\n\
pip install --no-cache-dir --pre torchvision torchaudio --no-deps --index-url https://download.pytorch.org/whl/nightly/cu124\n\
\n\
# ComfyUI 필수 부품 및 에러 방지용 패키지 설치\n\
pip install --no-cache-dir sqlalchemy aiohttp pillow ollama gdown open-clip-torch ftfy wcwidth==0.2.13\n\
\n\
# ComfyUI 본체 업데이트 및 가동\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
fi\n\
cd /workspace/ComfyUI\n\
pip install --no-cache-dir -r requirements.txt\n\
\n\
echo "=== 모든 뒤틀림 정화 완료! 5090 기동 ==="\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh && \
    chmod +x /start.sh

WORKDIR /workspace
CMD ["/bin/bash", "/start.sh"]
