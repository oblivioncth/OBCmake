# Configures and calls CPack in a straightforward manner, designed to be called from
# top-level CMakeLists.txt
#
# Assumes README.md and LICENSE are in root project directory, places package out in
# ${CMAKE_CURRENT_BINARY_DIR}/out/dist by default.
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

    # Parse arguments
    cmake_parse_arguments(STD_PKG "" "${oneValueArgs}" "" ${ARGN})

    # Validate input
    foreach(unk_val ${STD_PKG_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(STD_PKG_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${STD_PKG_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(WARNING "Not all required values were present!")
    endif()

    # Handle output directory
    if(STD_PKG_DIRECTORY)
        set(__output_pkg_dir "${STD_PKG_DIRECTORY}")
    else()
        set(__output_pkg_dir "${CMAKE_CURRENT_BINARY_DIR}/out/dist")
    endif()

    # Get system architecture
    include(OB/Utility)
    ob_get_system_architecture(__target_arch)

    set(CPACK_PACKAGE_VENDOR "${STD_PKG_VENDOR}")
    set(CPACK_PACKAGE_DIRECTORY "${__output_pkg_dir}")
    set(CPACK_PACKAGE_FILE_NAME "${PROJECT_NAME}_${PROJECT_VERSION_VERBOSE}_${CMAKE_SYSTEM_NAME}_${__target_arch}${STD_PKG_SUFFIX}")
    set(CPACK_GENERATOR "ZIP")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
    set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")
    include(CPack)
endfunction()

# Creates a standard package config and version config file for the project.
#
# PROJECT_VERSION is used for the package version. Uses the CammelCase style of package
# config files.
# 
# - OUTPUT_DIRECTORY is "${CMAKE_CURRENT_BINARY_DIR}/cmake" if not defined
# - PACKAGE_NAME is "${PROJECT_NAME}" if not defined
# - COMPATIBILITY is to be defined the same as in write_basic_package_version_file()
# - DEPENDENCIES is to be defined as a list of PACKAGE and optional COMPONENT combos
#                e.g. "PACKAGE Qt6 COMPONENTS Core Network"
# - INSTALL_DESTINATION is to be defined the same as in configure_package_config_file(),
#                       if not defined, a 'cmake' sub-folder of the install prefix is used

# Helper
function(__ob_parse_dependency return)
    #---------------- Function Setup ----------------------
    # Const variables
    set(COMPONENT_ENTRY_TEMPLATE "find_dependency(@DEPENDENCY_PACKAGE@ COMPONENTS @DEPENDENCY_COMPONENTS@)")
    set(ENTRY_TEMPLATE "find_dependency(@DEPENDENCY_PACKAGE@)")

    # Additional Function inputs
    set(oneValueArgs
        PACKAGE
    )

    set(multiValueArgs
        COMPONENTS
    )

    # Parse arguments
    cmake_parse_arguments(DEPENDENCY "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input
    foreach(unk_val ${DEPENDENCY_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(DEPENDENCY_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${DEPENDENCY_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(FATAL_ERROR "Not all required values were present!")
    endif()

    # Handle undefineds
    if(NOT DEFINED DEPENDENCY_PACKAGE)
        message(FATAL_ERROR "A package for each dependency entry must be included!")
    endif()

    #---------------- Parse Dependency  ----------------------
    if(DEFINED DEPENDENCY_COMPONENTS)
        string(CONFIGURE "${COMPONENT_ENTRY_TEMPLATE}" PARSED_ENTRY @ONLY)
    else()
        string(CONFIGURE "${ENTRY_TEMPLATE}" PARSED_ENTRY @ONLY)
    endif()

    set(${return} "${PARSED_ENTRY}" PARENT_SCOPE)
endfunction()

# Main function
function(ob_standard_project_package_config)
    #---------------- Function Setup ----------------------
    # Const variables
    set(CFG_TEMPLATE_FILE "__standard_pkg_cfg.cmake.in")

    # Additional Function inputs
    set(oneValueArgs
        OUTPUT_DIRECTORY
        INSTALL_DESTINATION
        PACKAGE_NAME
        COMPATIBILITY
    )

    set(multiValueArgs
        DEPENDENCIES
    )

    # Parse arguments
    cmake_parse_arguments(STD_PKG_CFG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input
    foreach(unk_val ${STD_PKG_CFG_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(STD_PKG_CFG_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${STD_PKG_CFG_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(WARNING "Not all required values were present!")
    endif()

    # Handle output directory
    if(STD_PKG_CFG_OUTPUT_DIRECTORY)
        set(__output_prefix "${STD_PKG_CFG_OUTPUT_DIRECTORY}")
    else()
        set(__output_prefix "${CMAKE_CURRENT_BINARY_DIR}/cmake")
    endif()

    # Handle install destination
    if(STD_PKG_CFG_INSTALL_DESTINATION)
        set(__install_dest "${STD_PKG_CFG_INSTALL_DESTINATION}")
    else()
        set(__install_dest "cmake")
    endif()

    # Handle package name
    if(STD_PKG_CFG_PACKAGE_NAME)
        set(PACKAGE_NAME "${STD_PKG_CFG_PACKAGE_NAME}")
    else()
        set(PACKAGE_NAME "${PROJECT_NAME}")
    endif()

    # Handle compatibility
    if(NOT DEFINED STD_PKG_CFG_COMPATIBILITY)
        message(FATAL_ERROR "A compatibility level must be provided!")
    endif()

    #---------------- Prepare Configuration  ----------------------

    # Create dependency check statements via the "PACKAGE" and "COMPONENT" sets
    include(OB/Utility)
    ob_parse_arguments_list(
        "PACKAGE"
        "__ob_parse_dependency"
        dependency_check_statements
        ${STD_PKG_CFG_DEPENDENCIES}
    )

    # Create multi-line string for dependency checks
    foreach(dep_statement ${dependency_check_statements})
        set(DEPENDENCY_CHECKS "${DEPENDENCY_CHECKS}${dep_statement}\n")
    endforeach()

    # Create config and version files
    include(CMakePackageConfigHelpers)

    configure_package_config_file(
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${CFG_TEMPLATE_FILE}"
        "${__output_prefix}/${PACKAGE_NAME}Config.cmake"
        INSTALL_DESTINATION "${__install_dest}"
    )

    write_basic_package_version_file(
        "${__output_prefix}/${PACKAGE_NAME}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY ${STD_PKG_CFG_COMPATIBILITY}
    )
endfunction()