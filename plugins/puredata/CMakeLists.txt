# Puredata plugin specific settings
include(PuredataConfig)

set(PUREDATA_BINARY_DIR "${PROJECT_BINARY_DIR}/pd/sfizz")

set(PUREDATA_RESOURCES
    "sfizz~-help.pd"
    "example.sfz")

function(copy_puredata_resources TARGET SOURCE_DIR DESTINATION_DIR)
    set(_deps)
    foreach(res ${PUREDATA_RESOURCES})
        get_filename_component(_dir "${res}" DIRECTORY)
        file(MAKE_DIRECTORY "${DESTINATION_DIR}/${_dir}")
        add_custom_command(
            OUTPUT "${DESTINATION_DIR}/${res}"
            COMMAND "${CMAKE_COMMAND}" "-E" "copy"
                    "${SOURCE_DIR}/${res}" "${DESTINATION_DIR}/${res}"
            DEPENDS "${SOURCE_DIR}/${res}")
        list(APPEND _deps "${DESTINATION_DIR}/${res}")
    endforeach()
    add_custom_target("${TARGET}_puredata_resources" DEPENDS ${_deps})
    add_dependencies("${TARGET}" "${TARGET}_puredata_resources")
endfunction()

add_pd_external(plugins_puredata "sfizz_puredata.c")

if(SFIZZ_CMAKE_USE_EMPTY_SOURCE_GROUPS)
    source_group("" FILES sfizz_puredata.c)
endif()

target_compile_definitions(plugins_puredata PRIVATE
    "MIDI_CC_COUNT=${MIDI_CC_COUNT}"
    "SFIZZ_VERSION=\"${CMAKE_PROJECT_VERSION}\""
)
target_link_libraries(plugins_puredata PRIVATE
    sfizz::import
    sfizz::sfizz
    plugins::git_build_id
)
set_target_properties(plugins_puredata PROPERTIES
    OUTPUT_NAME "sfizz"
    LIBRARY_OUTPUT_DIRECTORY "${PUREDATA_BINARY_DIR}/$<0:>")

if(MINGW)
    set_property(TARGET plugins_puredata APPEND_STRING
        PROPERTY LINK_FLAGS " -static")
endif()

# Copy resources
copy_puredata_resources(plugins_puredata
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${PUREDATA_BINARY_DIR}")

# Installation
if(NOT MSVC)
    install(DIRECTORY "${PUREDATA_BINARY_DIR}" DESTINATION "${PD_PLUGIN_INSTALL_DIR}"
        COMPONENT "puredata"
        USE_SOURCE_PERMISSIONS)
    bundle_dylibs(puredata
        "${PD_PLUGIN_INSTALL_DIR}/sfizz/sfizz${PUREDATA_SUFFIX}"
        COMPONENT "puredata")
endif()
