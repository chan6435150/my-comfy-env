# 1. 베이스: NVIDIA 최신 그래픽카드 환경을 가져옵니다.
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구들 설치: 컴퓨터가 기본적으로 갖춰야 할 연장들을 챙깁니다.
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# 3. 커스텀 노드 설치 (에러가 나도 무시하고 직진하는 || true 치트키 적용!)
WORKDIR /workspace/ComfyUI/custom_nodes

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git || true
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git || true
RUN git clone https://github.com/banodoco/steerable-motion.git || true
RUN git clone https://github.com/ttulttul/ComfyUI-Iterative-Mixer.git || true
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use.git || true
RUN git clone https://github.com/logerfo/ComfyUI-Color-Match.git || true

# 4. 필수 라이브러리 설치: 범인 색출을 위해 명령어를 분리합니다.
WORKDIR /workspace/ComfyUI

# 0) 패키지 설치 도구 최신화 및 컴파일(조립) 필수 도구 미리 깔기
RUN pip install --no-cache-dir --upgrade pip ninja wheel

# 1) 파이토치 환경 설치
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# 2) 코미풀 기본 요구사항 설치
RUN pip install --no-cache-dir -r requirements.txt

# 3) 필수 추가 라이브러리 (보통 여기서 에러가 많이 납니다)
RUN pip install --no-cache-dir triton sageattention nunchaku

# 5. 자동 실행 설정: printf를 써서 줄바꿈을 확실하게 만듭니다.
RUN printf '#!/bin/bash\ncd /workspace/ComfyUI\npython main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

# 컨테이너가 켜질 때 이 스크립트를 실행합니다.
CMD ["/bin/bash", "/start.sh"]
