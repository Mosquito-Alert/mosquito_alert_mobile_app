"""Make print-optimised copies of the built web pages (A4, contents list, no sticky navigation)."""
import re, os, sys
SP = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
PRINT_CSS = '''
<style>
  @page { size: A4; margin: 16mm 15mm 17mm; }
  html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { background: #fff; padding: 0; font-size: 10pt; line-height: 1.5; }
  .masthead { padding-block: 0 16px; }
  .stripe { height: 4px; margin-bottom: 20px; }
  h1 { font-size: 25pt; }
  .lede { font-size: 12pt; margin-bottom: 18px; }
  .meta { margin-bottom: 16px; gap: 8px 24px; }
  .meta dd { font-size: 10pt; }
  .glance { grid-template-columns: repeat(5, minmax(0, 1fr)); }
  .glance .v { font-size: 9pt; }
  .glance .k { font-size: 7.5pt; }
  .glance div { padding: 9px 12px; }
  .internal { font-size: 10pt; }
  .layout { display: block; max-width: none; padding-top: 14px; }
  .toc-wrap { position: static; max-height: none; overflow: visible; background: none; border: 0; padding: 0; margin-bottom: 6px; }
  .toc-title { font-size: 8.5pt; font-weight: 600; letter-spacing: .08em; text-transform: uppercase; color: var(--ink-2); margin: 0 0 6px; }
  .toc ol { list-style: none; margin: 0; padding: 0; display: block; column-count: 2; column-gap: 28px; }
  .toc li { break-inside: avoid; }
  .toc a { padding: 2px 0; font-size: 9.5pt; grid-template-columns: 22px 1fr; }
  .toc-note { margin: 8px 0 0; font-size: 9pt; }
  main { max-width: none; }
  main h2 { font-size: 16pt; margin: 24px 0 10px; padding-top: 12px; break-after: avoid; page-break-after: avoid; }
  main h3 { font-size: 11.5pt; margin: 18px 0 8px; break-after: avoid; page-break-after: avoid; }
  main p, main ul, main ol { max-width: none; }
  main p { margin-bottom: 9px; }
  .table-wrap { overflow: visible; margin: 4px 0 14px; }
  table { font-size: 9pt; line-height: 1.45; }
  th { font-size: 7.5pt; padding: 6px 9px; }
  td { padding: 6px 9px; }
  thead { display: table-header-group; }
  tr, .band, pre { break-inside: avoid; page-break-inside: avoid; }
  .t-req td:last-child, .t-ids td:not(.rid), .t-plain td { min-width: 0; }
  .t-plain td:first-child { min-width: 0; }
  .pill, .rid-chip { font-size: 8pt; padding: 3px 5px 2px; }
  pre { font-size: 8pt; overflow: visible; white-space: pre-wrap; }
  a { text-decoration: none; }
  .foot { margin-top: 22px; font-size: 8.5pt; }
</style>
'''
NAMES = {'toolchain': 'mosquitoalert-app-toolchain-upgrade-spec', 'round1': 'mosquitoalert-app-round1-spec'}
for name in [NAMES[k] for k in (sys.argv[1:] or NAMES)]:
    s = open(f'{SP}/{name}.html').read()
    s = re.sub(r'  @media print \{.*?\n  \}\n', '', s, flags=re.S)
    s = s.replace('<details class="toc" id="toc" open>\n      <summary>Contents</summary>', '<nav class="toc" aria-label="Contents"><p class="toc-title">Contents</p>')
    s = s.replace('</details>\n    <p class="toc-note">', '</nav>\n    <p class="toc-note">')
    s = re.sub(r'<script>.*?</script>\s*$', '', s, flags=re.S)
    s = s.replace('</style>', '</style>' + PRINT_CSS, 1)
    assert '<details class="toc"' not in s and '<script>' not in s
    open(f'{SP}/{name}-print.html', 'w').write(s)
    print('wrote', name)
