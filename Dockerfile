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

# 5. 커스텀 노드 설치 (무적의 || true 치트키 적용)
WORKDIR /workspace/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git || true
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git || true
RUN git clone https://github.com/banodoco/steerable-motion.git || true
RUN git clone https://github.com/ttulttul/ComfyUI-Iterative-Mixer.git || true
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use.git || true
RUN git clone https://github.com/logerfo/ComfyUI-Color-Match.git || true

# 6. 자동 실행 설정: 주피터랩과 코미풀을 동시에 켭니다.
RUN printf '#!/bin/bash\n\
# 주피터랩 백그라운드 실행\n\
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token="" --NotebookApp.password="" &\n\
\n\
# 코미풀 실행\n\
cd /workspace/ComfyUI\n\
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

# 7. 컨테이너 시작 명령
CMD ["/bin/bash", "/start.sh"]
