# Tools and Function Calling

## Overview

Z.ai supports three tool types:
1. **Function** - Custom function definitions
2. **Web Search** - Built-in web search
3. **Retrieval** - Knowledge base queries

## Function Calling

### Tool Definition
```json
{
  "type": "function",
  "function": {
    "name": "get_weather",
    "description": "Get weather for a city",
    "parameters": {
      "type": "object",
      "properties": {
        "city": {
          "type": "string",
          "description": "City name"
        }
      },
      "required": ["city"]
    }
  }
}
```

### Function Naming Rules
- Characters: a-z, A-Z, 0-9, underscore, dash
- Max length: 64 characters
- Pattern: `^[a-zA-Z0-9_-]+$`

### Request with Tools
```python
response = client.chat.completions.create(
    model="glm-4.7",
    messages=[{"role": "user", "content": "Weather in Beijing?"}],
    tools=[{
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather info",
            "parameters": {
                "type": "object",
                "properties": {
                    "city": {"type": "string"}
                },
                "required": ["city"]
            }
        }
    }],
    tool_choice="auto"
)
```

### Handling Tool Calls
```python
message = response.choices[0].message

if message.tool_calls:
    messages = [{"role": "user", "content": "Weather in Beijing?"}]
    messages.append(message.model_dump())

    for tool_call in message.tool_calls:
        # Execute function
        result = execute_function(
            tool_call.function.name,
            json.loads(tool_call.function.arguments)
        )

        # Add tool result
        messages.append({
            "role": "tool",
            "content": json.dumps(result),
            "tool_call_id": tool_call.id
        })

    # Get final response
    final = client.chat.completions.create(
        model="glm-4.7",
        messages=messages,
        tools=tools
    )
```

### Streaming Tool Calls (GLM-4.6 only)
```python
response = client.chat.completions.create(
    model="glm-4.6",
    messages=messages,
    tools=tools,
    tool_stream=True,  # Enable streaming for tool calls
    stream=True
)
```

## Web Search Tool

### Configuration
```json
{
  "type": "web_search",
  "web_search": {
    "enable": true,
    "search_engine": "search_pro_jina",
    "count": 10,
    "search_domain_filter": "example.com",
    "search_recency_filter": "oneWeek",
    "content_size": "medium",
    "result_sequence": "after",
    "search_result": true,
    "require_search": false
  }
}
```

### Parameters
| Parameter | Description | Values |
|-----------|-------------|--------|
| `enable` | Enable search | `true`/`false` |
| `search_engine` | Engine type | `search_pro_jina` |
| `count` | Results count | 1-50, default 10 |
| `search_domain_filter` | Domain whitelist | Domain string |
| `search_recency_filter` | Time filter | `oneDay`, `oneWeek`, `oneMonth`, `oneYear`, `noLimit` |
| `content_size` | Summary length | `medium` (400-600 chars), `high` (2500 chars) |
| `result_sequence` | Result position | `before`, `after` |
| `search_result` | Return results | `true`/`false` |
| `require_search` | Force search | `true`/`false` |
| `search_query` | Force query | Query string |
| `search_prompt` | Custom prompt | Prompt string |

### Web Search Response
```json
{
  "web_search": [
    {
      "title": "Page Title",
      "content": "Summary...",
      "link": "https://example.com",
      "media": "Site Name",
      "icon": "https://example.com/favicon.ico",
      "refer": "1",
      "publish_date": "2025-01-20"
    }
  ]
}
```

## Retrieval Tool (Knowledge Base)

### Configuration
```json
{
  "type": "retrieval",
  "retrieval": {
    "knowledge_id": "your_knowledge_base_id",
    "prompt_template": "Search for {{question}} in {{knowledge}}..."
  }
}
```

### Parameters
- `knowledge_id` (required): Knowledge base ID from platform
- `prompt_template`: Custom prompt with `{{knowledge}}` and `{{question}}` placeholders

## Standalone Web Search API

### Endpoint
`POST https://api.z.ai/api/paas/v4/web_search`

### Request
```json
{
  "search_engine": "search-prime",
  "search_query": "artificial intelligence news",
  "count": 10,
  "search_domain_filter": "techcrunch.com",
  "search_recency_filter": "oneWeek"
}
```

### Response
```json
{
  "id": "task_id",
  "created": 1234567890,
  "search_result": [
    {
      "title": "AI News",
      "content": "Summary...",
      "link": "https://example.com/article",
      "media": "TechCrunch",
      "icon": "favicon_url",
      "refer": "1",
      "publish_date": "2025-01-20"
    }
  ]
}
```

## Best Practices

1. **Clear Descriptions**: Provide detailed function descriptions
2. **Parameter Validation**: Always validate arguments before execution
3. **Error Handling**: Return structured error responses
4. **Security**: Implement permission controls for sensitive operations
5. **Logging**: Record all function calls for debugging

### Robust Function Pattern
```python
def safe_function(param: str) -> dict:
    try:
        if not param:
            return {"success": False, "error": "Missing parameter"}

        result = process(param)
        return {"success": True, "data": result}

    except Exception as e:
        return {"success": False, "error": str(e)}
```
