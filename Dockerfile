# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    git wget libgl1-mesa-glx libglib2.0-0 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 컴퓨터 본체로 이동
WORKDIR /app

# 3. uv 및 기본 파이썬 패키지 초고속 설치
RUN pip install --no-cache-dir --upgrade pip uv
RUN uv pip install --system --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 \
    triton

# 4. ComfyUI 본체 및 매니저 사전 설치
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI && \
    cd /app/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# 5. 의존성 패키지 일괄 설치
RUN uv pip install --system --no-cache-dir -r /app/ComfyUI/requirements.txt
RUN uv pip install --system --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyterlab color-matcher sympy mpmath

# 6. 마법의 시작 스크립트를 도커 파일 안에서 직접 만들기! (에러 없는 printf 방식!)
RUN printf '#!/bin/bash\n\
echo "=== 런팟 볼륨 매핑 시작 ==="\n\
mkdir -p /workspace/ComfyUI_Models\n\
mkdir -p /workspace/ComfyUI_Output\n\
rm -rf /app/ComfyUI/models\n\
ln -s /workspace/ComfyUI_Models /app/ComfyUI/models\n\
rm -rf /app/ComfyUI/output\n\
ln -s /workspace/ComfyUI_Output /app/ComfyUI/output\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
echo "=== 특수 부품(SageAttention) 조립 중... (시간이 조금 걸릴 수 있음) ==="\n\
if ! python -c "import sageattention" &> /dev/null; then\n\
    pip install ninja wheel setuptools\n\
    MAX_JOBS=1 pip install git+https://github.com/thu-ml/SageAttention.git\n\
fi\n\
echo "=== ComfyUI 기동 ==="\n\
cd /app/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh

# 스크립트에 실행 권한 주기
RUN chmod +x /start.sh

# 컨테이너가 켜질 때 스크립트 실행
CMD ["/bin/bash", "/start.sh"]
