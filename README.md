# Highlight-text Extension For Quarto

This is a Quarto extension that allows to highlight text in a document for various format: HTML, LaTeX, Typst, and Docx.

## Installing

```bash
quarto add mcanouil/highlight-text
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

To use the extension, add the following to your document's front matter:

```yaml
filters:
  - highlight-text
```

Then you can use the span syntax markup to highlight text in your document.

```markdown
[Red]{colour="#b22222"}
[Blue]{color="#0000FF"}
```

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

This is the output of `example.qmd` for:

- [HTML](https://m.canouil.dev/quarto-iconify/).
- [LaTeX/PDF](https://m.canouil.dev/quarto-iconify/highlight-latex.pdf).
- [Typst/PDF](https://m.canouil.dev/quarto-iconify/highlight-typst.pdf).
- [Docx](https://m.canouil.dev/quarto-iconify/highlight-openxml.docx).
