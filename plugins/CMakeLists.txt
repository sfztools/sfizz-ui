set(PLUGINSCOMMON_SOURCES
    common/plugin/RMSFollower.h
    common/plugin/MessageUtils.h
    common/plugin/MessageUtils.cpp
    common/plugin/InstrumentDescription.h
    common/plugin/InstrumentDescription.cpp
    common/plugin/NativeHelpers.h
    common/plugin/NativeHelpers.cpp
    common/plugin/SfizzFileScan.h
    common/plugin/SfizzFileScan.cpp
    common/plugin/FileTrie.h
    common/plugin/FileTrie.cpp
    common/plugin/SfizzForeignPaths.h
    common/plugin/SfizzForeignPaths.cpp
    common/plugin/SfizzSettings.h
    common/plugin/SfizzSettings.cpp
)
if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES ${PLUGINSCOMMON_SOURCES})
endif()
add_library(plugins_common STATIC EXCLUDE_FROM_ALL ${PLUGINSCOMMON_SOURCES})

if(APPLE)
    target_sources(plugins_common PRIVATE
        "common/plugin/SfizzForeignPaths.mm"
        "common/plugin/SfizzSettings.mm"
        "common/plugin/NativeHelpers.mm"
    )
    set_property(SOURCE
        "common/plugin/SfizzForeignPaths.mm"
        "common/plugin/SfizzSettings.mm"
        "common/plugin/NativeHelpers.mm"
        APPEND_STRING
        PROPERTY COMPILE_FLAGS " -fobjc-arc"
    )
endif()
target_include_directories(plugins_common PUBLIC "common")
target_link_libraries(plugins_common
    PUBLIC
        sfizz::spin_mutex
        sfizz::simde
        sfizz::filesystem
        absl::strings
    PRIVATE
        sfizz::pugixml
        sfizz::internal
        sfizz::sfizz
)
add_library(plugins::common ALIAS plugins_common)

add_custom_target(generate_plugins_git_build_id
    COMMAND
        "${CMAKE_COMMAND}"
        "-DSOURCE_DIR=${PROJECT_SOURCE_DIR}"
        "-DOUTPUT_FILE=${PROJECT_BINARY_DIR}/git-build-id/PluginGitBuildId.c"
        "-DPREFIX=Plugin"
        "-P" "${PROJECT_SOURCE_DIR}/library/cmake/GitBuildID.cmake"
    BYPRODUCTS
        "${PROJECT_BINARY_DIR}/git-build-id/PluginGitBuildId.c"
)
set(PLUGINS_GIT_BUILD_ID_SOURCES
    "${PROJECT_SOURCE_DIR}/plugins/git-build-id/PluginGitBuildId.h"
    "${PROJECT_BINARY_DIR}/git-build-id/PluginGitBuildId.c"
)
if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES ${PLUGINS_GIT_BUILD_ID_SOURCES})
endif()

add_library(plugins_git_build_id STATIC EXCLUDE_FROM_ALL ${PLUGINS_GIT_BUILD_ID_SOURCES})
target_include_directories(plugins_git_build_id PUBLIC "${PROJECT_SOURCE_DIR}/plugins/git-build-id")
add_dependencies(plugins_git_build_id generate_plugins_git_build_id)
add_library(plugins::git_build_id ALIAS plugins_git_build_id)

# Link system dependencies
if(WIN32)
elseif(ANDROID)
elseif(APPLE)
    target_link_libraries(plugins_common PRIVATE
        "${APPLE_FOUNDATION_LIBRARY}")
else()
endif()

if((PLUGIN_LV2 AND PLUGIN_LV2_UI) OR PLUGIN_VST3 OR PLUGIN_AU OR PLUGIN_VST2)
    add_subdirectory(editor)
endif()

if(PLUGIN_LV2)
    add_subdirectory(lv2)
endif()

if((PLUGIN_VST3 OR PLUGIN_AU OR PLUGIN_VST2) AND NOT (PROJECT_SYSTEM_PROCESSOR MATCHES "^(powerpc|ppc).*"))
    add_subdirectory(vst)
endif()

if(PLUGIN_PUREDATA)
    add_subdirectory(puredata)
endif()
