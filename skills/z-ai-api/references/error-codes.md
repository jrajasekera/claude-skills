# Error Handling and Rate Limits

## Error Response Format

```json
{
  "code": 1234,
  "message": "Error description"
}
```

## Common Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| 400 | Bad Request | Check request format and parameters |
| 401 | Unauthorized | Verify API key |
| 403 | Forbidden | Check permissions or account status |
| 404 | Not Found | Verify endpoint URL |
| 429 | Rate Limited | Reduce request frequency |
| 500 | Server Error | Retry with backoff |

## Finish Reasons

| Reason | Description | Action |
|--------|-------------|--------|
| `stop` | Normal completion | None needed |
| `tool_calls` | Function call requested | Execute function and continue |
| `length` | Max tokens reached | Increase max_tokens or truncate input |
| `sensitive` | Content filtered | Modify input content |
| `network_error` | Model inference error | Retry request |

## Rate Limits

Rate limits vary by account tier. Check your limits at the [API Keys Page](https://z.ai/manage-apikey/apikey-list).

### Headers
- `X-RateLimit-Limit`: Maximum requests per period
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset timestamp

## Best Practices

### Retry with Exponential Backoff
```python
import time
import random

def call_with_retry(func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return func()
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            wait = (2 ** attempt) + random.uniform(0, 1)
            time.sleep(wait)
```

### Handle Rate Limits
```python
import time

def rate_limited_call(func):
    try:
        return func()
    except RateLimitError as e:
        retry_after = e.headers.get('Retry-After', 60)
        time.sleep(int(retry_after))
        return func()
```

### Content Filter Handling
```python
response = client.chat.completions.create(...)

if response.choices[0].finish_reason == 'sensitive':
    # Content was filtered
    print("Request contained sensitive content")
    # Modify and retry with different input
```

## Token Usage

### Response Structure
```json
{
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

### Estimate Tokens
Use the tokenizer endpoint to estimate token count before sending:
`POST https://api.z.ai/api/paas/v4/tokenizer`

```json
{
  "model": "glm-4.7",
  "messages": [{"role": "user", "content": "Your text..."}]
}
```

## Media Content Filters

### Image Generation
```json
{
  "content_filter": [{
    "role": "assistant",
    "level": 0
  }]
}
```

Severity levels:
- `0`: Most severe (blocked)
- `1`: Severe
- `2`: Moderate
- `3`: Least severe (allowed)

### Video Generation Status
- `PROCESSING`: Generation in progress
- `SUCCESS`: Completed successfully
- `FAIL`: Generation failed

Poll the async result endpoint to check status.
