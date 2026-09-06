#include "drawing_history.hpp"
#include "shape_style.hpp"

#include <cassert>
#include <string>

struct DrawingSnapshot { std::string geometry; };
struct ReferenceImageState {
    int x;
    int y;
    double scale;
    int opacity;
};

int main()
{
    assert(AssColorFromRgb({255, 0, 0}) == "&H0000FF&");
    assert(AssColorFromRgb({0, 255, 0}) == "&H00FF00&");
    assert(AssColorFromRgb({0, 0, 255}) == "&HFF0000&");
    assert(AssAlphaFromOpacity(255) == "&H00&");
    assert(AssAlphaFromOpacity(0) == "&HFF&");

    ShapeStyle style;
    style.fill_color = { 0xF5, 0xA5, 0x42 };
    style.outline_enabled = true;
    style.outline_width = 3;
    assert(style.SerializeOverrideTags() == "{\\p1\\bord3.00\\1c&H42A5F5&\\1a&H00&\\3c&H000000&\\3a&H00&}");

    DrawingHistory<DrawingSnapshot> history;
    const ReferenceImageState background { 47, -19, 1.75, 63 };
    DrawingSnapshot drawing { "m 0 0 l 10 0" };
    history.Push(drawing);
    drawing.geometry = "m 0 0 l 10 0 l 10 10";
    history.Push(drawing);
    drawing.geometry = "m 0 0 l 10 0 l 10 10 l 0 10";

    DrawingSnapshot restored;
    assert(history.Undo(drawing, restored));
    drawing = restored;
    assert(drawing.geometry == "m 0 0 l 10 0 l 10 10");
    assert(background.x == 47 && background.y == -19 && background.scale == 1.75 && background.opacity == 63);
    assert(history.Undo(drawing, restored));
    drawing = restored;
    assert(drawing.geometry == "m 0 0 l 10 0");
    assert(background.x == 47 && background.y == -19 && background.scale == 1.75 && background.opacity == 63);
    assert(history.Redo(drawing, restored));
    drawing = restored;
    assert(drawing.geometry == "m 0 0 l 10 0 l 10 10");
    assert(background.x == 47 && background.y == -19 && background.scale == 1.75 && background.opacity == 63);
}
