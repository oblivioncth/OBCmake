function(__ob_get_verbose_version repo_dir return)
    #__ob_internal_command(__ob_get_verbose_version "3.0.0")
    # Not doing above for this file so that build script doesn't have to include private common

    # THIS FUNCTION ASSUMES THAT 'GIT_EXECUTABLE' IS DEFINED

    # Describe repo
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" describe --tags --match v*.* --dirty --always
        WORKING_DIRECTORY "${repo_dir}"
        COMMAND_ERROR_IS_FATAL ANY
        RESULT_VARIABLE res
        OUTPUT_VARIABLE GIT_DESC
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Command result
    if(NOT ("${GIT_DESC}" STREQUAL ""))
        set(${return} "${GIT_DESC}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Git returned a null description for ${repo_dir}!")
    endif()
endfunction()