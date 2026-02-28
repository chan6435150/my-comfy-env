# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 시스템 필수 부품 설치
RUN apt-get update && apt-get install -y \
    git wget libgl1-mesa-glx libglib2.0-0 ffmpeg build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. 파이썬 도구 최신화
RUN pip install --no-cache-dir --upgrade pip setuptools wheel uv

# 4. PyTorch 및 트라이톤 먼저 설치
RUN uv pip install --system --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN uv pip install --system --no-cache-dir triton ninja

# 🚀 [운명의 수정] 공장장에게 4090 사양(8.9)을 강제로 알려주기!
# 이 마법의 주문(TORCH_CUDA_ARCH_LIST)이 있으면 GPU가 없어도 조립이 가능하다네.
RUN TORCH_CUDA_ARCH_LIST="8.9" MAX_JOBS=2 pip install --no-cache-dir --no-build-isolation git+https://github.com/thu-ml/SageAttention.git

# 5. 나머지 일반 패키지 광속 설치 (여기에 ollama를 추가했네!)
RUN uv pip install --system --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyterlab color-matcher sympy mpmath ollama

# 6. 마법의 시작 스크립트 (자네의 소중한 파일 보존)
RUN printf '#!/bin/bash\n\
echo "=== 시스템 가동 및 파일 확인 ==="\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
cd /workspace/ComfyUI\n\
uv pip install --system --no-cache-dir -r requirements.txt\n\
echo "=== 모든 준비 완료! ComfyUI 기동 ==="\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh

RUN chmod +x /start.sh
CMD ["/bin/bash", "/start.sh"]
