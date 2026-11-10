# Specification build

Turns a Markdown specification for quotation into a designed web page and a PDF.

| Document | Source (edit this) | PDF (generated) | Web page (generated) |
|---|---|---|---|
| `toolchain` | `bid-toolchain/MosquitoAlert_App_Toolchain_Upgrade_Specifications.md` | same name, `.pdf`, next to the source | `tools/spec-build/out/mosquitoalert-app-toolchain-upgrade-spec.html` |
| `round1` (draft, seven work packages) | `bid-round1/MosquitoAlert_App_Round1_Specifications.md` | same name, `.pdf`, next to the source | `tools/spec-build/out/mosquitoalert-app-round1-spec.html` |

Run `./tools/spec-build/build.sh` to build the `toolchain` document, or name the documents to build: `./tools/spec-build/build.sh round1`. It needs pandoc, python3 and node. The first run installs `playwright-core`. If Chromium is missing, run `npx playwright-core install chromium` in this folder.

**Header facts are not read from the Markdown.** The title, dates, work period and "at a glance" boxes at the top of the page are set per document in `CFG` in `build_web.py`. If you change those facts in the Markdown, update them there too. The requirement counts and the PDF footer version are read from the Markdown automatically.

To add a document, add an entry to `CFG` in `build_web.py`, to `NAMES` in `make_print.py` and to `DOCS` in `make_pdf.js`.

The tooling was first written for the H-MIP project (github.com/h-mip) and reused for the Mosquito Alert website specification; it is reused here with only the configuration changed.
