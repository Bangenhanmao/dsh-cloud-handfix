#!/bin/bash
# setup-cloud.sh - AutoDL ComfyUI image edition (Blackwell)
# The image ships ComfyUI already (start via JupyterLab "Restart and Run All", port 6006).
# This script only: downloads models to /root/autodl-tmp/ComfyUI/models + installs Impact-Pack.
set -e

HF="https://hf-mirror.com"

COMFY_ROOT="/root/autodl-tmp/ComfyUI"
[ -d "$COMFY_ROOT" ] || COMFY_ROOT="$HOME/ComfyUI"
MODELS="$COMFY_ROOT/models"

echo "=== DSH cloud setup (ComfyUI image edition) ==="
echo "ComfyUI root: $COMFY_ROOT"
echo "Models dir:   $MODELS"

mkdir -p "$MODELS/unet" "$MODELS/clip" "$MODELS/vae" "$MODELS/ultralytics/bbox" "$MODELS/upscale_models"

echo "[1/5] FLUX.1-Fill-dev (~24GB, resume-capable)..."
curl -L -C - --retry 5 -o "$MODELS/unet/flux1-fill-dev.safetensors" \
  "$HF/black-forest-labs/FLUX.1-Fill-dev/resolve/main/flux1-fill-dev.safetensors"

echo "[2/5] text encoders..."
curl -L -C - --retry 5 -o "$MODELS/clip/clip_l.safetensors" \
  "$HF/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
curl -L -C - --retry 5 -o "$MODELS/clip/t5xxl_fp16.safetensors" \
  "$HF/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"

echo "[3/5] FLUX VAE (ae)..."
curl -L -C - --retry 5 -o "$MODELS/vae/ae.safetensors" \
  "$HF/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors"

echo "[4/5] anime hand detector..."
curl -L -C - --retry 5 -o "$MODELS/ultralytics/bbox/anime_hand_v1.0_s.pt" \
  "$HF/deepghs/anime_hand_detection/resolve/main/hand_detect_v1.0_s/model.pt"

echo "[5/5] anime 4x upscaler..."
curl -L -C - --retry 5 -o "$MODELS/upscale_models/realesrganX4plusAnime_v1.pt" \
  "$HF/ai-forever/Real-ESRGAN/resolve/main/realesrganX4plusAnime_v1.pt"

echo ""
echo "=== Impact-Pack (hand detection nodes) ==="
mkdir -p "$COMFY_ROOT/custom_nodes"
if [ ! -d "$COMFY_ROOT/custom_nodes/ComfyUI-Impact-Pack" ]; then
  cd "$COMFY_ROOT/custom_nodes"
  git clone --depth 1 https://ghfast.top/https://github.com/ltdrdata/ComfyUI-Impact-Pack.git 2>/dev/null || \
  git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
  cd ComfyUI-Impact-Pack
  pip install -r requirements.txt --quiet
  pip install ultralytics dill --quiet
else
  echo "  already present"
fi

echo ""
echo "=== DONE ==="
echo "Next: in JupyterLab click 'Restart and Run All' to reload ComfyUI (loads new nodes),"
echo "then open port 6006 via AutoDL 'Custom Service' and load hand-fix-cloud-max.json."
