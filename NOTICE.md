# Notices and attribution

ASSDraw is a standalone modernization of the historical Aegisub ASSDraw
project, originally written by ai-chan (2006–2007).  Historical source headers,
attribution, and the BSD 3-Clause licence notice are retained unchanged.

`src/agg_bcspline.*`, `src/agg_conv_bcspline.h`, and
`src/agg_vcgen_bcspline.*` retain their upstream Anti-Grain Geometry notices:
Copyright (C) 2002–2006 Maxim Shemanarev.  Those files explicitly state GNU GPL
version 2 or later.  The original project did not include a root-level copy of
the corresponding GPL text or document the licensing relationship with the
system `libagg` dependency; this repository records that fact rather than
assigning a new licence to it.

Portable Windows artifacts include this notice and `LICENSE`.  They link the
MSYS2 `wxWidgets` and `agg` packages.  Their package-provided licence files
remain available from the corresponding MSYS2 packages; the CI workflow does
not claim to relicense them.
