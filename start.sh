#!/bin/bash
echo "=== 교수님 특제 아키텍처: RunPod 볼륨 매핑 시작 ==="

# 1. 마법의 USB(영구 보관함) 폴더 만들기
mkdir -p /workspace/ComfyUI_Models
mkdir -p /workspace/ComfyUI_Output

# 2. 본체에 있는 폴더를 지우고 USB 폴더로 통로 연결하기 (심링크)
rm -rf /app/ComfyUI/models
ln -s /workspace/ComfyUI_Models /app/ComfyUI/models

rm -rf /app/ComfyUI/output
ln -s /workspace/ComfyUI_Output /app/ComfyUI/output

# 3. 주피터랩 실행
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace \
    --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" \
    --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True \
    --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &

# 🚀 [여기가 핵심 작전!] 까다로운 보스몹(SageAttention)을 GPU가 켜진 지금 설치한다!
echo "=== 까다로운 특수 부품(SageAttention) 조립 중... (시간이 조금 걸릴 수 있음) ==="
# 파이썬에 sageattention이 설치되어 있는지 확인하고, 없으면 설치!
if ! python -c "import sageattention" &> /dev/null; then
    pip install ninja wheel setuptools
    # MAX_JOBS=1 은 컴퓨터가 너무 무리해서 터지지 않게 천천히 하나씩 조립하라는 마법 주문!
    MAX_JOBS=1 pip install git+https://github.com/thu-ml/SageAttention.git
fi
echo "=== 특수 부품 설치 완료! ==="

# 4. ComfyUI 기동
echo "=== ComfyUI 기동 ==="
cd /app/ComfyUI
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity
