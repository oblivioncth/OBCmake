include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Helpers
function(__ob_process_header_paths processed_paths middle_path)
    __ob_internal_command(__ob_process_header_paths "3.0.0")

    # Function inputs
    set(oneValueArgs
        BASE
        COMMON
    )

    set(multiValueArgs
        FILES
    )

    # Required Arguments (All Types)
    set(requiredArgs
        BASE
        FILES
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(HEADER_INPUT "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Create full headers list
    if(HEADER_INPUT_COMMON)
        set(middle_segment "/${HEADER_INPUT_COMMON}")
    else()
        set(middle_segment "")
    endif()

    foreach(input_file ${HEADER_INPUT_FILES})
        list(APPEND full_paths "${HEADER_INPUT_BASE}${middle_segment}/${input_file}")
    endforeach()

    # Return
    set(${processed_paths} "${full_paths}" PARENT_SCOPE)
    set(${middle_path} "${middle_segment}" PARENT_SCOPE)
endfunction()

function(__ob_register_header_set set_name group_name base_dir)
    __ob_internal_command(__ob_register_header_set "3.23.0")

    set(header_args "${ARGN}")

    # Get full paths
    __ob_process_header_paths(full_header_paths common_path
        BASE "${base_dir}"
        ${header_args} # Forward full arg set after prepending BASE
    )

    # Add via FILE_SET
    target_sources(${_TARGET_NAME} PUBLIC
        FILE_SET "${set_name}"
        TYPE HEADERS
        BASE_DIRS ${base_dir}
        FILES ${full_header_paths}
    )

    # Setup source group for better IDE integration
    source_group(TREE "${base_dir}${common_path}"
        PREFIX "${group_name}"
        FILES ${full_header_paths}
    )
endfunction()

function(__ob_parse_export_header basename path)
    __ob_internal_command(__ob_parse_export_header "3.0.0")

    # Function inputs
    set(oneValueArgs
        BASE_NAME
        PATH
    )

    # Required Arguments (All Types)
    set(requiredArgs
        PATH
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(EXPORT_HEADER "" "${oneValueArgs}" "" "${requiredArgs}" ${ARGN})

    set(_PATH ${EXPORT_HEADER_PATH})

    if(EXPORT_HEADER_BASE_NAME)
        set(_BASE_NAME "${EXPORT_HEADER_BASE_NAME}")
    else()
        set(_BASE_NAME "")
    endif()

    set(${basename} "${_BASE_NAME}" PARENT_SCOPE)
    set(${path} "${_PATH}" PARENT_SCOPE)
endfunction()

# Creates a library target in the "OB Standard Fashion"
# via the provided arguments. Also produces an install
# component that matches the target name.
#
# This command will also define BUILD_SHARED_LIBS as an option/cache variable defaulted
# to NO if it isn't already defined.
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
#   based on the NAMESPACE and ALIAS values using casing that's typical for the
#   target platform
# TYPE: Type of library, follows BUILD_SHARED_LIBS if not defined
# EXPORT_HEADER:
#   Inner Form:
#       EXPORT_HEADER
#           BASENAME MYLIB
#           PATH "path/of/export/header.h"
#
#   This function generates an export header that provides export macros
#   for a library to more easily support shared builds. This argument is
#   to contain the sub-path (filename included) that the export header
#   is placed within the the portion of the project's include tree dedicated
#   to this library. It will be the same path used to include the header in source.
#
#   For example, if the path provided is "mylib/section/export.h"
#   Then the header can be included within the source for this target via:
#   #include "mylib/section/export.h"
#
#   It will be added as an include file and install automatically.
#
#   The BASE_NAME argument is optional sets the prefix of all macros present
#   in the header in accordance with the CMake command GENERATE_EXPORT_HEADER.
#   if not provided it will be set to "${NAMESPACE}_${ALIAS}".
#
#   This argument is required unless the TYPE is INTERFACE.
# HEADERS_API:
#   Inner Form:
#       HEADERS_API
#           COMMON "common/middle/path"
#           FILES
#               "header1.h"
#               "header2.h"
#
#   Uses File Sets. Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/include",
#   which is used to populate BASE_DIRS. COMMON can optionally be used to avoid having
#   to type out a shared common root within the include folder for each file
# HEADERS_API_GEN:
#   Same as HEADERS_API, but the files are assumed to be under
#   "${CMAKE_CURRENT_BINARY_DIR}/include"
# IMPLEMENTATION:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/src"
# DOC_ONLY:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/src"
# RESOURCE:
#   Files can be absolute, but relative paths are assumed to be under
#   "${CMAKE_CURRENT_SOURCE_DIR}/res". Added via
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
function(ob_add_standard_library target)
    __ob_command(ob_add_standard_library "3.23.0")

    #------------ Argument Handling ---------------

    # Function inputs
    set(oneValueArgs
        NAMESPACE
        ALIAS
        OUTPUT_NAME
        TYPE
    )

    set(multiValueArgs
        EXPORT_HEADER
        HEADERS_API
        HEADERS_API_GEN
        IMPLEMENTATION
        DOC_ONLY
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
        HEADERS_API
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_LIBRARY "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Standardized set and defaulted values
    set(_TARGET_NAME "${target}")
    set(_NAMESPACE "${STD_LIBRARY_NAMESPACE}")
    string(TOLOWER ${_NAMESPACE} _NAMESPACE_LC)
    set(_ALIAS "${STD_LIBRARY_ALIAS}")
    string(TOLOWER ${_ALIAS} _ALIAS_LC)

    if(STD_LIBRARY_OUTPUT_NAME)
        set(_OUTPUT_NAME "${STD_LIBRARY_OUTPUT_NAME}")
    else()
        if(CMAKE_SYSTEM_NAME STREQUAL Windows)
            set(_OUTPUT_NAME "${_NAMESPACE}${_ALIAS}")
        else()
            set(_OUTPUT_NAME "${_NAMESPACE_LC}-${_ALIAS_LC}")
        endif()
    endif()

    if(STD_LIBRARY_TYPE)
        set(_TYPE "${STD_LIBRARY_TYPE}")
    elseif(BUILD_SHARED_LIBS)
        set(_TYPE "SHARED")
    else()
        set(_TYPE "STATIC")
    endif()

    set(_EXPORT_HEADER "${STD_LIBRARY_EXPORT_HEADER}")
    set(_HEADERS_API "${STD_LIBRARY_HEADERS_API}")
    set(_HEADERS_API_GEN "${STD_LIBRARY_HEADERS_API_GEN}")
    set(_IMPLEMENTATION "${STD_LIBRARY_IMPLEMENTATION}")
    set(_DOC_ONLY "${STD_LIBRARY_DOC_ONLY}")
    set(_RESOURCE "${STD_LIBRARY_RESOURCE}")
    set(_LINKS "${STD_LIBRARY_LINKS}")
    set(_DEFINITIONS "${STD_LIBRARY_DEFINITIONS}")
    set(_OPTIONS "${STD_LIBRARY_OPTIONS}")
    set(_CONFIG "${STD_LIBRARY_CONFIG}")

    # Compute Intermediate Values
    if(_LINKS)
        include("${__OB_CMAKE_PRIVATE}/qt.cmake")
        __ob_should_be_qt_based_target(_LINKS _USE_QT)
    else()
        set(_USE_QT FALSE)
    endif()

    if("${_TYPE}" STREQUAL "INTERFACE")
        set(interface_private "INTERFACE")
        set(interface_public "INTERFACE")
    else()
        set(interface_private "PRIVATE")
        set(interface_public "PUBLIC")
    endif()

    #---------------- Library Setup -------------------

    # Create shared/static cache toggle if not already present
    option(BUILD_SHARED_LIBS "Prefer shared linkage when building libraries" OFF)

    # Create lib
    if(_USE_QT)
        qt_add_library(${_TARGET_NAME} ${_TYPE})
    else()
        add_library(${_TARGET_NAME} ${_TYPE})
    endif()

    add_library("${_NAMESPACE}::${_ALIAS}" ALIAS ${_TARGET_NAME})

    # Add implementation
    if(_IMPLEMENTATION)
        foreach(impl ${_IMPLEMENTATION})
            __ob_validate_source_for_system("${impl}" applicable_impl)
            if(applicable_impl)
                list(APPEND full_impl_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${impl}")
            endif()
        endforeach()

        if(full_impl_paths)
            target_sources(${_TARGET_NAME} PRIVATE ${full_impl_paths})

            # Group files with their parent directories stripped
            source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
                PREFIX "Implementation"
                FILES ${full_impl_paths}
            )

            # Include current source directory for easy includes of
            # private headers from the top level of the target hierarchy
            target_include_directories(${_TARGET_NAME}
                PRIVATE
                    "${CMAKE_CURRENT_SOURCE_DIR}/src"
            )
        endif()
    endif()

    # Doc
    if(_DOC_ONLY)
        # Build pathed include file list
        foreach(doc ${_DOC_ONLY})
            list(APPEND full_doc_only_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${doc}")
        endforeach()

        # Group include files with their parent directories stripped
        source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
            PREFIX "Doc"
            FILES ${full_doc_only_paths}
        )

        # Add include files as private target source so that they aren't built nor marked as a dependency,
        # but are shown with the target in the IDE
        target_sources(${_TARGET_NAME} PRIVATE ${full_doc_only_paths})
    endif()

    # Add standard API headers
    if(_HEADERS_API)
        __ob_register_header_set("headers_api"
            "Headers Include"
            "${CMAKE_CURRENT_SOURCE_DIR}/include"
            ${_HEADERS_API}
        )
    endif()

    # Add generated API headers
    if(_HEADERS_API_GEN)
        __ob_register_header_set("headers_api_gen"
            "Headers Include Generated"
            "${CMAKE_CURRENT_BINARY_DIR}/include"
            ${_HEADERS_API_GEN}
        )
    endif()

    # Shared Lib Support/Generate export header
    if(NOT "${_TYPE}" STREQUAL "INTERFACE")
        if(NOT _EXPORT_HEADER)
            message(FATAL_ERROR "EXPORT_HEADER is required for non-INTERFACE libraries!")
        endif()

        if("${_TYPE}" STREQUAL "SHARED")
            # Setup export decorator macros as require by Windows, but use the benefit on all supported platforms.
            # An alternative to this is to set CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS to TRUE, which handles all exports
            # and imports automatically, but doesn't provide the same speed benefits and still requires manual
            # marking of global data members (i.e. it only covers classes and functions). So if we have to mark those
            # anyway, mind as well do everything.

            # This isn't explained at all in the CMake docs for GenerateExportHeader, but the purpose of the
            # following property settings is to make non-Windows compilers match the behavior of windows in
            # regards to symbol visibility by default. Normally, on Windows when compiling shared libraries
            # all symbols are private by default, while on compilers like GCC, the symbols are all public by
            # default.
            #
            # Symbols that are explicitly marked as public benefit from better code generation and faster
            # initialization time. Since the manual marking must be done on Windows anyway, it makes sense
            # to private everything by default on other platforms as well in order to gain these benefits from
            # the manual export marks. These properties mark symbols and inline symbols as hidden on for the
            # non-windows compilers that support said options.
            #
            # Wrapped in an 'if' because this shouldn't be done for a static lib
            set_target_properties(${_TARGET_NAME}
                PROPERTIES
                    CXX_VISIBILITY_PRESET "hidden"
                    VISIBILITY_INLINES_HIDDEN 1
            )
        endif()

        # Generate Export Header
        # This is required regardless of whether or not the lib is actually shared in order for the sources that
        # use the macros this provides to compile
        include(GenerateExportHeader)
        __ob_parse_export_header(_eh_bn _eh_path ${_EXPORT_HEADER})

        if(_eh_bn)
            set(export_header_basename "${_eh_bn}")
        else()
            set(export_header_basename "${_NAMESPACE}_${_ALIAS}")
        endif()

        set(eh_gen_rel_path "${_eh_path}")
        set(eh_gen_path "${CMAKE_CURRENT_BINARY_DIR}/include/${eh_gen_rel_path}")

        # The STATIC_DEFINE portion of 'generate_export_header' only needs to be used if the project is setup to build the
        # static and shared versions of the library from the same configuration, as then only one header is
        # generated and used for both. We don't do this however, and the header generation is smart enough to
        # resolve the macros to empty strings when configuring a static library. The function also ensures the
        # correct definition is set on the target to use the EXPORT variant of the macro value instead of the
        # IMPORT variant.
        generate_export_header(${_TARGET_NAME}
            BASE_NAME "${export_header_basename}"
            EXPORT_FILE_NAME "${eh_gen_path}"
        )

        # Add via file set
        __ob_register_header_set("headers_export"
            "Headers Export"
            "${CMAKE_CURRENT_BINARY_DIR}/include"
            FILES
                "${eh_gen_rel_path}"
        )
    endif()

    # Add resources
    if(_RESOURCE)
        foreach(res ${_RESOURCE})
            # Ignore non-relevant system specific implementation
            __ob_validate_source_for_system("${res}" applicable_res)
            if(applicable_res)
                cmake_path(ABSOLUTE_PATH res BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/res")
                list(APPEND full_res_paths "${res}")
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

    # Link to libraries
    if(_LINKS)
        target_link_libraries(${_TARGET_NAME} ${_LINKS})
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
        VERSION ${PROJECT_VERSION}
        DEBUG_POSTFIX "d"
        EXPORT_NAME "${_ALIAS}"
        OUTPUT_NAME "${_OUTPUT_NAME}"
    )

    # Install target
    install(TARGETS ${_TARGET_NAME}
        COMPONENT ${_TARGET_NAME}
        EXPORT ${_NAMESPACE}${_ALIAS}Targets
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        FILE_SET headers_api
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ALIAS_LC}"
        FILE_SET headers_api_gen
            OPTIONAL
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ALIAS_LC}"
        FILE_SET headers_export
            OPTIONAL
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${_ALIAS_LC}"
    )

    # Package Config
    if(_CONFIG)
        # Install export
        install(EXPORT ${_NAMESPACE}${_ALIAS}Targets
            COMPONENT ${_TARGET_NAME}
            FILE "${_NAMESPACE}${_ALIAS}Targets.cmake"
            NAMESPACE ${_NAMESPACE}::
            DESTINATION "cmake/${_ALIAS}"
            ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
        )

        __ob_parse_std_target_config_option(${_TARGET_NAME}
            ${_NAMESPACE}
            ${_ALIAS}
            ${_CONFIG}
        )
    endif()
endfunction()

# Creates an OBJECT library target in the "OB Standard Fashion"
# via the provided arguments.
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
# SHARED_HEADERS:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/src". Similar to HEADERS_API
#   for regular libraries; headers that consumers need.
# IMPLEMENTATION:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/src"
# LINKS:
#   Same contents/arguments as with target_link_libraries().
# DEFINITIONS
#   Same contents/arguments as with target_compile_definitions().
# OPTIONS:
#   Same contents/arguments as with target_compile_options().
function(ob_add_standard_object_library target)
    __ob_command(ob_add_standard_object_library "3.12.0")

    #------------ Argument Handling ---------------

    # Function inputs
    set(oneValueArgs
        NAMESPACE
        ALIAS
    )

    set(multiValueArgs
        SHARED_HEADERS
        IMPLEMENTATION
        LINKS
        RESOURCE
        DEFINITIONS
        OPTIONS
    )

    # Required Arguments (All Types)
    set(requiredArgs
        NAMESPACE
        ALIAS
        IMPLEMENTATION
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_OBJ_LIB "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Standardized set and defaulted values
    set(_TARGET_NAME "${target}")
    set(_NAMESPACE "${STD_OBJ_LIB_NAMESPACE}")
    string(TOLOWER ${_NAMESPACE} _NAMESPACE_LC)
    set(_ALIAS "${STD_OBJ_LIB_ALIAS}")
    string(TOLOWER ${_ALIAS} _ALIAS_LC)
    set(_SHARED_HEADERS "${STD_OBJ_LIB_SHARED_HEADERS}")
    set(_IMPLEMENTATION "${STD_OBJ_LIB_IMPLEMENTATION}")
    set(_RESOURCE "${STD_OBJ_LIB_RESOURCE}")
    set(_LINKS "${STD_OBJ_LIB_LINKS}")
    set(_DEFINITIONS "${STD_OBJ_LIB_DEFINITIONS}")
    set(_OPTIONS "${STD_OBJ_LIB_OPTIONS}")
    set(_CONFIG "${STD_OBJ_LIB_CONFIG}")

    # Create lib
    add_library(${_TARGET_NAME} OBJECT)
    add_library("${_NAMESPACE}::${_ALIAS}" ALIAS ${_TARGET_NAME})

    # Add shared headers
    if(_SHARED_HEADERS)
        foreach(header ${_SHARED_HEADERS})
            list(APPEND full_header_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${header}")
        endforeach()

        target_sources(${_TARGET_NAME} PUBLIC ${full_header_paths})

        # Group files with their parent directories stripped
        source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
            PREFIX "Shared Headers"
            FILES ${full_header_paths}
        )
    endif()

    # Add implementation
    if(_IMPLEMENTATION)
        foreach(impl ${_IMPLEMENTATION})
            __ob_validate_source_for_system("${impl}" applicable_impl)
            if(applicable_impl)
                list(APPEND full_impl_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${impl}")
            endif()
        endforeach()

        if(full_impl_paths)
            target_sources(${_TARGET_NAME} PRIVATE ${full_impl_paths})

            # Group files with their parent directories stripped
            source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
                PREFIX "Implementation"
                FILES ${full_impl_paths}
            )

        endif()
    endif()

    # Include current source directory for easy includes of
    # headers from the top level of the target hierarchy,
    # and so that consumers can include shared headers
    target_include_directories(${_TARGET_NAME}
        PUBLIC
            "${CMAKE_CURRENT_SOURCE_DIR}/src"
    )

    # Add resources
    if(_RESOURCE)
        foreach(res ${_RESOURCE})
            # Ignore non-relevant system specific implementation
            __ob_validate_source_for_system("${res}" applicable_res)
            if(applicable_res)
                cmake_path(ABSOLUTE_PATH res BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/res")
                list(APPEND full_res_paths "${res}")
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

    # Link to libraries
    if(_LINKS)
        target_link_libraries(${_TARGET_NAME} ${_LINKS})
    endif()

    # Add definitions
    if(_DEFINITIONS)
        target_compile_definitions(${_TARGET_NAME} ${_DEFINITIONS})
    endif()

        # Add options
    if(_OPTIONS)
        target_compile_options(${_TARGET_NAME} ${_OPTIONS})
    endif()
endfunction()