#!/bin/bash
# setup-cloud.sh 鈥?AutoDL 浜戠淇墜鐜涓€閿厤缃紙鏈€楂橀厤锛欶LUX-Fill bf16 + 4x锛?# 鐢ㄦ硶锛歜ash setup-cloud.sh
# 妯″瀷瑁呭埌鏁版嵁鐩橈紙AutoDL: /root/autodl-tmp锛夛紝绯荤粺鐩?30GB 鍙斁 ComfyUI 鏈綋銆?set -e

HF="https://hf-mirror.com"

# AutoDL 鏁版嵁鐩樿矾寰勶紙濡傛寕杞界偣涓嶅悓锛屾敼杩欓噷锛?DATA_ROOT="/root/autodl-tmp"
[ -d "$DATA_ROOT" ] || DATA_ROOT="$HOME"
MODELS="$DATA_ROOT/ComfyUI/models"
COMFY_ROOT="${COMFY_ROOT:-$HOME/ComfyUI}"

echo "=== DSH cloud setup (max spec) ==="

echo "[0/6] Checking PyTorch/CUDA (Blackwell needs cu128+)..."
python -c "import torch; print('torch', torch.__version__, 'cuda', torch.version.cuda, 'available:', torch.cuda.is_available())" 2>/dev/null || echo "torch not installed"
TORCH_CUDA=$(python -c "import torch; print(torch.version.cuda)" 2>/dev/null || echo "")
if [ -z "$TORCH_CUDA" ] || [ "$(echo "$TORCH_CUDA" | cut -d. -f1)" -lt 12 ] || { [ "$(echo "$TORCH_CUDA" | cut -d. -f1)" -eq 12 ] && [ "$(echo "$TORCH_CUDA" | cut -d. -f2)" -lt 8 ]; }; then
  echo "  -> PyTorch CUDA < 12.8 (cannot run Blackwell). Installing cu128 build..."
  pip install --index-url https://download.pytorch.org/whl/cu128 torch torchvision --quiet || \
    pip install torch torchvision --quiet
else
  echo "  -> PyTorch CUDA $TORCH_CUDA OK"
fi
echo "ComfyUI root: $COMFY_ROOT"
echo "Models dir:   $MODELS"

if [ ! -d "$COMFY_ROOT" ]; then
  echo "[1/6] Installing ComfyUI..."
  cd "$(dirname "$COMFY_ROOT")"
  git clone https://github.com/comfyanonymous/ComfyUI.git
  cd "$COMFY_ROOT"
  pip install -r requirements.txt --quiet
else
  echo "[1/6] ComfyUI already present"
fi

mkdir -p "$MODELS/unet" "$MODELS/clip" "$MODELS/vae" "$MODELS/ultralytics/bbox" "$MODELS/upscale_models"

echo "[2/6] Downloading FLUX.1-Fill-dev (~24GB, be patient)..."
if [ ! -f "$MODELS/unet/flux1-fill-dev.safetensors" ]; then
  curl -L -o "$MODELS/unet/flux1-fill-dev.safetensors" \
    "$HF/black-forest-labs/FLUX.1-Fill-dev/resolve/main/flux1-fill-dev.safetensors"
else
  echo "  already present"
fi

echo "[3/6] Downloading text encoders..."
curl -L -o "$MODELS/clip/clip_l.safetensors" \
  "$HF/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors"
curl -L -o "$MODELS/clip/t5xxl_fp16.safetensors" \
  "$HF/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors"

echo "[4/6] Downloading FLUX VAE (ae)..."
curl -L -o "$MODELS/vae/ae.safetensors" \
  "$HF/black-forest-labs/FLUX.1-dev/resolve/main/ae.safetensors"

echo "[5/6] Downloading anime hand detector..."
curl -L -o "$MODELS/ultralytics/bbox/anime_hand_v1.0_s.pt" \
  "$HF/deepghs/anime_hand_detection/resolve/main/hand_detect_v1.0_s/model.pt"

echo "[6/6] Downloading anime 4x upscaler..."
curl -L -o "$MODELS/upscale_models/realesrganX4plusAnime_v1.pt" \
  "$HF/ai-forever/Real-ESRGAN/resolve/main/realesrganX4plusAnime_v1.pt"

echo ""
echo "=== Impact-Pack (hand detection) ==="
mkdir -p "$COMFY_ROOT/custom_nodes"
if [ ! -d "$COMFY_ROOT/custom_nodes/ComfyUI-Impact-Pack" ]; then
  cd "$COMFY_ROOT/custom_nodes"
  git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
  cd ComfyUI-Impact-Pack
  pip install -r requirements.txt --quiet
  pip install ultralytics dill --quiet
else
  echo "  already present"
fi

# 妯″瀷鐩綍绗﹀彿閾炬帴锛圕omfyUI 浠?~/ComfyUI/models 鎵炬ā鍨嬶級
if [ ! -L "$COMFY_ROOT/models" ] && [ "$MODELS" != "$COMFY_ROOT/models" ]; then
  rm -rf "$COMFY_ROOT/models"
  ln -s "$MODELS" "$COMFY_ROOT/models"
  echo "linked $MODELS -> $COMFY_ROOT/models"
fi

echo ""
echo "=== DONE ==="
echo "Start ComfyUI:"
echo "  cd $COMFY_ROOT && python main.py --listen 0.0.0.0 --port 8188"
echo "Then load hand-fix-cloud-max.json in the browser (port 8188 via AutoDL)."

