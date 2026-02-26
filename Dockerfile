## 1. 베이스 이미지: NVIDIA 최신 그래픽카드 환경
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구 설치
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# 3. 코미풀(ComfyUI) 본체 먼저 설치 (이게 있어야 requirements.txt가 생깁니다!)
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

# 4. 파이썬 라이브러리 설치 (에러 났던 부분 세분화)
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir --upgrade pip ninja wheel
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir triton sageattention nunchaku

# 5. 영상 처리(ffmpeg) 및 파이썬 필수 부품 영구 설치 (윽심님 맞춤형 치료제)
RUN apt-get update && apt-get install -y ffmpeg && \
    pip install --no-cache-dir --force-reinstall GitPython && \
    pip install --no-cache-dir opencv-python-headless numba deepdiff gguf piexif fal-client dynamicprompts && \
    pip install --no-cache-dir --upgrade nunchaku jupyter-server-terminals terminado ptyprocess bash_kernel

# 6. 자동 실행 설정 (커스텀 노드 자동 검사 + 주피터 터미널 활성화)
RUN printf '#!/bin/bash\n\
# 팟이 켜질 때마다 커스텀 노드들의 요구사항(requirements)을 싹쓸이 자동 설치\n\
echo "Checking and installing custom nodes requirements..."\n\
find /workspace/ComfyUI/custom_nodes -maxdepth 2 -name "requirements.txt" -exec python -m pip install -r {} \\;\n\
\n\
# 주피터랩 백그라운드 실행 (터미널 기능 켜기)\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace --ServerApp.terminals_enabled=True --NotebookApp.token="" --NotebookApp.password="" &\n\
\n\
# 코미풀 실행\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

# 7. 컨테이너 시작 명령
CMD ["/bin/bash", "/start.sh"]
