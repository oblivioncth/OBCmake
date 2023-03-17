include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Sets up libfp to be built/installed as an external project for use in the main project

# git_ref - Tag, branch name, or commit hash to retrieve. According to CMake docs,
#           a commit hash is preferred for speed and reliability

function(ob_fetch_libfp git_ref)
    __ob_command(ob_fetch_libfp "3.11.0")

    include(FetchContent)
    FetchContent_Declare(libfp
        GIT_REPOSITORY "https://github.com/oblivioncth/libfp"
        GIT_TAG ${git_ref}
    )
    FetchContent_MakeAvailable(libfp)
endfunction()
