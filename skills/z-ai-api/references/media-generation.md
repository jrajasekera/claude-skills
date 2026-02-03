# Media Generation APIs

## Image Generation

### Endpoint
`POST https://api.z.ai/api/paas/v4/images/generations`

### Models

| Model | Quality Default | Size Default | Notes |
|-------|-----------------|--------------|-------|
| `glm-image` | hd | 1280x1280 | Latest, high quality |
| `cogview-4-250304` | standard | 1024x1024 | Faster generation |

### Request
```json
{
  "model": "glm-image",
  "prompt": "A cute kitten on a sunny windowsill",
  "quality": "hd",
  "size": "1280x1280",
  "user_id": "optional_user_id"
}
```

### Parameters

**quality**
- `hd`: Detailed, rich, ~20 seconds (glm-image default)
- `standard`: Faster, ~5-10 seconds

**size (glm-image)**
- Recommended: `1280x1280`, `1568x1056`, `1056x1568`, `1472x1088`, `1088x1472`, `1728x960`, `960x1728`
- Custom: 1024-2048px, divisible by 32, max 2^22 pixels

**size (cogview-4)**
- Recommended: `1024x1024`, `768x1344`, `864x1152`, `1344x768`, `1152x864`, `1440x720`, `720x1440`
- Custom: 512-2048px, divisible by 16, max 2^21 pixels

### Response
```json
{
  "created": 1234567890,
  "data": [{
    "url": "https://cdn.z.ai/generated/image.png"
  }],
  "content_filter": [{
    "role": "assistant",
    "level": 3
  }]
}
```
Note: Image URLs expire after 30 days.

### Python Example
```python
response = client.images.generate(
    model="glm-image",
    prompt="A serene mountain landscape at sunset",
    size="1280x1280",
    quality="hd"
)
print(response.data[0].url)
```

---

## Video Generation (Async)

### Endpoint
`POST https://api.z.ai/api/paas/v4/videos/generations`

### Models

| Model | Type | Duration | Size |
|-------|------|----------|------|
| `cogvideox-3` | Text/Image to Video | 5-10s | Up to 4K |
| `viduq1-text` | Text to Video | 5s | 1920x1080 |
| `viduq1-image` | Image to Video | 5s | 1920x1080 |
| `vidu2-image` | Image to Video | 4s | 1280x720 |
| `viduq1-start-end` | First/Last Frame | 5s | 1920x1080 |
| `vidu2-start-end` | First/Last Frame | 4s | 1280x720 |
| `vidu2-reference` | Reference Images | 4s | 1280x720 |

### CogVideoX-3 Request
```json
{
  "model": "cogvideox-3",
  "prompt": "A cat playing with a ball",
  "quality": "quality",
  "with_audio": true,
  "size": "1920x1080",
  "fps": 30,
  "duration": 5,
  "image_url": ["https://example.com/start.jpg"]
}
```

**Parameters:**
- `prompt`: Description, max 512 chars
- `quality`: `speed` (default) or `quality`
- `with_audio`: Generate AI sound effects
- `size`: `1280x720`, `720x1280`, `1024x1024`, `1920x1080`, `1080x1920`, `2048x1080`, `3840x2160`
- `fps`: 30 or 60
- `duration`: 5 or 10 seconds
- `image_url`: Start image or [start, end] frames

### Vidu Text-to-Video Request
```json
{
  "model": "viduq1-text",
  "prompt": "A majestic eagle soaring",
  "style": "general",
  "aspect_ratio": "16:9",
  "movement_amplitude": "auto"
}
```

**Parameters:**
- `style`: `general` or `anime`
- `aspect_ratio`: `16:9`, `9:16`, `1:1`
- `movement_amplitude`: `auto`, `small`, `medium`, `large`

### Vidu Image-to-Video Request
```json
{
  "model": "viduq1-image",
  "image_url": "https://example.com/photo.jpg",
  "prompt": "Make the scene come alive",
  "movement_amplitude": "medium",
  "with_audio": true
}
```

### Vidu Reference-to-Video (vidu2-reference)
```json
{
  "model": "vidu2-reference",
  "image_url": [
    "https://example.com/ref1.jpg",
    "https://example.com/ref2.jpg"
  ],
  "prompt": "Generate a video with these characters",
  "aspect_ratio": "16:9"
}
```
Supports 1-3 reference images for consistent subject generation.

### Response (Async)
```json
{
  "model": "cogvideox-3",
  "id": "task_order_id",
  "request_id": "your_request_id",
  "task_status": "PROCESSING"
}
```

### Polling for Results
`GET https://api.z.ai/api/paas/v4/async-result/{task_id}`

```json
{
  "model": "cogvideox-3",
  "task_status": "SUCCESS",
  "video_result": [{
    "url": "https://cdn.z.ai/video.mp4",
    "cover_image_url": "https://cdn.z.ai/cover.jpg"
  }]
}
```

Task statuses: `PROCESSING`, `SUCCESS`, `FAIL`

---

## Audio Transcription

### Endpoint
`POST https://api.z.ai/api/paas/v4/audio/transcriptions`

Content-Type: `multipart/form-data`

### Model
- `glm-asr-2512`: Speech-to-text, multilingual

### Request
```python
import requests

files = {
    'file': ('audio.mp3', open('audio.mp3', 'rb'), 'audio/mpeg'),
    'model': (None, 'glm-asr-2512'),
    'stream': (None, 'false'),
    'hotwords': (None, '["technical_term", "brand_name"]')
}

response = requests.post(
    "https://api.z.ai/api/paas/v4/audio/transcriptions",
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    files=files
)
```

### Parameters
- `file`: Audio file (wav, mp3), max 25MB, max 30 seconds
- `file_base64`: Alternative to file upload
- `model`: `glm-asr-2512`
- `stream`: Enable streaming transcription
- `prompt`: Previous transcription for context (max 8000 chars)
- `hotwords`: Domain-specific terms for accuracy (max 100 items)

### Response
```json
{
  "id": "task_id",
  "created": 1234567890,
  "request_id": "request_id",
  "model": "glm-asr-2512",
  "text": "Transcribed audio content..."
}
```

### Streaming Response
```json
{
  "type": "transcript.text.delta",
  "delta": "Partial transcription..."
}
```
Final event: `type: "transcript.text.done"`
