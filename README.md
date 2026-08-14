# DSH 云端修手部署包（AutoDL 最高配）

单张图最高配置：**A100 80GB + FLUX.1-Fill-dev 完整版（bf16）+ 全程 4x**。

## 最高配管线（hand-fix-cloud-max.json）

```
原图 → RealESRGAN anime 4x 放大（2560x1536 高清基底）
     → anime 手部检测（4x 图手部 180x120，大而清晰）
     → FLUX-Fill bf16 蒙版填充重绘手部（steps 28, denoise 1.0）
     → 输出 4x 高清修手图
```

## AutoDL 步骤（用户操作）

1. **注册**：https://www.autodl.com （手机号）
2. **充值**：支付宝，充 50 元足够（单张图全程约 10-20 分钟）
3. **租卡**：「租用实例」→ 地区选最近 → GPU 选 **A100 40GB/80GB**（最高配，FLUX-Fill bf16 + 4x 全程无压力；4090 24GB 跑 4x fill 可能 OOM）
4. **选镜像**：社区镜像搜 **ComfyUI**（带 PyTorch 2.4+ 的）
5. **开机** → 终端/JupyterLab：
   ```bash
   # 上传 D:\dsh-cloud 的 4 个文件到 /root/cloud/
   cd /root/cloud && bash setup-cloud.sh
   cd ~/ComfyUI/custom_nodes
   git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
   pip install -r ComfyUI-Impact-Pack/requirements.txt ultralytics dill
   cd ~/ComfyUI && python main.py --listen 0.0.0.0 --port 8188
   ```
6. 浏览器开 AutoDL 8188 端口地址 → 拖入 **hand-fix-cloud-max.json** → 换输入图 `1786740275442.png` → 跑

## 模型清单（setup-cloud.sh 自动下载）

| 模型 | 来源 | 大小 |
|---|---|---|
| FLUX.1-Fill-dev | HF (hf-mirror) | ~24GB bf16 |
| clip_l + t5xxl_fp16 | HF | ~9GB |
| ae.safetensors (FLUX VAE) | HF | ~335MB |
| anime_hand_v1.0_s.pt | HF deepghs | 22MB |
| realesrganX4plusAnime | HF | 17MB |

## 参数速调（抽卡/微调）

- `denoise`（KSampler）：1.0 = 完全重画手（最干净，姿势可能微变）；0.85 = 保留更多原手结构
- `steps`：28（当前）→ 更细可 35
- 手部检测 `bbox_threshold`：0.25；手部区域溢出衣服时降 `bbox_dilation`（10 → 5）
