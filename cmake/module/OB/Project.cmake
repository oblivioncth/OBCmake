include("${__OB_CMAKE_PRIVATE}/common.cmake")

# - Set's non-intrusive default install prefix for top level projects
# - Adds the install directory to the clean target
# - Defines a variable containing "EXCLUDE_FROM_ALL" if project is not top-level, empty otherwise
# - Defines a variable containing "ALL" if project is top-level, empty otherwise
macro(ob_top_level_project_setup)
    __ob_command(ob_top_level_project_setup "3.21.0")

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
# - Defines PROJECT_NAME_LC and PROJECT_NAME_UC, self-explanatory
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
# - Defines PROJECT_NAMESPACE set to PROJECT_NAME
#
# TODO: Add tuneable arguments to this as needed

macro(ob_standard_project_setup)
    __ob_command(ob_standard_project_setup "3.21.0")

    # Note current cmake minimum version
    set(PROJECT_CMAKE_MINIMUM_REQUIRED_VERSION "${CMAKE_MINIMUM_REQUIRED_VERSION}")

    # Set lowercase and uppercase names
    string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LC)
    string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UC)

    # Include CMake GNUInstallDirs
    include(GNUInstallDirs)

    # Set reasonable defaults for CMAKE_RUNTIME_OUTPUT_DIRECTORY on windows and CMAKE_INSTALL_RPATH on non-Apple
    # Unix platforms. Puts DLLs in bin directory on Windows and adds compiler flags on Unix such that built executables
    # will search "../lib" for shared libraries, allowing them to run as they are structured within an install package.
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

    # Define namespace var using project name
    set(PROJECT_NAMESPACE "${PROJECT_NAME}")
    string(TOLOWER ${PROJECT_NAMESPACE} PROJECT_NAMESPACE_LC)
    string(TOUPPER ${PROJECT_NAMESPACE} PROJECT_NAMESPACE_UC)
endmacro()

function(__ob_split_target_config_nsa_str str ns_out alias_out)
    __ob_internal_command(__ob_split_target_config_nsa_str "3.0.0")

    # Const
    set(SEP "::")

    # Validate
    string(FIND "${str}" "${SEP}" sep_pos)

    if(sep_pos EQUAL -1)
        message(FATAL_ERROR "'${str}' is not a valid TARGET_CONFIGS string!" )
    endif()

    # Split
    string(REPLACE "${SEP}" ";" kv_list "${str}")
    list(GET kv_list 0 namespace)
    list(GET kv_list 1 alias)

    # Return
    set(${ns_out} "${namespace}" PARENT_SCOPE)
    set(${alias_out} "${alias}" PARENT_SCOPE)
endfunction()

function(__ob_process_config_target_config output)
    __ob_internal_command(__ob_process_config_target_config "3.0.0")

    # Const variables
    set(_tmpl_set_inclusion [[set(__inclusion "${CMAKE_CURRENT_LIST_DIR}/@+INCL_PATH+@")]])
    set(_tmpl_if_not_exists [[if(NOT EXISTS "${__inclusion}")]])
    set(_tmpl_if_exist_and_sel [[if(EXISTS "${__inclusion}") AND @+CMP+@ IN_LIST @+PKG_NAME+@_FIND_COMPONENTS)]])
    set(_tmpl_if_sel_or_default [[if(@+CMP+@ IN_LIST @+PKG_NAME+@_FIND_COMPONENTS OR NOT @+PKG_NAME+@_FIND_COMPONENTS)]])
    set(_tmpl_include [[include("${__inclusion}")]])
    set(_tmpl_err_no_always [[message(FATAL_ERROR "A mandatory inclusion of @+PKG_NAME+@ was missing!")]])
    set(_tmpl_err_no_default [[message(FATAL_ERROR "A default inclusion of @+PKG_NAME+@ was missing!")]])
    set(_tmpl_found_comp [[set(@+PKG_NAME+@_@+CMP+@_FOUND TRUE)]])
    set(_tmpl_endif [[endif()]])
    
    # Arguments
    set(opt
        DEFAULT
        OPTIONAL
    )
    
    set(ova
        TARGET
        COMPONENT
    )
        
    set(req
        TARGET
    )

    # Parse arguments
    ob_parse_arguments(STD_PCF "${opt}" "${ova}" "" "${req}" ${ARGN})
    
    # Simplify inputs
    set(_TARGET "${STD_PCF_TARGET}")
    set(_COMPONENT "${STD_PCF_COMPONENT}")
    set(_DEFAULT "${STD_PCF_DEFAULT}")
    set(_OPTIONAL "${STD_PCF_OPTIONAL}")
    
    # Check that target exists
    if(NOT TARGET "${_TARGET}")
        if(_OPTIONAL)
            set(${output} "" PARENT_SCOPE)
            return()
        else()
            message(FATAL_ERROR "${_TARGET} is not a valid target!")
        endif()
    endif()
    
    # Prepare config string
    if(NOT _COMPONENT)
        string(CONCAT config_str
            "${_tmpl_set_inclusion}\n"
            "${_tmpl_if_not_exists}\n"
            "   ${_tmpl_err_no_always}\n"
            "${_tmpl_endif}\n"
            "${_tmpl_include}\n"
        )
    elseif(_DEFAULT)
        string(CONCAT config_str
            "${_tmpl_set_inclusion}\n"
            "${_tmpl_if_not_exists}\n"
            "   ${_tmpl_err_no_default}\n"
            "else${_tmpl_if_sel_or_default}\n"
            "   ${_tmpl_found_comp}\n"
            "   ${_tmpl_include}\n"
            "${_tmpl_endif}\n"
        )
    else()
        string(CONCAT config_str
            "${_tmpl_set_inclusion}\n"
            "${_tmpl_if_exist_and_sel}\n"
            "   ${_tmpl_found_comp}\n"
            "   ${_tmpl_include}\n"
            "${_tmpl_endif}\n"
        )
    endif()
    
    # Split namespace and alias from target
    __ob_split_target_config_nsa_str("${_TARGET}" ns alias)
    
    # Prepare configure arguments
    set(+PKG_NAME+ "${pkg_name}") # NOTE: Taken from parent scope
    set(+CMP+ "${_COMPONENT}")
    set(+INCL_PATH+ "${alias}/${ns}${alias}Config.cmake")

    # Configure and return string
    string(CONFIGURE "${config_str}" prepared_str @ONLY)
    set(${output} "${prepared_str}" PARENT_SCOPE)
endfunction()

function(__ob_process_config_opt_std pkg_name gen_file)
    __ob_internal_command(__ob_process_config_opt_std "3.18.0")
    
    # Const variables
    set(CFG_TEMPLATE_FILE "${__OB_CMAKE_PRIVATE}/templates/__standard_primary_pkg_cfg.cmake.in")
    set(+PACKAGE_NAME+ "${pkg_name}")
    string(CONCAT +PRESUME_FOUND+
        "# Start by assuming package is found\n"
        "set(${pkg_name}_FOUND TRUE)\n"
        "\n"
    )
    string(CONCAT DEPENDENCY_CHECKS_HEADING
        "# Check for hard dependencies\n"
        "include(CMakeFindDependencyMacro)\n"
    )
    string(CONCAT CONFIG_INCLUDES_HEADING
        "# Import target configs\n"
    )

    set(mva
        TARGET_CONFIGS
        DEPENDS
    )
    
    set(req
        TARGET_CONFIGS
    )

    # Parse arguments
    ob_parse_arguments(STD_PCF "" "" "${mva}" "${req}" ${ARGN})
    
    # Handle target configs
    ob_parse_arguments_list(
        "TARGET"
        "__ob_process_config_target_config"
        target_config_statements
        ${STD_PCF_TARGET_CONFIGS}
    )
    
    set(+CONFIG_INCLUDES+ "${CONFIG_INCLUDES_HEADING}")
    foreach(cfg_statement ${target_config_statements})
        set(+CONFIG_INCLUDES+ "${+CONFIG_INCLUDES+}${cfg_statement}\n")
    endforeach()
    
    # Handle dependencies
    if(STD_PCF_DEPENDS)
        # Create dependency check statements via the "PACKAGE", "COMPONENT" and "VERSION" sets
        ob_parse_arguments_list(
            "PACKAGE"
            "__ob_parse_dependency"
            dependency_check_statements
            ${STD_PCF_DEPENDS}
        )

        # Create multi-line string for dependency checks
        set(+DEPENDENCY_CHECKS+ "${DEPENDENCY_CHECKS_HEADING}")
        foreach(dep_statement ${dependency_check_statements})
            set(+DEPENDENCY_CHECKS+ "${+DEPENDENCY_CHECKS+}${dep_statement}\n")
        endforeach()
        set(+DEPENDENCY_CHECKS+ "${+DEPENDENCY_CHECKS+}\n")
    endif()
    
    # Configure file
    configure_package_config_file(
        "${CFG_TEMPLATE_FILE}"
        "${gen_file}"
        INSTALL_DESTINATION "cmake"
        NO_SET_AND_CHECK_MACRO
    )    
endfunction()

function(__ob_process_config_opt_custom in_path gen_file)
    __ob_internal_command(__ob_process_config_opt_custom "3.0.0")

        configure_package_config_file(
            "${in_path}"
            "${gen_file}"
            INSTALL_DESTINATION "cmake"
        )
endfunction()

function(__ob_process_config_opt pkg_name gen_file)
    __ob_internal_command(__ob_process_config_opt "3.18.0")

    set(ova
        CUSTOM
    )
    
    set(mva
        STANDARD
    )

    # Parse arguments
    ob_parse_arguments(CONFIG "" "${ova}" "${mva}" "" ${ARGN})

    # Must have one, and only one form
    if(DEFINED CONFIG_CUSTOM AND CONFIG_STANDARD)
        message(FATAL_ERROR "CUSTOM and STANDARD mode are mutually exclusive!")
    elseif(NOT DEFINED CONFIG_CUSTOM AND NOT CONFIG_STANDARD)
        message(FATAL_ERROR "Either CUSTOM or STANDARD must be used!")
    endif()
    
    # Standard Form
    if(CONFIG_STANDARD)
        __ob_process_config_opt_std("${pkg_name}" "${gen_file}" ${CONFIG_STANDARD})
    else() # Custom Form
        __ob_process_config_opt_custom("${CONFIG_CUSTOM}" "${gen_file}")
    endif()
endfunction()

# Creates a standard package config and version config file for the project.
#
# PROJECT_VERSION is used for the package version. Uses the CammelCase style of package
# config files.
#
# - PACKAGE_NAME is "${PROJECT_NAME}" if not defined
# - COMPATIBILITY is to be defined the same as in write_basic_package_version_file()
# - CONFIG:
#   This argument is mandatory and can take two forms.
#
#   First:
#       CONFIG
#       CONFIG STANDARD
#           TARGET_CONFIGS
#               TARGET
#               COMPONENT
#               DEFAULT
#           DEPENDS
#
#   This form configures a package configuration file set to include
#   the provided target related package config files and find the optional dependencies
#   if provided.
#
#   TARGET_CONFIGS is to be a list of targets in the form Namespace::Alias, where each
#   entry will result in the final config file including each target config as:
#   "${CMAKE_CURRENT_LIST_DIR}/Namespace/NamespaceAliasConfig.cmake".
#   The config is installed into ${CMAKE_INSTALL_PREFIX}/cmake, making the inclusion paths
#   TARGET_CONFIGS is to be a list of entries that correlate to target configs.
#   Each must have at least a TARGET in the form Namespace::Alias,
#   which will result in the final config file including the target config as:
#   "${CMAKE_CURRENT_LIST_DIR}/Namespace/NamespaceAliasConfig.cmake". Only the above alias
#   form is supported and the command relies on the given target config existing to
#   function properly.
#
#   If COMPONENT is specified for a given item, the inclusion of that target config in
#   the generated config will only occur if that component is requested by the packages
#   consumer. If DEFAULT follows the COMPONENT argument for a given item, then the
#   target config will also be included if no components are specified when searching
#   for the package.
#
#   If OPTIONAL is specified, the entry is ignored if the specified target does not exist
#   instead of being counted as a FATAL_ERROR.
#
#   The generated config will be configured such that if a TARGET without a COMPONENT or
#   a DEFAULT TARGET is missing at "find_package time" it will be considered an error.
#
#   The generated config is installed into ${CMAKE_INSTALL_PREFIX}/cmake, making the inclusion paths
#   effectively:
#   "${CMAKE_INSTALL_PREFIX}/cmake/Alias/NamespaceAliasConfig.cmake".
#
#   The dependencies are passed as:
#       DEPENDS
#           PACKAGE "name"
#           COMPONENTS list of components
#           VERSION 1.0
#
#   Where COMPONENTS and VERSION are optional
#
#   Second:
#       CONFIG
#           CUSTOM "path"
#
#   This form uses configure_package_config_file() from CMakePackageConfigHelpers to
#   configure the custom configuration file input template from the provided path.
#   The template file is presumed to be prepared correctly to work properly with
#   said command.
#
#   Both files are installed to ${CMAKE_INSTALL_PREFIX}/cmake under the component
#   PROJECT_NAME_LC.
#
# TODO: At some point maybe have 'ob_add_standard_library()' and any similar functions
# create internal cache variables with any target configs they create so that they
# can be included by the config file created by here automatically, with manual input
# only needed for any targets that the project didn't make use of the ob_ functions to
# to add.
function(ob_standard_project_package_config)
    __ob_command(ob_standard_project_package_config "3.18.0")

    #---------------- Function Setup ----------------------
    # Const variables
    set(OUTPUT_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/cmake")
    
    # Function inputs
    set(oneValueArgs
        PACKAGE_NAME
        COMPATIBILITY
    )

    set(multiValueArgs
        CONFIG
    )

    set(requiredArgs
        CONFIG
        COMPATIBILITY
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_PKG_CFG "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Handle package name
    if(STD_PKG_CFG_PACKAGE_NAME)
        set(PACKAGE_NAME "${STD_PKG_CFG_PACKAGE_NAME}")
    else()
        set(PACKAGE_NAME "${PROJECT_NAME}")
    endif()

    #---------------- Prepare Configuration  ----------------------

    # Create config
    include(CMakePackageConfigHelpers)
    set(cfg_gen_path "${OUTPUT_PREFIX}/${PACKAGE_NAME}Config.cmake")
    set(ver_gen_path "${OUTPUT_PREFIX}/${PACKAGE_NAME}ConfigVersion.cmake")
    __ob_process_config_opt("${PACKAGE_NAME}" "${cfg_gen_path}" ${STD_PKG_CFG_CONFIG})
   
    # Create version file
    write_basic_package_version_file(
        "${ver_gen_path}"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY ${STD_PKG_CFG_COMPATIBILITY}
    )

    # Install both files
    install(FILES
        "${ver_gen_path}"
        "${cfg_gen_path}"
        COMPONENT ${PROJECT_NAME_LC}
        DESTINATION "cmake"
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )
endfunction()

# Invokes the `install` for standard project level files:
# - README.md and LICENSE
#
# Expects the README and LICENSE to be located in CMAKE_CURRENT_SOURCE_DIR.
#
# Requires ob_standard_project_setup() or ob_top_level_project_setup() to have been called.
#
# This function uses the SUB_PROJ_EXCLUDE_FROM_ALL variable to disable these installs
# when the project is used as a sub-project
#
# The install component for both installs is set to PROJECT_NAME_LC.
function(ob_standard_project_misc_install)
    __ob_command(ob_standard_project_misc_install "3.6.0")

    #---------------- Installs  ----------------------

    # Install README and LICENSE
    install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
        "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE"
        COMPONENT ${PROJECT_NAMESPACE_LC}
        DESTINATION .
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )
endfunction()
