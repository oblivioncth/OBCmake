# - Set's non-intrusive default install prefix for top level projects
# - Adds the install directory to the clean target
# - Defines a variable containing "EXCLUDE_FROM_ALL" if project is not top-level, empty otherwise
# - Defines a variable containing "ALL" if project is top-level, empty otherwise
macro(ob_top_level_project_setup)
    if(${PROJECT_IS_TOP_LEVEL})
        message(STATUS "NOTE: ${PROJECT_NAME} is being configured as a top-level project")

        # Install (override the CMake default, but not a user set value)
        if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
            set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/out/install"
                   CACHE PATH "Project install path" FORCE
            )
        endif()

        # Clean install when clean target is ran
        set_directory_properties(PROPERTIES ADDITIONAL_CLEAN_FILES "${CMAKE_INSTALL_PREFIX}")
        
        # Define vars
        set(TOP_PROJ_INCLUDE_IN_ALL "ALL")
        set(SUB_PROJ_EXCLUDE_FROM_ALL "")
    else()
        message(STATUS "NOTE: ${PROJECT_NAME} is being configured as a sub-project")

        # Keep install components out of 'all' target
        set(TOP_PROJ_INCLUDE_IN_ALL "")
        set(SUB_PROJ_EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
    endif()
endmacro()

# Performs additional setup of a project
#
# - Defines PROJECT_NAME_LC and PROJECT_NAME_UC, self-explanatory, except that '-' is also switched
#   for '_' in both of those versions of the name
# - Performs setup according to reasonable standards, similar to qt_standard_project_setup():
#   https://github.com/qt/qtbase/blob/26fec96a813b8d1c4955b394794c66e5e830e4c4/src/corelib/Qt6CoreMacros.cmake#L2734
#   > Automatically includes CMake's GNUInstallDirs
#   > Sets a reasonable default for CMAKE_RUNTIME_OUTPUT_DIRECTORY on Windows if it isn't already set
#   > Appends reasonable values to CMAKE_INSTALL_RPATH on platforms that support it
# - Defines PROJECT_CMAKE_MINIMUM_REQUIRED_VERSION to the version present when the project is defined. Useful since
#   find_package/find_dependency calls can override this
# - Does everything described by `ob_top_level_project_setup`
# - Calls ob_setup_verbose_versioning() and defines PROJECT_VERSION_VERBOSE to the result
# - Defines PROJECT_FILE_TEMPLATES set to "${CMAKE_CURRENT_SOURCE_DIR}/cmake/file_templates"
# - Appends "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module" to CMAKE_MODULE_PATH
#
# TODO: Add tuneable arguments to this as needed

macro(ob_standard_project_setup)    
    # Note current cmake minimum version
    set(PROJECT_CMAKE_MINIMUM_REQUIRED_VERSION "${CMAKE_MINIMUM_REQUIRED_VERSION}")
    
    # Set lowercase and uppercase names
    string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LC)
    string(REPLACE "-" "_" PROJECT_NAME_LC "${PROJECT_NAME_LC}")
    string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UC)
    string(REPLACE "-" "_" PROJECT_NAME_UC "${PROJECT_NAME_UC}")
    
    # Include CMake GNUInstallDirs
    include(GNUInstallDirs)
    
    # Set reasonable defaults for CMAKE_RUNTIME_OUTPUT_DIRECTORY on windows and CMAKE_INSTALL_RPATH on non-Apple
    # Unix platforms. Puts DLLs in bin directory on Windows and allows applications to more easily find libraries
    # within the same folder structure on those other platforms
    if(WIN32)
        if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
            set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
        endif()
    elseif(NOT APPLE)
        file(RELATIVE_PATH __ob_bin2lib_path
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}
        )
        list(APPEND CMAKE_INSTALL_RPATH $ORIGIN $ORIGIN/${__ob_bin2lib_path})
        list(REMOVE_DUPLICATES CMAKE_INSTALL_RPATH)
        unset(__ob_bin2lib_path)
    endif()

    # Perform top-level setup
    ob_top_level_project_setup()
    
    # Setup verbose versioning
    include(OB/VerboseVersioning)
    ob_setup_verbose_versioning(PROJECT_VERSION_VERBOSE)

    # Add local modules and file templates
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module")
    set(PROJECT_FILE_TEMPLATES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/file_templates")
endmacro()

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
    set(COMPONENT_ENTRY_TEMPLATE "find_dependency(@DEPENDENCY_PACKAGE@ COMPONENTS@components_list@)")
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
        # Split components list to one string
        foreach(comp ${DEPENDENCY_COMPONENTS})
            set(components_list "${components_list} ${comp}")
        endforeach()
    
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
    string(CONCAT DEPENDENCY_CHECKS_HEADING
        "\n"
        "# Check for hard dependencies\n"
        "include(CMakeFindDependencyMacro)\n"
    )

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

    if(DEFINED STD_PKG_CFG_DEPENDENCIES)
        # Create dependency check statements via the "PACKAGE" and "COMPONENT" sets
        include(OB/Utility)
        ob_parse_arguments_list(
            "PACKAGE"
            "__ob_parse_dependency"
            dependency_check_statements
            ${STD_PKG_CFG_DEPENDENCIES}
        )

        # Create multi-line string for dependency checks
        set(DEPENDENCY_CHECKS "${DEPENDENCY_CHECKS_HEADING}")
        foreach(dep_statement ${dependency_check_statements})
            set(DEPENDENCY_CHECKS "${DEPENDENCY_CHECKS}${dep_statement}\n")
        endforeach()
    endif()

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

# Invokes the `install` for standard project level files:
# - Package and package version config
# - README.md and LICENSE
#
# Expects the CammelCase style of package config files, and the README and LICENSE to be
# Located in CMAKE_CURRENT_SOURCE_DIR.
#
# - CONFIG_INPUT_DIRECTORY is where to look for the package config and config version files,
#   "${CMAKE_CURRENT_BINARY_DIR}/cmake" if not defined
# - CONFIG_DESTINATION is where the files are where the config and config version files are
#   installed to, the 'cmake' directory relative to CMAKE_INSTALL_PREFIX is used if not defined
# - PACKAGE_NAME is package name the function should expect for the config and config version
#   files, PROJECT_NAME is used if not defined
#
# Requires ob_standard_project_setup() or ob_top_level_project_setup() to have been called.
#
# This function uses the SUB_PROJ_EXCLUDE_FROM_ALL variable to disable these installs
# when the project is used as a sub-project
#
# The install component for both installs is set to PROJECT_NAME_LC.
function(ob_standard_project_install)
    # Additional Function inputs
    set(oneValueArgs
        CONFIG_INPUT_DIRECTORY
        CONFIG_DESTINATION
        PACKAGE_NAME
    )

    # Parse arguments
    cmake_parse_arguments(STD_PROJ_INSTALL "" "${oneValueArgs}" "${}" ${ARGN})

    # Validate input
    foreach(unk_val ${STD_PROJ_INSTALL_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(STD_PROJ_INSTALL_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${STD_PROJ_INSTALL_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(WARNING "Not all required values were present!")
    endif()

    # Handle config input directory
    if(STD_PROJ_INSTALL_CONFIG_INPUT_DIRECTORY)
        set(__config_input_prefix "${STD_PROJ_INSTALL_CONFIG_INPUT_DIRECTORY}")
    else()
        set(__config_input_prefix "${CMAKE_CURRENT_BINARY_DIR}/cmake")
    endif()

    # Handle config install destination
    if(STD_PROJ_INSTALL_CONFIG_DESTINATION)
        set(__config_install_dest "${STD_PROJ_INSTALL_CONFIG_DESTINATION}")
    else()
        set(__config_install_dest "cmake")
    endif()

    # Handle package name
    if(STD_PROJ_INSTALL_PACKAGE_NAME)
        set(__package_name "${STD_PROJ_INSTALL_PACKAGE_NAME}")
    else()
        set(__package_name "${PROJECT_NAME}")
    endif()

    #---------------- Installs  ----------------------

    # Install README and LICENSE
    install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
        "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE"
        COMPONENT ${PROJECT_NAME_LC}
        DESTINATION .
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )

    # Install Package Config
    install(FILES
        "${__config_input_prefix}/${__package_name}Config.cmake"
        "${__config_input_prefix}/${__package_name}ConfigVersion.cmake"
        COMPONENT ${PROJECT_NAME_LC}
        DESTINATION ${__config_install_dest}
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )
endfunction()
