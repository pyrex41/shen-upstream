# Shen — canonical mirror of Mark Tarver's distributions

This repository mirrors the Shen distributions Mark Tarver publishes on
[shenlanguage.org](https://shenlanguage.org/download.html), byte-for-byte.
It exists so that downstream projects (the [ratatoskr](https://github.com/pyrex41/ratatoskr)
tree-shaker and the `shen-*` ports) can pin their kernel provenance to a
git tag + commit instead of a zip URL — upstream reuses the same zip
filename for in-place updates, so a URL alone never identifies content.

**`master` = the latest upload, pristine.** Currently:

| import | tag | source | sha256 |
|---|---|---|---|
| **S42.0 (2026-08-25 release)** — current | `s42-pristine-20260825` | [S42.zip](https://www.shenlanguage.org/Download/S42.zip) | `30abdc7e…4dfb23` |
| **S41.2 (2026-07-11 refresh)** — current | `s41.2-pristine-20260711` | [S41.2.zip](https://www.shenlanguage.org/Download/S41.2.zip) | `51becbfd…3ee836` |
| S41.1 | `s41.1-pristine` | S41.1.zip | `1f35106a…1ec3cc` |

Earlier imports stay available via their tags; check out
`s41.1-pristine` if you need 41.1. Full per-import details, retrieval
dates, and the **S-series vs community-ShenOSKernel lineage note** (two
lineages share a version-numbering scheme; don't mix files across them)
are in [`PROVENANCE.md`](PROVENANCE.md).

## What's in the distribution

The repo root is the `S42/` "home directory" from the zip:

- `KLambda/` — the kernel as 15 KLambda files, including `backend.kl`
  (the Kλ→Common Lisp compiler, in-kernel since S41.1)
- `Sources/` — the kernel's Shen sources (`make.shen` regenerates KLambda)
- `Lib/StLib/` — the standard library (lazily loaded Shen sources)
- `Lib/` — Concurrency, Encrypt, IDE, LogicLab, THORN, Tk
- `Primitives/`, `Test Programs/`, `install.lsp`, `backend.lsp`

To install under SBCL, start SBCL here and `(load "install.lsp")` —
Tarver's own instructions are in [`README.txt`](README.txt) (written for
Windows; SBCL itself is cross-platform).

## Branch policy

- `master` holds the current upstream distribution byte-for-byte, one
  tagged commit per import; the only other changes on `master` are
  documentation (this file, `PROVENANCE.md`).
- Improvements, fixes, and experiments live on feature branches.

## License

Shen is © Mark Tarver, released under the BSD 3-clause license — see the
`LICENSE` files in the distribution. This mirror redistributes it
unmodified under the same terms.
