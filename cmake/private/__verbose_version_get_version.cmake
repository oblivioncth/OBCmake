include("${__OB_CMAKE_PRIVATE}/common.cmake")

function(__ob_get_verbose_version repo fallback return)
    __ob_internal_command(__ob_get_verbose_version "3.0.0")
    find_package(Git)

    if(Git_FOUND)
        # Describe repo
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --tags --match v*.* --dirty --always
            WORKING_DIRECTORY "${repo}"
            COMMAND_ERROR_IS_FATAL ANY
            RESULT_VARIABLE res
            OUTPUT_VARIABLE GIT_DESC
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Command result
        if(NOT ("${GIT_DESC}" STREQUAL ""))
            set(${return} "${GIT_DESC}" PARENT_SCOPE)
        else()
            message(FATAL_ERROR "Git returned a null description!")
        endif()

    elseif(NOT (${fallback} STREQUAL ""))
        set(${return} "${fallback}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Git could not be found! You can define NO_GIT to acknowledge building without verbose versioning.")
    endif()
endfunction()