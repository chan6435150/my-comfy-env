#!/bin/bash
echo "=== 교수님 특제 아키텍처: RunPod 볼륨 매핑 시작 ==="

# 🚀 [핵심 2] /workspace(네트워크 볼륨)에 영구 보관할 폴더들을 생성하네.
mkdir -p /workspace/ComfyUI_Models
mkdir -p /workspace/ComfyUI_Output

# 기존의 텅 빈 모델/아웃풋 폴더를 지우고, 영구 보관함으로 향하는 '바로가기'를 뚫어주네!
# 이렇게 하면 ComfyUI는 /app에 있지만, 모델은 /workspace에 저장되어 영구 보존되지.
rm -rf /app/ComfyUI/models
ln -s /workspace/ComfyUI_Models /app/ComfyUI/models

rm -rf /app/ComfyUI/output
ln -s /workspace/ComfyUI_Output /app/ComfyUI/output

# 주피터랩 실행 (자네의 고집대로 보안은 열어두었네. 디렉토리는 /workspace로 잡아두었으니 작업물은 안전할 거라네.)
jupyter lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace \
    --ServerApp.terminals_enabled=True --ServerApp.allow_origin="*" \
    --ServerApp.disable_check_xsrf=True --ServerApp.trust_xheaders=True \
    --ServerApp.allow_remote_access=True --ServerApp.token="" --ServerApp.password="" &

# ComfyUI 실행 (이제 설치 대기 시간 0초! 바로 켜질 걸세!)
echo "=== ComfyUI 기동 ==="
cd /app/ComfyUI
python main.py --listen 0.0.0.0 --port 8188 --highvram --preview-method auto || sleep infinity
