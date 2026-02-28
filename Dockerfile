# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구 설치
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 ffmpeg && rm -rf /var/lib/apt/lists/*

# 3. 기본 라이브러리 및 uv 설치
WORKDIR /workspace
RUN pip install --no-cache-dir --upgrade pip ninja wheel uv
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir triton

# 4. 가벼운 백신 패키지만 빌드 시 설치
RUN pip install --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab jupyter-server-terminals terminado

# 5. [핵심] 불사신 가상환경 부팅 스크립트
RUN printf '#!/bin/bash\n\
# 주피터랩 실행 (보안 해제 완료)\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
\n\
# 코미풀 본체 확인 및 클론\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    echo "ComfyUI not found. Cloning..."\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
fi\n\
\n\
# 매니저 복구 로직\n\
mkdir -p /workspace/ComfyUI/custom_nodes\n\
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
# 네트워크 볼륨 영구 보관함(venv) 생성\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    echo "Creating virtual environment..."\n\
    python -m venv /workspace/my_env --system-site-packages\n\
fi\n\
\n\
# ========= [가상환경 켜기] =========\n\
source /workspace/my_env/bin/activate\n\
\n\
# [긴급 복구] 꼬여버린 수학 부품(mpmath, sympy) 자동 감지 및 강제 초기화\n\
if ! python -c "import sympy; import mpmath" &> /dev/null; then\n\
    echo "Corrupted math packages detected! Force reinstalling..."\n\
    pip install --upgrade --force-reinstall mpmath sympy\n\
fi\n\
\n\
# 필수 부품 체크\n\
cd /workspace/ComfyUI\n\
pip install --no-cache-dir -r requirements.txt\n\
\n\
# 추가 부품 영구 설치\n\
if ! python -c "import color_matcher" &> /dev/null; then\n\
    pip install color-matcher\n\
fi\n\
if ! python -c "import sageattention" &> /dev/null; then\n\
    pip install --no-build-isolation git+https://github.com/thu-ml/SageAttention.git\n\
fi\n\
\n\
# 코미풀 실행 (방어막 추가: 에러 나더라도 서버 끄지 말고 무한 대기!)\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
