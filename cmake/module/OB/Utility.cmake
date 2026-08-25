include("${__OB_CMAKE_PRIVATE}/common.cmake")

function(ob_string_to_proper_case str return)
  __ob_command(ob_string_to_proper_case "3.2.0")

  string(SUBSTRING ${str} 0 1 FIRST_LETTER)
  string(SUBSTRING ${str} 1 -1 OTHER_LETTERS)
  string(TOUPPER ${FIRST_LETTER} FIRST_LETTER_UC)
  string(TOLOWER ${OTHER_LETTERS} OTHER_LETTERS_LC)

  set(${return} "${FIRST_LETTER_UC}${OTHER_LETTERS_LC}" PARENT_SCOPE)
endfunction()

function(ob_create_header_guard prefix name return)
    __ob_command(ob_create_header_guard "3.0.0")

    # Replace all dashes and space with underscore, force uppercase
    string(REGEX REPLACE "[\r\n\t -]" "_" prefix_clean ${prefix})
    string(REGEX REPLACE "[\r\n\t -]" "_" name_clean ${name})
    string(TOUPPER ${name_clean} name_clean_uc)
    string(TOUPPER ${prefix_clean} prefix_clean_uc)

    set(${return} "${prefix_clean_uc}_${name_clean_uc}_H" PARENT_SCOPE)
endfunction()

function(ob_get_subdirectory_list path return)
    __ob_command(ob_get_subdirectory_list "3.0.0")

    file(GLOB path_children RELATIVE "${path}" "${path}/*")
    foreach(child ${path_children})
        if(IS_DIRECTORY "${path}/${child}")
            list(APPEND subdirs ${child})
        endif()
    endforeach()

    set(${return} "${subdirs}" PARENT_SCOPE)
endfunction()

function(ob_get_proper_system_name return)
    __ob_command(ob_get_proper_system_name "3.0.0")
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

function(ob_get_system_bitness return)
    __ob_command(ob_get_system_bitness "3.0.0")
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(sys_bit 64)
    else()
      set(sys_bit 86)
    endif()

    set(${return} "${sys_bit}" PARENT_SCOPE)
endfunction()

# Form:
# ob_parse_arguments_list(<start_keyword> <parser> <return> <args>...)
#
# Arguments:
# - start_keyword: The keyword that denotes the start of a new entry
# - parser: Name of the function to invoke when parsing each entry, needs to
#           be of the form `parser_function(<output> <args>...)`.
# - return: The output variable in which to store the list of all parsed entries
# - args: The list of entries to split and parse
#
# This function is used to assist with parsing function arguments that contain
# a list of entries with their own arguments.
#
# For example, imagine a function that might be called like so:
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
# was used, the contents of "FILES" are stored in "FILE_ADD_FILES" after the initial
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
    __ob_command(ob_parse_arguments_list "3.18.0")

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
                    cmake_language(CALL ${parser} PARSED_ENTRY ${ENTRY_ARGS})
                else()
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

        # Add word to entry arg list
        list(APPEND ENTRY_ARGS ${word})
    endforeach()

    # Process last sub-list (above loop ends while populating final sub-list)
    if(parser)
        cmake_language(CALL ${parser} PARSED_ENTRY ${ENTRY_ARGS})
    else()
        set(PARSED_ENTRY "${ENTRY_ARGS}")
    endif()
    list(APPEND PARSED_LIST "${PARSED_ENTRY}")

    # Return resulting list
    set(${return} "${PARSED_LIST}" PARENT_SCOPE)
endfunction()

# Form ob_cache_project_version(<project_name>)
#
# Uses CMAKE_PROJECT_<PROJECT-NAME>_INCLUDE to inject code into a project without
# directly modifying it such that it will create an internal CACHE variable with
# its version, therefore accessible at any scope.
#
# For example the project "Code" will create a cached variable "Code_VERSION".
#
# If the project does not declare a version, a warning will be emitted instead.
#
# This function must be called before the project is added via add_subdirectory()
# or similar.
#
# If <project_name> is omitted, CMAKE_PROJECT_INCLUDE_BEFORE will
# be used instead, which will affect every project added at the same or lower scope
# after the function returns
function(ob_cache_project_version)
    __ob_command(ob_cache_project_version "3.15.0")

    set(INJECTION_FILE "${__OB_CMAKE_PRIVATE}/__project_cache_version_injection.cmake")

    if(ARGC GREATER 1)
        message(FATAL_ERROR "Too many arguments!")
    elseif(ARGC EQUAL 1)
        set(CMAKE_PROJECT_${ARGV0}_INCLUDE "${INJECTION_FILE}" PARENT_SCOPE)
    else()
        set(CMAKE_PROJECT_INCLUDE "${INJECTION_FILE}" PARENT_SCOPE)
    endif()
endfunction()

# Same as the non-PARSE_ARGV signature of cmake_parse_arguments() but with an
# extra "required-keywords" argument. Handles argument validation and ensures
# that all required keywords were provided.
#
# CAUTION: This function also will define the _ARG_NAME variables for ALL
# argument keywords even if they weren't defined, setting them to an empty
# string if so. This means it is best the check them via if(MY_ARG_NAME) without
# performing variable substitution, and better supports the pattern of using such
# a check to support treating the option as missing when it is provided with no value
# (allows for simpler syntax when forwarding arguments that may or may not be defined).
# Explicitly defining the missing arguments as empty strings avoids a plethora of
# "uninitialized variable" warnings when this pattern is used.
#
# NOTE: Because this is a macro, callers can still use ${PREFIX}_KEYWORDSS_MISSING_VALUES
# to see if an argument was completely omitted or provided without a value.
# If necessary this can be tweaked to return a list of arguments without a value directly,
# or completely change the model of the arguments by making them keyword based themselves.
macro(ob_parse_arguments prefix opt ovk mvk rk)
    __ob_command(ob_parse_arguments "3.0.0")

    # Parse
    cmake_parse_arguments("${prefix}" "${opt}" "${ovk}" "${mvk}" ${ARGN})

    # Validate
    foreach(unk_val ${${prefix}_UNPARSED_ARGUMENTS})
        message(FATAL_ERROR "Unrecognized parameter: ${unk_val}")
    endforeach()

    # Unused because some functions support passing a keyword with no value
    # to be see as the keyword not being used so that functions that need to
    # passthrough keyword arguments don't have to check for their presence
    # every time. Instead the required variable list is used.
    #if(${prefix}_KEYWORDS_MISSING_VALUES)
    #    foreach(missing_val ${${prefix}_KEYWORDS_MISSING_VALUES})
    #        message(WARNING "A value for '${missing_val}' must be provided")
    #    endforeach()
    #    message(FATAL_ERROR "Not all required values were present!")
    #endif()

    # Check for required arguments
    foreach(arg ${rk})
        if(NOT ${prefix}_${arg})
            message(FATAL_ERROR "'${arg}' must be defined and have a value!")
        endif()
    endforeach()

    # Define missing values as empty strings (option values are always defined)
    list(APPEND __ob_all_value_args ${ovk} ${mvk})
    foreach(arg ${__ob_all_value_args})
        if(NOT DEFINED ${prefix}_${arg})
            set(${prefix}_${arg} "")
        endif()
    endforeach()
    unset(__ob_all_value_args)
endmacro()

# Asserts that a condition (provided by ARGN) is true and prints a
# FATAL_ERROR containing the condition if not.
macro(ob_assert)
    __ob_command(ob_assert "3.7.0")
    # Wrapper to prevent the need of 'include(OB/Utility)' everywhere in implementation
    __ob_assert("${ARGN}")
endmacro()

# Sets a variable to a value, only if the variable is currently undefined
macro(ob_set_if_unset var)
    __ob_command(ob_set_if_unset "3.0.0")
    if(NOT DEFINED ${var})
        set(${var} ${ARGN})
    endif()
endmacro()

# Parses <semver> as a semver-like version string of the form:
#   <major>[.<minor>[.<patch>[.<tweak>]]][-<designator>]
#
# For each component (MAJOR, MINOR, PATCH, TWEAK), in order, that is present
# and well-formed (a run of one or more digits), sets:
#   ${<return_base>}_MAJOR
#   ${<return_base>}_MINOR
#   ${<return_base>}_PATCH
#   ${<return_base>}_TWEAK
# in the caller's scope.
#
# Parsing stops at the first missing or malformed component - components
# after that point are NOT set at all (not even to an empty string). If
# MAJOR itself is missing/malformed, no variables are set.
#
# Any trailing "-<designator>" (e.g. "-alpha", "-rc.1+build.5") is stripped
# before numeric parsing begins and has no effect on the numeric components.
function(ob_split_semver semver return_base)
    __ob_command(ob_split_semver "3.0.0")
    # Strip any pre-release/build designator. Everything from the first
    # '-' or '+' onward is discarded, it never contributes numeric components.
    string(REGEX REPLACE "[-+].*$" "" _numeric_part "${semver}")

    set(_component_names MAJOR MINOR PATCH TWEAK)
    set(_remaining "${_numeric_part}")
    set(_first TRUE)

    foreach(_name ${_component_names})
        if(_first)
            set(_pattern "^([0-9]+)")
            set(_first FALSE)
        else()
            set(_pattern "^\\.([0-9]+)")
        endif()

        string(REGEX MATCH "${_pattern}" _matched "${_remaining}")

        if(NOT _matched)
            break()
        endif()

        set(${return_base}_${_name} "${CMAKE_MATCH_1}" PARENT_SCOPE)

        # Consume the matched prefix and continue with what's left
        string(LENGTH "${_matched}" _matched_len)
        string(SUBSTRING "${_remaining}" ${_matched_len} -1 _remaining)
    endforeach()
endfunction()

# ob_compose_semver(<return_var>
#     [MAJOR <n>] [MINOR <n>] [PATCH <n>] [TWEAK <n>]
#     [PRERELEASE <id>] [BUILD <id>]
# )
#
# Safely composes a semver-ish string "MAJOR.MINOR.PATCH.TWEAK-PRERELEASE+BUILD"
# from pieces that may be missing or empty. Result is placed in <return_var>
# via PARENT_SCOPE.
#
# Behavior:
#   * MAJOR/MINOR/PATCH/TWEAK are numeric, joined with '.'.
#   * PRERELEASE is appended with a leading '-', BUILD with a leading '+'.
#   * A piece that is simply never passed is skipped. If a later numeric
#     piece is validly provided, any skipped numeric pieces in between are
#     filled with "0" (e.g. MAJOR 3, PATCH 5 -> "3.0.5"). PRERELEASE/BUILD
#     have no defaults.
#   * A piece that is passed but is empty or fails validation for its slot
#     (non-numeric for MAJOR/MINOR/PATCH/TWEAK, invalid identifier chars for
#     PRERELEASE/BUILD) is a hard stop: generation stops immediately and
#     whatever has been built so far is returned as-is. Nothing after that
#     point -- including otherwise-valid later pieces -- is appended.
function(ob_compose_semver return)
    __ob_command(ob_compose_semver "3.15.0")

    #------------ Argument Handling ---------------

    # Function inputs
    set(oneValueArgs
        MAJOR
        MINOR
        PATCH
        TWEAK
        PRERELEASE
        BUILD
    )

    ob_parse_arguments(SV_ARG "" "${oneValueArgs}" "" "" ${ARGN})

    # Working vars
    set(result "")
    set(stopped FALSE)
    set(pending_zeros 0)

    # --- Numeric pieces: MAJOR . MINOR . PATCH . TWEAK ---
    foreach(part MAJOR MINOR PATCH TWEAK)
        if(stopped)
            break()
        endif()

        list(FIND SV_ARG_KEYWORDS_MISSING_VALUES "${part}" missing_idx)

        if(DEFINED SV_ARG_${part})
            set(value "${SV_ARG_${part}}")
            if(value MATCHES "^[0-9]+$")
                # valid number: flush any pending zero-fillers, then append
                while(pending_zeros GREATER 0)
                    if(result STREQUAL "")
                        set(result "0")
                    else()
                        set(result "${result}.0")
                    endif()
                    math(EXPR pending_zeros "${pending_zeros} - 1")
                endwhile()

                if(result STREQUAL "")
                    set(result "${value}")
                else()
                    set(result "${result}.${value}")
                endif()
            else()
                # explicitly provided, but empty/invalid -> hard stop
                set(stopped TRUE)
                break()
            endif()
        elseif(NOT missing_idx EQUAL -1)
            # keyword given with no value at all (e.g. trailing "PATCH") -> hard stop
            set(stopped TRUE)
            break()
        else()
            # never mentioned -> maybe fill with 0 later, if something valid follows
            math(EXPR pending_zeros "${pending_zeros} + 1")
        endif()
    endforeach()

    # --- Prerelease piece: -PRERELEASE ---
    if(NOT stopped)
        list(FIND SV_ARG_KEYWORDS_MISSING_VALUES "PRERELEASE" missing_idx)
        if(DEFINED SV_ARG_PRERELEASE)
            set(value "${SV_ARG_PRERELEASE}")
            if(value MATCHES "^[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*$")
                set(result "${result}-${value}")
            else()
                set(stopped TRUE)
            endif()
        elseif(NOT missing_idx EQUAL -1)
            set(stopped TRUE)
        endif()
        # else: not mentioned at all -> silently skipped, no filler
    endif()

    # --- Build metadata piece: +BUILD ---
    if(NOT stopped)
        list(FIND SV_ARG_KEYWORDS_MISSING_VALUES "BUILD" missing_idx)
        if(DEFINED SV_ARG_BUILD)
            set(value "${SV_ARG_BUILD}")
            if(value MATCHES "^[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*$")
                set(result "${result}+${value}")
            else()
                set(stopped TRUE)
            endif()
        elseif(NOT missing_idx EQUAL -1)
            set(stopped TRUE)
        endif()
    endif()

    set(${return} "${result}" PARENT_SCOPE)
endfunction()
