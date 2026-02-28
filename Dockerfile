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

# 5. [핵심] 5090용 최신 PyTorch 나이틀리 빌드 설치 (sm_120 대응)
RUN uv pip install --system --no-cache-dir \
    --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128

# 6. [전수 조사] AI 노드 및 ComfyUI 0.14.1 필수 부품 (sqlalchemy 추가!)
RUN uv pip install --system --no-cache-dir \
    GitPython opencv-python-headless dill runwayml piexif dynamicprompts \
    numba deepdiff gguf fal-client toml py-cpuinfo onnxruntime-gpu \
    ultralytics segment-anything google-genai nvidia-ml-py natsort reportlab \
    jupyter-server-terminals terminado ollama gdown color-matcher \
    open-clip-torch scipy wcwidth ftfy transformers huggingface_hub \
    sqlalchemy aiohttp pillow

# 7. 시작 스크립트: 가상환경 복구 및 필수 부품 강제 주입 로직
RUN printf '#!/bin/bash\n\
echo "=== 5090 하이브리드 엔진 부팅 시작 ==="\n\
\n\
# 1. 주피터랩 가동\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &\n\
\n\
# 2. ComfyUI 본체 점검\n\
if [ ! -d "/workspace/ComfyUI" ]; then\n\
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI\n\
fi\n\
\n\
# 3. 가상환경(my_env) 및 pip 복구 로직 (핵심!)\n\
if [ ! -d "/workspace/my_env" ]; then\n\
    python -m venv /workspace/my_env --system-site-packages\n\
fi\n\
source /workspace/my_env/bin/activate\n\
\n\
# 💡 가상환경 내부의 pip이 깨졌을 경우를 대비해 심폐소생술을 실시하네\n\
python -m ensurepip --upgrade\n\
\n\
# 4. 필수 의존성 및 에러 방지용 부품 설치 (용량 아끼기 위해 캐시 미사용)\n\
# sqlalchemy, aiohttp, pillow는 최신 ComfyUI 가동에 필수라네\n\
pip install --no-cache-dir sqlalchemy aiohttp pillow ollama gdown open-clip-torch ftfy\n\
\n\
# 💡 wcwidth 이름표 에러 정화를 위해 특정 버전을 강제로 다시 설치하네\n\
pip install --no-cache-dir --force-reinstall wcwidth==0.2.13\n\
\n\
# 5. ComfyUI 기본 요구사항 최종 확인\n\
cd /workspace/ComfyUI\n\
pip install --no-cache-dir -r requirements.txt\n\
\n\
echo "=== 모든 뒤틀림 정화 완료! 5090 기동 ==="\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity\n' > /start.sh && \
    chmod +x /start.sh

CMD ["/bin/bash", "/start.sh"]
