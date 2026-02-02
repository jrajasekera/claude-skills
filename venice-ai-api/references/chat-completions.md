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
| `prompt_cache_key` | string | - | Routing hint for cache hits |
| `prompt_cache_retention` | string | - | "default", "extended", or "24h" |

### Reasoning Configuration
| Parameter | Type | Description |
|-----------|------|-------------|
| `reasoning.effort` | string | "low", "medium", "high" |
| `reasoning_effort` | string | OpenAI-compatible (takes precedence) |

**Reasoning effort levels:**
- `low` — Minimal thinking, fast and cheap
- `medium` — Balanced (default)
- `high` — Deep thinking, more tokens, better answers

**Reasoning response:**
```python
response = client.chat.completions.create(
    model="qwen3-235b-a22b-thinking-2507",
    messages=[{"role": "user", "content": "Prove there are infinitely many primes"}],
    reasoning_effort="high"
)
thinking = response.choices[0].message.reasoning_content  # Chain-of-thought
answer = response.choices[0].message.content               # Final answer
```

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

Also supports `response_format: {"type": "json_object"}` for free-form JSON (ensure the system prompt instructs the model on schema).

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

**Function calling execution loop:**
1. Send prompt + tools → model returns `tool_calls` with function name and JSON arguments
2. Parse arguments, execute your function, get result
3. Send follow-up with original messages + assistant tool_call message + `"role": "tool"` result message
4. Model incorporates tool result into final natural language response

### Prompt Caching

**Automatic caching (most models):**
System prompts are automatically cached. Use `prompt_cache_key` for improved routing:
```python
response = client.chat.completions.create(
    model="deepseek-v3.2",
    messages=[...],
    extra_body={
        "prompt_cache_key": "conversation-user-456"
    }
)
```

**Manual cache control (Claude, GPT models):**
Mark content for caching with `cache_control`:
```python
response = client.chat.completions.create(
    model="claude-opus-45",
    messages=[
        {
            "role": "system",
            "content": [
                {
                    "type": "text",
                    "text": "Long system prompt with instructions...",
                    "cache_control": {"type": "ephemeral"}
                }
            ]
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Long document content...",
                    "cache_control": {"type": "ephemeral"}
                },
                {"type": "text", "text": "What are the key points?"}
            ]
        }
    ]
)
```

**Cache hit detection (in usage):**
```json
"usage": {
    "prompt_tokens_details": {
        "cached_tokens": 128,
        "cache_creation_input_tokens": 64
    }
}
```

### Web Search Integration

```python
# Auto-detect when search is needed
response = client.chat.completions.create(
    model="llama-3.3-70b",
    messages=[{"role": "user", "content": "Who won the game last night?"}],
    extra_body={
        "venice_parameters": {
            "enable_web_search": "auto",
            "enable_web_citations": True
        }
    }
)
# Citations appear as ^index^ in text, metadata in response
```

### Web Scraping

```python
# Model reads URLs from the user message
response = client.chat.completions.create(
    model="venice-uncensored",
    messages=[{
        "role": "user",
        "content": "Summarize this page: https://example.com/article"
    }],
    extra_body={
        "venice_parameters": {
            "enable_web_scraping": True
        }
    }
)
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
Append to model name instead of using venice_parameters. Useful for SDKs that don't support extra body parameters:
```
llama-3.3-70b:enable_web_search=auto
venice-uncensored:include_venice_system_prompt=false
venice-uncensored:enable_web_search=on:enable_web_citations=true
```

## Streaming
Set `stream: true` for Server-Sent Events. Include `stream_options: {"include_usage": true}` for token counts.

```python
stream = client.chat.completions.create(
    model="venice-uncensored",
    messages=[{"role": "user", "content": "Write a story about AI"}],
    stream=True
)
for chunk in stream:
    if chunk.choices and chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

## LangChain Integration
```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    base_url="https://api.venice.ai/api/v1",
    api_key="...",
    model="venice-uncensored",
    model_kwargs={
        "venice_parameters": {"enable_web_search": "auto"}
    }
)
```

## Error Responses
| Status | Error Code | Meaning |
|--------|------------|---------|
| 400 | INVALID_REQUEST | Bad parameters |
| 401 | AUTHENTICATION_FAILED | Invalid API key |
| 402 | - | Insufficient balance |
| 403 | - | Unauthorized (check key type) |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| 500 | INFERENCE_FAILED | Model error |
| 503 | - | Model at capacity |
| 504 | - | Timeout (use streaming) |
