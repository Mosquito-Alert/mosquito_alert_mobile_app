# Pending Loco corrections

Every string in `assets/language/` is generated from Localise.biz, so a
correction made only in this repository is temporary: the next
`update_locales.py` run reverts it — and **any git tag push does so
automatically**, because `.github/workflows/update_locales.yml` fires on
`tags: ['*']` and opens an i18n PR from a fresh export.

This file tracks such local-only corrections until they are entered in
Localise.biz. Add a row when one appears; delete it once fixed upstream.

---

## Nothing pending

All 15 corrections (12 Vietnamese, 3 Arabic) were applied upstream in Loco on
2026-09-02 via the API, each verified by read-back, and a CI-style re-export of
both locales reproduced the repo files byte-for-byte. Exports and tag pushes
are safe again.

Before the edits, a full backup was taken with the export key (restorable
without relying on Loco's own revision history, which the API confirmed also
exists — each write returned an incremented `revision`):

- `backups/loco/loco-archive-json-2026-09-02.zip` — per-locale JSON archive
- `backups/loco/all-locales-2026-09-02.json` — all 33 locales x 352 assets
- `backups/loco/assets-metadata-2026-09-02.json` — asset ids, tags, notes
- `backups/loco/pre-edit-snapshot-2026-09-02.json` — verbatim before/after of
  exactly the 15 changed translations

`backups/` is gitignored; copy it somewhere durable. To restore any single
value, POST the `loco_before` string from the snapshot back to
`/api/translations/{key}/{locale}`.

When a new local-only correction appears, add it as a row here (key, Loco
value, local value) until it has been entered in Loco.

---

## Guard before every export
Run this before `update_locales.py` to see whether any pending correction would
be reverted. It needs a Loco API key with read access.

```bash
python3 - <<'PY'
import json, urllib.request, urllib.parse, pathlib
key = pathlib.Path('auth/loco_export_key.txt').read_text().strip()
CHECK = {
  'vi-VN': ['single_mosquito','single_breeding_site','single_bite',
            'auto_tagging_settings_placeholder','auto_tagging_settings_title',
            'terms_and_conditions_txt3','enter_password_title','access_txt',
            'reset','save','terms_and_conditions_txt1','plural_bite'],
  'ar-MA': ['privacy_link','terms_link','lisence_link'],
}
bad = 0
for loc, keys in CHECK.items():
    local = json.load(open(f"assets/language/{loc.replace('-','_')}.json"))
    for k in keys:
        r = urllib.request.Request(
            f'https://localise.biz/api/translations/{urllib.parse.quote(k)}/{loc}')
        r.add_header('Authorization', 'Loco ' + key)
        remote = json.load(urllib.request.urlopen(r)).get('translation', '')
        if remote != local.get(k, ''):
            bad += 1
            print(f'WOULD REVERT  {loc}  {k}')
print('OK — nothing pending' if not bad else f'{bad} correction(s) still only local')
PY
```
