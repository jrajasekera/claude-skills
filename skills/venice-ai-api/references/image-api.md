# Image API Reference

## Generate Images
`POST https://api.venice.ai/api/v1/image/generate`

### Request Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | required | Model ID (e.g., `venice-sd35`, `qwen-image`) |
| `prompt` | string | required | Image description (1-7500 chars, model-specific) |
| `negative_prompt` | string | - | What to avoid (max 7500 chars). Less effective on newer models like Flux |
| `width` | integer | 1024 | Image width (max 1280) |
| `height` | integer | 1024 | Image height (max 1280) |
| `format` | string | "webp" | "jpeg", "png", "webp" |
| `cfg_scale` | number | - | Prompt adherence (0-20, typically 7.0-15.0) |
| `steps` | integer | 0 | Inference steps (model-specific) |
| `seed` | integer | random | Reproducibility seed (-999999999 to 999999999) |
| `variants` | integer | 1 | Number of images (1-4, requires return_binary=false) |
| `style_preset` | string | - | Apply image style (see Style Presets below) |
| `aspect_ratio` | string | - | "1:1", "16:9", etc. (some models) |
| `resolution` | string | - | "1K", "2K", "4K" (some models like nano-banana-pro) |
| `lora_strength` | integer | - | LoRA strength (0-100) |
| `safe_mode` | boolean | true | Blur adult content. Set false for uncensored generation |
| `hide_watermark` | boolean | false | Remove Venice watermark |
| `embed_exif_metadata` | boolean | false | Include prompt in EXIF |
| `return_binary` | boolean | false | Return raw binary instead of base64 JSON |
| `enable_web_search` | boolean | false | Use web for reference (some models) |

### Response (JSON, when return_binary=false)
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

### Complete Generation Example (Python)
```python
import requests
import base64
import os

headers = {
    "Authorization": f"Bearer {os.getenv('VENICE_API_KEY')}",
    "Content-Type": "application/json"
}

response = requests.post(
    "https://api.venice.ai/api/v1/image/generate",
    headers=headers,
    json={
        "model": "venice-sd35",
        "prompt": "A cyberpunk city with neon lights and rain",
        "negative_prompt": "blur, low quality, distorted",
        "width": 1024,
        "height": 1024,
        "format": "webp",
        "cfg_scale": 7.5,
        "steps": 30,
        "seed": 42,
        "style_preset": "Cinematic",
        "safe_mode": True,
        "variants": 1
    }
)

result = response.json()
image_data = base64.b64decode(result["images"][0])
with open("output.webp", "wb") as f:
    f.write(image_data)
```

### Complete Generation Example (JavaScript)
```javascript
const response = await fetch('https://api.venice.ai/api/v1/image/generate', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${process.env.VENICE_API_KEY}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        model: 'venice-sd35',
        prompt: 'A cyberpunk city with neon lights and rain',
        negative_prompt: 'blur, low quality, distorted',
        width: 1024,
        height: 1024,
        format: 'webp'
    })
});

const result = await response.json();
const imageBuffer = Buffer.from(result.images[0], 'base64');
fs.writeFileSync('output.webp', imageBuffer);
```

### Response Headers
- `x-venice-is-blurred`: Image was blurred (safe mode triggered)
- `x-venice-is-content-violation`: Content policy violation
- `x-venice-model-deprecation-warning`: Deprecation notice

## Upscale Images
`POST https://api.venice.ai/api/v1/image/upscale`

Enhance image resolution 2x or 4x.

### Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `image` | string | Yes | Base64-encoded input image |
| `scale` | integer | Yes | Upscale factor: 2 or 4 |

### Pricing
- 2x upscale: $0.02
- 4x upscale: $0.08

### Python Example
```python
import base64
import requests

# Load source image
with open("photo.jpg", "rb") as f:
    image_base64 = base64.b64encode(f.read()).decode("utf-8")

# Upscale 4x
response = requests.post(
    "https://api.venice.ai/api/v1/image/upscale",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    },
    json={
        "image": image_base64,
        "scale": 4
    }
)

# Response is raw image binary
with open("upscaled.png", "wb") as f:
    f.write(response.content)
print(f"Upscaled: {len(response.content)} bytes")
```

### JavaScript Example
```javascript
import fs from 'fs';

const imageBase64 = fs.readFileSync('photo.jpg').toString('base64');

const response = await fetch('https://api.venice.ai/api/v1/image/upscale', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${process.env.VENICE_API_KEY}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        image: imageBase64,
        scale: 4
    })
});

const buffer = Buffer.from(await response.arrayBuffer());
fs.writeFileSync('upscaled.png', buffer);
```

## Edit Images (Inpainting)
`POST https://api.venice.ai/api/v1/image/edit`

Uses Qwen-Image model for AI-powered editing/inpainting. The model analyzes the image and text instruction to alter specific regions while preserving overall composition.

### Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt` | string | Yes | Edit instruction (e.g., "Colorize", "Change sky to sunset", "Add a hat") |
| `image` | string | Yes | Base64-encoded input image, or URL starting with http/https |

### Pricing
~$0.04 per edit

### Response
Returns raw image binary data.

### Python Example
```python
import base64
import requests

# Load source image
with open("photo.jpg", "rb") as f:
    image_base64 = base64.b64encode(f.read()).decode("utf-8")

# Edit the image
response = requests.post(
    "https://api.venice.ai/api/v1/image/edit",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    },
    json={
        "prompt": "Change the sky to a dramatic sunset with orange and purple clouds",
        "image": image_base64
    }
)

with open("edited.png", "wb") as f:
    f.write(response.content)
```

### JavaScript Example
```javascript
import fs from 'fs';

const imageBase64 = fs.readFileSync('photo.jpg').toString('base64');

const response = await fetch('https://api.venice.ai/api/v1/image/edit', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${process.env.VENICE_API_KEY}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        prompt: 'Make the background a cozy coffee shop',
        image: imageBase64
    })
});

const buffer = Buffer.from(await response.arrayBuffer());
fs.writeFileSync('edited.png', buffer);
```

### Using a URL Instead of Base64
```python
response = requests.post(
    "https://api.venice.ai/api/v1/image/edit",
    headers=headers,
    json={
        "prompt": "Colorize this black and white photo",
        "image": "https://example.com/bw-photo.jpg"
    }
)
```

### Generate → Edit → Upscale Pipeline
```python
import base64
import requests

headers = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json"
}

# Step 1: Generate
gen_resp = requests.post(
    "https://api.venice.ai/api/v1/image/generate",
    headers=headers,
    json={
        "model": "venice-sd35",
        "prompt": "A medieval castle on a hilltop",
        "width": 1024,
        "height": 1024
    }
)
generated_b64 = gen_resp.json()["images"][0]

# Step 2: Edit
edit_resp = requests.post(
    "https://api.venice.ai/api/v1/image/edit",
    headers=headers,
    json={
        "prompt": "Add a dragon flying above the castle",
        "image": generated_b64
    }
)
edited_b64 = base64.b64encode(edit_resp.content).decode("utf-8")

# Step 3: Upscale
upscale_resp = requests.post(
    "https://api.venice.ai/api/v1/image/upscale",
    headers=headers,
    json={
        "image": edited_b64,
        "scale": 4
    }
)
with open("final_4k.png", "wb") as f:
    f.write(upscale_resp.content)
```

## Image Models

| Model | Best For | Resolution | Pricing |
|-------|----------|------------|---------|
| `qwen-image` | Highest quality, editing | 1K, 2K, 4K | Variable |
| `venice-sd35` | General purpose (default) | Standard | ~$0.01/image |
| `hidream` | Fast generation | Standard | ~$0.01/image |
| `flux-2-pro` | Professional quality | Standard | ~$0.04/image |
| `flux-2-max` | High-quality output | Standard | ~$0.02/image |
| `nano-banana-pro` | Photorealism, product shots | 1K, 2K, 4K | $0.18-$0.35 |
| `z-image-turbo` | Fast, good quality | Standard | Variable |

**Note:** Model availability changes. Query `GET /models?type=image` for current options.

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

Query `/api/v1/image/styles` for the full up-to-date list.

## Error Handling
| Status | Meaning |
|--------|---------|
| 400 | Invalid parameters or image format |
| 401 | Authentication failed |
| 402 | Insufficient balance |
| 429 | Rate limit exceeded (20 RPM for images) |
| 500 | Inference/upscale failed |
| 503 | Model at capacity |
