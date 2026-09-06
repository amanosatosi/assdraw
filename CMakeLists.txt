cmake_minimum_required(VERSION 3.21)
project(ASSDraw VERSION 3.1.0 LANGUAGES CXX)

include(CTest)
find_package(wxWidgets 3.2 REQUIRED COMPONENTS core base aui propgrid)
include(${wxWidgets_USE_FILE})

# MSYS2 no longer packages the historical libagg dependency. Keep the
# renderer explicit, pinned, and built only by the supported CI toolchain.
include(FetchContent)
FetchContent_Declare(agg
    GIT_REPOSITORY https://github.com/ghaerr/agg-2.6.git
    GIT_TAG c4f36b4432142f22c0bf82c6fbdb41567a236be2
    GIT_SHALLOW TRUE
)
FetchContent_GetProperties(agg)
if(NOT agg_POPULATED)
    FetchContent_Populate(agg)
    file(GLOB ASSDRAW_AGG_SOURCES CONFIGURE_DEPENDS "${agg_SOURCE_DIR}/agg-src/src/*.cpp")
    add_library(assdraw-agg STATIC ${ASSDRAW_AGG_SOURCES})
    target_include_directories(assdraw-agg PUBLIC "${agg_SOURCE_DIR}/agg-src/include")
    target_compile_features(assdraw-agg PUBLIC cxx_std_17)
    configure_file("${agg_SOURCE_DIR}/agg-src/copying" "${CMAKE_BINARY_DIR}/THIRD_PARTY_AGG_COPYING" COPYONLY)
endif()

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
    enable_language(RC)
    target_sources(assdraw PRIVATE src/assdraw.rc)
endif()
target_include_directories(assdraw PRIVATE src)
target_compile_features(assdraw PRIVATE cxx_std_17)
target_compile_definitions(assdraw PRIVATE wxUSE_UNICODE=1)
target_link_libraries(assdraw PRIVATE ${wxWidgets_LIBRARIES} assdraw-agg)

if(BUILD_TESTING)
    add_executable(assdraw-core-tests tests/style_history_tests.cpp src/shape_style.cpp)
    target_include_directories(assdraw-core-tests PRIVATE src)
    target_compile_features(assdraw-core-tests PRIVATE cxx_std_17)
    add_test(NAME assdraw-core-tests COMMAND assdraw-core-tests)
endif()
