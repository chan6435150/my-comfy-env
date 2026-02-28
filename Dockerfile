# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    git wget libgl1-mesa-glx libglib2.0-0 ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 3. uv 및 파이썬 패키지 초고속 설치 (전용 마트와 일반 마트 분리!)
RUN pip install --no-cache-dir --upgrade pip uv

# [전용 마트] PyTorch 부품들만 특별한 곳에서 사오기
RUN uv pip install --system --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# [일반 마트] 나머지 모든 부품들은 일반 마트에서 사오기
RUN uv pip install --system --no-cache-dir \
    triton GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyterlab color-matcher sympy mpmath

# 4. 마법의 시작 스크립트 (자네의 소중한 예전 집을 그대로 씁니다!)
RUN printf '#!/bin/bash\n\
echo "=== 내 소중한 파일들 복구 및 실행 ==="\n\
\n\
# 주피터랩 실행 (이전과 동일)\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
\n\
# 1. 예전 집(/workspace/ComfyUI)이 무사한지 확인! (자네 파일들이 여기 있지!)\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    echo "ComfyUI가 없어서 새로 설치합니다..."\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
# 2. 자네의 원래 집으로 이동!\n\
cd /workspace/ComfyUI\n\
uv pip install --system --no-cache-dir -r requirements.txt\n\
\n\
# 3. 보스 몬스터(SageAttention) 안전하게 설치\n\
echo "=== 특수 부품(SageAttention) 확인 중... ==="\n\
if ! python -c "import sageattention" &> /dev/null; then\n\
    pip install ninja wheel setuptools\n\
    MAX_JOBS=1 pip install git+https://github.com/thu-ml/SageAttention.git\n\
fi\n\
\n\
# 4. 대망의 실행!\n\
echo "=== ComfyUI 기동 (커스텀 노드 전원 부활!) ==="\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh

# 스크립트에 실행 권한 주기
RUN chmod +x /start.sh

# 컨테이너가 켜질 때 스크립트 실행
CMD ["/bin/bash", "/start.sh"]
