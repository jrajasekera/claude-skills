#!/usr/bin/env bash
#
# install-deps.sh - Install article extraction dependencies
#
# This script installs tools for extracting article content from URLs.
# The main script (extract-article.sh) will work without these (using Jina API),
# but local tools are faster and work offline.
#
# Tools installed:
#   - trafilatura: Python-based extraction (pip)
#   - readability-cli: Mozilla's Readability algorithm (npm)
#

set -euo pipefail

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    NC=''
fi

log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo "================================================"
echo "  Article Extractor - Dependency Installer"
echo "================================================"
echo ""

# Check what's already installed
echo "Checking existing installations..."
echo ""

READABILITY_INSTALLED=false
TRAFILATURA_INSTALLED=false

if command -v readable &> /dev/null; then
    log_success "readability-cli is already installed"
    READABILITY_INSTALLED=true
else
    log_info "readability-cli not found"
fi

if command -v trafilatura &> /dev/null; then
    log_success "trafilatura is already installed"
    TRAFILATURA_INSTALLED=true
else
    log_info "trafilatura not found"
fi

echo ""

# Check for package managers
HAS_NPM=false
HAS_PIP=false

if command -v npm &> /dev/null; then
    HAS_NPM=true
fi

if command -v pip3 &> /dev/null || command -v pip &> /dev/null; then
    HAS_PIP=true
fi

# Install readability-cli if not present
if [[ "$READABILITY_INSTALLED" == false ]]; then
    if [[ "$HAS_NPM" == true ]]; then
        echo "Installing readability-cli via npm..."
        if npm install -g readability-cli 2>/dev/null; then
            log_success "readability-cli installed successfully"
            READABILITY_INSTALLED=true
        else
            log_warn "Failed to install readability-cli globally, trying with sudo..."
            if sudo npm install -g readability-cli 2>/dev/null; then
                log_success "readability-cli installed successfully (with sudo)"
                READABILITY_INSTALLED=true
            else
                log_error "Failed to install readability-cli"
            fi
        fi
    else
        log_warn "npm not found - cannot install readability-cli"
        log_info "Install Node.js/npm first: https://nodejs.org/"
    fi
fi

echo ""

# Install trafilatura if not present
if [[ "$TRAFILATURA_INSTALLED" == false ]]; then
    if [[ "$HAS_PIP" == true ]]; then
        echo "Installing trafilatura via pip..."
        PIP_CMD="pip3"
        if ! command -v pip3 &> /dev/null; then
            PIP_CMD="pip"
        fi
        
        # Try with --user first, then --break-system-packages for newer systems
        if $PIP_CMD install --user trafilatura 2>/dev/null; then
            log_success "trafilatura installed successfully"
            TRAFILATURA_INSTALLED=true
        elif $PIP_CMD install --break-system-packages trafilatura 2>/dev/null; then
            log_success "trafilatura installed successfully"
            TRAFILATURA_INSTALLED=true
        else
            log_warn "Failed to install trafilatura with pip"
            log_info "You may need to use a virtual environment or pipx"
        fi
    else
        log_warn "pip not found - cannot install trafilatura"
        log_info "Install Python/pip first: https://www.python.org/"
    fi
fi

echo ""
echo "================================================"
echo "  Installation Summary"
echo "================================================"
echo ""

if [[ "$READABILITY_INSTALLED" == true ]]; then
    log_success "readability-cli: installed (optional)"
else
    log_warn "readability-cli: not installed"
fi

if [[ "$TRAFILATURA_INSTALLED" == true ]]; then
    log_success "trafilatura: installed"
else
    log_warn "trafilatura: not installed"
fi

echo ""
log_info "Jina Reader API: always available (no install needed)"
echo ""

if [[ "$READABILITY_INSTALLED" == true || "$TRAFILATURA_INSTALLED" == true ]]; then
    log_success "Article extraction is ready to use!"
else
    log_warn "No local tools installed, but Jina API will be used as the primary extractor"
    log_info "This works but requires internet and may be slower"
fi

echo ""
echo "Manual installation commands:"
echo "  pip install trafilatura           # Python local extractor (recommended)"
echo "  npm install -g readability-cli    # Mozilla Readability (optional)"
echo ""
