#!/usr/bin/env bash
#
# extract-article.sh - Extract clean article content from URLs
#
# Usage: extract-article.sh <URL> [OPTIONS]
#
# Options:
#   -o, --output <file>    Output filename (auto-generated from title if not specified)
#   -t, --tool <tool>      Force specific tool: jina, readability, trafilatura, fallback
#   -d, --output-dir <dir> Output directory (default: current directory)
#   -w, --wayback          Try Wayback Machine if original URL fails
#   -q, --quiet            Suppress progress messages
#   -h, --help             Show this help message
#
# Exit Codes:
#   0 - Success
#   1 - Invalid arguments or usage error
#   2 - Network error (connection failed, timeout)
#   3 - Access denied (paywall, login required, blocked)
#   4 - No content extracted (empty or too short)
#   5 - Tool not available (forced tool missing)
#

set -euo pipefail

# Exit codes
EXIT_SUCCESS=0
EXIT_USAGE=1
EXIT_NETWORK=2
EXIT_ACCESS_DENIED=3
EXIT_NO_CONTENT=4
EXIT_TOOL_MISSING=5

# Defaults
OUTPUT_FILE=""
FORCE_TOOL=""
OUTPUT_DIR="."
QUIET=false
TRY_WAYBACK=false
TRAFILATURA_RUNNER=""

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    RED=''
    NC=''
fi

log() {
    if [[ "$QUIET" == false ]]; then
        echo -e "$1"
    fi
}

log_success() { log "${GREEN}[OK]${NC} $1"; }
log_warn() { log "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

show_help() {
    head -20 "$0" | tail -n +3 | sed 's/^# //' | sed 's/^#//'
    exit 0
}

# Parse arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -t|--tool)
            FORCE_TOOL="$2"
            shift 2
            ;;
        -d|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -w|--wayback)
            TRY_WAYBACK=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*|--*)
            log_error "Unknown option $1"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

# Validate forced tool value
if [[ -n "$FORCE_TOOL" ]]; then
    case "$FORCE_TOOL" in
        jina|readability|trafilatura|fallback)
            ;;
        *)
            log_error "Invalid tool '$FORCE_TOOL'. Use: jina, trafilatura, readability, or fallback."
            exit 1
            ;;
    esac
fi

# Validate URL argument
if [[ $# -lt 1 ]]; then
    log_error "Missing URL argument"
    echo "Usage: extract-article.sh <URL> [OPTIONS]"
    exit $EXIT_USAGE
fi

ARTICLE_URL="$1"

# URL validation
if [[ ! "$ARTICLE_URL" =~ ^https?:// ]]; then
    log_error "Invalid URL (must start with http:// or https://)"
    exit $EXIT_USAGE
fi

# Create output directory if needed
mkdir -p "$OUTPUT_DIR"

# Detect available tools
detect_tool() {
    if [[ -n "$FORCE_TOOL" ]]; then
        echo "$FORCE_TOOL"
        return
    fi

    # Priority: Jina API (excellent quality, always available) -> trafilatura -> readability-cli
    echo "jina"
}

set_trafilatura_runner() {
    if command -v trafilatura &> /dev/null; then
        TRAFILATURA_RUNNER="trafilatura"
    elif python3 -c "import trafilatura" &> /dev/null; then
        TRAFILATURA_RUNNER="python3 -m trafilatura"
    else
        TRAFILATURA_RUNNER=""
    fi
}

clean_readability_markdown() {
    local file="$1"
    local temp_file=$(mktemp)

    sed -E \
        -e 's/<div>//g' \
        -e 's:</div>::g' \
        -e 's/^::+.*$//g' \
        -e 's/\[(.+)\]\{.+\}/\1/g' \
        -e 's/^>(.+) --- (.+)$/\1\n>\n> <cite>\2<\/cite>/g' \
        "$file" > "$temp_file"

    cat -s "$temp_file" > "$file"
    rm -f "$temp_file"
}

# Sanitize title for filename
sanitize_filename() {
    local title="$1"
    echo "$title" | \
        tr '[:upper:]' '[:lower:]' | \
        tr ' ' '-' | \
        tr '/' '-' | \
        tr ':' '-' | \
        tr -d '?"'"'"'<>*|\\' | \
        sed 's/\.\.*/\./g' | \
        sed 's/--*/-/g' | \
        sed 's/^-\+\|-\+$//g' | \
        sed 's/^\.\+\|\.\+$//g' | \
        cut -c 1-80
}

# Generate unique filename if exists
unique_filename() {
    local filepath="$1"
    local dir=$(dirname "$filepath")
    local base=$(basename "$filepath")
    local name="${base%.*}"
    local ext="${base##*.}"

    if [[ ! -f "$filepath" ]]; then
        echo "$filepath"
        return
    fi

    local counter=1
    while [[ -f "${dir}/${name}-${counter}.${ext}" ]]; do
        ((counter++))
    done

    echo "${dir}/${name}-${counter}.${ext}"
}

# Extract using Jina Reader API (no install needed)
extract_jina() {
    local url="$1"
    local output="$2"

    log "Using Jina Reader API..."

    # Jina returns markdown by default
    if ! curl -sS "https://r.jina.ai/$url" > "$output" 2>/dev/null; then
        return 1
    fi

    # Check if we got valid content (not an error message)
    if [[ ! -s "$output" ]]; then
        return 1
    fi

    # Check for common error patterns (case-insensitive)
    if grep -qi "error\|failed\|denied\|upstream connect" "$output" 2>/dev/null; then
        return 1
    fi

    # Check if content is suspiciously short (less than 100 chars suggests error)
    local content_size=$(wc -c < "$output" | tr -d ' ')
    if [[ "$content_size" -lt 100 ]]; then
        return 1
    fi

    return 0
}

# Extract using readability-cli
extract_readability() {
    local url="$1"
    local output="$2"
    local temp_html=$(mktemp)

    log "Using readability-cli..."

    if ! readable "$url" > "$temp_html" 2>/dev/null; then
        rm -f "$temp_html"
        return 1
    fi

    if command -v pandoc &> /dev/null; then
        local temp_md=$(mktemp)
        if pandoc -f html -t markdown "$temp_html" > "$temp_md" 2>/dev/null; then
            clean_readability_markdown "$temp_md"
            mv "$temp_md" "$output"
        else
            log_warn "pandoc failed to convert readability output; saving HTML as-is."
            mv "$temp_html" "$output"
            rm -f "$temp_md"
            return 0
        fi
        rm -f "$temp_html"
    else
        mv "$temp_html" "$output"
    fi

    return 0
}

# Extract using trafilatura
extract_trafilatura() {
    local url="$1"
    local output="$2"

    log "Using trafilatura..."

    set_trafilatura_runner
    if [[ -z "$TRAFILATURA_RUNNER" ]]; then
        log_error "trafilatura is not available on PATH and the Python module is not installed."
        return 1
    fi

    if ! $TRAFILATURA_RUNNER --URL "$url" --output-format "markdown" --no-comments > "$output" 2>/dev/null; then
        return 1
    fi

    return 0
}

# Fallback extraction using curl + Python
extract_fallback() {
    local url="$1"
    local output="$2"

    log "Using fallback extraction..."

    curl -sS "$url" | python3 -c "
from html.parser import HTMLParser
import sys
import re

class ArticleExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_content = False
        self.in_skip = False
        self.content = []
        self.title = ''
        self.skip_tags = {'script', 'style', 'nav', 'header', 'footer', 'aside', 'form', 'noscript'}
        self.current_tag = None
        self.depth = 0

    def handle_starttag(self, tag, attrs):
        if tag in self.skip_tags:
            self.in_skip = True
            self.depth = 1
            return

        if tag == 'title' and not self.title:
            self.current_tag = 'title'
        elif tag in {'p', 'article', 'main', 'section'}:
            self.in_content = True
        elif tag in {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}:
            self.in_content = True
            self.content.append('')

    def handle_endtag(self, tag):
        if self.in_skip:
            if tag in self.skip_tags:
                self.depth -= 1
                if self.depth <= 0:
                    self.in_skip = False
        if tag == 'title':
            self.current_tag = None
        if tag in {'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'}:
            self.content.append('')

    def handle_data(self, data):
        if self.in_skip:
            return
        if self.current_tag == 'title':
            self.title = data.strip()
        elif self.in_content and data.strip():
            self.content.append(data.strip())

    def get_content(self):
        # Clean up multiple blank lines
        text = '\n'.join(self.content)
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text.strip()

parser = ArticleExtractor()
parser.feed(sys.stdin.read())
print('# ' + parser.title)
print()
print(parser.get_content())
" > "$output" 2>/dev/null

    if [[ ! -s "$output" ]]; then
        return 1
    fi

    return 0
}

# Get Wayback Machine URL for a given URL
get_wayback_url() {
    local url="$1"
    local api_response

    # Query Wayback Machine availability API
    api_response=$(curl -sS "https://archive.org/wayback/available?url=$url" 2>/dev/null) || return 1

    # Extract the archived URL using Python (more reliable than jq dependency)
    local archived_url
    archived_url=$(echo "$api_response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    snapshot = data.get('archived_snapshots', {}).get('closest', {})
    if snapshot.get('available'):
        print(snapshot.get('url', ''))
except:
    pass
" 2>/dev/null)

    if [[ -n "$archived_url" ]]; then
        echo "$archived_url"
        return 0
    fi

    return 1
}

# Extract from Wayback Machine
extract_wayback() {
    local url="$1"
    local output="$2"

    log "Checking Wayback Machine for archived version..."

    local wayback_url
    if ! wayback_url=$(get_wayback_url "$url"); then
        log_warn "No Wayback Machine snapshot found"
        return 1
    fi

    log "Found archived version: $wayback_url"

    # Try extraction tools on the wayback URL
    if extract_jina "$wayback_url" "$output"; then
        return 0
    fi

    set_trafilatura_runner
    if [[ -n "$TRAFILATURA_RUNNER" ]] && extract_trafilatura "$wayback_url" "$output"; then
        return 0
    fi

    if command -v readable &> /dev/null && extract_readability "$wayback_url" "$output"; then
        return 0
    fi

    if extract_fallback "$wayback_url" "$output"; then
        return 0
    fi

    return 1
}

# Get title from extracted content
get_title() {
    local file="$1"
    local title=""

    # Try to get title from first markdown heading (skip frontmatter)
    title=$(grep -m1 '^# ' "$file" 2>/dev/null | sed 's/^# //' || true)

    # If no title found, try first non-empty, non-metadata line
    if [[ -z "$title" ]]; then
        # Skip lines that are: empty, ---, metadata keys (word:), or very short
        title=$(grep -v '^$\|^---$\|^[a-z_]*:' "$file" 2>/dev/null | \
                grep -m1 '.\{10,\}' | \
                head -c 80 || true)
    fi

    # Default if still empty
    if [[ -z "$title" ]]; then
        title="article-$(date +%Y%m%d-%H%M%S)"
    fi

    echo "$title"
}

# Add metadata header to file
add_metadata() {
    local file="$1"
    local url="$2"
    local temp_file=$(mktemp)

    {
        echo "---"
        echo "source: $url"
        echo "extracted: $(date -Iseconds)"
        echo "---"
        echo ""
        cat "$file"
    } > "$temp_file"

    mv "$temp_file" "$file"
}

# Main extraction logic
main() {
    local tool=$(detect_tool)
    local temp_file=$(mktemp)
    local success=false
    local tried_tools=()

    log "Extracting article from: $ARTICLE_URL"

    if [[ -n "$FORCE_TOOL" ]]; then
        case "$FORCE_TOOL" in
            readability)
                if ! command -v readable &> /dev/null; then
                    log_error "Forced tool 'readability' is not available on PATH. Install readability-cli or remove --tool."
                    rm -f "$temp_file"
                    exit $EXIT_TOOL_MISSING
                fi
                ;;
            trafilatura)
                set_trafilatura_runner
                if [[ -z "$TRAFILATURA_RUNNER" ]]; then
                    log_error "Forced tool 'trafilatura' is not available on PATH. Add it to PATH or install the Python module."
                    rm -f "$temp_file"
                    exit $EXIT_TOOL_MISSING
                fi
                ;;
        esac
    fi

    # Try extraction with selected/detected tool
    case "$tool" in
        jina)
            if extract_jina "$ARTICLE_URL" "$temp_file"; then
                success=true
            fi
            ;;
        readability)
            if extract_readability "$ARTICLE_URL" "$temp_file"; then
                success=true
            fi
            ;;
        trafilatura)
            if extract_trafilatura "$ARTICLE_URL" "$temp_file"; then
                success=true
            fi
            ;;
        fallback)
            if extract_fallback "$ARTICLE_URL" "$temp_file"; then
                success=true
            fi
            ;;
    esac

    tried_tools+=("$tool")

    # Automatic fallback: try other tools if primary failed
    if [[ "$success" == false ]]; then
        log_warn "Primary tool '$tool' failed, trying alternatives..."

        # Try all available tools in priority order
        for fallback_tool in jina trafilatura readability fallback; do
            # Skip if already tried
            if [[ " ${tried_tools[@]} " =~ " ${fallback_tool} " ]]; then
                continue
            fi

            log "Trying $fallback_tool..."
            case "$fallback_tool" in
                jina)
                    if extract_jina "$ARTICLE_URL" "$temp_file"; then
                        success=true
                        break
                    fi
                    ;;
                readability)
                    if command -v readable &> /dev/null && extract_readability "$ARTICLE_URL" "$temp_file"; then
                        success=true
                        break
                    fi
                    ;;
                trafilatura)
                    set_trafilatura_runner
                    if [[ -n "$TRAFILATURA_RUNNER" ]] && extract_trafilatura "$ARTICLE_URL" "$temp_file"; then
                        success=true
                        break
                    fi
                    ;;
                fallback)
                    if extract_fallback "$ARTICLE_URL" "$temp_file"; then
                        success=true
                        break
                    fi
                    ;;
            esac
            tried_tools+=("$fallback_tool")
        done
    fi

    if [[ "$success" == false ]]; then
        # Try Wayback Machine if enabled
        if [[ "$TRY_WAYBACK" == true ]]; then
            log_warn "All extraction tools failed. Trying Wayback Machine..."
            if extract_wayback "$ARTICLE_URL" "$temp_file"; then
                success=true
                log_success "Extracted from Wayback Machine archive"
            fi
        fi
    fi

    if [[ "$success" == false ]]; then
        # Determine appropriate exit code based on failure symptoms
        local exit_code=$EXIT_NO_CONTENT

        # Check if it's likely an access issue
        if curl -sS -o /dev/null -w "%{http_code}" "$ARTICLE_URL" 2>/dev/null | grep -qE "^(401|403|451)$"; then
            exit_code=$EXIT_ACCESS_DENIED
            log_error "Access denied. The site may require authentication or has blocked access."
        elif ! curl -sS -o /dev/null "$ARTICLE_URL" 2>/dev/null; then
            exit_code=$EXIT_NETWORK
            log_error "Network error. Could not connect to the URL."
        else
            log_error "Failed to extract article content. The site may use heavy JavaScript rendering."
            if [[ "$TRY_WAYBACK" == false ]]; then
                log "Tip: Try --wayback flag to check for an archived version."
            fi
        fi

        rm -f "$temp_file"
        exit $exit_code
    fi

    # Determine output filename
    if [[ -z "$OUTPUT_FILE" ]]; then
        local title=$(get_title "$temp_file")
        local safe_name=$(sanitize_filename "$title")
        OUTPUT_FILE="${OUTPUT_DIR}/${safe_name}.md"
    else
        # Ensure output file is in output directory if not absolute path
        if [[ "$OUTPUT_FILE" != /* ]]; then
            OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILE}"
        fi
    fi

    # Get unique filename if file exists
    OUTPUT_FILE=$(unique_filename "$OUTPUT_FILE")

    # Add metadata header
    add_metadata "$temp_file" "$ARTICLE_URL"

    # Move to final location
    mv "$temp_file" "$OUTPUT_FILE"

    log_success "Extracted article"
    log_success "Saved to: $OUTPUT_FILE"
    log ""
    log "Preview (first 15 lines):"
    log "─────────────────────────────────────────"
    head -n 15 "$OUTPUT_FILE"
    log "─────────────────────────────────────────"

    # Output file info
    local size=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
    local lines=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    log ""
    log "File: $OUTPUT_FILE"
    log "Size: $size bytes, $lines lines"
}

main