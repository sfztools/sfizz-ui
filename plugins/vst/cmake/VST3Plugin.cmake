set(VST3_PLUGIN_PRJ_NAME "plugins_vst3")
set(VST3_PLUGIN_BUNDLE_NAME "${PROJECT_NAME}.vst3")

if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES VstPluginFactory.cpp)
endif()

add_library(${VST3_PLUGIN_PRJ_NAME} MODULE "VstPluginFactory.cpp")

if(WIN32)
    target_sources(${VST3_PLUGIN_PRJ_NAME} PRIVATE vst3.def)
endif()

target_include_directories(${VST3_PLUGIN_PRJ_NAME}
    PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(${VST3_PLUGIN_PRJ_NAME}
    PRIVATE plugins_vst3_core)
set_target_properties(${VST3_PLUGIN_PRJ_NAME} PROPERTIES
    OUTPUT_NAME "${PROJECT_NAME}"
    PREFIX "")

plugin_add_vst3sdk(${VST3_PLUGIN_PRJ_NAME})
plugin_add_vstgui(${VST3_PLUGIN_PRJ_NAME})

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    target_link_libraries(${VST3_PLUGIN_PRJ_NAME} PRIVATE
        "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/vst3.version")
endif()
sfizz_enable_lto_if_needed(${VST3_PLUGIN_PRJ_NAME})
if(MINGW)
    set_target_properties(${VST3_PLUGIN_PRJ_NAME} PROPERTIES LINK_FLAGS "-static")
endif()

# Create the bundle(see "VST 3 Locations / Format")
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/Resources")
copy_editor_resources(
    ${VST3_PLUGIN_PRJ_NAME}
    "${CMAKE_CURRENT_SOURCE_DIR}/../editor/resources"
    "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/Resources")
if(WIN32)
    set_target_properties(${VST3_PLUGIN_PRJ_NAME} PROPERTIES
        SUFFIX ".vst3"
        LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/${VST3_PACKAGE_ARCHITECTURE}-win/$<0:>")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/win/Plugin.ico"
        "${CMAKE_CURRENT_SOURCE_DIR}/win/desktop.ini"
        DESTINATION "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}")
elseif(APPLE)
    set_target_properties(${VST3_PLUGIN_PRJ_NAME} PROPERTIES
        SUFFIX ""
        LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/MacOS/$<0:>")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/mac/PkgInfo"
        DESTINATION "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents")
    set(SFIZZ_VST3_BUNDLE_EXECUTABLE "${PROJECT_NAME}")
    set(SFIZZ_VST3_BUNDLE_VERSION "${PROJECT_VERSION}")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/mac/Info.vst3.plist"
        "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/Info.plist" @ONLY)
else()
    set_target_properties(${VST3_PLUGIN_PRJ_NAME} PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/${VST3_PACKAGE_ARCHITECTURE}-linux/$<0:>")
endif()

# Copy the license
if(APPLE)
    # on macOS, files are not permitted at the bundle root, during code signing
    file(COPY "gpl-3.0.txt"
        DESTINATION "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/SharedSupport/License")
else()
    file(COPY "gpl-3.0.txt"
        DESTINATION "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}")
endif()

# To help debugging the link only
if(FALSE)
    target_link_options(${VST3_PLUGIN_PRJ_NAME} PRIVATE "-Wl,-no-undefined")
endif()

# Installation
if(NOT MSVC)
    install(DIRECTORY "${PROJECT_BINARY_DIR}/${VST3_PLUGIN_BUNDLE_NAME}"
        DESTINATION "${VST3_PLUGIN_INSTALL_DIR}"
        COMPONENT "vst"
        USE_SOURCE_PERMISSIONS)
    bundle_dylibs(vst
        "${VST3_PLUGIN_INSTALL_DIR}/${VST3_PLUGIN_BUNDLE_NAME}/Contents/MacOS/sfizz"
        COMPONENT "vst")
endif()
