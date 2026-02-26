# 1. 베이스 이미지: NVIDIA 최신 그래픽카드 환경
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구 및 영상 처리(ffmpeg) 한 번에 설치 (최적화)
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 ffmpeg && rm -rf /var/lib/apt/lists/*

# 3. 코미풀(ComfyUI) 본체 먼저 설치
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# 4. 파이썬 기본 라이브러리 및 최강 속도 툴(uv) 설치
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir --upgrade pip ninja wheel uv
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir -r requirements.txt
# (수정) 구버전 sageattention 삭제, triton만 유지
RUN pip install --no-cache-dir triton 

# 5. 커스텀 노드 에러 방지용 '슈퍼 백신' 통합 설치
# 깃허브 로봇(CPU)이 C++ 컴파일할 때 RTX 4090용으로 조립하도록 강제 지정! (필수)
ENV TORCH_CUDA_ARCH_LIST="8.9"

# 무한 재부팅 원인(natsort) 및 최신 SageAttention(깃허브 직통) 추가
RUN pip install --no-cache-dir \
    GitPython \
    opencv-python-headless \
    dill \
    runwayml \
    piexif \
    dynamicprompts \
    numba \
    deepdiff \
    gguf \
    fal-client \
    toml \
    py-cpuinfo \
    onnxruntime-gpu \
    ultralytics \
    segment-anything \
    google-genai \
    nvidia-ml-py \
    natsort \
    reportlab \
    git+https://github.com/thu-ml/SageAttention.git

# 주피터 터미널 엔진 영구 설치
RUN pip install --no-cache-dir jupyter-server-terminals terminado ptyprocess bash_kernel

# 6. 자동 실행 설정 (네트워크 볼륨 덮어쓰기 방어 로직 추가)
RUN printf '#!/bin/bash\n\
# 주피터랩 백그라운드 실행\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no
