# Chat Completions API Reference

## Endpoint
`POST https://api.venice.ai/api/v1/chat/completions`

## Request Parameters

### Required
| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | string | Model ID (e.g., `llama-3.3-70b`, `venice-uncensored`) |
| `messages` | array | Conversation messages array |

### Message Roles
- `system` - Instructions for model behavior
- `user` - User input (text, images, audio, video)
- `assistant` - Previous model responses
- `tool` - Function calling results
- `developer` - High-level instructions for reasoning models

### Optional Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `temperature` | number | 1 | Sampling temperature (0-2) |
| `max_tokens` | integer | - | Max tokens in response |
| `max_completion_tokens` | integer | - | Max tokens including reasoning |
| `top_p` | number | 0.95 | Nucleus sampling (0-1) |
| `top_k` | integer | - | Top-k filtering |
| `min_p` | number | - | Minimum probability threshold (0-1) |
| `frequency_penalty` | number | 0 | Repeat penalty (-2 to 2) |
| `presence_penalty` | number | 0 | Topic diversity (-2 to 2) |
| `repetition_penalty` | number | - | Repetition penalty (>1 discourages) |
| `stream` | boolean | false | Enable streaming |
| `stop` | string/array | - | Stop sequences (max 4) |
| `seed` | integer | - | Random seed for reproducibility |
| `n` | integer | 1 | Number of completions |
| `logprobs` | boolean | - | Include log probabilities |
| `top_logprobs` | integer | - | Top tokens to return per position |

### Venice Parameters
Use via `venice_parameters` object (Python: `extra_body={"venice_parameters": {...}}`):

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `include_venice_system_prompt` | boolean | true | Include Venice's default prompts |
| `enable_web_search` | string | "off" | "off", "on", or "auto" |
| `enable_web_scraping` | boolean | false | Scrape URLs in user message |
| `enable_web_citations` | boolean | false | Request `^index^` citation format |
| `include_search_results_in_stream` | boolean | false | Search results in first chunk |
| `return_search_results_as_documents` | boolean | false | LangChain-compatible tool call |
| `character_slug` | string | - | Public character ID |
| `strip_thinking_response` | boolean | false | Remove `<think>` blocks |
| `disable_thinking` | boolean | false | Disable thinking entirely |

### Reasoning Configuration
| Parameter | Type | Description |
|-----------|------|-------------|
| `reasoning.effort` | string | "low", "medium", "high" |
| `reasoning_effort` | string | OpenAI-compatible (takes precedence) |

### Structured Outputs
```python
response_format={
    "type": "json_schema",
    "json_schema": {
        "name": "schema_name",
        "strict": True,  # Required
        "schema": {
            "type": "object",
            "properties": {...},
            "required": [...],
            "additionalProperties": False  # Required
        }
    }
}
```

### Function Calling
```python
tools=[{
    "type": "function",
    "function": {
        "name": "function_name",
        "description": "What it does",
        "parameters": {
            "type": "object",
            "properties": {...},
            "required": [...]
        },
        "strict": False  # Optional: enforce exact schema
    }
}]
tool_choice="auto"  # or {"type": "function", "function": {"name": "..."}}
parallel_tool_calls=True  # Enable parallel calls
```

### Prompt Caching
| Parameter | Type | Description |
|-----------|------|-------------|
| `prompt_cache_key` | string | Routing hint for cache hits |
| `prompt_cache_retention` | string | "default", "extended", or "24h" |

Mark content for caching:
```python
{"type": "text", "text": "...", "cache_control": {"type": "ephemeral"}}
```

## Multimodal Content

### Image Input
```python
{"type": "image_url", "image_url": {"url": "https://..." or "data:image/png;base64,..."}}
```

### Audio Input
```python
{"type": "input_audio", "input_audio": {"data": "<base64>", "format": "wav"}}
```
Formats: wav, mp3, aiff, aac, ogg, flac, m4a, pcm16, pcm24

### Video Input
```python
{"type": "video_url", "video_url": {"url": "https://..." or "data:video/mp4;base64,..."}}
```
Formats: mp4, mpeg, mov, webm

## Response Structure
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1677858240,
  "model": "llama-3.3-70b",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Response text",
      "tool_calls": [...],
      "reasoning_content": "..."
    },
    "finish_reason": "stop",
    "logprobs": null
  }],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30,
    "prompt_tokens_details": {
      "cached_tokens": 128,
      "cache_creation_input_tokens": 64
    }
  },
  "venice_parameters": {
    "enable_web_search": "auto",
    "web_search_citations": [...]
  }
}
```

## Model Feature Suffixes
Append to model name instead of using venice_parameters:
```
llama-3.3-70b:enable_web_search=auto
venice-uncensored:include_venice_system_prompt=false
```

## Streaming
Set `stream: true` for Server-Sent Events. Include `stream_options: {"include_usage": true}` for token counts.

## Error Responses
| Status | Error Code | Meaning |
|--------|------------|---------|
| 400 | INVALID_REQUEST | Bad parameters |
| 401 | AUTHENTICATION_FAILED | Invalid API key |
| 402 | - | Insufficient balance |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| 500 | INFERENCE_FAILED | Model error |
| 503 | - | Model at capacity |
| 504 | - | Timeout (use streaming) |
