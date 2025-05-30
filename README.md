# Highlight-text Extension For Quarto

This is a Quarto extension that allows to highlight text in a document for various format: HTML, LaTeX, Typst, and Docx.

## Installing

```bash
quarto add mcanouil/quarto-highlight-text
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

To use the extension, add the following to your document's front matter:

```yaml
filters:
  - highlight-text
```

Then you can use the span syntax markup to highlight text in your document, *e.g.*:

```markdown
[Red]{colour="#b22222" bg-colour="#abc123"} # UK
[Blue]{color="#0000FF" bg-color="#ABC123"} # US
```

You can also use the shorter syntax ([v1.1.1](../../releases/tag/1.1.1)):

```markdown
[Red]{fg="red" bg="primary"}
```

Using colours from `_brand.yml` ([v1.1.0](../../releases/tag/1.1.0)):

```yaml
color:
  palette:
    red: "#b22222"
  primary: "#abc123"
```

```markdown
[Red]{colour="brand-color.red" bg-colour="brand-color.primary"}
```

Using colours from light/dark themes with Quarto CLI >=1.7.28 ([v1.2.0](../../releases/tag/1.2.0)):

- From document front matter:

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

- From `_quarto.yml` and `_brand.yml` file

  ```yaml
  brand:
    dark: _brand.yml
  ```

```markdown
[Light: White/Red | Dark: Red/White]{colour="brand-color.fg" bg-colour="brand-color.bg"}
```

> [!NOTE]
> Only the `html` support light/dark mode switching.
> The other formats will use the light mode colours if available or the dark mode colours otherwise.

## Limitations

LaTeX `\colorbox` command does not support wrapping/line breaks in the text to be highlighted.
This means that the above example will not work well in LaTeX output.  
In order to get a slightly better result, you can use the `par=true` attribute to add `\parbox{\linewidth}`:

```markdown
[Red]{colour="#b22222" bg-colour="#abc123" par=true}
```

Use `pdf-engine: lualatex` in your YAML front matter to use the `luatex` engine and fully alleviate the above issue.

## Examples

Here is the source code for a minimal example: [`example.qmd`](example.qmd).

Outputs of `example.qmd`:

- [HTML](https://m.canouil.dev/quarto-highlight-text/)
- [Typst/PDF](https://m.canouil.dev/quarto-highlight-text/highlight-typst.pdf)
- [LaTeX/PDF (XeLaTeX)](https://m.canouil.dev/quarto-highlight-text/highlight-xelatex.pdf)
- [LaTeX/PDF (LuaLaTeX)](https://m.canouil.dev/quarto-highlight-text/highlight-lualatex.pdf)
- [LaTeX/PDF (PDFLaTeX)](https://m.canouil.dev/quarto-highlight-text/highlight-pdflatex.pdf)
- [Word/Docx](https://m.canouil.dev/quarto-highlight-text/highlight-openxml.docx) (**only supports plain text, *i.e.*, no URLs**)
- [Reveal.js](https://m.canouil.dev/quarto-highlight-text/highlight-revealjs.html)
- [Beamer/PDF](https://m.canouil.dev/quarto-highlight-text/highlight-beamer.pdf)
- [PowerPoint/Pptx](https://m.canouil.dev/quarto-highlight-text/highlight-pptx.pptx) (**only supports plain text, *i.e.*, no URLs**)
