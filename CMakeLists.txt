cmake_minimum_required(VERSION 3.24)

# Use CMake's first-class MSVC runtime selection for this project and every
# dependency target added below.
cmake_policy(SET CMP0091 NEW)

project(ASSDraw VERSION 3.0.0 LANGUAGES C CXX)

if(NOT WIN32)
    message(FATAL_ERROR "The supported CMake build produces the Windows ASSDraw3 executable only.")
endif()
if(NOT MSVC)
    message(FATAL_ERROR "The supported Windows build requires Microsoft Visual C++ (MSVC).")
endif()

enable_language(RC)

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    CACHE STRING "Use the static MSVC runtime for all targets" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build all dependencies as static libraries" FORCE)

include(CTest)
include(FetchContent)

# wxWidgets 3.2.11 is the pinned stable wxWidgets release. Use its official
# release archive: unlike GitHub's automatically generated source archive, it
# contains the bundled third-party sources required for a self-contained build.
set(wxBUILD_SHARED OFF CACHE BOOL "" FORCE)
set(wxBUILD_MONOLITHIC OFF CACHE BOOL "" FORCE)
set(wxBUILD_SAMPLES OFF CACHE STRING "" FORCE)
set(wxBUILD_TESTS OFF CACHE STRING "" FORCE)
set(wxBUILD_DEMOS OFF CACHE BOOL "" FORCE)
set(wxBUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)
set(wxBUILD_LOCALES OFF CACHE BOOL "" FORCE)
set(wxBUILD_INSTALL OFF CACHE BOOL "" FORCE)
set(wxBUILD_PRECOMP ON CACHE STRING "" FORCE)
set(wxBUILD_USE_STATIC_RUNTIME ON CACHE BOOL "" FORCE)
set(wxBUILD_MSVC_MULTIPROC ON CACHE BOOL "" FORCE)
set(wxUSE_SYS_LIBS OFF CACHE BOOL "Use wxWidgets' bundled static dependencies" FORCE)

# ASSDraw uses core/base plus AUI docking, property grid, and HTML controls.
# Avoid building unrelated optional wx component libraries.
set(wxUSE_AUI ON CACHE BOOL "" FORCE)
set(wxUSE_PROPGRID ON CACHE BOOL "" FORCE)
set(wxUSE_HTML ON CACHE BOOL "" FORCE)
set(wxUSE_OPENGL OFF CACHE BOOL "" FORCE)
set(wxUSE_MEDIACTRL OFF CACHE BOOL "" FORCE)
set(wxUSE_RIBBON OFF CACHE BOOL "" FORCE)
set(wxUSE_RICHTEXT OFF CACHE BOOL "" FORCE)
set(wxUSE_STC OFF CACHE BOOL "" FORCE)
set(wxUSE_WEBVIEW OFF CACHE BOOL "" FORCE)
set(wxUSE_XRC OFF CACHE BOOL "" FORCE)

FetchContent_Declare(wxwidgets
    URL https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.11/wxWidgets-3.2.11.zip
    URL_HASH SHA1=960fe81c101eaf336f965adb130a731f91b72d84
    DOWNLOAD_EXTRACT_TIMESTAMP FALSE
)
FetchContent_MakeAvailable(wxwidgets)

# ASSDraw carries its customized AGG B-spline adapter, but the renderer also
# needs the upstream AGG headers and implementation. Pin the exact source
# revision and build it as an internal static library without its demos or
# platform backends.
FetchContent_Declare(agg
    GIT_REPOSITORY https://github.com/ghaerr/agg-2.6.git
    GIT_TAG c4f36b4432142f22c0bf82c6fbdb41567a236be2
    GIT_PROGRESS TRUE
    SOURCE_SUBDIR __assdraw_no_upstream_cmake_project
)
FetchContent_MakeAvailable(agg)

file(GLOB ASSDRAW_AGG_SOURCES "${agg_SOURCE_DIR}/agg-src/src/*.cpp")
if(NOT ASSDRAW_AGG_SOURCES)
    message(FATAL_ERROR "The pinned AGG source archive did not contain agg-src/src/*.cpp")
endif()

add_library(assdraw-agg STATIC ${ASSDRAW_AGG_SOURCES})
target_include_directories(assdraw-agg PUBLIC "${agg_SOURCE_DIR}/agg-src/include")
target_compile_features(assdraw-agg PUBLIC cxx_std_17)
set_target_properties(assdraw-agg PROPERTIES
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

configure_file(
    "${agg_SOURCE_DIR}/agg-src/copying"
    "${CMAKE_BINARY_DIR}/THIRD_PARTY_AGG_COPYING"
    COPYONLY
)

add_executable(ASSDraw3 WIN32
    src/agg_bcspline.cpp
    src/agg_vcgen_bcspline.cpp
    src/assdraw.cpp
    src/assdraw_settings.cpp
    src/assdraw.rc
    src/canvas.cpp
    src/canvas_mouse.cpp
    src/cmd.cpp
    src/dlgctrl.cpp
    src/engine.cpp
    src/library.cpp
    src/settings.cpp
    src/shape_style.cpp
    src/wxAGG/AGGWindow.cpp
)

target_include_directories(ASSDraw3 PRIVATE src)
target_compile_features(ASSDraw3 PRIVATE cxx_std_17)
target_compile_definitions(ASSDraw3 PRIVATE wxUSE_UNICODE=1)
target_link_libraries(ASSDraw3 PRIVATE
    wx::base
    wx::core
    wx::aui
    wx::propgrid
    wx::html
    assdraw-agg
)
set_target_properties(ASSDraw3 PROPERTIES
    OUTPUT_NAME "ASSDraw3"
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

# assdraw.rc embeds the complete application manifest. Suppress the linker's
# generated default so resource ID 1 has a single authoritative definition.
target_link_options(ASSDraw3 PRIVATE /MANIFEST:NO)

if(BUILD_TESTING)
    add_executable(assdraw-core-tests
        tests/style_history_tests.cpp
        src/shape_style.cpp
    )
    target_include_directories(assdraw-core-tests PRIVATE src)
    target_compile_features(assdraw-core-tests PRIVATE cxx_std_17)
    set_target_properties(assdraw-core-tests PROPERTIES
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
    )
    add_test(NAME assdraw-core-tests COMMAND assdraw-core-tests)
endif()
