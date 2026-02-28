# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구 설치
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 ffmpeg && rm -rf /var/lib/apt/lists/*

# 3. 기본 라이브러리 및 uv 설치 (시스템 파이썬에 기본 세팅)
WORKDIR /workspace
RUN pip install --no-cache-dir --upgrade pip ninja wheel uv
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir triton

# 4. 가벼운 백신 패키지만 빌드 시 설치
RUN pip install --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab jupyter-server-terminals terminado

# 5. [핵심] 시작 스크립트: 가상환경(venv) 구축 및 절대 안 날아가는 1초 부팅 로직
RUN printf '#!/bin/bash\n\
# 주피터랩 실행\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True &\n\
\n\
# [수정포인트 1] 런팟 네트워크 볼륨 덮어쓰기 방지용 코미풀 복구\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    echo "ComfyUI not found in workspace. Cloning..."\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
    cd /workspace/ComfyUI && pip install --no-cache-dir -r requirements.txt\n\
fi\n\
\n\
# 매니저 복구 로직\n\
mkdir -p /workspace/ComfyUI/custom_nodes\n\
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
# [수정포인트 2] 네트워크 볼륨에 영구 보관함(venv) 생성 및 활성화\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    echo "Creating virtual environment in network volume..."\n\
    python -m venv /workspace/my_env --system-site-packages\n\
fi\n\
source /workspace/my_env/bin/activate\n\
\n\
# [수정포인트 3] 필수 부품 영구 설치 (이미 있으면 1초 만에 건너뜀)\n\
if ! python -c "import color_matcher" &> /dev/null; then\n\
    echo "Installing color-matcher..."\n\
    pip install color-matcher\n\
fi\n\
if ! python -c "import sageattention" &> /dev/null; then\n\
    echo "Installing SageAttention..."\n\
    pip install --no-build-isolation git+https://github.com/thu-ml/SageAttention.git\n\
fi\n\
\n\
# 코미풀 실행 (가상환경의 파이썬으로 실행)\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
