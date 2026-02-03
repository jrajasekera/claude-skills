# Claude Skills Collection

A collection of Claude Skills for various tasks and workflows.

## About

This repository contains custom Claude Skills that can be used to extend Claude's capabilities for specific tasks.

## Available Skills

### [article-extractor](./skills/article-extractor/)
Extract clean, readable content from web articles by removing navigation, ads, and other clutter. Supports multiple extraction methods and output formats.

### [codex-review](./skills/codex-review/)
Cross-agent review for design docs and implementation plans using Codex. Gets feedback on plans before implementation.

### [openrouter-api](./skills/openrouter-api/)
OpenRouter API integration for unified access to 400+ LLM models from 70+ providers through a single API.

### [pandoc-converter](./skills/pandoc-converter/)
Convert documents between common formats using Pandoc for consistent output and easy automation.

### [venice-ai-api](./skills/venice-ai-api/)
Venice.ai API integration for privacy-first AI applications including chat, image generation, video, TTS, STT, and embeddings.

### [z-ai-api](./skills/z-ai-api/)
Z.ai/ZhipuAI API integration for building applications with GLM models including chat, vision, image/video generation, and audio transcription.

## Structure

```
claude-skills/
├── skills/                 # All skill folders
│   ├── article-extractor/
│   ├── codex-review/
│   ├── openrouter-api/
│   ├── pandoc-converter/
│   ├── venice-ai-api/
│   └── z-ai-api/
├── packaged_skills/        # Packaged .skill files for import
├── package-skills.sh       # Packaging script
└── README.md
```

Each skill folder contains:
- `SKILL.md` - Skill documentation and usage instructions
- `scripts/` - Executable scripts for the skill (if applicable)

## Usage

Navigate to the individual skill folders to see specific usage instructions and documentation.

Packaged skills are available in `packaged_skills/` and can be imported directly into Claude.

## Author

Created by Jrajasekera

---

*Last updated: February 2, 2026*
