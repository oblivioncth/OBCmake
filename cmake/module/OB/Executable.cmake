include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Creates an executable target in the "OB Standard Fashion"
# via the provided arguments. Also produces an install
# component that matches the target name.
#
# This function will handle setup for installation of the component's
# dependencies, including if it uses shared Qt libraries.
#
# Adds CMAKE_CURRENT_SOURCE_DIR as an include directory to the target.
#
# Argument Notes:
# ---------------
# NAMESPACE:
#   Namespace to use for file generation, export configuration, and installation pathing.
# ALIAS:
#   Do not use "::" as part of the libraries alias, they will be
#   added automatically after first prepending the provided namespace.
#
#   Used for file generation, export configuration, and installation pathing.
# OUTPUT_NAME:
#   Maps to the OUTPUT_NAME property of the target. If not provided, by default its set
#   based on the ALIAS value using casing that's typical for the target platform
# SOURCE:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/src"
# SOURCE_GEN:
#   Files are assumed to be under "${CMAKE_CURRENT_BINARY_DIR}/src"
# RESOURCE:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/res". Added via
#   target_sources(<tgt> PRIVATE <resources>), mainly for .qrc or .rc files
# LINKS:
#   Same contents/arguments as with target_link_libraries().
# DEFINITIONS
#   Same contents/arguments as with target_compile_definitions().
# OPTIONS:
#   Same contents/arguments as with target_compile_options().
# CONFIG:
#   This optional argument can take two forms.
#
#   First:
#       CONFIG
#           STANDARD
#           DEPENDS
#
#   This form configures and installs a package configuration file set to include
#   the library target and find the optional dependencies if provided. The dependencies
#   are passed via the same form as in the CONFIG argument from the
#   ob_standard_project_package_config() command.
#
#   Second:
#       CONFIG
#           CUSTOM "path"
#
#   This form uses configure_file() to configure the custom configuration file input
#   template (presumably associated with the target) from the provided path. It also
#   handles its installation.
#
#   The config file is installed as:
#   ${CMAKE_INSTALL_PREFIX)/cmake/${NAMESPACE}/${NAMESPACE}${ALIAS}Config.cmake
# WIN32:
#   Same as supplying WIN32 to add_executable()
function(ob_add_standard_executable target)
    __ob_command(ob_add_standard_executable "3.16.0")

    #------------ Argument Handling ---------------

    # Function inputs
    set(options
        WIN32
    )

    set(oneValueArgs
        NAMESPACE
        ALIAS
        OUTPUT_NAME
    )

    set(multiValueArgs
        SOURCE
        SOURCE_GEN
        RESOURCE
        LINKS
        DEFINITIONS
        OPTIONS
        CONFIG
    )

    # Required Arguments (All Types)
    set(requiredArgs
        NAMESPACE
        ALIAS
        SOURCE
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_EXECUTABLE "${options}" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Standardized set and defaulted values
    set(_TARGET_NAME "${target}")
    set(_NAMESPACE "${STD_EXECUTABLE_NAMESPACE}")
    string(TOLOWER ${_NAMESPACE} _NAMESPACE_LC)
    set(_ALIAS "${STD_EXECUTABLE_ALIAS}")
    string(TOLOWER ${_ALIAS} _ALIAS_LC)

    if(STD_EXECUTABLE_OUTPUT_NAME)
        set(_OUTPUT_NAME "${STD_EXECUTABLE_OUTPUT_NAME}")
    else()
        if(CMAKE_SYSTEM_NAME STREQUAL Windows)
            set(_OUTPUT_NAME "${_ALIAS}")
        else()
            set(_OUTPUT_NAME "${_ALIAS_LC}")
        endif()
    endif()

    set(_SOURCE "${STD_EXECUTABLE_SOURCE}")
    set(_SOURCE_GEN "${STD_EXECUTABLE_SOURCE_GEN}")
    set(_RESOURCE "${STD_EXECUTABLE_RESOURCE}")
    set(_LINKS "${STD_EXECUTABLE_LINKS}")
    set(_DEFINITIONS "${STD_EXECUTABLE_DEFINITIONS}")
    set(_OPTIONS "${STD_EXECUTABLE_OPTIONS}")
    set(_CONFIG "${STD_EXECUTABLE_CONFIG}")

    # Compute Intermediate Values
    if(_LINKS)
        include("${__OB_CMAKE_PRIVATE}/qt.cmake")
        __ob_should_be_qt_based_target(_LINKS _USE_QT)
    else()
        set(_USE_QT FALSE)
    endif()

    if(STD_EXECUTABLE_WIN32)
        set(_OPTION_WIN32 "WIN32")
    else()
        set(_OPTION_WIN32 "")
    endif()

    if("${_TYPE}" STREQUAL "INTERFACE")
        set(interface_private "INTERFACE")
        set(interface_public "INTERFACE")
    else()
        set(interface_private "PRIVATE")
        set(interface_public "PUBLIC")
    endif()

    #---------------- Executable Setup -------------------

    # Create lib
    if(_USE_QT)
        qt_add_executable(${_TARGET_NAME} ${_OPTION_WIN32})
    else()
        add_executable(${_TARGET_NAME} ${_OPTION_WIN32})
    endif()

    add_executable("${_NAMESPACE}::${_ALIAS}" ALIAS ${_TARGET_NAME})

    # Add implementation
    foreach(impl ${_SOURCE})
        # Ignore non-relevant system specific implementation
        __ob_validate_source_for_system("${impl}" applicable_impl)
        if(applicable_impl)
            list(APPEND full_impl_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${impl}")
        endif()
    endforeach()

    if(full_impl_paths)
        target_sources(${_TARGET_NAME} PRIVATE ${full_impl_paths})

        source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
            # "Implementation" is preferred, but we also want this group to appear below header groups
            PREFIX "Source"
            FILES ${full_impl_paths}
        )
    endif()

    # Add generated implementation
    if(_SOURCE_GEN)
        foreach(impl_gen ${_SOURCE_GEN})
            # Ignore non-relevant system specific implementation
            __ob_validate_source_for_system("${impl_gen}" applicable_impl_gen)
            if(applicable_impl_gen)
                list(APPEND full_impl_gen_paths "${CMAKE_CURRENT_BINARY_DIR}/src/${impl_gen}")
            endif()
        endforeach()

        if(applicable_impl_gen)
            target_sources(${_TARGET_NAME} PRIVATE ${full_impl_gen_paths})

            source_group(TREE "${CMAKE_CURRENT_BINARY_DIR}/src"
                PREFIX "Generated Source"
                FILES ${applicable_impl_gen}
            )
        endif()
    endif()

    # Add resources
    if(_RESOURCE)
        foreach(res ${_RESOURCE})
            # Ignore non-relevant system specific implementation
            __ob_validate_source_for_system("${res}" applicable_res)
            if(applicable_res)
                list(APPEND full_res_paths "${CMAKE_CURRENT_SOURCE_DIR}/res/${res}")
            endif()
        endforeach()

        if(full_res_paths)
            target_sources(${_TARGET_NAME} PRIVATE ${full_res_paths})

            # Group files with their parent directories stripped
            source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/res"
                PREFIX "Resource"
                FILES ${full_res_paths}
            )
        endif()
    endif()

    # Include current source and generated source directories for easy includes from the top
    # level of the target hierarchy
    target_include_directories(${_TARGET_NAME}
        PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}/src"
            "${CMAKE_CURRENT_BINARY_DIR}/src"
    )

    # Link to libraries
    if(_LINKS)
        target_link_libraries(${_TARGET_NAME} ${_LINKS})
    endif()

    # Add wayland support to Qt executables on Linux, if available
    if(_USE_QT AND CMAKE_SYSTEM_NAME STREQUAL Linux AND TARGET Qt6::WaylandClient AND TARGET Qt6::QWaylandIntegrationPlugin)
        # We don't want to override the default platform plugin (usually xcb), but just
        # include the wayland platform plugin with executeables if the plugin
        # is available. This avoids the warning
        #
        # qt.qpa.plugin could not find the qt platform plugin "wayland" in ""
        #
        # from being printed by said executeables when they're run in a Desktop
        # environment that uses Wayland, and allows users to start them under
        # wayland if desired. If wayland ever becomes the default this won't be
        # required anymore as the default platform plugin is always statically
        # linked (see qt_internal_add_plugin())
        #
        # Default logic for app that use Qt GUI (otherwise mkspecs are used):
        # https://github.com/qt/qtbase/blob/2636258b29fb09551f78a26512790dc66a4a3036/src/gui/CMakeLists.txt#L32
        #
        # It seems like the qt_import_plugins() call probably adds the plugin, while
        # linking to the waylandclient target ensures that wayland related dependencies
        # are deployed in shared builds
        qt_import_plugins(${_TARGET_NAME}
            INCLUDE Qt6::QWaylandIntegrationPlugin
        )
        target_link_libraries(${_TARGET_NAME} PRIVATE Qt6::WaylandClient)
    endif()

    # Add definitions
    if(_DEFINITIONS)
        target_compile_definitions(${_TARGET_NAME} ${_DEFINITIONS})
    endif()

    # Add recognized common definitions
    list(APPEND __recog_defs
        QT_NO_CAST_FROM_ASCII
        QT_RESTRICTED_CAST_FROM_ASCII
    )

    foreach(__gd ${__recog_defs})
        if(${${__gd}})
            target_compile_definitions(${_TARGET_NAME} ${interface_private} ${__gd})
        endif()
    endforeach()

    # Add options
    if(_OPTIONS)
        target_compile_options(${_TARGET_NAME} ${_OPTIONS})
    endif()

    # Configure target properties
    set_target_properties(${_TARGET_NAME} PROPERTIES
        EXPORT_NAME "${_ALIAS}"
        DEBUG_POSTFIX "d"
        OUTPUT_NAME "${_OUTPUT_NAME}"
    )

    # Install target and configure export
    install(TARGETS ${_TARGET_NAME}
        COMPONENT ${_TARGET_NAME}
        EXPORT ${_NAMESPACE}${_ALIAS}Targets
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )

    # Install target export
    install(EXPORT ${_NAMESPACE}${_ALIAS}Targets
        COMPONENT ${_TARGET_NAME}
        FILE "${_NAMESPACE}${_ALIAS}Targets.cmake"
        NAMESPACE ${_NAMESPACE}::
        DESTINATION "cmake/${_ALIAS}"
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )

    # Install runtime dependencies
    if(_LINKS)
        # Normal runtime dependencies
        # This would be easier to do with install(TARGET ... RUNTIME_DEPENDENCIES), but for some reason
        # that blacklists files that are created within the build-tree, presumeably since you're intended
        # to "just install" those, but that gets tricky with limiting what is installed since in this context
        # fetched sub-projects are just there as a dependency and we don't want their headers, configure scripts,
        # etc. to be installed. Each project would need an option to filter what it installs, which then
        # doesn't really work for third-party projects (without crazy amounts of bodging).
        #
        # This method simply has CMake directly pull only what the executable needs.
        #
        # We filter out system libraries, and qt libraries (on windows) since they're handled independently
        #
        # TODO Add passthrough arguments for appending to the filters of file(GET_RUNTIME_DEPENDENCIES)
        if(CMAKE_SYSTEM_NAME STREQUAL Windows)
            set(_runtime_path "${CMAKE_INSTALL_BINDIR}")
        elseif(CMAKE_SYSTEM_NAME STREQUAL Linux OR CMAKE_SYSTEM_NAME STREQUAL Darwin)
            set(_runtime_path "${CMAKE_INSTALL_LIBDIR}")
        else()
            set(_runtime_path "${CMAKE_INSTALL_LIBDIR}")
            message(WARNING "Unsupported platform, assuming '${CMAKE_INSTALL_LIBDIR}' as runtime sub-path")
        endif()

        install(CODE "set(OB_EXECUTABLE \"$<TARGET_FILE:${_TARGET_NAME}>\")"
            COMPONENT ${_TARGET_NAME}
            ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
        )
        install(CODE "set(OB_RUNTIME_PATH \"${_runtime_path}\")"
            COMPONENT ${_TARGET_NAME}
            ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
        )
        install(CODE [==[
            file(GET_RUNTIME_DEPENDENCIES
                EXECUTABLES "${OB_EXECUTABLE}"
                RESOLVED_DEPENDENCIES_VAR _runtime_deps_resolved
                UNRESOLVED_DEPENDENCIES_VAR _runtime_deps_unresolved
                PRE_EXCLUDE_REGEXES
                    [=[api-ms-]=] # VC Redistibutable DLLs
                    [=[ext-ms-]=] # Windows extension DLLs
                    [=[[Qq]t[0-9]+[^\\/]*\.dll]=] # Qt Libs, don't block on Linux since users likely only have older Qt available
                POST_EXCLUDE_REGEXES
                    [=[.*system32\/.*\.dll]=] # Windows system DLLs
                    [=[^\/(lib|usr\/lib|usr\/local\/lib)]=] # Unix system libraries
            )
            if(_runtime_deps_unresolved)
                foreach(_udep ${_runtime_deps_unresolved})
                    message(SEND_ERROR "Failed to resolve dependency: ${_udep}")
                endforeach()
                message(FATAL_ERROR "Unable to resolve all dependencies for executable ${OB_EXECUTABLE}")
            endif()

            foreach(_rdep ${_runtime_deps_resolved})
                file(INSTALL
                  DESTINATION "${CMAKE_INSTALL_PREFIX}/${OB_RUNTIME_PATH}"
                  FILES "${_rdep}"
                  FOLLOW_SYMLINK_CHAIN
            )
            endforeach()
            ]==]
            COMPONENT ${_TARGET_NAME}
            ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
        )

        # Qt dependencies (on Windows), only if target links to Qt and the helper script is available
        if(COMMAND "qt_generate_deploy_app_script")
            if(_USE_QT)
                # Check if Qt linkage type is the likely case
                get_target_property(_qt_target_type Qt6::Core TYPE)
                if(BUILD_SHARED_LIBS AND _qt_target_type STREQUAL "STATIC_LIBRARY")
                    message(WARNING "BUILD_SHARED_LIBS is ON but a static build of Qt is being used for runtime deployment.")
                endif()

                # This function checks for appropriate platforms by itself
                qt_generate_deploy_app_script(
                    TARGET "${_TARGET_NAME}"
                    OUTPUT_SCRIPT qt_runtime_deploy_script
                    NO_UNSUPPORTED_PLATFORM_ERROR
                    NO_COMPILER_RUNTIME
                )

                install(SCRIPT ${qt_runtime_deploy_script}
                    COMPONENT ${_TARGET_NAME}
                    ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
                )
            endif()
        endif()
    endif()

    # Package Config
    if(_CONFIG)
        __ob_parse_std_target_config_option(${_TARGET_NAME}
            ${_NAMESPACE}
            ${_ALIAS}
            ${_CONFIG}
        )
    endif()
endfunction()
