---
name: venice-ai-api
description: Venice.ai API integration for privacy-first AI applications. Use when building applications with Venice.ai API for chat completions, image generation, video generation, text-to-speech, speech-to-text, or embeddings. Triggers on Venice, Venice.ai, uncensored AI, privacy-first AI, or when users need OpenAI-compatible API with uncensored models.
---

# Venice.ai API Skill

Venice.ai provides privacy-first AI infrastructure with uncensored models. The API is OpenAI-compatible, allowing use of the OpenAI SDK with Venice's base URL.

## Quick Reference

**Base URL:** `https://api.venice.ai/api/v1`
**Auth:** `Authorization: Bearer VENICE_API_KEY`
**SDK:** Use OpenAI SDK with custom base URL

## Setup

```python
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("VENICE_API_KEY"),
    base_url="https://api.venice.ai/api/v1"
)
```

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
    apiKey: process.env.VENICE_API_KEY,
    baseURL: 'https://api.venice.ai/api/v1'
});
```

## API Capabilities

### 1. Chat Completions
Text inference with multimodal support (text, images, audio, video).

```python
completion = client.chat.completions.create(
    model="llama-3.3-70b",
    messages=[
        {"role": "system", "content": "You are a helpful assistant"},
        {"role": "user", "content": "Hello!"}
    ]
)
```

**Popular Models:**
- `llama-3.3-70b` - Balanced performance
- `zai-org-glm-4.7` - Complex tasks, deep reasoning
- `mistral-31-24b` - Vision + function calling
- `venice-uncensored` - No content filtering

**Venice Parameters** (via `extra_body` in Python, direct in JS):
- `enable_web_search`: "off" | "on" | "auto"
- `enable_web_scraping`: boolean
- `include_venice_system_prompt`: boolean (default: true)
- `strip_thinking_response`: boolean
- `disable_thinking`: boolean
- `character_slug`: string

See [references/chat-completions.md](references/chat-completions.md) for full parameter reference.

### 2. Image Generation
Generate images from text prompts.

```python
import requests

response = requests.post(
    "https://api.venice.ai/api/v1/image/generate",
    headers={"Authorization": f"Bearer {os.getenv('VENICE_API_KEY')}"},
    json={
        "model": "venice-sd35",
        "prompt": "A sunset over mountains",
        "width": 1024,
        "height": 1024
    }
)
# Response contains base64 images in images array
```

**Image Models:** `qwen-image` (highest quality), `venice-sd35` (default), `hidream` (fast)

See [references/image-api.md](references/image-api.md) for all parameters.

### 3. Video Generation
Async queue-based video generation.

**Workflow:**
1. Get quote: `POST /video/quote`
2. Queue job: `POST /video/queue` → returns `queue_id`
3. Poll status: `GET /video/retrieve?queue_id=...`
4. Cleanup: `POST /video/complete`

```python
# Queue video
response = requests.post(
    "https://api.venice.ai/api/v1/video/queue",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "model": "wan-2.5-preview-image-to-video",
        "prompt": "A timelapse of clouds",
        "duration": "5s",
        "image_url": "data:image/png;base64,..."
    }
)
queue_id = response.json()["queue_id"]
```

### 4. Text-to-Speech
Convert text to audio with 60+ voices.

```python
response = requests.post(
    "https://api.venice.ai/api/v1/audio/speech",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "input": "Hello, welcome to Venice.",
        "model": "tts-kokoro",
        "voice": "af_sky",
        "response_format": "mp3"
    }
)
# Returns audio binary
```

**Voices:** `af_sky`, `af_nova`, `am_liam`, `bf_emma`, `zf_xiaobei`, `jm_kumo`, and 50+ more.

### 5. Speech-to-Text
Transcribe audio files.

```python
with open("audio.mp3", "rb") as f:
    response = requests.post(
        "https://api.venice.ai/api/v1/audio/transcriptions",
        headers={"Authorization": f"Bearer {api_key}"},
        files={"file": f},
        data={"model": "nvidia/parakeet-tdt-0.6b-v3"}
    )
```

**Formats:** WAV, FLAC, MP3, M4A, AAC, MP4

### 6. Embeddings
Generate vector embeddings for RAG and semantic search.

```python
response = requests.post(
    "https://api.venice.ai/api/v1/embeddings",
    headers={"Authorization": f"Bearer {api_key}"},
    json={
        "model": "text-embedding-bge-m3",
        "input": "Privacy-first AI infrastructure",
        "encoding_format": "float"
    }
)
```

### 7. Vision (Multimodal)
Analyze images with vision-capable models.

```python
response = client.chat.completions.create(
    model="mistral-31-24b",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": "What is in this image?"},
            {"type": "image_url", "image_url": {"url": "https://..."}}
        ]
    }]
)
```

### 8. Function Calling
Define tools for the model to call.

```python
tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get current weather",
        "parameters": {
            "type": "object",
            "properties": {"location": {"type": "string"}},
            "required": ["location"]
        }
    }
}]

response = client.chat.completions.create(
    model="zai-org-glm-4.7",
    messages=[{"role": "user", "content": "Weather in SF?"}],
    tools=tools
)
```

### 9. Structured Outputs
Get guaranteed JSON schema responses.

```python
response = client.chat.completions.create(
    model="venice-uncensored",
    messages=[...],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "my_response",
            "strict": True,
            "schema": {
                "type": "object",
                "properties": {"answer": {"type": "string"}},
                "required": ["answer"],
                "additionalProperties": False
            }
        }
    }
)
```

**Requirements:** `strict: true`, `additionalProperties: false`, all fields in `required`.

## Error Handling

| Code | Status | Meaning |
|------|--------|---------|
| `AUTHENTICATION_FAILED` | 401 | Invalid API key |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INFERENCE_FAILED` | 500 | Model error |
| `MODEL_NOT_FOUND` | 404 | Invalid model ID |

## Response Headers

Monitor these headers for production:
- `x-ratelimit-remaining-requests` - Requests left in window
- `x-ratelimit-remaining-tokens` - Tokens left in window
- `x-venice-balance-usd` - USD balance
- `CF-RAY` - Request ID for support

## Reference Files

- [references/chat-completions.md](references/chat-completions.md) - Full chat API parameters
- [references/image-api.md](references/image-api.md) - Image generation details
- [references/models.md](references/models.md) - Available models and capabilities
