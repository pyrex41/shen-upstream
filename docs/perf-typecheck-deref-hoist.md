# Experiment: dereference once, outside the type checker's search loops

**Status: experiment branch, not an upstream proposal.** `master` in this repository is a
byte-for-byte mirror of Mark Tarver's S-series uploads (see `PROVENANCE.md`) and is never
changed by this branch. Nothing here has been sent to Shen-Language, Mark Tarver or any port
maintainer.

## The change

Two predicates in `Sources/t-star.shen` loop over a list and, on every iteration,
re-dereference (that is, copy) a term that cannot have changed since the loop was entered:

| predicate | loops over | re-derefs per iteration (KL as shipped) |
|---|---|---|
| `shen.search-user-datatypes P Hyp Datatypes` | every user datatype | `(shen.deref P B)` and `(shen.deref Hyp B)` in `(call (((shen.deref Fn B) (shen.deref P B)) (shen.deref Hyp B)) ...)` |
| `shen.by-hypothesis X A Hyps` | every hypothesis | `(shen.deref X B)` in `(when (= (shen.deref X B) (shen.deref Y B)) ...)` |

`defprolog` compiles every variable in a function-call argument into a full `deref`, which
walks and copies the whole term. When the expression being type checked is large, as with big
literals, this copying dominates type checking. In shen-scheme on one workload, 99% of the
nodes `shen.deref` visited came from these two call sites (measurements below).

Each predicate becomes a plain `define` that takes the Prolog plumbing arguments
(`Bindings Lock Key Continuation`, the same idiom the file already uses for `sigf`). The
`define` derefs the term once and hands it to a `-h` predicate. The `-h` predicate is the old
`defprolog` with the term marked `(0 ...)`, so it is passed through without a further deref:

```shen
(define by-hypothesis
  X A Hyp Bindings Lock Key Continuation
  -> (by-hypothesis-h (deref X Bindings) A Hyp Bindings Lock Key Continuation))

(defprolog by-hypothesis-h
 X A (- [[Y Colon B] | _]) <-- (when (= Colon (intern ":"))) (when (= (0 X) Y)) (is! A B);
 X A (- [_ | Hyp])         <-- (by-hypothesis-h X A Hyp);)

(define search-user-datatypes
  P Hyp Datatypes Bindings Lock Key Continuation
  -> (search-user-datatypes-h (deref P Bindings) (deref Hyp Bindings) Datatypes
                              Bindings Lock Key Continuation))

(defprolog search-user-datatypes-h
   P Hyp (- [[_ | Fn] | _]) <-- (call (Fn (0 P) (0 Hyp)));
   P Hyp (- [_ | Ds]) <-- (search-user-datatypes-h P Hyp Ds);)
```

The remaining per-iteration derefs, of the hypothesis `Y` and of the datatype's rule `Fn`, are
of different terms on each iteration, so they stay.

The generated `-h` defuns are the old ones with `V_x` in place of `(shen.deref V_x B)`. The
`shen.incinfs` calls, the `shen.unlocked?` checks, clause order and arities are unchanged.

## Why this preserves behaviour

The claim: at the start of every iteration, `(deref T B)` returns a term structurally equal to
`(deref T B)` at loop entry. Given that, computing it once is equivalent, because `deref` is
pure and conses are never mutated.

The binding store `B` is a vector that only these `Sources/prolog.shen` functions write:

1. **`bind!`** (`prolog.shen`, `bind!`/`bindv`/`unwind`) writes a variable's slot, thaws the
   continuation, and if the result is `false` writes `-null-` back into the slot before
   returning `false`. It is only reached through `lzy=`, `lzy=!` and `bind`, and those only
   bind a term that `lazyderef` returned as a variable, which means an unbound one. Unwinding
   therefore restores exactly the state before the bind.
2. **A loop iteration moves on only if the previous one returned `false`.** In both compiled
   predicates, the second clause runs only when `(= W false)` holds for the first. A
   non-`false` result returns straight out of the loop, so no later iteration runs. Every
   `false` that reaches the loop has come back through every `bind!` made during the failed
   attempt, each of which unwound its own binding. So `B` is the same at the start of every
   iteration, at least on the slots of variables that existed at loop entry.
3. **`overbind`** (used by `findall`) writes with `bindv` and does not unwind. It only writes
   the `Store` variable that `findall` creates with `(is Store [])` after loop entry, so that
   variable cannot occur in a term dereferenced at entry. `Store`'s own binding is undone when
   that `is` unwinds through `bind!`.
4. **`newpv` and `gc` (tickets)** allocate fresh variables and give back their slot numbers on
   failure. A term dereferenced at entry only contains variables allocated before entry, whose
   slot numbers are below the entry ticket, so slot reuse after entry cannot reach them. Each
   new variable's slot is set to `-null-` when allocated (`nextticket`).
5. **Cut and lock:** neither predicate contains a cut, so the original compiled code does not
   increment `Key`, and the wrapper passes `Lock` and `Key` through unchanged. When a callee
   closes the lock, the `shen.unlocked?` tests in the `-h` loop see it exactly as before.

**Extra work, not a change in behaviour:** when the lock is already closed at entry, or the list
is empty, the wrapper derefs once where the original did not deref at all. `deref` is pure, so
this costs a little work but cannot change a result.

**Empirical check:** under SBCL, `Test Programs/runme.shen` produces byte-identical output for
the base and patched kernels apart from `run time:` lines (134 passed, 0 failed in both), and
that includes the inference count printed for every typechecked test program.

## What the branch contains

| path | what |
|---|---|
| `Sources/t-star.shen` | the source change above (CRLF line endings kept) |
| `KLambda/t-star.kl` | the shipped file with exactly two defuns, `shen.by-hypothesis` and `shen.search-user-datatypes`, replaced by the four regenerated defuns (each wrapper and its `-h`). Every other line is byte-identical to `master`. |
| `patches/regen/regen-s42.sh` | regenerates `Sources/*.kl` with the kernel's own `make.shen` under SBCL |
| `patches/regen/splice.py` | does the two-defun replacement from a regenerated file |
| `patches/shenoskernel-43.1/typecheck-deref-hoist.patch` | the same change for the community ShenOSKernel 43.1 (`sources/t-star.shen` and `klambda/t-star.kl`), applied with `patch -p1` in the kernel root |
| `patches/shenoskernel-43.1/t-star.kl`, `t-star.shen` | the two files of 43.1 after that patch, ready to drop in |

### How the KL was produced (not hand-written)

**S42.** `patches/regen/regen-s42.sh OUT` copies the checkout and boots the kernel under SBCL
2.6.8 (`nix shell nixpkgs#sbcl`, store path `/nix/store/6ghx7ifbm1j2ljq1v705zn9izqb4k5m4-sbcl-2.6.8`),
using `install.lsp` up to its `FMAKUNBOUND` line followed by
`(cd "Sources/") (load "make.shen") (make)`.
- **Pristine sources:** the run reproduces all 15 shipped `KLambda/*.kl` files. yacc, core, load,
  prolog, reader and sequent come out byte-identical. The rest differ only in gensym numbering
  (`V4446` versus `V4448` and so on; the offset begins in `sys.kl`), and are identical once every
  `[A-Za-z]+[0-9]{3,}` is replaced with one symbol.
- **Patched sources:** compared with the pristine regeneration under that normalisation, the
  only difference in any file is the four `t-star.kl` defuns.

The committed `KLambda/t-star.kl` is a splice: `splice.py KLambda/t-star.kl OUT/Sources/t-star.kl`
puts the four regenerated defuns verbatim in place of the two shipped ones and leaves every
other line alone. That keeps the diff to the changed functions, where a full regeneration would
renumber every variable in the file. The splice and the full regeneration are identical under the
normalisation above. Variable names in KL are local to each defun, so the mixed numbering is
harmless.

**43.1.** The 43.1 kernel's own route is `make klambda-kernel`, which runs
`shen-scheme eval -l make.shen -e "(make)"`. It was run with a shen-scheme 0.52 binary running kernel
43.1. The pristine 43.1 tree was verified against the release archive
(`ShenOSKernel-43.1.tar.gz`, sha256 `900eedef44f440af78f9395ed06e689ce1604546fc309f5bc7c8bc84cc651920`).
- **Pristine sources:** reproduces all 21 kernel `.kl` files (`stlib.kl` is a separate target and
  untouched) byte-identical or identical under the normalisation.
- **Patched sources:** the only difference is the same four defuns in `t-star.kl`.

The patch's `klambda/t-star.kl` is spliced in the same way.

| file | sha256 |
|---|---|
| 43.1 pristine `klambda/t-star.kl` | `2d77020564e9f2bcb94fa4850f2ee4191d36b15fb2eae9e9a3523b36945d6256` |
| 43.1 pristine `sources/t-star.shen` | `20c1a50c87a4db2733f91a59f4d5f311e4a985691368bf87a0d4c715c0f490b9` |
| 43.1 patched `klambda/t-star.kl` | `a0cedbb0334eb7f66fe5e2296056ea66d1e2f42c9efe176f6d1be2f0b28bf2ec` |
| 43.1 patched `sources/t-star.shen` | `b0016aa6ee0cc45905c7859ed4694eda4e0cd3b6ab2dd1d69f01d81b8245e9df` |

## Measurements

### Prior measurement: shen-scheme with kernel 42.2, KL hand-patched

These numbers come from before this branch. They used the same four defuns, hand-written in KL
and compiled with shen-scheme's own KL-to-Scheme compiler, on the capcov `b-typed` workload,
which typechecks large signature literals.

- **Instrumentation:** 5.55 M top-level `shen.deref` calls visited 2.60 G nodes and copied 1.30 G
  cons cells, about 21 GB of the run's 28 GB allocation. 99% of the nodes in large derefs came
  from `search-user-datatypes` (71%) and `by-hypothesis` (28%). The occurs check accounted for only
  0.69 M nodes.
- **Timing:** 2 interleaved rounds. b-typed CPU went from 8.07 s to 5.79 s (-28%) and from 8.93 s
  to 4.96 s (-44%) with both hoists.
- **Correctness:** payloads were byte-identical on 8/8 workloads, and `make test` passed 134 with
  0 failures.

### Ports with this branch's kernel change

Appended below as each port is measured.
