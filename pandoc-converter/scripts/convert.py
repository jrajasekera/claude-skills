#!/usr/bin/env python3
"""
Pandoc Document Converter

Converts documents between formats using Pandoc.

Usage:
    python convert.py <input_file> <output_file> [options]
    python convert.py <input_file> --to <format> [options]
    python convert.py --check  # Check if Pandoc is installed
    python convert.py --formats  # List supported formats

Options:
    --from <format>    Specify input format (auto-detected by default)
    --to <format>      Specify output format (required if no output file)
    --standalone       Produce standalone document with headers/footers
    --toc              Include table of contents
    --pdf-engine <eng> PDF engine (pdflatex, xelatex, lualatex)

Examples:
    python convert.py report.md report.docx
    python convert.py document.docx --to markdown
    python convert.py data.csv output.html --standalone
"""

import subprocess
import sys
import shutil
from pathlib import Path

# Format mappings: extension -> pandoc format name
INPUT_FORMATS = {
    '.md': 'markdown',
    '.markdown': 'markdown',
    '.html': 'html',
    '.htm': 'html',
    '.docx': 'docx',
    '.csv': 'csv',
    '.tsv': 'tsv',
    '.xlsx': 'xlsx',
    '.pptx': 'pptx',
    '.tex': 'latex',
    '.latex': 'latex',
    '.epub': 'epub',
    '.rtf': 'rtf',
    '.json': 'json',
    '.xml': 'xml',
    '.gfm': 'gfm',
    '.commonmark': 'commonmark',
}

OUTPUT_FORMATS = {
    '.md': 'markdown',
    '.markdown': 'markdown',
    '.html': 'html',
    '.htm': 'html',
    '.docx': 'docx',
    '.pptx': 'pptx',
    '.tex': 'latex',
    '.latex': 'latex',
    '.epub': 'epub',
    '.rtf': 'rtf',
    '.json': 'json',
    '.xml': 'xml',
    '.pdf': 'pdf',
    '.gfm': 'gfm',
    '.commonmark': 'commonmark',
}

# Formats that only work as input (no output support)
INPUT_ONLY = {'.csv', '.tsv', '.xlsx'}

# Formats that require --standalone for proper output
STANDALONE_REQUIRED = {'.html', '.htm', '.epub', '.pdf'}


def check_pandoc_installed():
    """Check if Pandoc is installed and return version info."""
    pandoc_path = shutil.which('pandoc')
    if not pandoc_path:
        return None, None
    
    try:
        result = subprocess.run(
            ['pandoc', '--version'],
            capture_output=True,
            text=True
        )
        version_line = result.stdout.split('\n')[0]
        return pandoc_path, version_line
    except Exception:
        return pandoc_path, "unknown version"


def get_installation_instructions():
    """Return platform-specific installation instructions."""
    return """
Pandoc Installation Instructions
================================

macOS (using Homebrew):
    brew install pandoc

macOS (using MacPorts):
    sudo port install pandoc

Ubuntu/Debian:
    sudo apt-get install pandoc

Fedora:
    sudo dnf install pandoc

Windows (using Chocolatey):
    choco install pandoc

Windows (using Scoop):
    scoop install pandoc

Or download from: https://pandoc.org/installing.html

For PDF output, you also need a LaTeX distribution:
    macOS: brew install --cask mactex-no-gui
    Ubuntu: sudo apt-get install texlive-xetex
    Windows: Install MiKTeX from https://miktex.org/
"""


def detect_format(filepath, format_map):
    """Detect format from file extension."""
    ext = Path(filepath).suffix.lower()
    return format_map.get(ext)


def validate_conversion(input_format, output_format, input_ext, output_ext):
    """Check if the conversion makes sense."""
    # Input-only formats can't be outputs
    if output_ext in INPUT_ONLY:
        return False, f"Cannot convert TO {output_ext} - it's an input-only format"
    
    # Warn about potentially lossy conversions
    warnings = []
    
    # Data formats to rich documents
    if input_ext in {'.csv', '.tsv', '.xlsx'}:
        if output_ext in {'.pptx', '.epub'}:
            return False, f"Converting tabular data ({input_ext}) to {output_ext} is not supported"
    
    return True, None


def build_pandoc_command(input_file, output_file, input_format=None, output_format=None,
                         standalone=False, toc=False, pdf_engine=None, extra_args=None):
    """Build the Pandoc command."""
    cmd = ['pandoc']
    
    # Input format
    if input_format:
        cmd.extend(['-f', input_format])
    
    # Output format
    if output_format:
        cmd.extend(['-t', output_format])
    
    # Output file
    if output_file:
        cmd.extend(['-o', str(output_file)])
    
    # Standalone mode
    output_ext = Path(output_file).suffix.lower() if output_file else None
    if standalone or (output_ext and output_ext in STANDALONE_REQUIRED):
        cmd.append('-s')
    
    # Table of contents
    if toc:
        cmd.append('--toc')
    
    # PDF engine
    if pdf_engine:
        cmd.extend(['--pdf-engine', pdf_engine])
    
    # Extra arguments
    if extra_args:
        cmd.extend(extra_args)
    
    # Input file
    cmd.append(str(input_file))
    
    return cmd


def convert(input_file, output_file=None, input_format=None, output_format=None,
            standalone=False, toc=False, pdf_engine=None, extra_args=None):
    """
    Convert a document using Pandoc.
    
    Returns:
        tuple: (success: bool, message: str, output_path: str or None)
    """
    # Check Pandoc installation
    pandoc_path, version = check_pandoc_installed()
    if not pandoc_path:
        return False, "Pandoc is not installed.\n" + get_installation_instructions(), None
    
    input_path = Path(input_file)
    
    # Validate input file exists
    if not input_path.exists():
        return False, f"Input file not found: {input_file}", None
    
    # Detect input format if not specified
    if not input_format:
        input_format = detect_format(input_file, INPUT_FORMATS)
        if not input_format:
            return False, f"Could not detect input format for: {input_file}", None
    
    # Handle output
    if output_file:
        output_path = Path(output_file)
        if not output_format:
            output_format = detect_format(output_file, OUTPUT_FORMATS)
            if not output_format:
                return False, f"Could not detect output format for: {output_file}", None
    elif output_format:
        # Generate output filename from input + new extension
        ext_map = {v: k for k, v in OUTPUT_FORMATS.items()}
        new_ext = ext_map.get(output_format, f'.{output_format}')
        output_path = input_path.with_suffix(new_ext)
        output_file = str(output_path)
    else:
        return False, "Must specify either output file or --to format", None
    
    # Validate conversion
    input_ext = input_path.suffix.lower()
    output_ext = output_path.suffix.lower()
    valid, error = validate_conversion(input_format, output_format, input_ext, output_ext)
    if not valid:
        return False, error, None
    
    # Check PDF engine for PDF output
    if output_ext == '.pdf' and not pdf_engine:
        # Check if any LaTeX engine is available
        for engine in ['pdflatex', 'xelatex', 'lualatex']:
            if shutil.which(engine):
                pdf_engine = engine
                break
        if not pdf_engine:
            return False, (
                "PDF output requires a LaTeX engine (pdflatex, xelatex, or lualatex).\n"
                "Install a LaTeX distribution:\n"
                "  macOS: brew install --cask mactex-no-gui\n"
                "  Ubuntu: sudo apt-get install texlive-xetex\n"
                "  Windows: Install MiKTeX from https://miktex.org/"
            ), None
    
    # Build and run command
    cmd = build_pandoc_command(
        input_file, output_file, input_format, output_format,
        standalone, toc, pdf_engine, extra_args
    )
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            error_msg = result.stderr or "Unknown error"
            return False, f"Pandoc conversion failed:\n{error_msg}", None
        
        # Verify output was created
        if not output_path.exists():
            return False, "Conversion completed but output file was not created", None
        
        return True, f"Successfully converted to {output_path}", str(output_path)
        
    except Exception as e:
        return False, f"Error running Pandoc: {str(e)}", None


def list_formats():
    """Print supported formats."""
    print("Supported Input Formats:")
    print("-" * 40)
    for ext, fmt in sorted(INPUT_FORMATS.items()):
        note = " (input only)" if ext in INPUT_ONLY else ""
        print(f"  {ext:12} -> {fmt}{note}")
    
    print("\nSupported Output Formats:")
    print("-" * 40)
    for ext, fmt in sorted(OUTPUT_FORMATS.items()):
        print(f"  {ext:12} -> {fmt}")
    
    print("\nNotes:")
    print("  - CSV, TSV, XLSX are input-only (tabular data)")
    print("  - PDF output requires LaTeX installation")
    print("  - HTML, EPUB, PDF automatically use standalone mode")


def main():
    args = sys.argv[1:]
    
    if not args or '-h' in args or '--help' in args:
        print(__doc__)
        return
    
    if '--check' in args:
        path, version = check_pandoc_installed()
        if path:
            print(f"✓ Pandoc is installed: {version}")
            print(f"  Location: {path}")
        else:
            print("✗ Pandoc is not installed")
            print(get_installation_instructions())
        return
    
    if '--formats' in args:
        list_formats()
        return
    
    # Parse arguments
    input_file = None
    output_file = None
    input_format = None
    output_format = None
    standalone = False
    toc = False
    pdf_engine = None
    extra_args = []
    
    i = 0
    while i < len(args):
        arg = args[i]
        
        if arg == '--from' or arg == '-f':
            input_format = args[i + 1]
            i += 2
        elif arg == '--to' or arg == '-t':
            output_format = args[i + 1]
            i += 2
        elif arg == '-o':
            output_file = args[i + 1]
            i += 2
        elif arg == '--standalone' or arg == '-s':
            standalone = True
            i += 1
        elif arg == '--toc':
            toc = True
            i += 1
        elif arg == '--pdf-engine':
            pdf_engine = args[i + 1]
            i += 2
        elif arg.startswith('-'):
            # Pass through other Pandoc options
            extra_args.append(arg)
            if i + 1 < len(args) and not args[i + 1].startswith('-'):
                extra_args.append(args[i + 1])
                i += 1
            i += 1
        elif not input_file:
            input_file = arg
            i += 1
        elif not output_file:
            output_file = arg
            i += 1
        else:
            i += 1
    
    if not input_file:
        print("Error: No input file specified")
        print("Usage: python convert.py <input_file> <output_file>")
        sys.exit(1)
    
    success, message, output_path = convert(
        input_file, output_file, input_format, output_format,
        standalone, toc, pdf_engine, extra_args
    )
    
    print(message)
    if success:
        print(f"Output: {output_path}")
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
