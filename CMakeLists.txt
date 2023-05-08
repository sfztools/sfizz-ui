if (WIN32)
    cmake_minimum_required (VERSION 3.15)
    cmake_policy(SET CMP0091 NEW)
else()
    # FIXME: The old JPC fork of mod-plugin-builder image used in CI requires 3.5.
    #        The current upstream one needs a different configuration.
    #        Minimum required to use SFIZZ_USE_SYSTEM_ABSEIL is 3.11,
    #        see library/cmake/SfizzDeps.cmake at line 70.
    cmake_minimum_required(VERSION 3.11)
endif()

project (sfizz VERSION 1.2.2 LANGUAGES CXX C)
set (PROJECT_DESCRIPTION
    "SFZ based sampler, providing AU, LV2, PureData and VST plugins."
)
# External configuration CMake scripts
set (CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};"
    "${CMAKE_CURRENT_SOURCE_DIR}/library/cmake;"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
)
include(BuildType)
include(OptionEx)

option_ex(SFIZZ_AU                 "Enable AU plug-in build" APPLE)
option_ex(SFIZZ_LV2                "Enable LV2 plug-in build" ON)
option_ex(SFIZZ_LV2_UI             "Enable LV2 plug-in user interface" ON)
option_ex(SFIZZ_PUREDATA           "Enable Puredata plug-in build" OFF)
option_ex(SFIZZ_USE_SYSTEM_LV2     "Use LV2 headers preinstalled on system" OFF)
option_ex(SFIZZ_USE_SYSTEM_VST3SDK "Use VST3SDK source files preinstalled on system" OFF)
option_ex(SFIZZ_VST2               "Enable VST2 plug-in build (unsupported)" OFF)
option_ex(SFIZZ_VST                "Enable VST plug-in build" ON)

set(MIDI_CC_MAX 512 CACHE STRING "Maximum amount of Control Change Messages")

include(SfizzConfig) # Re-used for this project
include(BundleDylibs)

add_subdirectory(library)
add_subdirectory(plugins)

# Windows installer
if(WIN32)
    include(VSTConfig)
    configure_file(${PROJECT_SOURCE_DIR}/scripts/innosetup.iss.in
        ${PROJECT_BINARY_DIR}/innosetup.iss @ONLY)
endif()

# Put it at the end so that the vst/lv2 directories are registered
if (NOT MSVC)
    include(PluginsUninstall)
endif()

show_build_info_if_needed()
