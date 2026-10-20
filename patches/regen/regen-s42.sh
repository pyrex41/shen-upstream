#!/bin/sh
# usage: patches/regen/regen-s42.sh OUTDIR
# Boots the S42 kernel from this checkout's KLambda/ under SBCL (install.lsp up to its
# FMAKUNBOUND line, i.e. without the Lib/ install or the image save), then runs the kernel's own
# Sources/make.shen, which writes Sources/*.kl. Everything happens in a copy under OUTDIR.
# SBCL comes from `nix shell nixpkgs#sbcl` unless SBCL is set (measured with SBCL 2.6.8,
# /nix/store/6ghx7ifbm1j2ljq1v705zn9izqb4k5m4-sbcl-2.6.8).
set -e
OUT=$1; [ -n "$OUT" ] || { echo "usage: $0 OUTDIR" >&2; exit 2; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
rm -rf "$OUT"; mkdir -p "$OUT"
(cd "$ROOT" && git ls-files -z | xargs -0 tar cf -) | tar xf - -C "$OUT"
cd "$OUT"
rm -f Sources/*.kl
sed -n '1,/FMAKUNBOUND/p' install.lsp > boot.lsp
printf '(cd "Sources/")\n(load "make.shen")\n(make)\n(SB-EXT:EXIT)\n' >> boot.lsp
if [ -n "$SBCL" ]; then "$SBCL" --non-interactive --load boot.lsp > regen.log 2>&1
else nix shell nixpkgs#sbcl -c sbcl --non-interactive --load boot.lsp > regen.log 2>&1; fi
ls Sources/*.kl
