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

The Windows build fetches the AGG 2.6 fork at commit
`c4f36b4432142f22c0bf82c6fbdb41567a236be2`, whose upstream documentation says
it is based on AGG 2.4 under the historical permissive AGG licensing.  Its
`copying` file is included in portable artifacts.  This does not alter the GPL
notices retained in ASSDraw's historical AGG-derived spline files.
