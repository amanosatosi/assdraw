# ASSDraw

ASSDraw is a small standalone editor for ASS vector drawings, modernized from
the historical Aegisub ASSDraw source.  It deliberately has no Aegisub IPC or
embedding code: create/edit a shape, then copy the generated ASS text into an
ASS editor.

## Windows builds

The supported build is CMake with current MSYS2 MinGW-w64 and wxWidgets 3.2.
The renderer is the pinned AGG 2.6 source dependency declared in CMake; it is
fetched and built by CMake rather than relying on an obsolete system package.
GitHub Actions is the authoritative compiler and test environment. The Windows
workflow installs dependencies, configures CMake, builds, runs the
non-interactive core tests, verifies `assdraw.exe`, and uploads
`ASSDraw-windows-x64`.

For a local development environment (not required to use the CI artifacts),
install the MSYS2 packages named in `.github/workflows/windows.yml`, then use
CMake/Ninja in an MSYS2 MinGW64 shell. Generated project files are not kept in
the repository; historical Autotools, Dev-C++, and Visual Studio project files
remain only as reference.

The portable artifact contains `assdraw.exe`, the non-system MinGW/wxWidgets
runtime DLLs reported by `ldd`, and the project notice files.

## Drawing, background tracing, and undo

The editor retains the historical `m`, `l`, `b`, and optional spline command
workflow, including point/handle editing, transformations, canvas pan/zoom,
background-image loading, placement, scaling, opacity, and the command-text
clipboard workflow.  Point and Bezier-handle markers, including their drag
targets, retain a usable on-screen size when the canvas is zoomed out.

The **Drawing commands** pane has a direct **Copy ASS** action. Pressing Enter
in the pane applies its contents; newlines and tabs are treated as whitespace,
so formatted command text cannot join and corrupt adjacent draw commands.

**Coloring** mode selects only a filled area of the current drawing (an
oppositely-wound hole is not selectable). Double-click the selected area to
open the native Windows color selector for the fill. This changes `\1c` only:
ASS drawing coordinates are unchanged, although an enabled `\bord` naturally
extends pixels around the same coordinates. Each separate visible sub-shape
has its own fill/outline style and is exported as its own complete ASS drawing
run; directly nested reverse-winding contours remain attached to their outer
sub-shape as holes.

Drawing undo history now contains only drawing/document state.  Background
image identity, placement, scale, and opacity are reference/view state, so
normal Ctrl+Z/Ctrl+Y cannot reload or move a tracing image.  Canvas view state
is likewise not restored by drawing undo.

## Shape styling and output

The **Shape** section in the existing Settings pane controls enabled state,
RGB color, and opacity for fill and outline, plus outline width.  Changes apply
immediately to the canvas.  Colors are serialized as ASS BGR values
(`&HBBGGRR&`); the UI's opacity is converted to ASS alpha (`00` opaque, `FF`
transparent).  Output is kept separate from geometry and has the form:

```
{\p1\bord3.00\1c&H42A5F5&\1a&H00&\3c&HFFFFFF&\3a&H00&}
m 100 100 l 300 100 l 300 300 l 100 300
```

Disabled fill is emitted as `\1a&HFF&`; disabled outline uses `\bord0` and
`\3a&HFF&`, allowing fill-only, fill-plus-outline, and outline-only drawings
without mixing override tags into the stored vector command list.

## Licensing

Read `LICENSE` and `NOTICE.md` before redistributing.  In particular, the
AGG-derived spline files retain their own GPL notices; their exact relationship
to the historical external AGG dependency was not documented upstream and is
not relabelled here.
