# 1. 5090(sm_120)을 지원하는 최신 베이스 이미지
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# 2. 필수 시스템 도구 및 파이썬 설치 (빈 방에 가구 들이기)
RUN apt-get update && apt-get install -y \
    python3-pip python3-dev git wget libgl1-mesa-glx libglib2.0-0 ffmpeg build-essential libopengl0 \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 명령어를 'python'으로 연결해주네
RUN ln -s /usr/bin/python3 /usr/bin/python

# 3. 최신 공구(uv) 설치
RUN pip install --no-cache-dir --upgrade pip uv

# 4. [5090 특화 설정] Blackwell 아키텍처 지원 명시
ENV TORCH_CUDA_ARCH_LIST="8.9;9.0;10.0;12.0"
ENV MAX_JOBS=4

# 5. [핵심] 5090용 최신 PyTorch 나이틀리 빌드 설치
# 이제 uv가 설치되었으니 이 명령어가 잘 돌아갈 걸세!
RUN uv pip install --system --no-cache-dir \
    --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128

# 6. 나머지 AI 및 Fill-Nodes 필수 패키지 통합 설치
RUN uv pip install --system --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyter-server-terminals terminado ollama gdown color-matcher \
    open-clip-torch scipy wcwidth ftfy transformers huggingface_hub

# (이후 7번 시작 스크립트 부분은 이전과 동일하게 유지하게)
RUN printf '#!/bin/bash\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
fi\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    python -m venv /workspace/my_env --system-site-packages\n\
fi\n\
source /workspace/my_env/bin/activate\n\
pip install ollama gdown open-clip-torch wcwidth==0.2.13 ftfy\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
