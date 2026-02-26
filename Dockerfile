# 1. 베이스 이미지: NVIDIA 최신 그래픽카드 환경
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구 및 영상 처리(ffmpeg) 한 번에 설치 (최적화)
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 ffmpeg && rm -rf /var/lib/apt/lists/*

# 3. 코미풀(ComfyUI) 본체 먼저 설치
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# 4. 파이썬 기본 라이브러리 및 최강 속도 툴(uv) 설치
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir --upgrade pip ninja wheel uv
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir triton sageattention

# 5. 커스텀 노드 에러 방지용 '슈퍼 백신' 통합 설치
# (가짜 눈차쿠 대신 깃허브 본진 주소로 직통 설치)
RUN pip install --no-cache-dir \
    GitPython \
    opencv-python-headless \
    dill \
    runwayml \
    piexif \
    dynamicprompts \
    numba \
    deepdiff \
    gguf \
    fal-client \
    toml \
    py-cpuinfo \
    onnxruntime-gpu \
    ultralytics \
    segment-anything \
    google-genai \
    nvidia-ml-py \
    git+https://github.com/nunchaku-ai/nunchaku.git \
    git+https://github.com/facebookresearch/sam2.git

# 주피터 터미널 엔진 영구 설치
RUN pip install --no-cache-dir jupyter-server-terminals terminado ptyprocess bash_kernel

# 6. 자동 실행 설정 (네트워크 볼륨 덮어쓰기 방어 로직 추가)
RUN printf '#!/bin/bash\n\
# 주피터랩 백그라운드 실행\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --NotebookApp.token="" --NotebookApp.password="" &\n\
\n\
# 매니저 생존 확인 및 자동 복구 (런팟 볼륨 마운트 대비)\n\
mkdir -p /workspace/ComfyUI/custom_nodes\n\
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    echo "ComfyUI-Manager not found! Cloning now..."\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
# 코미풀 실행\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

# 7. 컨테이너 시작 명령
CMD ["/bin/bash", "/start.sh"]
