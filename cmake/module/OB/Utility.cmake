function(string_to_proper_case str return)
  string(SUBSTRING ${str} 0 1 FIRST_LETTER)
  string(SUBSTRING ${str} 1 -1 OTHER_LETTERS)
  string(TOUPPER ${FIRST_LETTER} FIRST_LETTER_UC)
  string(TOLOWER ${OTHER_LETTERS} OTHER_LETTERS_LC)

  set(${return} "${FIRST_LETTER_UC}${OTHER_LETTERS_LC}" PARENT_SCOPE)
endfunction()

function(create_header_guard prefix name return)
    # Replace all dashes and space with underscore, force uppercase
    string(REGEX REPLACE "[\r\n\t -]" "_" prefix_clean ${prefix})
    string(REGEX REPLACE "[\r\n\t -]" "_" name_clean ${name})
    string(TOUPPER ${name_clean} name_clean_uc)
    string(TOUPPER ${prefix_clean} prefix_clean_uc)

    set(${return} "${prefix_clean_uc}_${name_clean_uc}_H" PARENT_SCOPE)
endfunction()

function(get_subdirectory_list path return)
    file(GLOB path_children RELATIVE "${path}" "${path}/*")
    foreach(child ${path_children})
        if(IS_DIRECTORY "${path}/${child}")
            list(APPEND subdirs ${child})
        endif()
    endforeach()

    set(${return} "${subdirs}" PARENT_SCOPE)
endfunction()

function(get_proper_system_name return)
    if(CMAKE_SYSTEM_NAME STREQUAL Windows)
        set(${return} Windows PARENT_SCOPE)
    elseif(CMAKE_SYSTEM_NAME STREQUAL Linux)
        # Get distro name
        execute_process(
            COMMAND sh -c "( awk -F= '\$1==\"NAME\" { print \$2 ;}' /etc/os-release || lsb_release -is ) 2>/dev/null"
            ERROR_QUIET
            RESULT_VARIABLE res
            OUTPUT_VARIABLE distro_name
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Handle cleanup and fallback
        if(("${distro_name}" STREQUAL ""))
            message(WARNING "Could not determine distro name. Falling back to 'Linux'")
            set(distro_name "Linux")
        else()
            string(REPLACE "\"" "" distro_name ${distro_name}) # Remove possible quotation
        endif()

        set(${return} "${distro_name}" PARENT_SCOPE)
    endif()
endfunction()

function(get_system_architecture return)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(sys_arch x64)
    else()
      set(sys_arch x86)
    endif()

    set(${return} "${sys_arch}" PARENT_SCOPE)
endfunction()

# Form:
# ob_parse_arguments_list(<start_keyword> <parser> <return> <args>...)
# 
# Arguments:
# - start_keyword: The keyword that denotes the start of a new entry
# - parser: Name of the function to invoke when parsing each entry, needs to
#           be of the form `parser_function(<output> <args>...)`. If this argument
#           is passed as an empty string (""), this function will only handle
#           the splitting of each entry with no intermediate parsing.
# - return: The output variable in which to store the list of all parsed entries,
#           or just split entries if no parser was provided
# - args: The list of entries to split and parse
#
# This function is used to assist with parsing function arguments that contain
# a list of entries with their own arguments.
#
# For example, a suppose a function that might be called like so:
#
# add_files(
#   TARGET "myTarget"
#   FILES
#       PATH "path/one"   ALIAS "FileOne"
#       PATH "path/two"
#       PATH "path/three" ALIAS "FileThree"
# )
#
# Presumably the function add_files is parsed using cmake_parse_arguments()
# where "FILES" is a multi-value keyword and if we assume the prefix "FILE_ADD"
# was used, the contents of "FILES" are stored in "FILE_ADD_FILES" after the initialize
# parse. At this point those contents need to be split into tokens for each set
# pair of "PATH" and optional "ALIAS" so that they can be parsed individually by
# another function. The contents of "FILE_ADD_FILES" aren't intrinsically split like this
# though and instead the variable is simply composed as a list like so:
#
# PATH;
# path/one;
# ALIAS;
# FileOne;
# PATH;
# path/two;
# ...
#
# ob_parse_arguments_list() breaks up each entry based on a primary
# keyword that denotes the start of a new entry and then parses that entry
# using the provided function, storing the results of each in a list that is
# then returned via "return"
#
# For example, the "add_files" function could handle parsing it's "FILES" keyword
# like so:
#
# ob_parse_arguments_list(
#   "PATH" 
#   "file_parser_fn"
#   parsed_files
#   ${FILE_ADD_FILES}
# )
#
# with "parsed_files" then containing the result.

function(ob_parse_arguments_list start_keyword parser return)
    # Constants
    set(FORMAL_PARAMETER_COUNT 3)

    # Working vars (not required to "initialize" in cmake, but here for clarity)
    set(FIRST_ENTRY_ACCOUNTED FALSE)
    set(ENTRY_ARGS "")
    set(PARSED_LIST "")
    set(PARSED_ENTRY "")
    
    # Ensure that the args list was passed
    if(NOT ARGC GREATER FORMAL_PARAMETER_COUNT)
        message(FATAL_ERROR "No arguments to parse were provided!")
    endif()
    
    # Build parsed entry list
    foreach(word ${ARGN})
        if("${word}" STREQUAL "${start_keyword}")
            if(${FIRST_ENTRY_ACCOUNTED})
                # Parse or append sub-list
                if(parser)
                    cmake_language(CALL ${parser) PARSED_ENTRY ${ENTRY_ARGS})
                else
                    set(PARSED_ENTRY "${ENTRY_ARGS}")
                endif()
                list(APPEND PARSED_LIST "${PARSED_ENTRY}")

                # Reset intermediate argument list
                set(ENTRY_ARGS "")
            else()
                set(FIRST_ENTRY_ACCOUNTED TRUE)
            endif()
        elseif(NOT FIRST_ENTRY_ACCOUNTED)
            message(FATAL_ERROR "The arguments list must start with an entry as marked by ${start_keyword}")
        endif()

        # Add word to entry arg list, can't use list(APPEND) here as in order to support
        # the use of this function without a parser, the returned list must only have semi-colons
        # that separate each entry, with none appearing within an entry. list(APPEND) uses semi-colons
        # so that wouldn't work. By just using set() this way, the entry args are separated via whitespace.
        set(ENTRY_ARGS "${ENTRY_ARGS} ${word}")
    endforeach()

    # Process last sub-list (above loop ends while populating final sub-list)
    if(parser)
        cmake_language(CALL ${parser) PARSED_ENTRY ${ENTRY_ARGS})
    else
        set(PARSED_ENTRY "${ENTRY_ARGS}")
    endif()
    list(APPEND PARSED_LIST "${PARSED_ENTRY}")

    # Return resulting list
    set(${return} "${PARSED_LIST}" PARENT_SCOPE)
endfunction()