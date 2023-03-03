# Configures and calls CPack in a straightforward manner, designed to be called from
# top-level CMakeLists.txt
#
# Assumes README.md and LICENSE are in root project directory, places package out in
# ${CMAKE_CURRENT_BINARY_DIR}/out/dist by default.
#
# Makes use of BUILD_SHARED_LIBS to determine if build should be marked as Static or Shared.
#
# The suffix argument does not automatically use a leading "_"
#
# Requires ob_standard_project_setup() or ob_setup_verbose_versioning() otherwise
# to have been used.

function(ob_standard_project_package)
    # Additional Function inputs
    set(oneValueArgs
        VENDOR
        SUFFIX
        DIRECTORY
    )
    
    set(requiredArgs
        VENDOR
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_PKG "" "${oneValueArgs}" "" "${requiredArgs}" ${ARGN})

    # Handle output directory
    if(STD_PKG_DIRECTORY)
        set(__output_pkg_dir "${STD_PKG_DIRECTORY}")
    else()
        set(__output_pkg_dir "${CMAKE_CURRENT_BINARY_DIR}/out/dist")
    endif()

    # Get system architecture
    ob_get_system_architecture(__target_arch)
    
    # Determine linkage string
    if(BUILD_SHARED_LIBS)
        set(link_str "Shared")
    else()
        set(link_str "Static")
    endif()

    set(CPACK_PACKAGE_VENDOR "${STD_PKG_VENDOR}")
    set(CPACK_PACKAGE_DIRECTORY "${__output_pkg_dir}")
    set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}_${PROJECT_VERSION_VERBOSE}_${CMAKE_SYSTEM_NAME}_${link_str}_${__target_arch}${STD_PKG_SUFFIX}")
    set(CPACK_GENERATOR "ZIP")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
    include(CPack)
endfunction()