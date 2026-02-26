# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구 설치
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 ffmpeg && rm -rf /var/lib/apt/lists/*

# 3. 코미풀 본체 설치
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# 4. 기본 라이브러리 및 uv 설치
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir --upgrade pip ninja wheel uv
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir triton

# 5. 가벼운 백신 패키지만 빌드 시 설치 (natsort 등 포함)
RUN pip install --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab jupyter-server-terminals terminado

# 6. [핵심] 시작 스크립트: SageAttention 자동 검사 및 복구 로직
RUN printf '#!/bin/bash\n\
# 주피터랩 실행\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True &\n\
\n\
# 매니저 복구 로직\n\
mkdir -p /workspace/ComfyUI/custom_nodes\n\
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
# [네트워크 볼륨 최적화] SageAttention 설치 여부 확인\n\
if ! python -c "import sageattention" &> /dev/null; then\n\
    echo "SageAttention not found. Installing to network volume..."\n\
    pip install git+https://github.com/thu-ml/SageAttention.git\n\
fi\n\
\n\
# 코미풀 실행\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
