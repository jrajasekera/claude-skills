# Venice.ai Models Reference

## Text Models

### General Purpose
| Model | Context | Capabilities | Best For |
|-------|---------|--------------|----------|
| `llama-3.3-70b` | 32K | Chat, functions, web search | Balanced performance |
| `venice-uncensored` | 32K | Chat, functions, schema, web | Uncensored responses |
| `zai-org-glm-4.7` | - | Chat, functions, reasoning | Complex tasks |

### Vision Models
| Model | Capabilities |
|-------|--------------|
| `mistral-31-24b` | Vision + function calling |
| `qwen-2.5-vl` | Vision, multimodal |

### Reasoning Models
| Model | Features |
|-------|----------|
| Models with `reasoning` capability | Extended thinking, `<think>` blocks |

Use `strip_thinking_response: true` or `disable_thinking: true` to control output.

## Image Models

### Generation
| Model | Resolution | Speed | Quality |
|-------|------------|-------|---------|
| `qwen-image` | 1024x1024 | Medium | Highest |
| `venice-sd35` | 1024x1024 | Medium | High |
| `hidream` | 1024x1024 | Fast | Good |
| `nano-banana-pro` | Up to 4K | Medium | High |
| `z-image-turbo` | 1024x1024 | Fast | Good |

### Editing & Upscaling
| Model | Type |
|-------|------|
| `qwen-image` | Inpainting/editing |
| Various | Upscaling |

## Video Models

| Model | Type | Duration |
|-------|------|----------|
| `wan-2.5-preview-image-to-video` | Image-to-video | 5s, 10s |

## Audio Models

### Text-to-Speech
| Model | Voices | Languages |
|-------|--------|-----------|
| `tts-kokoro` | 60+ | Multilingual |

### Speech-to-Text
| Model | Formats |
|-------|---------|
| `nvidia/parakeet-tdt-0.6b-v3` | WAV, FLAC, MP3, M4A, AAC, MP4 |

## Embedding Models

| Model | Dimensions | Max Tokens |
|-------|------------|------------|
| `text-embedding-bge-m3` | Variable | 8192 |

## Model Capabilities

Query `/api/v1/models` for capabilities:

```json
{
  "model_spec": {
    "availableContextTokens": 32768,
    "capabilities": {
      "supportsFunctionCalling": true,
      "supportsResponseSchema": true,
      "supportsWebSearch": true
    }
  }
}
```

### Capability Flags
- `supportsFunctionCalling` - Tool/function definitions
- `supportsResponseSchema` - Structured JSON outputs
- `supportsWebSearch` - Web search integration
- `supportsVision` - Image analysis
- `supportsReasoning` - Extended thinking

## Model Traits
Request by trait instead of specific model:
- Query `/api/v1/models/traits` for available traits
- Use trait as model ID for automatic routing

## Compatibility Mappings
Venice supports OpenAI model ID mappings:
- Query `/api/v1/models/compatibility_mapping` for mappings
- Use OpenAI model names, Venice routes to equivalent

## Deprecation Policy
Check response headers:
- `x-venice-model-deprecation-warning` - Warning message
- `x-venice-model-deprecation-date` - Sunset date

See `/overview/deprecations` for migration guidance.

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
