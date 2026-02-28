# 1. 베이스 이미지 (최신 CUDA 환경)
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 시스템 필수 부품 및 컴파일 도구 설치 (SageAttention 빌드에 필수!)
RUN apt-get update && apt-get install -y \
    git wget libgl1-mesa-glx libglib2.0-0 ffmpeg build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. uv 설치 및 기본 패키지 세팅
RUN pip install --no-cache-dir --upgrade pip uv

# [중요] 4. 빌드 단계에서 SageAttention 미리 설치 (이게 자동화의 핵심!)
# RTX 4090 환경에 맞춰서 미리 컴파일해서 넣어버립니다.
RUN uv pip install --system --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    
RUN uv pip install --system --no-cache-dir ninja wheel setuptools
RUN MAX_JOBS=4 uv pip install --system --no-cache-dir git+https://github.com/thu-ml/SageAttention.git

# 5. 나머지 일반 패키지 광속 설치
RUN uv pip install --system --no-cache-dir \
    triton GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyterlab color-matcher sympy mpmath

# 6. 마법의 시작 스크립트 (기존 파일 보존형)
RUN printf '#!/bin/bash\n\
echo "=== 시스템 가동 및 파일 확인 ==="\n\
\n\
# 주피터랩 배경 실행\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
\n\
# 원래 있던 ComfyUI 폴더 확인\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    echo "새로 설치를 시작합니다..."\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
cd /workspace/ComfyUI\n\
# 필수 라이브러리 최종 점검 (이미 깔려있으면 1초만에 넘어감)\n\
uv pip install --system --no-cache-dir -r requirements.txt\n\
\n\
echo "=== 모든 준비 완료! ComfyUI를 시작합니다. ==="\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh

RUN chmod +x /start.sh
CMD ["/bin/bash", "/start.sh"]
