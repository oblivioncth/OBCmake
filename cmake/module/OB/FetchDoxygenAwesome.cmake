include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Checks out doxygen-awesome-css and returns the path to its source directory

# git_ref - Tag, branch name, or commit hash to retrieve. According to CMake docs,
#           a commit hash is preferred for speed and reliability

function(ob_fetch_doxygen_awesome git_ref return)
    __ob_command(ob_fetch_doxygen_awesome "3.11.0")

    include(FetchContent)
    FetchContent_Declare(doxygen-awesome-css
        GIT_REPOSITORY "https://github.com/jothepro/doxygen-awesome-css"
        GIT_TAG ${git_ref}
        GIT_SHALLOW true
        # In-case the repo ever adds a CMakeLists.txt, pointing this input to
        # a non-existent directory ensure it's not added to the build
        SOURCE_SUBDIR "DISABLE_BUILD"
    )
    FetchContent_MakeAvailable(doxygen-awesome-css)
    
    set(${return} ${doxygen-awesome-css_SOURCE_DIR} PARENT_SCOPE)
endfunction()
