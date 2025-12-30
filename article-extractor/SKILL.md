---
name: article-extractor
description: Extract clean article content from URLs and save as markdown. Triggers when user provides a webpage URL and wants to download it, extract content, get a clean version without ads, or capture an article for offline reading. Handles blog posts, news articles, tutorials, documentation pages, and similar web content. This skill handles the entire workflow - do NOT use web_fetch or other tools first, just call the extraction script directly with the URL.
---

# Article Extractor

Extract clean article content from URLs, automatically removing ads, navigation, and clutter. Multi-tool fallback ensures reliability.

## Workflow

When user provides a URL to download/extract:
1. Call the extraction script directly with the URL (do NOT fetch the URL first with web_fetch)
2. Script handles fetching, extraction, and saving automatically
3. Returns clean markdown file with frontmatter

## Usage

```bash
# Basic extraction
scripts/extract-article.sh "https://example.com/article"

# Specify output file or directory
scripts/extract-article.sh "https://example.com/article" --output my-article.md
scripts/extract-article.sh "https://example.com/article" --output-dir ~/Documents/articles
```

Make script executable if needed: `chmod +x scripts/extract-article.sh`

## Options

- `--output <file>` / `-o`: Output filename (auto-generated from title if omitted)
- `--output-dir <dir>` / `-d`: Output directory (default: current directory)
- `--tool <tool>` / `-t`: Force specific tool: `jina`, `readability`, `trafilatura`, `fallback`
- `--quiet` / `-q`: Suppress progress messages

## Tool Selection & Fallback

Script tries tools in this order until one succeeds:
1. **Jina Reader API** (default, always available)
2. **trafilatura** (if installed - better for academic articles)
3. **readability-cli** (if installed)

Automatic fallback ensures reliability. Install local tools with `scripts/install-deps.sh` for offline usage.

## Output Format

Files include YAML frontmatter with metadata and clean markdown content:

```markdown
---
source: https://example.com/article
extracted: 2025-01-15T10:30:00-05:00
---

# Article Title

Clean article content...
```

## Error Handling

Script automatically handles common issues:
- Tool not available → tries next tool in fallback chain
- Extraction fails → tries all tools before reporting failure
- File exists → auto-appends number (article-1.md, article-2.md)
- No title found → generates timestamp-based filename

Common failures (after all tools exhausted): paywall/login required, complex JavaScript rendering, site blocks automation.

## Local Tools (Optional)

For offline extraction, install local tools: `scripts/install-deps.sh`

Or manually: `pip install trafilatura` and `npm install -g readability-cli`

## Examples

Extract to current directory:
```bash
scripts/extract-article.sh "https://blog.example.com/post"
```

Extract to specific location:
```bash
scripts/extract-article.sh "https://news.example.com/story" -d ~/reading -o story.md
```

Batch extraction:
```bash
for url in "${urls[@]}"; do
    scripts/extract-article.sh "$url" -d ~/articles -q
done
```

Force specific tool:
```bash
scripts/extract-article.sh "https://example.com/article" --tool trafilatura
```