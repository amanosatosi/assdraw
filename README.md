# ASSDraw

ASSDraw is a small standalone editor for ASS vector drawings, modernized from
the historical Aegisub ASSDraw source.  It deliberately has no Aegisub IPC or
embedding code: create/edit a shape, then copy the generated ASS text into an
ASS editor.

## Windows builds

The supported build is 64-bit MSVC through CMake. wxWidgets 3.2.11 and AGG are
pinned source dependencies, built as static libraries together with their
bundled dependencies. Release targets use the static MSVC runtime (`/MT`), so
the distributable application is the single file `ASSDraw3.exe`.

The normal build interface from a Visual Studio developer environment is:

```powershell
cmake -S . -B build -A x64
cmake --build build --config Release
```

The executable is written to `build/Release/ASSDraw3.exe`. The historical
Autotools, Dev-C++, and Visual Studio 2008 files remain as reference, but they
are not the supported Windows build.

GitHub Actions is the authoritative compiler and test environment. The Windows
workflow builds with Visual Studio 2022, runs the non-interactive tests, audits
the EXE imports with `dumpbin`, verifies the embedded icon/version/manifest,
launches the EXE from an otherwise empty temporary directory, and uploads
`ASSDraw3.exe` as the only file in the `ASSDraw3-windows-x64` artifact.

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
extends pixels around the same coordinates. Differently-styled contours use
separate ASS drawing runs, while adjacent contours with the same effective
style share one run. ASS lays separate drawing runs out inline, so ASSDraw
offsets their serialized X coordinates by prior run advances to keep every
contour in the editor's shared logical coordinate system. Directly nested
reverse-winding contours remain in their outer contour's run as holes.

Drawing undo history now contains only drawing/document state.  Background
image identity, placement, scale, and opacity are reference/view state, so
normal Ctrl+Z/Ctrl+Y cannot reload or move a tracing image.  Canvas view state
is likewise not restored by drawing undo.

## Shape styling and output

The **Coloring** mode is the compact shape-styling workflow: click a visible
sub-shape, then double-click it to choose its fill color. Colors are
serialized in canonical uppercase ASS BGR form (`&HBBGGRR&`); the UI's opacity
is converted to uppercase ASS alpha (`&H00&` opaque, `&HFF&` transparent).
Copied ASS is one physical line suitable for one event text field. Multiline
whitespace remains accepted on import. Output is kept separate from geometry
and has the form:

```
{\p1\bord3.00\1c&H42A5F5&\1a&H00&\3c&HFFFFFF&\3a&H00&}m 100 100 l 300 100 l 300 300 l 100 300
```

Disabled fill is emitted as `\1a&HFF&`; disabled outline uses `\bord0` and
`\3a&HFF&`, allowing fill-only, fill-plus-outline, and outline-only drawings
without mixing override tags into the stored vector command list.

## Licensing

Read `LICENSE` and `NOTICE.md` before redistributing.  In particular, the
AGG-derived spline files retain their own GPL notices; their exact relationship
to the historical external AGG dependency was not documented upstream and is
not relabelled here.
