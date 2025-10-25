# Highlight-text Extension For Quarto

This is a Quarto extension that allows to highlight text in a document for various formats: HTML, LaTeX, Typst, Docx, PowerPoint, Reveal.js, and Beamer.

## Installation

```bash
quarto add mcanouil/quarto-highlight-text
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

## Usage

To use the extension, add the following to your document's front matter:

```yaml
filters:
  - highlight-text
```

Then you can use the span syntax markup to highlight text in your document.

### Basic Syntax

The extension supports both British and American English spelling for colour attributes:

```markdown
[Red]{colour="#b22222" bg-colour="#abc123"} # UK spelling
[Blue]{color="#0000ff" bg-color="#abc123"} # US spelling
```

### Shorter Syntax

You can use abbreviated attribute names ([v1.1.1](../../releases/tag/1.1.1)):

```markdown
[Red text]{fg="#b22222"}
[Red background]{bg="#abc123"}
[White on Red]{fg="#ffffff" bg="#b22222"}
```

Supported attributes:

- **Foreground (text) colour**: `fg`, `colour`, or `color`
- **Background colour**: `bg`, `bg-colour`, or `bg-color`

### Using Brand Colours

Define colours once in `_brand.yml` and reference them throughout your documents ([v1.1.0](../../releases/tag/1.1.0)):

```yaml
color:
  palette:
    red: "#b22222"
    custom-blue: "#0000ff"
  primary: "#abc123"
```

Reference these colours directly by name:

```markdown
[Red text]{fg="red"}
[Custom background]{bg="custom-blue"}
[Primary highlight]{bg="primary"}
```

> [!NOTE]
> The old `brand-color.` prefix syntax (e.g., `colour="brand-color.red"`) is deprecated but still supported ([v1.4.0](../../releases/tag/1.4.0)).
> You'll see a warning when using it.
> Use the colour name directly instead: `colour="red"`.

### Light and Dark Theme Support

With Quarto CLI ≥1.7.28, you can define different colours for light and dark themes ([v1.2.0](../../releases/tag/1.2.0)):

**Option 1**: Define themes in document front matter:

```yaml
brand:
  light:
    color:
      palette:
        fg: "#ffffff"
        bg: "#b22222"
  dark:
    color:
      palette:
        fg: "#b22222"
        bg: "#ffffff"
```

**Option 2**: Use external `_brand.yml` file:

```yaml
brand:
  light: _brand.yml
  dark: _brand-dark.yml
```

Then reference theme-aware colours:

```markdown
[This text adapts to theme]{fg="fg" bg="bg"}
```

> [!NOTE]
> Only HTML formats support dynamic light/dark mode switching.
> Other formats will use the light mode colours if available, or fall back to dark mode colours otherwise, unless specified otherwise.

## Limitations

### LaTeX/PDF Output

The LaTeX `\colorbox` command does not support line wrapping for highlighted text with background colours.
Long highlighted text may overflow or break awkwardly.

**Workaround for XeLaTeX and PDFLaTeX**: Use the `par=true` attribute to add `\parbox{\linewidth}`:

```markdown
[Long text with background]{colour="#b22222" bg-colour="#abc123" par=true}
```

**Best solution**: Use LuaLaTeX as your PDF engine for proper line wrapping with the `lua-ul` package:

```yaml
format:
  pdf:
    pdf-engine: lualatex
```

> [!NOTE]
> LuaLaTeX is the default PDF engine in Quarto CLI ≥1.8.25.

### Word and PowerPoint Output

Docx and Pptx formats only support highlighting plain text.

Links and other inline formatting within highlighted spans may not render correctly.

## Example

Here is the source code for a minimal example: [`example.qmd`](example.qmd).

Output of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-highlight-text/)
- [Typst/PDF](https://m.canouil.dev/quarto-highlight-text/highlight-typst.pdf)
- [LaTeX/PDF (XeLaTeX)](https://m.canouil.dev/quarto-highlight-text/highlight-xelatex.pdf)
- [LaTeX/PDF (LuaLaTeX)](https://m.canouil.dev/quarto-highlight-text/highlight-lualatex.pdf)
- [LaTeX/PDF (PDFLaTeX)](https://m.canouil.dev/quarto-highlight-text/highlight-pdflatex.pdf)
- [Word/Docx](https://m.canouil.dev/quarto-highlight-text/highlight-openxml.docx) (**only supports plain text, *i.e.*, no URLs**)
- [Reveal.js](https://m.canouil.dev/quarto-highlight-text/highlight-revealjs.html)
- [Beamer/PDF](https://m.canouil.dev/quarto-highlight-text/highlight-beamer.pdf)
- [PowerPoint/Pptx](https://m.canouil.dev/quarto-highlight-text/highlight-pptx.pptx) (**only supports plain text, *i.e.*, no URLs**)
