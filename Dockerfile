# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    git wget libgl1-mesa-glx libglib2.0-0 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 🚀 [핵심 1] RunPod의 /workspace 덮어쓰기를 피하기 위해 안전한 /app으로 대피!
WORKDIR /app

# 3. uv 및 기본 파이썬 패키지 설치 (캐시 날려서 이미지 다이어트)
RUN pip install --no-cache-dir --upgrade pip uv
RUN uv pip install --system --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 \
    triton

# 4. ComfyUI 본체 및 매니저 사전 설치 (절대 변하지 않는 뼈대)
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI && \
    cd /app/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# 5. 의존성 패키지 일괄 설치 (uv --system을 써서 venv 없이 가장 빠르고 깔끔하게!)
RUN uv pip install --system --no-cache-dir -r /app/ComfyUI/requirements.txt
RUN uv pip install --system --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyterlab color-matcher sympy mpmath


# 7. 시작 스크립트 복사
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
