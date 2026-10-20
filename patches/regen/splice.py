"""usage: splice.py SHIPPED_KL REGENERATED_KL OUT -- replace the shipped defuns of shen.by-hypothesis and
shen.search-user-datatypes with the regenerated defuns (wrapper + -h), keeping every other line byte-for-byte."""
import sys, re
shipped, regen, out = sys.argv[1:]
nl = b"\r\n" if b"\r\n" in open(shipped, "rb").read() else b"\n"
S = open(shipped, "rb").read().split(nl); R = open(regen, "rb").read().split(b"\n")
def find(lines, name):
    hits = [i for i, l in enumerate(lines) if l.startswith(b"(defun " + name + b" ")]
    assert len(hits) == 1, (name, hits); return hits[0]
for name in [b"shen.by-hypothesis", b"shen.search-user-datatypes"]:
    i = find(S, name); w = R[find(R, name)]; h = R[find(R, name + b"-h")]
    assert S[i + 1] == b""
    S[i:i + 1] = [w.rstrip(b"\r"), b"", h.rstrip(b"\r")]
open(out, "wb").write(nl.join(S))
