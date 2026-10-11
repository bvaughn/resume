# Create PDF
The print stylesheet lays the page out as a single US Letter page.

```sh
./print-pdf.sh
```

This uses headless Chrome to write `resume.pdf`, and warns if the result is longer than one page. Pass a path to write somewhere else (`./print-pdf.sh resume.pdf`), or set `CHROME` to use a different Chrome or Chromium binary.

The phone number is only included in the PDF, never in the published HTML. The script reads it from `$RESUME_PHONE` or from the first line of a gitignored `.phone` file, and leaves it out (with a warning) if neither is set.

Or from any browser (without the phone number): File > Print > Save as PDF (with headers and footers turned off).
