# Venice.ai Models Reference

## Text Model Tiers

Venice categorizes text models into tiers (XS, S, M, L) which determine rate limits and pricing.

### Tier XS: Efficiency Layer
| Model | Context | Best For | Input $/1M | Output $/1M |
|-------|---------|----------|------------|-------------|
| `qwen3-4b` | 40K | Chatbots, classification, high-volume tasks | ~$0.15 | ~$0.60 |
| `llama-3.2-3b` | 32K | Real-time classification, summarization | Minimal | Minimal |

**Rate Limits:** 500 RPM, 1,000,000 TPM

### Tier S: Balanced Layer
| Model | Context | Best For | Input $/1M | Output $/1M |
|-------|---------|----------|------------|-------------|
| `venice-uncensored` | 32K | Creative writing, uncensored responses | ~$0.40 | ~$1.60 |
| `mistral-31-24b` | 131K | Vision + function calling, multimodal | ~$0.20 | ~$0.60 |

**Rate Limits:** 75 RPM, 750,000 TPM

### Tier M: Intelligence Layer
| Model | Context | Best For | Input $/1M | Output $/1M |
|-------|---------|----------|------------|-------------|
| `llama-3.3-70b` | 128K | RAG, content creation, analysis | ~$0.28 | ~$1.12 |
| `google-gemma-3-27b-it` | — | General purpose | — | — |
| `qwen3-next-80b` | — | Complex instruction following | — | — |

**Rate Limits:** 50 RPM, 750,000 TPM

### Tier L: Frontier Layer
| Model | Context | Best For | Input $/1M | Output $/1M |
|-------|---------|----------|------------|-------------|
| `zai-org-glm-4.7` | 128K | Deep reasoning, agent planning | ~$0.40 | ~$3.00 |
| `deepseek-ai-DeepSeek-R1` | 64K | Math, coding, chain-of-thought | ~$0.25 | ~$1.87 |
| `qwen3-235b` | — | Massive MoE reasoning | — | — |

**Rate Limits:** 20 RPM, 500,000 TPM

### Code-Specialized Models
| Model | Capabilities |
|-------|--------------|
| `qwen3-coder-480b` | Code generation, trained on code repositories |
| `grok-code-fast` | Fast code generation |

### Vision Models
| Model | Capabilities |
|-------|--------------|
| `mistral-31-24b` | Vision + function calling |
| `qwen-2.5-vl` | Vision, multimodal |
| `llama-3.2-3b` | Vision (lightweight) |

### Reasoning Models
| Model | Features |
|-------|----------|
| `deepseek-ai-DeepSeek-R1` | Chain-of-thought, `<think>` blocks |
| `qwen3-235b-a22b-thinking-2507` | Deep reasoning with `reasoning_content` |
| Models with `supportsReasoning` flag | Extended thinking |

**Reasoning Controls:**
- `reasoning_effort`: "low" | "medium" | "high"
- `strip_thinking_response: true` → Perform thinking but remove `<think>` from response
- `disable_thinking: true` → Skip thinking entirely (saves tokens, may degrade quality)

## Image Models

### Generation
| Model | Resolution | Speed | Quality | Pricing |
|-------|------------|-------|---------|---------|
| `qwen-image` | 1K-4K | Medium | Highest | Variable |
| `venice-sd35` | Standard | Medium | High | ~$0.01 |
| `hidream` | Standard | Fast | Good | ~$0.01 |
| `flux-2-pro` | Standard | Medium | Professional | ~$0.04 |
| `flux-2-max` | Standard | Medium | High | ~$0.02 |
| `nano-banana-pro` | 1K-4K | Medium | High (photorealism) | $0.18-$0.35 |
| `z-image-turbo` | Standard | Fast | Good | Variable |

### Editing & Upscaling
| Model/Endpoint | Type | Pricing |
|----------------|------|---------|
| `qwen-image` (via /image/edit) | Inpainting/editing | ~$0.04/edit |
| /image/upscale (2x) | Resolution enhancement | $0.02 |
| /image/upscale (4x) | Resolution enhancement | $0.08 |

## Video Models

| Model | Type | Duration |
|-------|------|----------|
| `kling-2.5-turbo-pro-text-to-video` | Text-to-video | 5s, 10s |
| `kling-2.5-turbo-pro-image-to-video` | Image-to-video | 5s, 10s |
| `wan-2.5-preview-image-to-video` | Image-to-video | 5s, 10s |
| `ltx-2-full` | Text/Image-to-video | 5s, 10s |
| `veo3-fast` | Text/Image-to-video | Speed-optimized |
| `sora-2` | Image-to-video | High-end |

**Pricing:** Variable — always call `/video/quote` first.

## Audio Models

### Text-to-Speech
| Model | Voices | Languages | Pricing |
|-------|--------|-----------|---------|
| `tts-kokoro` | 60+ | Multilingual | $3.50/1M chars |

### Speech-to-Text
| Model | Formats | Pricing |
|-------|---------|---------|
| `nvidia/parakeet-tdt-0.6b-v3` | WAV, FLAC, MP3, M4A, AAC, MP4 | $0.0001/sec |

## Embedding Models

| Model | Dimensions | Max Tokens | Pricing |
|-------|------------|------------|---------|
| `text-embedding-bge-m3` | Variable | 8192 | $0.15 input / $0.60 output per 1M tokens |

## Model Capabilities

Query `GET /api/v1/models` for capabilities:

```json
{
  "model_spec": {
    "availableContextTokens": 32768,
    "capabilities": {
      "supportsFunctionCalling": true,
      "supportsResponseSchema": true,
      "supportsWebSearch": true,
      "supportsVision": false,
      "supportsReasoning": false
    },
    "pricing": {
      "input": 0.40,
      "output": 1.60
    }
  }
}
```

### Capability Flags
- `supportsFunctionCalling` — Tool/function definitions
- `supportsResponseSchema` — Structured JSON outputs
- `supportsWebSearch` — Web search integration
- `supportsVision` — Image analysis
- `supportsReasoning` — Extended thinking

## Model Traits
Request by trait instead of specific model for automatic routing:
```python
# Get available traits
traits = requests.get("https://api.venice.ai/api/v1/models/traits", params={"type": "text"}).json()
# e.g. {"default": "zai-org-glm-4.7", "fastest": "qwen3-4b", "uncensored": "venice-uncensored"}

# Use trait as model ID
response = client.chat.completions.create(model="fastest", messages=[...])
```

## Compatibility Mappings
Venice supports OpenAI model ID mappings:
- Query `GET /api/v1/models/compatibility_mapping` for mappings
- Use OpenAI model names, Venice routes to equivalent

## Deprecation Policy
Check response headers:
- `x-venice-model-deprecation-warning` — Warning message
- `x-venice-model-deprecation-date` — Sunset date

## Rate Limits Summary

**Text Models:**
| Tier | RPM | TPM |
|------|-----|-----|
| XS | 500 | 1,000,000 |
| S | 75 | 750,000 |
| M | 50 | 750,000 |
| L | 20 | 500,000 |

**Other Endpoints:**
| Endpoint | RPM |
|----------|-----|
| Image Generation | 20 |
| Audio Synthesis | 60 |
| Audio Transcription | 60 |
| Embeddings | 500 |
| Video Queue | 40 |
| Video Retrieve | 120 |

## TTS Voices

### American English
**Female:** af_alloy, af_aoede, af_bella, af_heart, af_jadzia, af_jessica, af_kore, af_nicole, af_nova, af_river, af_sarah, af_sky

**Male:** am_adam, am_echo, am_eric, am_fenrir, am_liam, am_michael, am_onyx, am_puck, am_santa

### British English
**Female:** bf_alice, bf_emma, bf_lily
**Male:** bm_daniel, bm_fable, bm_george, bm_lewis

### Chinese
**Female:** zf_xiaobei, zf_xiaoni, zf_xiaoxiao, zf_xiaoyi
**Male:** zm_yunjian, zm_yunxi, zm_yunxia, zm_yunyang

### Other Languages
- French: ff_siwis
- Hindi: hf_alpha, hf_beta, hm_omega, hm_psi
- Italian: if_sara, im_nicola
- Japanese: jf_alpha, jf_gongitsune, jf_nezumi, jf_tebukuro, jm_kumo
- Portuguese: pf_dora, pm_alex, pm_santa
- Spanish: ef_dora, em_alex, em_santa

## Prompt Caching Pricing

| Model | Min Tokens | Cache Write Premium | Cache Read Discount | Lifetime |
|-------|------------|---------------------|---------------------|----------|
| Claude Opus 4.5 | 4,000 | +25% | -90% | 5 min |
| GPT-5.2 | 1,024 | None | -90% | 5-10 min |
| Gemini 3 | 1,024 | None | -75-90% | 1 hour |
| DeepSeek, Kimi | 1,024 | None | -50% | 5 min |
