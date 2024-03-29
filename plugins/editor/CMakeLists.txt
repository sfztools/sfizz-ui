if(SFIZZ_USE_SYSTEM_VST3SDK)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(VST3SDK "vst3sdk" REQUIRED)
    set(VSTGUI_BASEDIR "${VST3SDK_INCLUDE_DIRS}/vstgui4")
else()
    set(VSTGUI_BASEDIR "${CMAKE_CURRENT_SOURCE_DIR}/external/vstgui4")
endif()

include("cmake/Vstgui.cmake")

set(EDITOR_THEMES
    resources/Themes/Default/theme.xml
    resources/Themes/Dark/theme.xml
)
set(EDITOR_RESOURCES
    logo.png
    logo_orange.png
    logo_text.png
    logo_text_white.png
    logo_text_shaded.png
    logo_text@2x.png
    logo_text_white@2x.png
    logo_text_shaded@2x.png
    background.png
    background@2x.png
    background_button_about.png
    background_button_about@2x.png
    icon_white.png
    icon_white@2x.png
    knob48.png
    knob48@2x.png
    Fonts/sfizz-fluentui-system-r20.ttf
    Fonts/sfizz-fluentui-system-f20.ttf
    Fonts/sfizz-misc-icons.ttf
    Fonts/Roboto-Regular.ttf
    Themes/Default/theme.xml
    Themes/Dark/theme.xml
    PARENT_SCOPE
)
function(copy_editor_resources TARGET SOURCE_DIR DESTINATION_DIR)
    set(_deps)
    foreach(res ${EDITOR_RESOURCES})
        get_filename_component(_dir "${res}" DIRECTORY)
        file(MAKE_DIRECTORY "${DESTINATION_DIR}/${_dir}")
        add_custom_command(
            OUTPUT "${DESTINATION_DIR}/${res}"
            COMMAND "${CMAKE_COMMAND}" "-E" "copy"
                    "${SOURCE_DIR}/${res}" "${DESTINATION_DIR}/${res}"
            DEPENDS "${SOURCE_DIR}/${res}")
        list(APPEND _deps "${DESTINATION_DIR}/${res}")
    endforeach()
    add_custom_target("${TARGET}_editor_resources" DEPENDS ${_deps})
    add_dependencies("${TARGET}" "${TARGET}_editor_resources")
endfunction()

# editor
set(EDITOR_UI_FILES layout/main.fl layout/about.fl)
set(EDITOR_SOURCES
    src/editor/EditIds.h
    src/editor/EditIds.cpp
    src/editor/Editor.h
    src/editor/Editor.cpp
    src/editor/EditorLibs.h
    src/editor/EditorLibs.cpp
    src/editor/EditorController.h
    src/editor/GUIComponents.h
    src/editor/GUIComponents.cpp
    src/editor/GUIDefs.h
    src/editor/GUIDefs.cpp
    src/editor/GUIHelpers.h
    src/editor/GUIHelpers.cpp
    src/editor/GUIPiano.h
    src/editor/GUIPiano.cpp
    src/editor/DlgAbout.h
    src/editor/DlgAbout.cpp
    src/editor/Theme.h
    src/editor/Theme.cpp
    src/editor/ColorHelpers.h
    src/editor/ColorHelpers.cpp
    src/editor/ImageHelpers.h
    src/editor/ImageHelpers.cpp
    src/editor/NativeHelpers.h
    src/editor/NativeHelpers.cpp
    src/editor/VSTGUIHelpers.h
    src/editor/VSTGUIHelpers.cpp
    src/editor/layout/main.hpp
    src/editor/layout/about.hpp
    src/editor/utility/vstgui_after.h
    src/editor/utility/vstgui_before.h
)
if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES ${EDITOR_SOURCES})
    source_group("" FILES ${EDITOR_UI_FILES})
    source_group("" FILES ${EDITOR_THEMES})
endif()

add_library(plugins_editor STATIC EXCLUDE_FROM_ALL
    ${EDITOR_SOURCES}
    ${EDITOR_THEMES}
    ${EDITOR_UI_FILES}
)
add_library(plugins::editor ALIAS plugins_editor)

target_include_directories(plugins_editor PUBLIC src)
target_link_libraries(plugins_editor PUBLIC
    sfizz::messaging
    plugins::common
)
target_link_libraries(plugins_editor PRIVATE
    plugins::vstgui
    plugins::git_build_id
)
target_compile_definitions(plugins_editor PRIVATE
    "SFIZZ_VERSION=\"${CMAKE_PROJECT_VERSION}\"")
if(APPLE)
    find_library(APPLE_APPKIT_LIBRARY "AppKit")
    find_library(APPLE_CORESERVICES_LIBRARY "CoreServices")
    find_library(APPLE_FOUNDATION_LIBRARY "Foundation")
    target_sources(plugins_editor PRIVATE
        src/editor/NativeHelpers.mm
        src/editor/VSTGUIHelpers.mm)
    target_link_libraries(plugins_editor PRIVATE
        "${APPLE_APPKIT_LIBRARY}"
        "${APPLE_CORESERVICES_LIBRARY}"
        "${APPLE_FOUNDATION_LIBRARY}")
    target_compile_options(plugins_editor PRIVATE "-fobjc-arc")
endif()

# dependencies
add_library(plugins_colorspaces INTERFACE)
add_library(plugins::colorspaces ALIAS plugins_colorspaces)
target_include_directories(plugins_colorspaces INTERFACE "external/color-spaces")

add_library(plugins_stb_image INTERFACE)
add_library(plugins::stb_image ALIAS plugins_stb_image)
target_include_directories(plugins_stb_image INTERFACE "external/stb_image")

if(WIN32)
    #
elseif(APPLE)
    #
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(sfizz-gio "gio-2.0" REQUIRED)
    target_include_directories(plugins_editor PRIVATE ${sfizz-gio_INCLUDE_DIRS})
    target_link_libraries(plugins_editor PRIVATE ${sfizz-gio_LIBRARIES})
endif()
target_link_libraries(plugins_editor PRIVATE
    plugins::colorspaces
    plugins::stb_image
    sfizz::bit_array
    sfizz::filesystem
    sfizz::pugixml
)
# layout tool
if(NOT CMAKE_CROSSCOMPILING)
    set(LAYOUTMAKER_SOURCES
        tools/layout-maker/sources/layout.h
        tools/layout-maker/sources/reader.cpp
        tools/layout-maker/sources/reader.h
        tools/layout-maker/sources/main.cpp
    )
    if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
        source_group("" FILES ${LAYOUTMAKER_SOURCES})
    endif()

    add_executable(layout-maker ${LAYOUTMAKER_SOURCES})
    target_link_libraries(layout-maker PRIVATE absl::strings)

    foreach(_layout main about)
        add_custom_command(
            OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/editor/layout/${_layout}.hpp"
            COMMAND "$<TARGET_FILE:layout-maker>"
            "${CMAKE_CURRENT_SOURCE_DIR}/layout/${_layout}.fl"
            > "${CMAKE_CURRENT_SOURCE_DIR}/src/editor/layout/${_layout}.hpp"
            DEPENDS layout-maker "${CMAKE_CURRENT_SOURCE_DIR}/layout/${_layout}.fl")
    endforeach()
endif()
