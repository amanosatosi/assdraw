// ASSDraw shape style model and ASS override-tag serialization.
// New code in this file is licensed under the BSD 3-Clause License; see LICENSE.
#include "shape_style.hpp"

#include <algorithm>
#include <cstdio>
#include <cstdlib>

namespace {

bool ReadHexByte(const std::string& text, const std::string& tag, std::uint8_t& value)
{
    const std::string marker = "\\" + tag + "&H";
    const std::size_t start = text.find(marker);
    if (start == std::string::npos)
        return false;

    const std::size_t digits = start + marker.size();
    const std::size_t end = text.find('&', digits);
    if (end == std::string::npos || end - digits != 2)
        return false;

    const std::string digits_text = text.substr(digits, 2);
    char* parsed_end = nullptr;
    const unsigned long parsed = std::strtoul(digits_text.c_str(), &parsed_end, 16);
    if (parsed_end == nullptr || *parsed_end != '\0' || parsed > 0xff)
        return false;
    value = static_cast<std::uint8_t>(parsed);
    return true;
}

bool ReadColor(const std::string& text, const std::string& tag, AssRgb& color)
{
    const std::string marker = "\\" + tag + "&H";
    const std::size_t start = text.find(marker);
    if (start == std::string::npos)
        return false;

    const std::size_t digits = start + marker.size();
    const std::size_t end = text.find('&', digits);
    if (end == std::string::npos || end - digits != 6)
        return false;

    const std::string digits_text = text.substr(digits, 6);
    char* parsed_end = nullptr;
    const unsigned long parsed = std::strtoul(digits_text.c_str(), &parsed_end, 16);
    if (parsed_end == nullptr || *parsed_end != '\0' || parsed > 0xffffff)
        return false;
    color.blue = static_cast<std::uint8_t>((parsed >> 16) & 0xff);
    color.green = static_cast<std::uint8_t>((parsed >> 8) & 0xff);
    color.red = static_cast<std::uint8_t>(parsed & 0xff);
    return true;
}

} // namespace

std::string AssColorFromRgb(AssRgb color)
{
    char value[10] = {};
    std::snprintf(value, sizeof(value), "&H%02X%02X%02X&",
        static_cast<unsigned>(color.blue), static_cast<unsigned>(color.green), static_cast<unsigned>(color.red));
    return value;
}

std::string AssAlphaFromOpacity(std::uint8_t opacity)
{
    char value[6] = {};
    std::snprintf(value, sizeof(value), "&H%02X&", 255U - static_cast<unsigned>(opacity));
    return value;
}

std::string ShapeStyle::SerializeOverrideTags() const
{
    char border[32] = {};
    std::snprintf(border, sizeof(border), "%.2f", std::max(0.0, outline_width));
    std::string tags = "{\\p1\\bord";
    tags += outline_enabled ? border : "0";
    tags += "\\1c" + AssColorFromRgb(fill_color);
    tags += "\\1a" + AssAlphaFromOpacity(fill_enabled ? fill_opacity : 0);
    tags += "\\3c" + AssColorFromRgb(outline_color);
    tags += "\\3a" + AssAlphaFromOpacity(outline_enabled ? outline_opacity : 0);
    tags += "}";
    return tags;
}

bool ShapeStyle::ImportOverrideTags(const std::string& text)
{
    bool changed = false;
    changed = ReadColor(text, "1c", fill_color) || changed;
    changed = ReadColor(text, "3c", outline_color) || changed;

    std::uint8_t alpha = 0;
    if (ReadHexByte(text, "1a", alpha)) {
        fill_opacity = static_cast<std::uint8_t>(255U - alpha);
        fill_enabled = alpha != 255;
        changed = true;
    }
    if (ReadHexByte(text, "3a", alpha)) {
        outline_opacity = static_cast<std::uint8_t>(255U - alpha);
        changed = true;
    }

    const std::string marker = "\\bord";
    const std::size_t start = text.find(marker);
    if (start != std::string::npos) {
        char* parsed_end = nullptr;
        const double width = std::strtod(text.c_str() + start + marker.size(), &parsed_end);
        if (parsed_end != text.c_str() + start + marker.size()) {
            outline_width = std::max(0.0, width);
            outline_enabled = outline_width > 0.0 && outline_opacity > 0;
            changed = true;
        }
    }
    return changed;
}
