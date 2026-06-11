# Provenance

This repository tracks the **canonical S41.1 distribution** of Shen as
published on [shenlanguage.org](https://shenlanguage.org/download.html).

- **Source:** <https://www.shenlanguage.org/Download/S41.1.zip>
- **SHA-256 of zip:** `1f35106aad6d4fa0208a3462484171f60c4d9ecb62823a60a57e9cb4e11ec3cc`
- **Retrieved:** 2026-06-11
- **Author:** Mark Tarver — Shen S41.1 for SBCL (Windows), based on kernel
  S41 and a standard installation of SBCL 2.0.0. See `README.txt` and the
  BSD 3-clause `LICENSE` files in each subdirectory.

The repository root corresponds to the `S41.1/S41/` directory inside the
zip — the "home directory" referenced by the official install instructions
(`(load "install.lsp")` from an SBCL REPL started here).

## Branch policy

- `master` holds the canonical distribution as published. The byte-for-byte
  import is tagged [`s41.1-pristine`](../../releases/tag/s41.1-pristine);
  the only changes on `master` beyond it are documentation like this file.
- All improvements, fixes, and experiments live on feature branches.
