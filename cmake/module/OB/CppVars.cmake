#########################################################################################
#
# CppVars.cmake
#
# Generates a header file with macro definitions and adds it to the given target
# via 'target_include_directories'. Useful for forwarding CMake variables into
# a C/C++ project.
#
# Full Signature:
#
# add_cpp_vars(
#   <target>
#   NAME name
#   PREFIX prefix
#   VARS vars...
# )
#
# Details:
#
# The NAME argument uniquely identifies the group of C++ variables and is used
# to determine the filename and guard of the header. The value is case-insensitive
# as the name in uppercase will be used for the guard and the name in lowercase
# will be used for the filename.
#
# The PREFIX argument is an optional prefix that is prepended to all macro names.
# No '_' is automatically inserted afterwards so if that is what you desire you
# must add it as part of the prefix yourself.
#
# The VARS argument needs to be a list of key/value pairs, with each acting as
# a macro name and value respectively
#
# Example:
#
# add_cpp_vars(
#   my_target
#   NAME cmake_forwards
#   PREFIX CMAKE_
#   VARS
#       PROJ_NAME "\"my_proj\""
#       PROJ_VER 1.0
# )
#
# Will result in the header file "cmake_forwards.h" with the following contents:
#
# cmake_forwards.h``````````````````
# 
# #ifndef CMAKE_FORWARDS_H
# #define CMAKE_FORWARDS_H

# #define CMAKE_PROJ_NAME "my_proj"
# #define CMAKE_PROJ_VER 1.0

# #endif // CMAKE_FORWARDS_H
#
# ``````````````````````````````````
#
# The file can be included in that target with simply:
# #include "cmake_forwards.h"
#
##########################################################################################

function(ob_add_cpp_vars target)
    #---------------- Function Setup ----------------------
    # Const variables
    set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    set(TEMPLATE_FILE "${__OB_CMAKE_PRIVATE}/templates/__cpp_vars.h.in")
    
    # Additional Function inputs
    set(oneValueArgs
        NAME
        PREFIX
    )
    set(multiValueArgs
        VARS
    )

    # Parse arguments
    cmake_parse_arguments(CPP_VARS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input
    foreach(unk_val ${CPP_VARS_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(CPP_VARS_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${CPP_VARS_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(FATAL_ERROR "Not all required values were present!")
    endif()

    # Handle defaults/undefineds
    if(NOT DEFINED CPP_VARS_NAME)
        message(FATAL_ERROR "A name for the variable group must be provided!")
    endif()
    if(NOT DEFINED CPP_VARS_VARS)
        message(FATAL_ERROR "Variables were not provided!")
    endif()

    # Validate VARS input
    list(LENGTH CPP_VARS_VARS __VARSC)
    math(EXPR __VARSC_DIV2_REMAINDER "${__VARSC} % 2")
    if(${__VARSC_DIV2_REMAINDER} GREATER 0)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} requires an even number of arguments following VARS!")
    endif()

    #---------------- Prepare Header ----------------------

    string(TOLOWER "${CPP_VARS_NAME}" __NAME_LC)
    string(TOUPPER "${CPP_VARS_NAME}" __NAME_UC)

    set(GENERATED_NAME "${__NAME_LC}.h")
    set(GENERATED_PATH "${GENERATED_DIR}/${GENERATED_NAME}")
    set(GENERATED_GUARD "${__NAME_UC}_H")
    

    # Generate defines
    while(CPP_VARS_VARS)
        # Get key/value
        list(POP_FRONT CPP_VARS_VARS __KEY __VALUE)
        
        # Validate key
        if("${__KEY}" MATCHES "[ ]")
            message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} a key cannot contain spaces!")
        endif()

        # Update define list
        set(GENERATED_MACROS "${GENERATED_MACROS}#define ${CPP_VARS_PREFIX}${__KEY} ${__VALUE}\n")
    endwhile()
    
    # Generate header
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/${TEMPLATE_FILE}"
        "${GENERATED_PATH}"
        @ONLY
        NEWLINE_STYLE UNIX
    )

    # Add file to target
    target_sources(${target} PRIVATE "${GENERATED_PATH}")
endfunction()
