#!/bin/bash
# Rebuilds resume/Jackson-Naik-Resume.pdf and .docx from the local copy of the site.
# Run it after changing index.html, then commit the new files.
set -e

cd "$(dirname "$0")"
PAGE_URL="http://nezuko/ctrlshifti-ai.github.io/"
CHROME=$(ls ~/.cache/ms-playwright/chromium-*/chrome-linux*/chrome | head -n 1)
WORK_DIR=$(mktemp -d)
mkdir -p resume

# PDF: same output as the browser's print, using the print styles in style.css
"$CHROME" --headless --no-pdf-header-footer --virtual-time-budget=5000 \
  --print-to-pdf="resume/Jackson-Naik-Resume.pdf" "$PAGE_URL"

# Word: save the rendered page, strip things a Word file can't use, then convert with LibreOffice
"$CHROME" --headless --virtual-time-budget=5000 --dump-dom "$PAGE_URL" > "$WORK_DIR/page.html"
python3 - "$WORK_DIR/page.html" <<'EOF'
import re, sys
path = sys.argv[1]
html = open(path, encoding="utf-8").read()
html = re.sub(r"<script.*?</script>", "", html, flags=re.S)
html = re.sub(r"<link[^>]*>", "", html)
html = re.sub(r"<meta(?! charset)[^>]*>", "", html)
html = re.sub(r"<img[^>]*>", "", html)
html = re.sub(r"<button.*?</button>", "", html, flags=re.S)
html = re.sub(r"<details.*?</details>", "", html, flags=re.S)
html = re.sub(r'<span class="duration">.*?</span>', "", html, flags=re.S)
html = re.sub(r"<footer.*?</footer>", "", html, flags=re.S)
html = re.sub(r'<section class="no-print">.*?</section>', "", html, flags=re.S)
open(path, "w", encoding="utf-8").write(html)
EOF
mv "$WORK_DIR/page.html" "$WORK_DIR/Jackson-Naik-Resume.html"
soffice --headless --convert-to "docx:MS Word 2007 XML" --outdir resume "$WORK_DIR/Jackson-Naik-Resume.html" > /dev/null

# Word ignores the CSS page-break rules, so set them on the Word styles instead:
# headings and project titles stay with the paragraph after them, and no paragraph splits across pages.
python3 - "resume/Jackson-Naik-Resume.docx" <<'PYEOF'
import re, sys, zipfile
path = sys.argv[1]

with zipfile.ZipFile(path) as docx:
    files = {name: docx.read(name) for name in docx.namelist()}

def add_page_rules(styles_xml, style_id, rules):
    pattern = re.compile(r'(<w:style [^>]*w:styleId="' + style_id + r'"[^>]*>)(.*?)(</w:style>)', re.S)
    match = pattern.search(styles_xml)
    if not match:
        return styles_xml
    body = match.group(2)
    if "<w:pPr>" in body:
        body = body.replace("<w:pPr>", "<w:pPr>" + rules, 1)
    elif "<w:pPr/>" in body:
        body = body.replace("<w:pPr/>", "<w:pPr>" + rules + "</w:pPr>", 1)
    elif "<w:rPr" in body:
        # pPr must come before rPr inside a style
        body = body.replace("<w:rPr", "<w:pPr>" + rules + "</w:pPr><w:rPr", 1)
    else:
        body = body + "<w:pPr>" + rules + "</w:pPr>"
    return styles_xml[:match.start(2)] + body + styles_xml[match.end(2):]

styles = files["word/styles.xml"].decode("utf-8")
for style_id in ["Heading1", "Heading2", "Heading3", "ListHeading"]:
    styles = add_page_rules(styles, style_id, "<w:keepNext/><w:keepLines/>")
for style_id in ["ListContents", "BodyText"]:
    styles = add_page_rules(styles, style_id, "<w:keepLines/>")
# Use Calibri everywhere: LibreOffice's Liberation fonts are missing on most Windows/Mac machines
styles = re.sub(r"<w:rFonts [^>]*/>", '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/>', styles)
files["word/styles.xml"] = styles.encode("utf-8")

# Keep each job in one piece: every paragraph from the job title to its last bullet
# stays with the next one, so the whole job moves to the next page instead of splitting.
document = files["word/document.xml"].decode("utf-8")
paragraphs = re.split(r"(?=<w:p>|<w:p )", document)
in_job = False
for i, paragraph in enumerate(paragraphs):
    is_job_title = '<w:pStyle w:val="Heading3"/>' in paragraph
    is_section_title = re.search(r'<w:pStyle w:val="Heading[12]"/>', paragraph)
    if is_job_title:
        in_job = True
    elif is_section_title:
        in_job = False
    if not in_job:
        continue
    next_paragraph = paragraphs[i + 1] if i + 1 < len(paragraphs) else ""
    next_starts_new_block = re.search(r'<w:pStyle w:val="Heading[123]"/>', next_paragraph)
    if not next_starts_new_block:
        # Word requires keepNext to come right after the paragraph's style tag
        paragraphs[i] = re.sub(r'(<w:pStyle w:val="[^"]*"/>)', r"\1<w:keepNext/>", paragraph, count=1)
document = "".join(paragraphs)
files["word/document.xml"] = document.encode("utf-8")

# Open in normal page view (LibreOffice sets web view for HTML input) and don't hyphenate words
settings = files["word/settings.xml"].decode("utf-8")
settings = settings.replace('<w:view w:val="web"/>', '<w:view w:val="print"/>')
settings = settings.replace('<w:autoHyphenation w:val="true"/>', '<w:autoHyphenation w:val="false"/>')
files["word/settings.xml"] = settings.encode("utf-8")

with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as docx:
    for name, data in files.items():
        docx.writestr(name, data)
PYEOF

rm -rf "$WORK_DIR"
echo "Done: resume/Jackson-Naik-Resume.pdf and resume/Jackson-Naik-Resume.docx"
