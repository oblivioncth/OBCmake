macro(ob_module_minimum_required min_ver)
    if(CMAKE_VERSION VERSION_LESS "${min_ver}") # Have to expand input variable since this is a macro
        file(RELATIVE_PATH __ob_module_sub_path
            "${__OB_CMAKE_ROOT}/module"
            "${CMAKE_CURRENT_LIST_FILE}"
        )
        message(FATAL_ERROR "CMake version ${min_ver} is required to use ${__ob_module_sub_path}")
    endif()
endmacro()

function(__ob_parse_dependency return)
    #---------------- Function Setup ----------------------
    # Const variables
    set(COMPONENT_ENTRY_TEMPLATE "find_dependency(@PACKAGE_STATEMENT@ COMPONENTS@components_list@)")
    set(ENTRY_TEMPLATE "find_dependency(@PACKAGE_STATEMENT@)")

    # Additional Function inputs
    set(oneValueArgs
        PACKAGE
        VERSION
    )

    set(multiValueArgs
        COMPONENTS
    )

    set(requiredArgs
        PACKAGE
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(DEPENDENCY "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    #---------------- Parse Dependency  ----------------------

    if(DEFINED DEPENDENCY_VERSION)
        set(PACKAGE_STATEMENT "${DEPENDENCY_PACKAGE} ${DEPENDENCY_VERSION}")
    else()
        set(PACKAGE_STATEMENT "${DEPENDENCY_PACKAGE}")
    endif()

    if(DEFINED DEPENDENCY_COMPONENTS)
        # Split components list to one string
        set(components_list "")
        foreach(comp ${DEPENDENCY_COMPONENTS})
            set(components_list "${components_list} ${comp}")
        endforeach()

        string(CONFIGURE "${COMPONENT_ENTRY_TEMPLATE}" PARSED_ENTRY @ONLY)
    else()
        string(CONFIGURE "${ENTRY_TEMPLATE}" PARSED_ENTRY @ONLY)
    endif()

    set(${return} "${PARSED_ENTRY}" PARENT_SCOPE)
endfunction()

# Creates a "standard" config file that includes additional files and optionally handles dependencies
#
# The INCLUDE paths are relative to ${CMAKE_CURRENT_LIST_DIR}, i.e. where the configured file gets
# installed.
function(__ob_generate_std_target_package_config_file)
    # Const variables
    set(CFG_TEMPLATE_FILE "${__OB_CMAKE_PRIVATE}/templates/__standard_target_pkg_cfg.cmake.in")
    string(CONCAT DEPENDENCY_CHECKS_HEADING
        "# Check for hard dependencies\n"
        "include(CMakeFindDependencyMacro)\n"
    )
    string(CONCAT CONFIG_INCLUDES_HEADING
        "# Import targets\n"
    )
    set(INCLUDE_TEMPLATE [=[include("${CMAKE_CURRENT_LIST_DIR}/@SINGLE_INCLUDE@")]=])

    # Function inputs
    set(oneValueArgs
        OUTPUT
    )

    set(multiValueArgs
        INCLUDES
        DEPENDS
    )

    set(requiredArgs
        OUTPUT
        INCLUDES
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_TCF "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Handle dependencies
    if(DEFINED STD_TCF_DEPENDS)
        # Create dependency check statements via the "PACKAGE", "COMPONENT" and "VERSION" sets
        ob_parse_arguments_list(
            "PACKAGE"
            "__ob_parse_dependency"
            dependency_check_statements
            ${STD_TCF_DEPENDS}
        )

        # Create multi-line string for dependency checks
        set(DEPENDENCY_CHECKS "${DEPENDENCY_CHECKS_HEADING}")
        foreach(dep_statement ${dependency_check_statements})
            set(DEPENDENCY_CHECKS "${DEPENDENCY_CHECKS}${dep_statement}\n")
        endforeach()
        set(DEPENDENCY_CHECKS "${DEPENDENCY_CHECKS}\n")
    else()
        set(DEPENDENCY_CHECKS "") # Avoid un-init warning when configuring file
    endif()

    # Handle Include Statements
    set(CONFIG_INCLUDES "${CONFIG_INCLUDES_HEADING}")
    foreach(inc ${STD_TCF_INCLUDES})
        set(SINGLE_INCLUDE ${inc})
        string(CONFIGURE "${INCLUDE_TEMPLATE}" one_include @ONLY)
        set(CONFIG_INCLUDES "${CONFIG_INCLUDES}${one_include}\n")
    endforeach()

    # Create config file
    configure_file(
        "${CFG_TEMPLATE_FILE}"
        "${STD_TCF_OUTPUT}"
        @ONLY
    )
endfunction()

# Called as
# __ob_parse_std_target_config_option(myTarget
#   targetNamespace
#   targetAlias
#   ${CONFIG_OPTION_ARGS}
#)
function(__ob_parse_std_target_config_option target ns alias)
    set(cfg_gen_include "${ns}${alias}Targets.cmake")
    set(cfg_gen_name "${ns}${alias}Config.cmake")
    set(cfg_gen_path "${CMAKE_CURRENT_BINARY_DIR}/cmake/${cfg_gen_name}")
    
    # Additional Function Arguments
    set(options
        STANDARD
    )

    set(oneValueArgs
        CUSTOM
    )

    set(multiValueArgs
        DEPENDS
    )

    # Parse arguments
    ob_parse_arguments(CONFIG "${options}" "${oneValueArgs}" "${multiValueArgs}" "" ${ARGN})

    # Must have one, and only one form
    if(DEFINED CONFIG_CUSTOM AND (CONFIG_STANDARD OR DEFINED CONFIG_DEPENDS))
        message(FATAL_ERROR "CUSTOM and STANDARD mode are mutually exclusive!")
    elseif(NOT DEFINED CONFIG_CUSTOM AND NOT CONFIG_STANDARD)
        message(FATAL_ERROR "Either CUSTOM or STANDARD must be used!")
    endif()

    # Standard Form
    if(CONFIG_STANDARD)
        # Generate config
        __ob_generate_std_target_package_config_file(
            OUTPUT "${cfg_gen_path}"
            INCLUDES "${cfg_gen_include}"
            DEPENDS ${CONFIG_DEPENDS}
        )
    else() # Custom Form
        configure_file(
            "${CONFIG_CUSTOM}"
            "${cfg_gen_path}"
            @ONLY
        )
    endif()

    # Install config
    install(FILES
        "${cfg_gen_path}"
        COMPONENT ${target}
        DESTINATION "cmake/${alias}"
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )
endfunction()