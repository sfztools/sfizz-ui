#set(AUWRAPPER_BASEDIR "${VST3SDK_BASEDIR}/public.sdk/source/vst/auwrapper")
set(AUWRAPPER_BASEDIR "${CMAKE_CURRENT_SOURCE_DIR}/external/sfzt_auwrapper")
set(AU_PLUGIN_PRJ_NAME "plugins_au")
set(AU_PLUGIN_BUNDLE_NAME "${PROJECT_NAME}.component")

add_library(${AU_PLUGIN_PRJ_NAME} MODULE
    "VstPluginFactory.cpp"
    "${AUWRAPPER_BASEDIR}/aucarbonview.mm"
    "${AUWRAPPER_BASEDIR}/aucocoaview.mm"
    "${AUWRAPPER_BASEDIR}/ausdk.mm"
    "${AUWRAPPER_BASEDIR}/auwrapper.mm"
    "${AUWRAPPER_BASEDIR}/NSDataIBStream.mm")
target_include_directories(${AU_PLUGIN_PRJ_NAME} PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}"
    "${VST3SDK_BASEDIR}")
target_link_libraries(${AU_PLUGIN_PRJ_NAME} PRIVATE
    "${APPLE_FOUNDATION_LIBRARY}"
    "${APPLE_COCOA_LIBRARY}"
    "${APPLE_CARBON_LIBRARY}"
    "${APPLE_AUDIOTOOLBOX_LIBRARY}"
    "${APPLE_AUDIOUNIT_LIBRARY}"
    "${APPLE_COREAUDIO_LIBRARY}"
    "${APPLE_COREMIDI_LIBRARY}")

target_link_libraries(${AU_PLUGIN_PRJ_NAME}
    PRIVATE plugins_vst3_core)
set_target_properties(${AU_PLUGIN_PRJ_NAME} PROPERTIES
    OUTPUT_NAME "${PROJECT_NAME}"
    PREFIX "")

plugin_add_vst3sdk(${AU_PLUGIN_PRJ_NAME})
plugin_add_vstgui(${AU_PLUGIN_PRJ_NAME})

# Get Core Audio utility classes if missing
set(CA_UTILITY_BASEDIR
    "${CMAKE_CURRENT_SOURCE_DIR}/external/CoreAudioUtilityClasses")
if(EXISTS "${CA_UTILITY_BASEDIR}")
    message(STATUS "The CoreAudioUtilityClasses are available locally")
else()
    message(STATUS "The CoreAudioUtilityClasses are not available locally")

    set(CA_UTILITY_VERSION "1.1")
    set(CA_UTILITY_ARCHIVE "CoreAudioUtilityClasses-${CA_UTILITY_VERSION}.tar.gz")
    set(CA_UTILITY_DOWNLOAD_URL "https://github.com/sfztools/CoreAudioUtilityClasses/releases/download/v${CA_UTILITY_VERSION}/${CA_UTILITY_ARCHIVE}")
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/download/${CA_UTILITY_ARCHIVE}")
        message(STATUS "The CoreAudioUtilityClasses archive is available")
    else()
        message(STATUS "The CoreAudioUtilityClasses archive is missing")
        message(STATUS "Downloading: ${CA_UTILITY_DOWNLOAD_URL}")

        file(MAKE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/download")
        file(DOWNLOAD "${CA_UTILITY_DOWNLOAD_URL}"
            "${CMAKE_CURRENT_SOURCE_DIR}/download/${CA_UTILITY_ARCHIVE}")
    endif()
    message(STATUS "Extracting: ${CA_UTILITY_ARCHIVE}")
    execute_process(COMMAND "${CMAKE_COMMAND}" "-E" "tar" "xvf"
        "${CMAKE_CURRENT_SOURCE_DIR}/download/${CA_UTILITY_ARCHIVE}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/external")
endif()

# Add Core Audio utility classes
target_include_directories(${AU_PLUGIN_PRJ_NAME} PRIVATE
    "${CA_UTILITY_BASEDIR}/CoreAudio"
    "${CA_UTILITY_BASEDIR}/CoreAudio/AudioUnits"
    "${CA_UTILITY_BASEDIR}/CoreAudio/AudioUnits/AUPublic/AUBase"
    "${CA_UTILITY_BASEDIR}/CoreAudio/AudioUnits/AUPublic/Utility"
    "${CA_UTILITY_BASEDIR}/CoreAudio/PublicUtility")

# Add VST hosting classes
target_link_libraries(${AU_PLUGIN_PRJ_NAME} PRIVATE vst3sdk_hosting)

# Add generated source
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include")
target_include_directories(${AU_PLUGIN_PRJ_NAME} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/include")
string(TIMESTAMP SFIZZ_AU_CLASS_PREFIX_NUMBER "%s" UTC)
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/include/aucocoaclassprefix.h"
    "#define SMTG_AU_NAMESPACE SMTGAUCocoa${SFIZZ_AU_CLASS_PREFIX_NUMBER}_")

sfizz_enable_lto_if_needed(${AU_PLUGIN_PRJ_NAME})

# Create the bundle
execute_process(
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/Resources")
copy_editor_resources(
    ${AU_PLUGIN_PRJ_NAME}
    "${CMAKE_CURRENT_SOURCE_DIR}/../editor/resources"
    "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/Resources")
set_target_properties(${AU_PLUGIN_PRJ_NAME} PROPERTIES
    SUFFIX ""
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/MacOS/$<0:>")
file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/mac/PkgInfo"
    DESTINATION "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents")
set(SFIZZ_AU_BUNDLE_EXECUTABLE "${PROJECT_NAME}")
set(SFIZZ_AU_BUNDLE_VERSION "${PROJECT_VERSION}")
set(SFIZZ_AU_BUNDLE_IDENTIFIER "tools.sfz.sfizz.au")
set(SFIZZ_AU_BUNDLE_TYPE "aumu")
set(SFIZZ_AU_BUNDLE_SUBTYPE "samp")
set(SFIZZ_AU_BUNDLE_MANUFACTURER "Sfzt")
set(SFIZZ_AU_BUNDLE_AUTHOR "SFZTools")
math(EXPR SFIZZ_AU_DECIMAL_VERSION
    "${PROJECT_VERSION_MAJOR}*256*256 + ${PROJECT_VERSION_MINOR}*256 + ${PROJECT_VERSION_PATCH}")
execute_process(
    COMMAND "sh" "-c" "echo 'obase=16;${SFIZZ_AU_DECIMAL_VERSION}' | bc"
    OUTPUT_VARIABLE SFIZZ_AU_HEXADECIMAL_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/mac/Info.au.plist"
    "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/Info.plist" @ONLY)

file(COPY "gpl-3.0.txt"
    DESTINATION "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/SharedSupport/License")

# Add the resource fork
if(FALSE)
    execute_process(COMMAND "xcrun" "--find" "Rez"
        OUTPUT_VARIABLE OSX_REZ_COMMAND OUTPUT_STRIP_TRAILING_WHITESPACE)
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/mac/audiounitconfig.h.in"
        "${CMAKE_CURRENT_BINARY_DIR}/include/audiounitconfig.h" @ONLY)
    add_custom_command(TARGET ${AU_PLUGIN_PRJ_NAME} POST_BUILD COMMAND
        "${OSX_REZ_COMMAND}"
        "-d" "SystemSevenOrLater=1"
        "-script" "Roman"
        "-d" "i386_YES"
        "-d" "x86_64_YES"
        "-is" "${CMAKE_OSX_SYSROOT}"
        "-I" "${CMAKE_OSX_SYSROOT}/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Versions/A/Headers"
        "-I" "/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Versions/A/Headers"
        "-I" "/System/Library/Frameworks/AudioUnit.framework/Versions/A/Headers/"
        "-I" "${CA_UTILITY_BASEDIR}/CoreAudio/AudioUnits/AUPublic/AUBase"
        "-I" "${CMAKE_CURRENT_BINARY_DIR}/include" # generated audiounitconfig.h
        "-o" "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/Resources/${PROJECT_NAME}.rsrc"
        "-useDF"
        "${AUWRAPPER_BASEDIR}/auresource.r")
endif()

# Installation
if(AU_PLUGIN_INSTALL_DIR)
    install(DIRECTORY "${PROJECT_BINARY_DIR}/${AU_PLUGIN_BUNDLE_NAME}"
        DESTINATION "${AU_PLUGIN_INSTALL_DIR}"
        COMPONENT "au"
        USE_SOURCE_PERMISSIONS)
    bundle_dylibs(au
        "${AU_PLUGIN_INSTALL_DIR}/${AU_PLUGIN_BUNDLE_NAME}/Contents/MacOS/sfizz"
        COMPONENT "au")
endif()
