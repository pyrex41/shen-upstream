# Provenance

This repository is the **canonical mirror of Mark Tarver's Shen
distributions** as published on
[shenlanguage.org](https://shenlanguage.org/download.html). `master` always
holds the latest upload, byte-for-byte; each import is tagged. Downstream
repos (ratatoskr, the shen-* ports) should cite the tag + commit here as
their kernel source of truth rather than the raw zip URL.

## Imports (newest first)

### S42.0 — 2026-08-25 release (tag `s42-pristine-20260825`)

- **Source:** <https://www.shenlanguage.org/Download/S42.zip>
- **SHA-256 of zip:** `30abdc7e5a1e27b7a20109c1ed141e4712885e31f24d9710d16415fbbd4dfb23`
- **Retrieved:** 2026-08-27
- **Contents:** exact `S42/` directory from the official archive; no source
  files were modified.

### S41.2 — 2026-07-11 refresh (tag `s41.2-pristine-20260711`)

- **Source:** <https://www.shenlanguage.org/Download/S41.2.zip>
- **Last-Modified (server):** Sat, 11 Jul 2026 04:36:00 GMT
- **SHA-256 of zip:** `51becbfd60fa8c93c3f8ae5b20b948eaa84c4b1d14ad2f5d2a056002a53ee836`
- **Retrieved:** 2026-07-14
- **Caveat:** upstream reuses the `S41.2.zip` filename for in-place
  updates; the version number alone does not identify the content — cite
  the sha256 or this repo's tag. Delta vs S41.1: 6 KLambda files touched
  (backend, declarations, macros, t-star, types, writer — 85 lines
  changed), the standard library reorganised under `Lib/StLib/`
  (previously spread under `Lib/` directly), plus install updates. This is
  the upload accompanying Tarver's new stlib and his 64-LOC Warshall
  `fdg.shen`.

### S41.1 (tag `s41.1-pristine`)

- **Source:** <https://www.shenlanguage.org/Download/S41.1.zip>
- **SHA-256 of zip:** `1f35106aad6d4fa0208a3462484171f60c4d9ecb62823a60a57e9cb4e11ec3cc`
- **Retrieved:** 2026-06-11
- **Author:** Mark Tarver — Shen S41.1 for SBCL (Windows), based on kernel
  S41 and a standard installation of SBCL 2.0.0. See `README.txt` and the
  BSD 3-clause `LICENSE` files in each subdirectory.

## Lineage note

### S42 certification errata

The initial ShenOSKernel-42 certification script included four assertions
that do not describe the canonical S42 S-series kernel: one expected
`update-lambda-table` to delete a `shen.lambda-form` property, and three
called the private `shen.variancy-signature` helper (which S42 does not
export).  S42's public `fn`/lambdatable and `variancy` behavior is intentional
and is covered by the regression cases in `Test Programs/kerneltests.shen`.
The pristine import and its KLambda sources remain byte-for-byte unchanged.

Tarver's S-series distributions (this repo) and the community
**ShenOSKernel** releases (github.com/Shen-Language/shen-sources, e.g.
`shen-41.2`) are **different lineages** that share a version numbering
scheme. The S-series kernel is 15 KLambda files with the Common Lisp
backend in-kernel (`backend.kl`), no `dict.kl`/`init.kl`/`stlib.kl`
(pointer-based dicts, initialisation in `declarations.kl`/`toplevel.kl`,
stlib as lazy sources under `Lib/StLib/`). The community lineage carries
`dict.kl`, `init.kl`, a compiled `stlib.kl` and the `extension-*.kl`
additions. At the defun level the shared kernel differs in ~156 of 672
functions (measured 2026-07-14 against ShenOSKernel-41.2). Do not mix
files across lineages without noting it.

The repository root corresponds to the `S42/` directory inside the zip —
the "home directory" referenced by the official install instructions
(`(load "install.lsp")` from an SBCL REPL started here).

## Branch policy

- `master` holds the canonical distribution as published, byte-for-byte,
  tagged per import; the only changes on `master` beyond the imports are
  documentation like this file.
- All improvements, fixes, and experiments live on feature branches.
