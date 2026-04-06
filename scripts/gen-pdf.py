import markdown, os

with open('REPORT.md', 'r', encoding='utf-8') as f:
    md_text = f.read()

# Keep relative image paths (dashboards/xxx.png) for HTTP serving
html = markdown.markdown(md_text, extensions=['tables', 'fenced_code'])

style = """
body { font-family: Segoe UI, Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; font-size: 11pt; line-height: 1.5; color: #1a1a1a; }
h1 { color: #0078d4; border-bottom: 2px solid #0078d4; padding-bottom: 8px; }
h2 { color: #106ebe; margin-top: 30px; }
h3 { color: #333; }
table { border-collapse: collapse; width: 100%; margin: 15px 0; font-size: 10pt; }
th, td { border: 1px solid #ddd; padding: 6px 10px; text-align: left; }
th { background: #f0f0f0; font-weight: 600; }
tr:nth-child(even) { background: #fafafa; }
code { background: #f4f4f4; padding: 1px 4px; border-radius: 3px; font-size: 10pt; }
pre { background: #1e1e1e; color: #d4d4d4; padding: 12px; border-radius: 4px; overflow-x: auto; font-size: 9pt; line-height: 1.4; }
pre code { background: none; color: inherit; }
img { max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; margin: 10px 0; }
blockquote { border-left: 4px solid #0078d4; margin: 15px 0; padding: 8px 16px; background: #f0f7ff; }
strong { color: #1a1a1a; }
"""

head = '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' + style + '</style></head><body>'
tail = '</body></html>'
full_html = head + html + tail

with open('REPORT.html', 'w', encoding='utf-8') as f:
    f.write(full_html)

print('REPORT.html generated')
