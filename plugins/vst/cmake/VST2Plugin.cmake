set(VST2_PLUGIN_PRJ_NAME "${PROJECT_NAME}_vst2")
set(VST2_PLUGIN_BUNDLE_NAME "${PROJECT_NAME}.vst2")

set(VST2SDK_BASEDIR "${CMAKE_CURRENT_SOURCE_DIR}/external/vstsdk2.4")
set(VST2WRAPPER_BASEDIR "${CMAKE_CURRENT_SOURCE_DIR}/external/VST_SDK/VST3_SDK/public.sdk/source/vst/vst2wrapper")

if(NOT EXISTS "${VST2SDK_BASEDIR}/pluginterfaces/vst2.x/aeffect.h")
    message(FATAL_ERROR "VST SDK 2.4 is missing. Make it available in the following folder: ${VST2SDK_BASEDIR}")
endif()

add_library(${VST2_PLUGIN_PRJ_NAME} MODULE
    "VstPluginFactory.cpp"
    "Vst2PluginFactory.cpp"
    "Vst2PluginEntry.c"
    "${VST2WRAPPER_BASEDIR}/vst2wrapper.cpp"
    "${VST2WRAPPER_BASEDIR}/../basewrapper/basewrapper.cpp"
    "${VST2SDK_BASEDIR}/public.sdk/source/vst2.x/audioeffect.cpp"
    "${VST2SDK_BASEDIR}/public.sdk/source/vst2.x/audioeffectx.cpp")
target_include_directories(${VST2_PLUGIN_PRJ_NAME} PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}"
    "${VST2SDK_BASEDIR}")

if(NOT WIN32)
    target_compile_definitions(${VST2_PLUGIN_PRJ_NAME} PRIVATE "__cdecl=")
endif()

target_link_libraries(${VST2_PLUGIN_PRJ_NAME}
    PRIVATE plugins_vst3_core)
set_target_properties(${VST2_PLUGIN_PRJ_NAME} PROPERTIES
    OUTPUT_NAME "${PROJECT_NAME}"
    PREFIX "")

plugin_add_vst3sdk(${VST2_PLUGIN_PRJ_NAME})
plugin_add_vstgui(${VST2_PLUGIN_PRJ_NAME})

# Add VST hosting classes
target_link_libraries(${VST2_PLUGIN_PRJ_NAME} PRIVATE vst3sdk_hosting)

sfizz_enable_lto_if_needed(${VST2_PLUGIN_PRJ_NAME})

# Create the bundle
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${PROJECT_BINARY_DIR}/${VST2_PLUGIN_BUNDLE_NAME}/Contents/Resources")
copy_editor_resources(
    ${VST2_PLUGIN_PRJ_NAME}
    "${CMAKE_CURRENT_SOURCE_DIR}/../editor/resources"
    "${PROJECT_BINARY_DIR}/${VST2_PLUGIN_BUNDLE_NAME}/Contents/Resources")
set_target_properties(${VST2_PLUGIN_PRJ_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${VST2_PLUGIN_BUNDLE_NAME}/Contents/Binary/$<0:>")

file(COPY "gpl-3.0.txt"
    DESTINATION "${PROJECT_BINARY_DIR}/${VST2_PLUGIN_BUNDLE_NAME}")

if(MINGW)
    set_target_properties(${VST2_PLUGIN_PRJ_NAME} PROPERTIES LINK_FLAGS "-static")
endif()

# Installation
if(VST2_PLUGIN_INSTALL_DIR)
    install(DIRECTORY "${PROJECT_BINARY_DIR}/${VST2_PLUGIN_BUNDLE_NAME}"
        DESTINATION "${VST2_PLUGIN_INSTALL_DIR}"
        COMPONENT "vst2"
        USE_SOURCE_PERMISSIONS)
    if(APPLE)
        bundle_dylibs(vst2
            "${VST2_PLUGIN_INSTALL_DIR}/${VST2_PLUGIN_BUNDLE_NAME}/Contents/Binary/sfizz.${CMAKE_SHARED_MODULE_SUFFIX}"
            COMPONENT "vst2")
    endif()
endif()
