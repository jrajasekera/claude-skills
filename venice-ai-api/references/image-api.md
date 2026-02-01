# Image API Reference

## Generate Images
`POST https://api.venice.ai/api/v1/image/generate`

### Request Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | required | Model ID (e.g., `venice-sd35`, `qwen-image`) |
| `prompt` | string | required | Image description (1-7500 chars, model-specific) |
| `negative_prompt` | string | - | What to avoid (max 7500 chars) |
| `width` | integer | 1024 | Image width (max 1280) |
| `height` | integer | 1024 | Image height (max 1280) |
| `format` | string | "webp" | "jpeg", "png", "webp" |
| `cfg_scale` | number | - | Prompt adherence (0-20) |
| `steps` | integer | 0 | Inference steps (model-specific) |
| `seed` | integer | random | Reproducibility seed (-999999999 to 999999999) |
| `variants` | integer | 1 | Number of images (1-4, requires return_binary=false) |
| `style_preset` | string | - | Apply image style |
| `aspect_ratio` | string | - | "1:1", "16:9", etc. (some models) |
| `resolution` | string | - | "1K", "2K", "4K" (some models) |
| `lora_strength` | integer | - | LoRA strength (0-100) |
| `safe_mode` | boolean | true | Blur adult content |
| `hide_watermark` | boolean | false | Remove Venice watermark |
| `embed_exif_metadata` | boolean | false | Include prompt in EXIF |
| `return_binary` | boolean | false | Return raw binary instead of base64 |
| `enable_web_search` | boolean | false | Use web for reference (some models) |

### Response (JSON)
```json
{
  "id": "generate-image-...",
  "images": ["<base64-encoded-image>"],
  "timing": {
    "total": 5000,
    "inferenceDuration": 4500,
    "inferenceQueueTime": 300,
    "inferencePreprocessingTime": 200
  }
}
```

### Response Headers
- `x-venice-is-blurred`: Image was blurred (Safe Venice)
- `x-venice-is-content-violation`: Content policy violation
- `x-venice-model-deprecation-warning`: Deprecation notice

## Edit Images
`POST https://api.venice.ai/api/v1/image/edit`

Uses Qwen-Image model for AI-powered inpainting.

### Request
| Parameter | Type | Description |
|-----------|------|-------------|
| `prompt` | string | Edit instruction (e.g., "Colorize", "Add a hat") |
| `image` | string | Base64-encoded input image |

### Response
Returns raw image binary data.

```python
response = requests.post(
    "https://api.venice.ai/api/v1/image/edit",
    headers={"Authorization": f"Bearer {api_key}"},
    json={"prompt": "Colorize", "image": base64_image}
)
with open("edited.png", "wb") as f:
    f.write(response.content)
```

## Upscale Images
`POST https://api.venice.ai/api/v1/image/upscale`

Enhance image resolution.

### Request
| Parameter | Type | Description |
|-----------|------|-------------|
| `image` | string | Base64-encoded input image |
| `scale` | integer | Upscale factor (e.g., 2, 4) |

### Response
Returns raw image binary data.

## Image Models

| Model | Best For | Features |
|-------|----------|----------|
| `qwen-image` | Highest quality | Generation, editing |
| `venice-sd35` | General purpose | All features |
| `hidream` | Fast generation | Production speed |
| `nano-banana-pro` | Resolution options | 2K, 4K support |

## Style Presets
Available styles (use with `style_preset`):
- 3D Model
- Analog Film
- Anime
- Cinematic
- Comic Book
- Digital Art
- Enhance
- Fantasy Art
- Isometric
- Line Art
- Low Poly
- Neon Punk
- Origami
- Photographic
- Pixel Art
- Tile Texture

See `/api/v1/image/styles` for full list.

## Error Handling
| Status | Meaning |
|--------|---------|
| 400 | Invalid parameters or image format |
| 401 | Authentication failed |
| 402 | Insufficient balance |
| 429 | Rate limit exceeded |
| 500 | Inference/upscale failed |
| 503 | Model at capacity |
