# 1. 베이스 이미지
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 시스템 도구 설치
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 ffmpeg build-essential \
    && rm -rf /var/lib/apt/lists/*

# 3. [범용 설정] 4090(8.9)과 5090(10.0) 이름표 미리 준비
ENV TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0;10.0"
ENV MAX_JOBS=4

# 4. 기본 도구 및 고속 설치기(uv) 세팅
WORKDIR /workspace
RUN pip install --no-cache-dir --upgrade pip ninja wheel setuptools uv
RUN uv pip install --system --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN uv pip install --system --no-cache-dir triton

# 5. 빌드 시 미리 넣어둘 AI 패키지 (ollama, gdown, color-matcher 포함)
RUN uv pip install --system --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyter-server-terminals terminado ollama gdown color-matcher

# 6. 시작 스크립트 작성 (줄 끝의 역슬래시 \ 를 아주 조심해야 하네!)
RUN printf '#!/bin/bash\n\
echo "=== 하이브리드 시스템 부팅 시작 ==="\n\
\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    echo "ComfyUI를 새로 설치합니다..."\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
fi\n\
\n\
mkdir -p /workspace/ComfyUI/custom_nodes\n\
if [ ! -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then\n\
    cd /workspace/ComfyUI/custom_nodes && git clone https://github.com/ltdrdata/ComfyUI-Manager.git\n\
fi\n\
\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    python -m venv /workspace/my_env --system-site-packages\n\
fi\n\
\n\
source /workspace/my_env/bin/activate\n\
\n\
cd /workspace/ComfyUI\n\
pip install --no-cache-dir -r requirements.txt\n\
\n\
if ! python -c "import sageattention" &> /dev/null; then\n\
    echo "SageAttention 조립 시작..."\n\
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0;10.0" pip install --no-build-isolation git+https://github.com/thu-ml/SageAttention.git\n\
fi\n\
\n\
echo "=== 모든 준비 완료! ComfyUI 기동 ==="\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
