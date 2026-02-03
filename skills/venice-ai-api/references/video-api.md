# Video Generation API Reference

Venice video generation uses an asynchronous queue system. Always call `/video/quote` first for pricing before queuing a job.

## Workflow Overview

1. **Quote** → `POST /video/quote` — Get price estimate
2. **Queue** → `POST /video/queue` — Start generation, receive `queueid`
3. **Poll** → `POST /video/retrieve` — Check status / download completed video
4. **Complete** → `POST /video/complete` — Delete from Venice storage (optional)

## Step 1: Get Price Quote

`POST https://api.venice.ai/api/v1/video/quote`

### Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `model` | string | Yes | Video model ID |
| `duration` | string | Yes | "5s" or "10s" |
| `resolution` | string | No | "720p" (default), "1080p" |
| `aspect_ratio` | string | No | "16:9", "9:16", "1:1" |
| `audio` | boolean | No | Include audio generation |

### Response
```json
{
  "quote": 0.25,
  "currency": "USD"
}
```

## Step 2: Queue Generation

`POST https://api.venice.ai/api/v1/video/queue`

### Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `model` | string | Yes | Video model ID |
| `prompt` | string | Yes | Description of the video |
| `negative_prompt` | string | No | What to avoid |
| `duration` | string | Yes | "5s" or "10s" |
| `resolution` | string | No | "720p" (default) |
| `aspect_ratio` | string | No | "16:9", "9:16", "1:1" |
| `audio` | boolean | No | Include audio |
| `image_url` | string | No | Base64 data URI or URL for image-to-video |
| `seed` | integer | No | For reproducibility |

### Text-to-Video Example
```python
queue_resp = requests.post(
    "https://api.venice.ai/api/v1/video/queue",
    headers=headers,
    json={
        "model": "kling-2.5-turbo-pro-text-to-video",
        "prompt": "A serene forest with sunlight filtering through trees",
        "negative_prompt": "low quality, blurry",
        "duration": "10s",
        "resolution": "720p",
        "aspect_ratio": "16:9",
        "audio": True
    }
)
queue_id = queue_resp.json()["queueid"]
```

### Image-to-Video Example
```python
import base64

with open("image.png", "rb") as f:
    img_b64 = base64.b64encode(f.read()).decode("utf-8")

queue_resp = requests.post(
    "https://api.venice.ai/api/v1/video/queue",
    headers=headers,
    json={
        "model": "wan-2.5-preview-image-to-video",
        "prompt": "Animate this scene with gentle motion",
        "image_url": f"data:image/png;base64,{img_b64}",
        "duration": "5s",
        "resolution": "720p"
    }
)
queue_id = queue_resp.json()["queueid"]
```

### Response
```json
{
  "queueid": "abc123-def456",
  "status": "queued"
}
```

## Step 3: Poll Status / Retrieve Video

`POST https://api.venice.ai/api/v1/video/retrieve`

### Request Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `model` | string | Yes | Same model used in queue |
| `queueid` | string | Yes | Queue ID from step 2 |
| `delete_media_on_completion` | boolean | No | Auto-delete after download (default: false) |

### Polling Logic
The response type indicates status:
- **JSON response** → Still processing (check `status` field)
- **`Content-Type: video/mp4`** → Video is ready, response body is the video binary

### Processing Response (JSON)
```json
{
  "status": "processing",
  "executionDuration": 15000,
  "estimatedDuration": 60000
}
```

### Complete Polling Example
```python
import time

MAX_POLLS = 60
POLL_INTERVAL = 10  # seconds

for attempt in range(MAX_POLLS):
    status_resp = requests.post(
        "https://api.venice.ai/api/v1/video/retrieve",
        headers=headers,
        json={
            "model": "kling-2.5-turbo-pro-text-to-video",
            "queueid": queue_id,
            "delete_media_on_completion": False
        }
    )

    content_type = status_resp.headers.get("Content-Type", "")
    if status_resp.status_code == 200 and "video/" in content_type:
        with open("output.mp4", "wb") as f:
            f.write(status_resp.content)
        print("Video saved!")
        break
    elif status_resp.status_code == 200:
        status = status_resp.json()
        print(f"Status: {status.get('status')}, "
              f"Elapsed: {status.get('executionDuration', 0)}ms")
        time.sleep(POLL_INTERVAL)
    else:
        print(f"Error: {status_resp.status_code}")
        status_resp.raise_for_status()
else:
    print("Timed out waiting for video generation")
```

### JavaScript Polling Example
```javascript
async function pollForVideo(headers, model, queueId, maxPolls = 60, interval = 10000) {
    for (let i = 0; i < maxPolls; i++) {
        const resp = await fetch('https://api.venice.ai/api/v1/video/retrieve', {
            method: 'POST',
            headers,
            body: JSON.stringify({
                model,
                queueid: queueId,
                delete_media_on_completion: false
            })
        });

        const contentType = resp.headers.get('Content-Type') || '';
        if (resp.ok && contentType.includes('video/')) {
            return Buffer.from(await resp.arrayBuffer());
        }

        const status = await resp.json();
        console.log(`Status: ${status.status}, Elapsed: ${status.executionDuration}ms`);
        await new Promise(r => setTimeout(r, interval));
    }
    throw new Error('Video generation timed out');
}
```

## Step 4: Cleanup (Optional)

`POST https://api.venice.ai/api/v1/video/complete`

Deletes the generated video from Venice storage. Call after downloading.

### Request
```python
requests.post(
    "https://api.venice.ai/api/v1/video/complete",
    headers=headers,
    json={
        "model": "kling-2.5-turbo-pro-text-to-video",
        "queueid": queue_id
    }
)
```

## Video Models

| Model | Type | Features |
|-------|------|----------|
| `kling-2.5-turbo-pro-text-to-video` | Text-to-Video | Fast, high quality |
| `kling-2.5-turbo-pro-image-to-video` | Image-to-Video | Fast, high quality |
| `wan-2.5-preview-image-to-video` | Image-to-Video | Animation specialist |
| `ltx-2-full` | Text/Image-to-Video | Full quality |
| `veo3-fast` | Text/Image-to-Video | Speed-optimized |
| `sora-2` | Image-to-Video | High-end quality |

**Note:** Model availability changes frequently. Query `GET /models?type=video` for current options.

## Rate Limits

| Endpoint | RPM |
|----------|-----|
| Video Queue | 40 |
| Video Retrieve | 120 |

## Pricing

Video pricing varies by model, duration, resolution, and audio. **Always call `/video/quote` before queuing** to get the current price for your configuration.

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 400 | Invalid parameters | Check model, duration, resolution |
| 401 | Auth failed | Verify API key |
| 402 | Insufficient balance | Add funds |
| 429 | Rate limited | Wait and retry with backoff |
| 500 | Generation failed | Retry with backoff |

### Common Issues
- **Wrong model for retrieve/complete**: You must pass the same `model` used during `queue`.
- **Polling too fast**: Use 10+ second intervals to avoid rate limits on `/video/retrieve`.
- **Timeout**: Video generation can take 1-5 minutes. Set `MAX_POLLS` accordingly.
