# Find Linux system libraries
add_library(dl INTERFACE)

if(NOT WIN32 AND NOT APPLE)
    find_library(DL_LIBRARY "dl")
    target_link_libraries(dl INTERFACE "${DL_LIBRARY}")

    # JACK
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(JACK "jack" REQUIRED)

    # The X11 library
    find_package(X11 REQUIRED)
    add_library(sfizz_x11 INTERFACE)
    target_include_directories(sfizz_x11 INTERFACE "${X11_INCLUDE_DIR}")
    target_link_libraries(sfizz_x11 INTERFACE "${X11_X11_LIB}")
    add_library(sfizz::x11 ALIAS sfizz_x11)

    # The GtkMM library
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTKMM "gtkmm-3.0" REQUIRED)
    add_library(sfizz_gtkmm INTERFACE)
    target_include_directories(sfizz_gtkmm INTERFACE ${GTKMM_INCLUDE_DIRS})
    target_link_libraries(sfizz_gtkmm INTERFACE ${GTKMM_LIBRARIES})
    link_libraries(${GTKMM_LIBRARY_DIRS})
    add_library(sfizz::gtkmm ALIAS sfizz_gtkmm)
endif()

add_library(sfizz::dl ALIAS dl)
