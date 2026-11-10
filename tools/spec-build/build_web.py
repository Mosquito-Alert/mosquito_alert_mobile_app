"""Build the designed web page (HTML) for a specification from its Markdown source.

Usage: python3 build_web.py <toolchain|round1>
The header block (title, dates, at-a-glance facts) lives in CFG below: update it if you change those facts in the Markdown.
"""
import re, subprocess, html, sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
OUT = os.path.join(HERE, 'out')
os.makedirs(OUT, exist_ok=True)
cfg_name = sys.argv[1]
CFG = {
 'round1': dict(
   src=os.path.join(ROOT, 'bid-round1', 'MosquitoAlert_App_Round1_Specifications.md'),
   out='mosquitoalert-app-round1-spec.html',
   title='Mosquito Alert Mobile App Round 1 Specification',
   header='''<header class="masthead">
  <div class="stripe" aria-hidden="true"></div>
  <p class="eyebrow">Specification for quotation <span class="draft">Round 1 · draft</span></p>
  <h1>Mosquito Alert mobile app: seven independent work packages</h1>
  <p class="lede">Maintenance and improvement work on the Mosquito Alert Flutter app for Android and iOS, specified as seven self-contained work packages that can be quoted, awarded, delivered and invoiced separately: a dependency and toolchain upgrade sweep, automated store uploads, native-project fixes, robust report submission, an update prompt, camera improvements and a device test pass.</p>
  <dl class="meta">
    <div><dt>Client</dt><dd>Mosquito Alert · Universitat Pompeu Fabra (UPF)</dd></div>
    <div><dt>Contact</dt><dd>John Palmer · <a href="mailto:john.palmer@upf.edu">john.palmer@upf.edu</a> · <a href="mailto:it@mosquitoalert.com">it@mosquitoalert.com</a></dd></div>
    <div><dt>Quotations due</dt><dd>Fri 27 Nov 2026, 12:00 CET (<a href="#how-to-submit-a-quotation">§12</a>)</dd></div>
    <div><dt>Work period</dt><dd>Kick-off Thu 10 Dec 2026 · delivery by Fri 5 Feb 2027 at the latest, per package</dd></div>
  </dl>
  <div class="glance" role="list" aria-label="At a glance">
    <div role="listitem"><span class="k">Platform</span><span class="v">Flutter · Android and iOS · GPL-3.0</span></div>
    <div role="listitem"><span class="k">Packages</span><span class="v">7, independent · any subset</span></div>
    <div role="listitem"><span class="k">Codebase</span><span class="v">13,500 lines · 77 dependencies · 26 languages</span></div>
    <div role="listitem"><span class="k">Backend</span><span class="v">Out of scope · SDK frozen</span></div>
    <div role="listitem"><span class="k">Requirements</span><span class="v num">{{MUST}} must · {{SHOULD}} should · {{OPTS}} opt.</span></div>
  </div>
</header>''',
   tocnote='<p class="toc-note">The code and the issues cited are in the public repository <code>github.com/Mosquito-Alert/mosquito_alert_mobile_app</code>. No attachments.</p>'),
 'toolchain': dict(
   src=os.path.join(ROOT, 'bid-toolchain', 'MosquitoAlert_App_Toolchain_Upgrade_Specifications.md'),
   out='mosquitoalert-app-toolchain-upgrade-spec.html',
   title='Mosquito Alert Mobile App Dependency and Toolchain Upgrade Specification',
   header='''<header class="masthead">
  <div class="stripe" aria-hidden="true"></div>
  <p class="eyebrow">Specification for quotation</p>
  <h1>Mosquito Alert mobile app: dependency and toolchain upgrade</h1>
  <p class="lede">One package of work on the Mosquito Alert Flutter app for Android and iOS: bring Flutter, the build tooling and every package up to date in a single verified sweep, with no change in what the app does and no loss of users' accounts or data when they update.</p>
  <dl class="meta">
    <div><dt>Client</dt><dd>Mosquito Alert · Universitat Pompeu Fabra (UPF)</dd></div>
    <div><dt>Contact</dt><dd>John Palmer · <a href="mailto:john.palmer@upf.edu">john.palmer@upf.edu</a> · <a href="mailto:it@mosquitoalert.com">it@mosquitoalert.com</a></dd></div>
    <div><dt>Quotations due</dt><dd>Tue 17 Nov 2026, 12:00 CET (<a href="#how-to-submit-a-quotation">§10</a>)</dd></div>
    <div><dt>Work period</dt><dd>Kick-off Fri 20 Nov 2026 · delivery by Fri 15 Jan 2027 at the latest</dd></div>
  </dl>
  <div class="glance" role="list" aria-label="At a glance">
    <div role="listitem"><span class="k">Platform</span><span class="v">Flutter · Android and iOS · GPL-3.0</span></div>
    <div role="listitem"><span class="k">Scope</span><span class="v">One package · one contractor</span></div>
    <div role="listitem"><span class="k">Codebase</span><span class="v">13,500 lines · 55 packages, 39 behind</span></div>
    <div role="listitem"><span class="k">Backend</span><span class="v">Out of scope · SDK unchanged</span></div>
    <div role="listitem"><span class="k">Requirements</span><span class="v num">{{MUST}} must · {{SHOULD}} should</span></div>
  </div>
</header>''',
   tocnote='<p class="toc-note">The code, issues and pull requests cited are in the public repository <code>github.com/Mosquito-Alert/mosquito_alert_mobile_app</code>. No attachments.</p>'),
}[cfg_name]

body = subprocess.run(['pandoc', CFG['src'], '-t', 'html5', '--wrap=none'], capture_output=True, text=True, check=True).stdout
body = body[body.index('<h2'):]
ack_i = body.rfind('<p><em>Mosquito Alert is coordinated')
if ack_i > 0: body = body[:ack_i]
body = body.replace('<hr />', '')

toc = []
def h2(m):
    hid, num, text = m.group(1), m.group(2), m.group(3)
    num = num.replace('Appendix ', '')
    toc.append((hid, num, re.sub('<[^>]+>', '', text)))
    return f'<h2 id="{hid}"><span class="secno">{num}</span><span>{text}</span></h2>'
body = re.sub(r'<h2 id="([^"]+)">(\d+|Appendix [A-Z])\. (.*?)</h2>', h2, body)
body = re.sub(r'<h3 id="([^"]+)">([A-Z]?\d*\.\d+) (.*?)</h3>', r'<h3 id="\1"><span class="subno">\2</span> \3</h3>', body)

must = len(re.findall(r'<td>MUST</td>', body))
should = len(re.findall(r'<td>SHOULD</td>', body))
opts = len(set(re.findall(r'<td>(?:<strong>)?(OPT-\d\d)(?:</strong>)?</td>', body)))

body = re.sub(r'<td>(MUST|SHOULD)</td>', lambda m: f'<td class="pri"><span class="pill pill-{m.group(1).lower()}">{m.group(1)}</span></td>', body)
body = re.sub(r'<td>(?:<strong>)?((?:[A-Z0-9]{2,5}-\d\d)|D-\d\d)(?:</strong>)?</td>', r'<td class="rid"><span class="rid-chip">\1</span></td>', body)
body = body.replace('<li><strong>MUST</strong>:', '<li><span class="pill pill-must">MUST</span>')
body = body.replace('<li><strong>SHOULD</strong>:', '<li><span class="pill pill-should">SHOULD</span>')

body = re.sub(r'<colgroup>.*?</colgroup>', '', body, flags=re.S)
body = re.sub(r'<table style="[^"]*">', '<table>', body)  # pandoc adds a width style to tables with relative column widths
def wrap_table(m):
    t = m.group(0)
    kind = 'req' if '<th>ID</th>' in t and '<th>Priority</th>' in t else ('ids' if '<th>ID</th>' in t else 'plain')
    return f'<div class="table-wrap"><table class="t-{kind}">' + t[len('<table>'):] + '</div>'
body = re.sub(r'<table>(?:(?!</table>).)*?<th>At a glance</th>.*?</table>', '', body, flags=re.S)
body = re.sub(r'<table>.*?</table>', wrap_table, body, flags=re.S)

toc_html = ''.join(f'<li><a href="#{i}"><span class="toc-no">{n}</span>{html.escape(t)}</a></li>' for i, n, t in toc)
tpl = open(os.path.join(HERE, 'template.html')).read()
out = (tpl.replace('{{HEADER}}', CFG['header']).replace('{{TOCNOTE}}', CFG['tocnote']).replace('{{TITLE}}', CFG['title'])
          .replace('{{BODY}}', body).replace('{{TOC}}', toc_html)
          .replace('{{MUST}}', str(must)).replace('{{SHOULD}}', str(should)).replace('{{OPTS}}', str(opts)))
assert '{{' not in out, re.findall(r'\{\{\w+\}\}', out)
open(os.path.join(OUT, CFG['out']), 'w').write(out)
print(cfg_name, 'must', must, 'should', should, 'opts', opts, 'toc', len(toc), 'bytes', len(out))
