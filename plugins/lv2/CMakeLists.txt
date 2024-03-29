set(LV2_PLUGIN_PRJ_NAME "plugins_lv2")

# Set the build directory as <build_dir>/lv2/<plugin_name>.lv2/
set(PROJECT_BINARY_DIR "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.lv2")

# LV2 plugin specific settings
include(LV2Config)

# Keep non build turtle files in IDE
set(LV2_PLUGIN_TTL_SOURCES
    manifest.ttl.in
    ${PROJECT_NAME}.ttl.in
)
if(PLUGIN_LV2_UI)
    list(APPEND LV2_PLUGIN_TTL_SOURCES ${PROJECT_NAME}_ui.ttl.in)
endif()
set(LV2_PLUGIN_SOURCES
    ${PROJECT_NAME}.cpp
    ${PROJECT_NAME}_lv2_common.cpp
    ${LV2_PLUGIN_TTL_SOURCES}
)
if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES ${LV2_PLUGIN_SOURCES})
endif()
source_group("Turtle Files" FILES ${LV2_PLUGIN_TTL_SOURCES})

add_library(${LV2_PLUGIN_PRJ_NAME} MODULE ${LV2_PLUGIN_SOURCES})
target_link_libraries(${LV2_PLUGIN_PRJ_NAME} PRIVATE
    sfizz::sfizz
    sfizz::import
    plugins::common
)
if(PLUGIN_LV2_UI)
    set(LV2_PLUGIN_UI_FILES
        ${PROJECT_NAME}_ui.cpp
        ${PROJECT_NAME}_lv2_common.cpp
        vstgui_helpers.h
        vstgui_helpers.cpp
    )
    if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
        source_group("" FILES ${LV2_PLUGIN_UI_FILES})
    endif()

    add_library(${LV2_PLUGIN_PRJ_NAME}_ui MODULE ${LV2_PLUGIN_UI_FILES})

    target_link_libraries(${LV2_PLUGIN_PRJ_NAME}_ui PRIVATE
        plugins::editor
        plugins::vstgui
        plugins::common
    )
endif()

if(PLUGIN_LV2_PSA)
    target_compile_definitions(${LV2_PLUGIN_PRJ_NAME} PRIVATE "PLUGIN_LV2_PSA=1")
    if(PLUGIN_LV2_UI)
        target_compile_definitions(${LV2_PLUGIN_PRJ_NAME}_ui PRIVATE "PLUGIN_LV2_PSA=1")
    endif()
endif()

# Explicitely strip all symbols on Linux but lv2_descriptor()
# MacOS linker does not support this apparently https://bugs.webkit.org/show_bug.cgi?id=144555
if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    target_link_libraries(${LV2_PLUGIN_PRJ_NAME} PRIVATE "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/lv2.version")
    # target_link_libraries(${LV2_PLUGIN_PRJ_NAME} "-Wl,-u,lv2_descriptor")
    if(PLUGIN_LV2_UI)
        target_link_libraries(${LV2_PLUGIN_PRJ_NAME}_ui PRIVATE "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/lv2ui.version")
        # target_link_libraries(${LV2_PLUGIN_PRJ_NAME}_ui "-Wl,-u,lv2ui_descriptor")
    endif()
endif()

target_include_directories(${LV2_PLUGIN_PRJ_NAME} PRIVATE . external/ardour)
if(SFIZZ_USE_SYSTEM_LV2)
    find_path(LV2_INCLUDE_DIR "lv2.h")
    if(NOT LV2_INCLUDE_DIR)
        message(FATAL_ERROR "Cannot find lv2 include directory")
    else()
        message(STATUS "Found system lv2")
    endif()
else()
    target_include_directories(${LV2_PLUGIN_PRJ_NAME} PRIVATE vendor)
endif()
sfizz_enable_lto_if_needed(${LV2_PLUGIN_PRJ_NAME})
if(MINGW)
    set_target_properties(${LV2_PLUGIN_PRJ_NAME} PROPERTIES LINK_FLAGS "-static")
endif()

if(PLUGIN_LV2_UI)
    target_include_directories(${LV2_PLUGIN_PRJ_NAME}_ui PRIVATE . external/ardour)
    if(NOT SFIZZ_USE_SYSTEM_LV2)
        target_include_directories(${LV2_PLUGIN_PRJ_NAME}_ui PRIVATE vendor)
    endif()
    sfizz_enable_lto_if_needed(${LV2_PLUGIN_PRJ_NAME}_ui)
    if(MINGW)
        set_target_properties(${LV2_PLUGIN_PRJ_NAME}_ui PROPERTIES LINK_FLAGS "-static")
    endif()
endif()

# Define a preprocessor variable to indicate a build with UI enabled
if(PLUGIN_LV2_UI)
    target_compile_definitions(${LV2_PLUGIN_PRJ_NAME} PRIVATE "PLUGIN_LV2_UI=1")
    target_compile_definitions(${LV2_PLUGIN_PRJ_NAME}_ui PRIVATE "PLUGIN_LV2_UI=1")
endif()

# Remove the "lib" prefix, rename the target name and build it in the .lv build dir
# <build_dir>/lv2/<plugin_name>_lv2.<ext> to
# <build_dir>/lv2/<plugin_name>.lv2/<plugin_name>.<ext>
set_target_properties(${LV2_PLUGIN_PRJ_NAME} PROPERTIES PREFIX "")
set_target_properties(${LV2_PLUGIN_PRJ_NAME} PROPERTIES OUTPUT_NAME "${PROJECT_NAME}")
set_target_properties(${LV2_PLUGIN_PRJ_NAME} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Contents/Binary/$<0:>")

if(PLUGIN_LV2_UI)
    set_target_properties(${LV2_PLUGIN_PRJ_NAME}_ui PROPERTIES PREFIX "")
    set_target_properties(${LV2_PLUGIN_PRJ_NAME}_ui PROPERTIES OUTPUT_NAME "${PROJECT_NAME}_ui")
    set_target_properties(${LV2_PLUGIN_PRJ_NAME}_ui PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/Contents/Binary/$<0:>")
endif()

# Generate *.ttl files from *.in sources,
# create the destination directory if it doesn't exists and copy needed files
file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR})
configure_file(manifest.ttl.in ${PROJECT_BINARY_DIR}/manifest.ttl)
configure_file(${PROJECT_NAME}.ttl.in ${PROJECT_BINARY_DIR}/${PROJECT_NAME}.ttl)
if(PLUGIN_LV2_UI)
    configure_file(${PROJECT_NAME}_ui.ttl.in ${PROJECT_BINARY_DIR}/${PROJECT_NAME}_ui.ttl)
endif()
configure_file(LICENSE.md.in ${PROJECT_BINARY_DIR}/LICENSE.md)

# Generate controllers.ttl
generate_lv2_controllers_ttl("${PROJECT_BINARY_DIR}/controllers.ttl")

# Copy resource files into the bundle
set(LV2_RESOURCES
    DefaultInstrument.sfz
    DefaultScale.scl)
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${PROJECT_BINARY_DIR}/Contents/Resources")
foreach(res ${LV2_RESOURCES})
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/resources/${res}"
        DESTINATION "${PROJECT_BINARY_DIR}/Contents/Resources")
endforeach()

# Copy editor resources
if(PLUGIN_LV2_UI)
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${PROJECT_BINARY_DIR}/Contents/Resources")
    copy_editor_resources(
        ${LV2_PLUGIN_PRJ_NAME}_ui
        "${CMAKE_CURRENT_SOURCE_DIR}/../editor/resources"
        "${PROJECT_BINARY_DIR}/Contents/Resources")
endif()

# Installation
if(NOT MSVC)
    install(DIRECTORY ${PROJECT_BINARY_DIR} DESTINATION ${LV2_PLUGIN_INSTALL_DIR}
        COMPONENT "lv2"
        USE_SOURCE_PERMISSIONS)
    bundle_dylibs(lv2
        "${LV2_PLUGIN_INSTALL_DIR}/${PROJECT_NAME}.lv2/Contents/Binary/sfizz.so"
        COMPONENT "lv2")
    bundle_dylibs(lv2-ui
        "${LV2_PLUGIN_INSTALL_DIR}/${PROJECT_NAME}.lv2/Contents/Binary/sfizz_ui.so"
        COMPONENT "lv2")
endif()
