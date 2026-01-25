# Chat Completions API Reference

## Endpoint
`POST https://api.z.ai/api/paas/v4/chat/completions`

For GLM Coding Plan: `POST https://api.z.ai/api/coding/paas/v4/chat/completions`

## Text Models

| Model | Description | Max Output |
|-------|-------------|------------|
| `glm-4.7` | Latest flagship, best for agent applications | 128K |
| `glm-4.7-flash` | Faster version of GLM-4.7 | 128K |
| `glm-4.7-flashx` | Optimized flash variant | 128K |
| `glm-4.6` | Previous flagship | 128K |
| `glm-4.5` | High-quality general model | 96K |
| `glm-4.5-flash` | Fast inference | 96K |
| `glm-4-32b-0414-128k` | 32B parameter model | 16K |

## Vision Models

| Model | Description | Max Output |
|-------|-------------|------------|
| `glm-4.6v` | Multimodal vision model | 32K |
| `glm-4.6v-flash` | Fast vision model | 32K |
| `glm-4.5v` | Previous vision model | 16K |
| `autoglm-phone-multilingual` | Mobile intelligent assistant | 4K |

## Request Parameters

### Required
- `model` (string): Model code
- `messages` (array): Conversation messages

### Message Roles
- `system`: System instructions
- `user`: User input (text or multimodal)
- `assistant`: Model responses (can include tool_calls)
- `tool`: Tool execution results (requires tool_call_id)

### Optional Parameters
- `stream` (boolean): Enable streaming, default `false`
- `temperature` (float): Randomness 0.0-1.0, default varies by model
- `top_p` (float): Nucleus sampling 0.01-1.0, default ~0.95
- `max_tokens` (integer): Max output tokens
- `stop` (array): Stop sequences, max 1 item
- `do_sample` (boolean): Enable sampling, default `true`
- `request_id` (string): Custom request identifier
- `user_id` (string): End user ID, 6-128 chars

### Thinking Mode
```json
{
  "thinking": {
    "type": "enabled",
    "clear_thinking": true
  }
}
```
- Supported by GLM-4.5+ models
- `type`: `enabled` or `disabled`
- `clear_thinking`: Whether to clear reasoning from history (default `true`)

### Response Format
```json
{
  "response_format": {
    "type": "json_object"
  }
}
```
Options: `text` (default), `json_object`

## Multimodal Content (Vision Models)

### Image Input
```json
{
  "type": "image_url",
  "image_url": {
    "url": "https://example.com/image.png"
  }
}
```
- Supports URL or Base64
- Max 5MB per image
- Max 6000x6000 pixels
- Formats: jpg, png, jpeg

### Video Input
```json
{
  "type": "video_url",
  "video_url": {
    "url": "https://example.com/video.mp4"
  }
}
```
- Max 200MB
- Formats: mp4, mkv, mov

### File Input (GLM-4.6V, GLM-4.5V)
```json
{
  "type": "file_url",
  "file_url": {
    "url": "https://example.com/document.pdf"
  }
}
```
- Formats: pdf, txt, word, jsonl, xlsx, pptx
- Max 50 files

## Response Structure

```json
{
  "id": "task_id",
  "request_id": "request_id",
  "created": 1234567890,
  "model": "glm-4.7",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Response text",
      "reasoning_content": "Thinking process (if enabled)",
      "tool_calls": [...]
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 50,
    "total_tokens": 150,
    "prompt_tokens_details": {
      "cached_tokens": 20
    }
  }
}
```

### Finish Reasons
- `stop`: Normal completion
- `tool_calls`: Function call requested
- `length`: Token limit reached
- `sensitive`: Content filtered
- `network_error`: Model error

## Python SDK Example

```python
from zai import ZaiClient

client = ZaiClient(api_key="YOUR_API_KEY")

response = client.chat.completions.create(
    model="glm-4.7",
    messages=[
        {"role": "system", "content": "You are helpful."},
        {"role": "user", "content": "Hello!"}
    ],
    temperature=1.0,
    stream=False
)

print(response.choices[0].message.content)
```

## OpenAI SDK Compatibility

```python
from openai import OpenAI

client = OpenAI(
    api_key="YOUR_ZAI_API_KEY",
    base_url="https://api.z.ai/api/paas/v4/"
)

response = client.chat.completions.create(
    model="glm-4.7",
    messages=[{"role": "user", "content": "Hello!"}]
)
```
