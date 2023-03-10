include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Sets up Neargye's magic_enum to be grabbed from git

# git_ref - Tag, branch name, or commit hash to retrieve. According to CMake docs,
#           a commit hash is preferred for speed and reliability

function(ob_fetch_magicenum git_ref)
    __ob_command(ob_fetch_magicenum "3.11.0")

    include(FetchContent)
    FetchContent_Declare(magicenum
        GIT_REPOSITORY "https://github.com/Neargye/magic_enum"
        GIT_TAG ${git_ref}
    )
    FetchContent_MakeAvailable(magicenum)
endfunction()
