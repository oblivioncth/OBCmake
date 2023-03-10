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
    __ob_internal_command(__ob_process_header_paths "3.0.0")
    
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
# This command will also defined BUILD_SHARED_LIBS as an option/cache variable defaulted
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
# HEADERS_PRIVATE:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}/include"
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
# LINKS:
#   Same contents/arguments as with target_link_libraries().
# DEFINITIONS
#   Same contents/arguments as with target_compile_definitions().
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
        TYPE
        EXPORT_HEADER
    )

    set(multiValueArgs
        HEADERS_PRIVATE
        HEADERS_API
        HEADERS_API_GEN
        IMPLEMENTATION
        DOC_ONLY
        LINKS
        DEFINITIONS
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
    set(_ALIAS "${STD_LIBRARY_ALIAS}")

    if(STD_LIBRARY_TYPE)
        set(_TYPE "${STD_LIBRARY_TYPE}")
    elseif(BUILD_SHARED_LIBS)
        set(_TYPE "SHARED")
    else()
        set(_TYPE "STATIC")
    endif()

    set(_EXPORT_HEADER "${STD_LIBRARY_EXPORT_HEADER}")

    set(_HEADERS_PRIVATE "${STD_LIBRARY_HEADERS_PRIVATE}")
    set(_HEADERS_API "${STD_LIBRARY_HEADERS_API}")
    set(_HEADERS_API_GEN "${STD_LIBRARY_HEADERS_API_GEN}")
    set(_IMPLEMENTATION "${STD_LIBRARY_IMPLEMENTATION}")
    set(_DOC_ONLY "${STD_LIBRARY_DOC_ONLY}")
    set(_LINKS "${STD_LIBRARY_LINKS}")
    set(_DEFINITIONS "${STD_LIBRARY_DEFINITIONS}")
    set(_CONFIG "${STD_LIBRARY_CONFIG}")

    # Compute Intermediate Values
    if(_LINKS MATCHES "Qt[0-9]*::")
        set(_USE_QT TRUE)
    else()
        set(_USE_QT FALSE)
    endif()

    string(TOLOWER ${_NAMESPACE} _NAMESPACE_LC)
    string(TOLOWER ${_ALIAS} _ALIAS_LC)

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
            # Ignore non-relevant system specific implementation
            string(REGEX MATCH [[_win\.cpp$]] IS_WIN_IMPL "${impl}")
            string(REGEX MATCH [[_linux\.cpp$]] IS_LINUX_IMPL "${impl}")
            if((IS_WIN_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows") OR
               (IS_LINUX_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Linux"))
                continue()
            endif()

            list(APPEND full_impl_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${impl}")
        endforeach()

        target_sources(${_TARGET_NAME} PRIVATE ${full_impl_paths})
    endif()

    # Doc
    if(_DOC_ONLY)
        # Build pathed include file list
        foreach(doc ${_DOC_ONLY})
            list(APPEND full_doc_only_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${doc}")
        endforeach()

        # Group include files with their parent directories stripped
        source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}/src"
            PREFIX "Doc Files"
            FILES ${full_doc_only_paths}
        )

        # Add include files as private target source so that they aren't built nor marked as a dependency,
        # but are shown with the target in the IDE
        target_sources(${_TARGET_NAME} PRIVATE ${full_doc_only_paths})
    endif()

    # Add private headers
    if(_HEADERS_PRIVATE)
        foreach(p_header ${_HEADERS_PRIVATE})
            list(APPEND full_pheader_paths "${CMAKE_CURRENT_SOURCE_DIR}/src/${p_header}")
        endforeach()

        target_sources(${_TARGET_NAME} PRIVATE ${full_pheader_paths})
    endif()

    # Add standard API headers
    if(_HEADERS_API)
        __ob_register_header_set("headers_api"
            "Include Files"
            "${CMAKE_CURRENT_SOURCE_DIR}/include"
            ${_HEADERS_API}
        )
    endif()

    # Add generated API headers
    if(_HEADERS_API_GEN)
        __ob_register_header_set("headers_api_gen"
            "Generated Include Files"
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
            set(export_header_basename "${NAMESPACE}_${ALIAS}")
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
            "Export Headers"
            "${CMAKE_CURRENT_BINARY_DIR}/include"
            FILES
                "${eh_gen_rel_path}"
        )
    endif()

    # Link to libraries
    if(_LINKS)
        target_link_libraries(${_TARGET_NAME} ${_LINKS})
    endif()
    
    # Add definitions
    if(_DEFINITIONS)
        target_compile_definitions(${_TARGET_NAME} ${_DEFINITIONS})
    endif()

    # Configure target properties
    set_target_properties(${_TARGET_NAME} PROPERTIES
        VERSION ${PROJECT_VERSION}
        DEBUG_POSTFIX "d"
        EXPORT_NAME "${_ALIAS}"
    )

    if(CMAKE_SYSTEM_NAME STREQUAL Windows)
        set_target_properties(${_TARGET_NAME} PROPERTIES
            OUTPUT_NAME "${_NAMESPACE}${_ALIAS}"
        )
    endif()


    if(CMAKE_SYSTEM_NAME STREQUAL Linux)
        set_target_properties(${_TARGET_NAME} PROPERTIES
            OUTPUT_NAME "${_NAMESPACE_LC}-${_ALIAS_LC}"
        )
    endif()

    # Install target and export
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

    install(EXPORT ${_NAMESPACE}${_ALIAS}Targets
        COMPONENT ${_TARGET_NAME}
        FILE "${_NAMESPACE}${_ALIAS}Targets.cmake"
        NAMESPACE ${_NAMESPACE}::
        DESTINATION "cmake/${_ALIAS}"
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )

    # Package Config
    if(_CONFIG)        
        __ob_parse_std_target_config_option(${_TARGET_NAME}
            ${_NAMESPACE}
            ${_ALIAS}
            ${_CONFIG}
        )
    endif()
endfunction()