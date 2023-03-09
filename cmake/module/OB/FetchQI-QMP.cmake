include("${__OB_CMAKE_PRIVATE}/common.cmake")
ob_module_minimum_required(3.20.0)

# Sets up QI-QMP to be built/installed as an external project for use in the main project

# git_ref - Tag, branch name, or commit hash to retrieve. According to CMake docs,
#           a commit hash is preferred for speed and reliability

function(ob_fetch_qi_qmp git_ref)
    include(FetchContent)
    FetchContent_Declare(QI-QMP
        GIT_REPOSITORY "https://github.com/oblivioncth/QI-QMP"
        GIT_TAG ${git_ref}
    )
    FetchContent_MakeAvailable(QI-QMP)
endfunction()
