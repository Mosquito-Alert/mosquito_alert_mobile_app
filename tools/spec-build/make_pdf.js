// Render the print-optimised page to PDF with page-numbered footers.
// Uses Playwright's Chromium (install once with: npx playwright-core install chromium).
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

const HERE = __dirname;
const ROOT = path.resolve(HERE, '..', '..');
const OUT = path.join(HERE, 'out');
const version = md => (fs.readFileSync(md, 'utf8').match(/\*\*Version:\*\*\s*([^·\n]+)/) || [])[1]?.trim() || '';

const DOCS = {
  toolchain: {
    md: path.join(ROOT, 'bid-toolchain', 'MosquitoAlert_App_Toolchain_Upgrade_Specifications.md'),
    html: 'mosquitoalert-app-toolchain-upgrade-spec-print.html',
    label: 'Mosquito Alert mobile app · Dependency and Toolchain Upgrade · Specifications for Quotation',
    title: 'Mosquito Alert Mobile App — Dependency and Toolchain Upgrade: Specifications for Quotation',
  },
  round1: {
    md: path.join(ROOT, 'bid-round1', 'MosquitoAlert_App_Round1_Specifications.md'),
    html: 'mosquitoalert-app-round1-spec-print.html',
    label: 'Mosquito Alert mobile app · Round 1 Specifications for Quotation',
    title: 'Mosquito Alert Mobile App — Round 1 Specifications for Quotation',
  },
};
const keys = process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(DOCS);
const jobs = keys.map(k => {
  const d = DOCS[k];
  if (!d) throw new Error(`Unknown document "${k}". Known: ${Object.keys(DOCS).join(', ')}`);
  return { src: path.join(OUT, d.html), out: d.md.replace(/\.md$/, '.pdf'), label: `${d.label} · v${version(d.md)}`, title: d.title };
});

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
  for (const j of jobs) {
    const page = await browser.newPage();
    await page.emulateMedia({ media: 'print', colorScheme: 'light' });
    await page.goto('file://' + j.src, { waitUntil: 'networkidle' });
    await page.evaluate(async t => { document.title = t; await document.fonts.ready; }, j.title);
    await page.pdf({
      path: j.out, format: 'A4', printBackground: true, preferCSSPageSize: true, displayHeaderFooter: true,
      headerTemplate: '<div></div>',
      footerTemplate: `<div style="font-family: Helvetica, Arial, sans-serif; font-size: 7.5px; color: #4B5C57; width: 100%; padding: 0 15mm; display: flex; justify-content: space-between;"><span>${j.label}</span><span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span></div>`,
    });
    console.log('Wrote', path.relative(ROOT, j.out));
    await page.close();
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
