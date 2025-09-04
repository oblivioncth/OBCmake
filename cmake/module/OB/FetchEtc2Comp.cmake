function(ob_fetch_etc2comp git_ref)
    __ob_command(ob_fetch_etc2comp "3.11.0")

    include(FetchContent)
    FetchContent_Declare(ETC2COMP
        GIT_REPOSITORY "https://github.com/oblivioncth/etc2comp"
        GIT_TAG ${git_ref}
    )
    FetchContent_MakeAvailable(ETC2COMP)
endfunction()