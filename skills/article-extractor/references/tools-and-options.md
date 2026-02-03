# Article Extractor Tools & Options Reference

## Command Options

| Option | Short | Description |
|--------|-------|-------------|
| `--output <file>` | `-o` | Output filename (auto-generated from title if omitted) |
| `--output-dir <dir>` | `-d` | Output directory (default: current directory) |
| `--tool <tool>` | `-t` | Force specific tool: `jina`, `readability`, `trafilatura`, `fallback` |
| `--wayback` | `-w` | Try Wayback Machine if original URL fails |
| `--quiet` | `-q` | Suppress progress messages |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments or usage error |
| 2 | Network error (connection failed, timeout) |
| 3 | Access denied (paywall, login required, blocked) |
| 4 | No content extracted (empty or too short) |
| 5 | Tool not available (forced tool missing) |

## Extraction Tools

Script tries tools in this order until one succeeds:

### 1. Jina Reader API (default)
- Always available (no installation needed)
- Excellent quality for most sites
- Handles JavaScript-rendered content
- Rate limited for heavy usage

### 2. trafilatura
- Better for academic articles and research papers
- Good metadata extraction
- Install: `pip install trafilatura`

### 3. readability-cli
- Mozilla's Readability algorithm
- Good for news articles and blogs
- Install: `npm install -g readability-cli`

### 4. Fallback (built-in)
- Basic HTML parsing with Python
- No external dependencies
- Works offline
- Lower quality extraction

## Wayback Machine Support

Use `--wayback` to automatically try archive.org if:
- Original URL fails or is paywalled
- Site has been taken down
- Content has been removed

The script queries the Wayback Machine API to find the most recent snapshot, then attempts extraction on the archived version.

## Output Format

Files include YAML frontmatter:

```markdown
---
source: https://example.com/article
extracted: 2025-01-15T10:30:00-05:00
---

# Article Title

Clean article content...
```

## Error Handling

- **Tool not available** → tries next tool in fallback chain
- **Extraction fails** → tries all tools before reporting failure
- **File exists** → auto-appends number (article-1.md, article-2.md)
- **No title found** → generates timestamp-based filename
- **Paywall/auth** → suggests --wayback if not already used

## Examples

### Basic extraction
```bash
scripts/extract-article.sh "https://blog.example.com/post"
```

### Extract to specific location
```bash
scripts/extract-article.sh "https://news.example.com/story" -d ~/reading -o story.md
```

### Try Wayback Machine for old/dead links
```bash
scripts/extract-article.sh "https://defunct-site.com/article" --wayback
```

### Force specific tool
```bash
scripts/extract-article.sh "https://example.com/article" --tool trafilatura
```

### Batch extraction
```bash
for url in "${urls[@]}"; do
    scripts/extract-article.sh "$url" -d ~/articles -q
done
```

### Check exit code for scripting
```bash
if scripts/extract-article.sh "$url" -q; then
    echo "Success"
elif [[ $? -eq 3 ]]; then
    echo "Paywall detected, trying wayback..."
    scripts/extract-article.sh "$url" --wayback -q
fi
```

## Installing Local Tools

For offline extraction capability:

```bash
# Run the install script
scripts/install-deps.sh

# Or install manually
pip install trafilatura
npm install -g readability-cli
```