# README i18n Maintenance

Secret Wallet uses `README.md` as the single source of truth.

Supported translations:
- `README.ko.md`
- `README.ja.md`
- `README.zh-CN.md`
- `README.fr.md`
- `README.de.md`

## Sync rules

1. Update `README.md` first.
2. Port the same changes to all translation files.
3. Keep command examples and option flags exactly identical to English.
4. Keep section hierarchy identical (`##` / `###` order).
5. Update the metadata line in each translation:

```md
> Last synced with `README.md` commit: `<commit-sha>`
```

## Validation

Run:

```bash
./scripts/check-readme-i18n.sh
```

This check validates:
- translation files exist
- language selector exists
- sync metadata line exists
- section heading structure matches the English README
