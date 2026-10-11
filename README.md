# Create PDF
The print stylesheet lays the page out as a single US Letter page.

```sh
./print-pdf.sh
```

This uses headless Chrome to write `resume.pdf`, and warns if the result is longer than one page. Pass a path to write somewhere else (`./print-pdf.sh resume.pdf`), or set `CHROME` to use a different Chrome or Chromium binary.

Or from any browser: File > Print > Save as PDF (with headers and footers turned off).
