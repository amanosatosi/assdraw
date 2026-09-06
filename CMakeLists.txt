cmake_minimum_required(VERSION 3.21)
project(ASSDraw VERSION 3.1.0 LANGUAGES CXX)

include(CTest)
find_package(wxWidgets 3.2 REQUIRED COMPONENTS core base aui propgrid)
include(${wxWidgets_USE_FILE})
find_package(PkgConfig REQUIRED)
pkg_check_modules(AGG REQUIRED IMPORTED_TARGET libagg)

add_executable(assdraw WIN32
    src/agg_bcspline.cpp
    src/agg_vcgen_bcspline.cpp
    src/assdraw.cpp
    src/assdraw_settings.cpp
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
if(WIN32)
    target_sources(assdraw PRIVATE src/assdraw.rc)
endif()
target_include_directories(assdraw PRIVATE src)
target_compile_features(assdraw PRIVATE cxx_std_17)
target_compile_definitions(assdraw PRIVATE wxUSE_UNICODE=1)
target_link_libraries(assdraw PRIVATE ${wxWidgets_LIBRARIES} PkgConfig::AGG)

if(BUILD_TESTING)
    add_executable(assdraw-core-tests tests/style_history_tests.cpp src/shape_style.cpp)
    target_include_directories(assdraw-core-tests PRIVATE src)
    target_compile_features(assdraw-core-tests PRIVATE cxx_std_17)
    add_test(NAME assdraw-core-tests COMMAND assdraw-core-tests)
endif()
