list(APPEND CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
)
if(SFIZZ_USE_SYSTEM_VST3SDK)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(VST3SDK "vst3sdk" REQUIRED)
    set(VST3SDK_BASEDIR "${VST3SDK_INCLUDE_DIRS}")
else()
    set(VST3SDK_BASEDIR "${CMAKE_CURRENT_SOURCE_DIR}/external/VST_SDK/VST3_SDK")
endif()

# VST plugin specific settings
include(VSTConfig)

configure_file(VstPluginDefs.h.in "${CMAKE_CURRENT_BINARY_DIR}/VstPluginDefs.h")

# Build VST3 SDK
include(VST3SDK)

# Add the ring buffer
set(RINGBUFFER_SOURCES
    "external/ring_buffer/ring_buffer/ring_buffer.h"
    "external/ring_buffer/ring_buffer/ring_buffer.tcc"
    "external/ring_buffer/ring_buffer/ring_buffer.cpp"
)
if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES ${RINGBUFFER_SOURCES})
endif()

add_library(plugins_ring_buffer STATIC EXCLUDE_FROM_ALL ${RINGBUFFER_SOURCES})
target_include_directories(plugins_ring_buffer PUBLIC "external/ring_buffer")
add_library(plugins::ring-buffer ALIAS plugins_ring_buffer)

# Build the VST shared code
set(VST3_CORE_SOURCES
    SfizzVstProcessor.cpp
    SfizzVstProcessor.h
    SfizzVstController.cpp
    SfizzVstController.h
    SfizzVstEditor.cpp
    SfizzVstEditor.h
    SfizzVstState.cpp
    SfizzVstState.h
    SfizzVstParameters.h
    SfizzVstUpdates.h
    SfizzVstUpdates.hpp
    SfizzVstUpdates.cpp
    SfizzVstIDs.h
    OrderedEventProcessor.h
    OrderedEventProcessor.hpp
    IdleUpdateHandler.h
    X11RunLoop.h
    X11RunLoop.cpp
)
if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES ${VST3_CORE_SOURCES})
endif()

add_library(plugins_vst3_core STATIC EXCLUDE_FROM_ALL ${VST3_CORE_SOURCES})

target_include_directories(plugins_vst3_core PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(plugins_vst3_core PRIVATE
    sfizz::sfizz
    sfizz::filesystem
    sfizz::import
    sfizz::pugixml
    plugins::common
    plugins::editor
    plugins::ring-buffer
    absl::strings
    absl::optional
    absl::container_common
    vst3sdk
    vst3sdk_vstgui
)
gw_target_warn(plugins_vst3_core PRIVATE
    "-Wno-ignored-qualifiers"
    "-Wno-unused-parameter")
add_library(plugins::vst3_core ALIAS plugins_vst3_core)

# --- VST3 plugin --- #
if(PLUGIN_VST3)
    include(VST3Plugin)
endif()

# --- Audio Unit wrapper --- #
if(PLUGIN_AU AND NOT APPLE)
    message(WARNING "Audio Unit is available only for macOS builds")
elseif(PLUGIN_AU)
    include(AU2Plugin)
endif()

# --- VST2 wrapper --- #
if(PLUGIN_VST2)
    include(VST2Plugin)
endif()
