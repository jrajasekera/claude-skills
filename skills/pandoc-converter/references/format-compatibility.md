# Pandoc Format Compatibility Reference

## Format Categories

### Document Formats (Full Read/Write)
| Format | Extension | Pandoc Name | Notes |
|--------|-----------|-------------|-------|
| Markdown | .md | markdown | Pandoc-flavored markdown |
| GitHub Markdown | .md | gfm | GitHub-Flavored Markdown |
| CommonMark | .md | commonmark | Standard CommonMark |
| HTML | .html | html | HTML5 by default |
| Word | .docx | docx | Office Open XML |
| LaTeX | .tex | latex | For academic/scientific docs |
| EPUB | .epub | epub | E-book format |
| RTF | .rtf | rtf | Rich Text Format |
| PowerPoint | .pptx | pptx | Slide presentations |
| PDF | .pdf | pdf | Output only, needs LaTeX |

### Data Formats (Input Only)
| Format | Extension | Pandoc Name | Best Output Formats |
|--------|-----------|-------------|---------------------|
| CSV | .csv | csv | html, docx, markdown, latex |
| TSV | .tsv | tsv | html, docx, markdown, latex |
| Excel | .xlsx | xlsx | html, docx, markdown, latex |

### Native AST Formats
| Format | Extension | Pandoc Name | Use Case |
|--------|-----------|-------------|----------|
| JSON | .json | json | Pandoc native AST |
| XML | .xml | xml | Pandoc native AST |

## Conversion Matrix

### From Markdown/GFM/CommonMark
- ✅ → HTML, DOCX, PDF, LaTeX, EPUB, RTF, PPTX
- ✅ → JSON, XML (AST export)

### From HTML
- ✅ → Markdown, DOCX, PDF, LaTeX, EPUB, RTF
- ⚠️ → PPTX (limited, text extraction only)

### From DOCX
- ✅ → Markdown, HTML, PDF, LaTeX, EPUB, RTF
- ⚠️ → PPTX (text extraction only)

### From LaTeX
- ✅ → Markdown, HTML, DOCX, PDF, EPUB, RTF
- ⚠️ Complex LaTeX may not convert perfectly

### From EPUB
- ✅ → Markdown, HTML, DOCX, PDF, LaTeX, RTF

### From RTF
- ✅ → Markdown, HTML, DOCX, PDF, LaTeX, EPUB

### From CSV/TSV/XLSX (Data)
- ✅ → Markdown, HTML, DOCX, LaTeX (as tables)
- ❌ → PPTX, EPUB (not meaningful)
- ❌ → CSV, TSV, XLSX (can't output to these)

### From PPTX
- ✅ → Markdown, HTML, DOCX (text extraction)
- ⚠️ Slide structure may be lost
- ❌ → PDF without LaTeX

### From JSON/XML (AST)
- ✅ → Any output format
- Used for programmatic document manipulation

## Common Conversion Patterns

### Documentation Workflows
```
markdown → docx    # For sharing with Word users
markdown → html    # For web publishing
markdown → pdf     # For print/archival
docx → markdown    # For version control
```

### Data Publishing
```
csv → html         # Interactive data tables
xlsx → markdown    # Documentation with data
csv → docx         # Reports with tabular data
```

### Academic/Scientific
```
markdown → latex   # For journal submission
latex → pdf        # Final publication
latex → docx       # For collaborators
```

### E-books
```
markdown → epub    # E-book creation
epub → markdown    # E-book editing
html → epub        # Web to e-book
```

## Special Requirements

### PDF Output
Requires LaTeX distribution:
- macOS: `brew install --cask mactex-no-gui`
- Ubuntu: `sudo apt-get install texlive-xetex`
- Windows: Install MiKTeX

PDF engines: pdflatex (default), xelatex (better Unicode), lualatex

### Standalone Documents
These formats automatically use standalone mode:
- HTML (includes <head>, <body>)
- EPUB (complete e-book structure)
- PDF (complete document)

### Tabular Data Notes
- CSV/TSV/XLSX are parsed as single-table documents
- Best converted to formats that support tables well
- Complex multi-sheet Excel files: only first sheet by default
