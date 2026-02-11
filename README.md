# Highlight-text Extension For Quarto

This is a Quarto extension that allows to highlight text in a document for various formats: HTML, LaTeX, Typst, Docx, PowerPoint, Reveal.js, and Beamer.

## Installation

```bash
quarto add mcanouil/quarto-highlight-text@2.0.2
```

This will install the extension under the `_extensions` subdirectory.

If you're using version control, you will want to check in this directory.

## Usage

To use the extension, add the following to your document's front matter:

```yaml
filters:
  - highlight-text
```

Then you can use either span syntax for inline highlighting or div syntax for block-level highlighting.

### Inline Highlighting (Spans)

Highlight text inline using span syntax:

```markdown
[Red]{colour="#b22222" bg-colour="#abc123"} # UK spelling
[Blue]{color="#0000ff" bg-color="#abc123"} # US spelling
```

### Block Highlighting (Divs)

Highlight entire blocks using div syntax:

```markdown
::: {fg="#ffffff" bg="#0000ff"}
This is a block-level highlighted section.

It can contain multiple paragraphs, lists, and other content.
:::
```

### Shorter Syntax

You can use abbreviated attribute names:

```markdown
[Red text]{fg="#b22222"}
[Red text (ink alias)]{ink="#b22222"}
[Red background]{bg="#abc123"}
[Red background (paper alias)]{paper="#abc123"}
[White on Red]{fg="#ffffff" bg="#b22222"}
[White on Red (ink/paper aliases)]{ink="#ffffff" paper="#b22222"}
[Text with solid border]{bc="#0000ff"}
[Text with dashed border]{bc="#b22222" bs="dashed"}
[Text with dotted border]{bc="#00aa00" border-style="dotted"}
```

For block-level highlighting:

```markdown
::: {fg="#ffffff" bg="#b22222"}
Block with white text on red background.
:::

::: {ink="#ffffff" paper="#b22222"}
Block with white text on red background (ink/paper aliases).
:::

::: {bc="#b22222" bg="#ffffcc"}
Block with red solid border and light yellow background.
:::

::: {bc="#0000ff" bg="#f0f0f0" bs="dashed"}
Block with blue dashed border and light grey background.
:::
```

Supported attributes:

- **Foreground (text) colour**: `ink`, `fg`, `colour`, or `color`
- **Background colour**: `paper`, `bg`, `bg-colour`, or `bg-color`
- **Border colour**: `bc`, `border-colour`, or `border-color`
- **Border style**: `bs` or `border-style` (values: `solid`, `dashed`, `dotted`, `double`; defaults to `solid`)

### Using Brand Colours

Define colours once in `_brand.yml` and reference them throughout your documents:

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
> The old `brand-color.` prefix syntax (e.g., `colour="brand-color.red"`) is deprecated but still supported.
> You'll see a warning when using it.
> Use the colour name directly instead: `colour="red"`.

### Light and Dark Theme Support

With Quarto CLI ≥1.7.28, you can define different colours for light and dark themes:

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

**For inline highlighting**: Use the `par=true` attribute to add `\parbox{\linewidth}` (XeLaTeX and PDFLaTeX only):

```markdown
[Long text with background]{colour="#b22222" bg-colour="#abc123" par=true}
```

**For block-level highlighting**: Automatic line wrapping is enabled for all engines.
Block divs automatically use `\parbox` for non-LuaLaTeX engines.

**Best solution**: Use LuaLaTeX as your PDF engine for proper line wrapping with the `lua-ul` package:

```yaml
format:
  pdf:
    pdf-engine: lualatex
```

> [!NOTE]
> LuaLaTeX is the default PDF engine in Quarto CLI ≥1.8.25.

### PowerPoint Output

Links are not supported in highlighted text in PowerPoint output, *i.e.*, URLs will be rendered using default styles.

Border colour is not supported in PowerPoint output.

### Word Output

Links are not supported in highlighted text in Word output, *i.e.*, URLs will be rendered using default styles.

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
