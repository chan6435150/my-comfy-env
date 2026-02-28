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

# 5. [핵심] 시작 스크립트: 에러 없는 완벽한 가상환경 부팅 로직
RUN printf '#!/bin/bash\n\
# 주피터랩 실행 (프록시 차단 해제 및 자동 로그인 적용)\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
\n\
# 코미풀 본체 확인 및 클론\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    echo "ComfyUI not found in workspace. Cloning..."\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
fi\n\
\n\
# 매니저 복구 로직\n\
mkdir -p /workspace/ComfyUI/custom_nodes\n\
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
# 네트워크 볼륨에 영구 보관함(venv) 생성\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    echo "Creating virtual environment in network volume..."\n\
    python -m venv /workspace/my_env --system-site-packages\n\
fi\n\
\n\
# ========= [여기서부터 진짜 핵심] =========\n\
# 1. 가상환경 활성화\n\
source /workspace/my_env/bin/activate\n\
\n\
# 2. 필수 부품 체크 (이미 있으면 1~2초 만에 스킵, 없으면 sqlalchemy 등 설치)\n\
cd /workspace/ComfyUI\n\
pip install --no-cache-dir -r requirements.txt\n\
\n\
# 3. 추가 부품(color-matcher, SageAttention) 영구 설치 확인\n\
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
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
