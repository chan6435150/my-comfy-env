# 1. 베이스: NVIDIA 최신 그래픽카드 환경을 가져옵니다.
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 2. 필수 도구들 설치: 컴퓨터가 기본적으로 갖춰야 할 연장들을 챙깁니다.
RUN apt-get update && apt-get install -y git wget libgl1-mesa-glx libglib2.0-0 && rm -rf /var/lib/apt/lists/*

# 3. 코미풀 및 필수 커스텀 노드 미리 설치
WORKDIR /workspace/ComfyUI/custom_nodes

# 매니저 설치
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# 윽심님이 쓰시는 필수 노드들 미리 복제
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    git clone https://github.com/banodoco/steerable-motion.git

# 4. 필수 라이브러리 설치: 윽심님이 고생했던 Triton, SageAttention 등을 미리 박아버립니다.
RUN cd ComfyUI && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir triton sageattention nunchaku

# 5. 자동 실행 설정: printf를 써서 줄바꿈을 확실하게 만듭니다.
RUN printf '#!/bin/bash\ncd /workspace/ComfyUI\npython main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto\n' > /start.sh && \
    chmod +x /start.sh

# 컨테이너가 켜질 때 이 스크립트를 실행합니다.
CMD ["/bin/bash", "/start.sh"]
