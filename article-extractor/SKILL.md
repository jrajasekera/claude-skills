---
name: article-extractor
description: Extract clean article content from URLs and save as markdown or text. Triggers when user provides an article/blog/news URL and wants to download it, extract content, save it as text, get a clean version without ads, or capture an article for offline reading. Handles blog posts, news articles, tutorials, documentation pages, and similar web content.
---

# Article Extractor

Extract clean, readable content from web articles by removing navigation, ads, newsletter signups, and other clutter. The tool automatically tries multiple extraction methods to ensure success.

## Quick Usage

```bash
# Basic extraction (outputs markdown)
scripts/extract-article.sh "https://example.com/article"

# Output as plain text
scripts/extract-article.sh "https://example.com/article" --format txt

# Specify output file
scripts/extract-article.sh "https://example.com/article" --output my-article.md

# Specify output directory
scripts/extract-article.sh "https://example.com/article" --output-dir ~/Documents/articles
```

## Script Location

The extraction script is located at:
```
scripts/extract-article.sh
```

Run it directly or copy to a working directory first.

**Note:** If you get a "Permission denied" error, make the script executable:
```bash
chmod +x scripts/extract-article.sh
```

## Command Options

| Option | Short | Description |
|--------|-------|-------------|
| `--output <file>` | `-o` | Output filename (auto-generated from title if not specified) |
| `--format <fmt>` | `-f` | Output format: `txt` or `md` (default: md) |
| `--tool <tool>` | `-t` | Force specific tool: `jina`, `readability`, `trafilatura`, `fallback` |
| `--output-dir <dir>` | `-d` | Output directory (default: current directory) |
| `--quiet` | `-q` | Suppress progress messages |
| `--help` | `-h` | Show help message |

## Automatic Tool Selection & Fallback

The script intelligently selects and falls back between extraction tools:

**Primary tool priority:**
1. **readability-cli** (if installed) - Mozilla's Readability algorithm, excellent quality
2. **trafilatura** (if installed) - Python-based, great for blogs and news
3. **Jina Reader API** (always available) - No install needed, works via API

**Automatic fallback:** If the primary tool fails, the script automatically tries all other available tools until one succeeds. This ensures maximum reliability without manual intervention.

## Output Format

Extracted files include:
- YAML frontmatter with source URL and extraction date
- Article title as heading
- Clean article body
- Preserved section headings

Example output:
```markdown
---
source: https://example.com/great-article
extracted: 2025-01-15T10:30:00-05:00
---

# Article Title

Article content here...
```

## What Gets Removed

- Navigation menus and headers
- Ads and promotional content
- Newsletter signup forms
- Related articles sidebars
- Comment sections
- Social media buttons
- Cookie notices

## Error Handling

The script handles issues gracefully with automatic recovery:

| Issue | Behavior |
|-------|----------|
| Tool not installed | Automatically uses next available tool |
| Extraction fails | Tries all available tools before giving up |
| TLS/certificate errors | Detects and tries alternative tools |
| Paywall/login required | Reports error after trying all tools |
| Invalid URL | Validates format before attempting extraction |
| File exists | Auto-appends number to filename (article-1.md, article-2.md) |
| No title found | Generates timestamp-based filename |
| Empty/short content | Detected as error, triggers fallback |

## Installing Dependencies (Optional)

For faster, offline extraction, install local tools:

```bash
# Run the installer
scripts/install-deps.sh

# Or install manually:
npm install -g readability-cli    # Recommended
pip install trafilatura           # Alternative
```

Without local tools, the script uses Jina's Reader API which works but requires internet.

## Example Workflows

### Extract single article
```bash
scripts/extract-article.sh "https://blog.example.com/post"
# Creates: Post-Title.md in current directory
```

### Extract to specific location
```bash
scripts/extract-article.sh "https://news.example.com/story" -d ~/reading -o story.md
# Creates: ~/reading/story.md
```

### Batch extraction
```bash
urls=(
    "https://example.com/article1"
    "https://example.com/article2"
    "https://example.com/article3"
)

for url in "${urls[@]}"; do
    scripts/extract-article.sh "$url" -d ~/articles -q
done
```

### Force specific tool
```bash
# Use Jina API even if local tools installed
scripts/extract-article.sh "https://example.com/article" --tool jina
```

## Tips

- **Markdown output** (default) preserves headings and formatting
- **Plain text output** (`--format txt`) strips all formatting
- **Jina API** is always available as fallback - no install needed
- **readability-cli** gives best results for most sites
- **trafilatura** is better for academic articles and non-English content

## Troubleshooting

**"Failed to extract article" (after trying all tools)**
- Site requires authentication/login
- Content is behind a paywall
- Site uses complex JavaScript rendering
- Site actively blocks automated extraction
- Try visiting the URL in a browser first to verify it's accessible

**Garbled or incomplete output**
- Some sites have unusual HTML structure
- Try forcing a different tool: `--tool readability` or `--tool trafilatura`
- Install local tools for better results: `scripts/install-deps.sh`

**File saved but contains error message**
- This was a bug in earlier versions - should not happen with current version
- If you see this, the script's error detection needs improvement
- Report the URL so error patterns can be added

**Empty filename (file named just ".md")**
- Article has no detectable title
- Script will auto-generate a timestamp-based name
- You can specify filename manually with `--output my-file.md`
