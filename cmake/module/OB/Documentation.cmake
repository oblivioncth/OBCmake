include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Essentially just defines and populates the following variables
# if their paths can be located:
# - QT_HELP_GEN_PATH: path to qhelpgenerator executable
# - QT_DOCS_DIR: path to the root of Qt documentation
function(ob_find_qt_doc_resources qt_prefix)
    __ob_command(ob_find_qt_doc_resources "3.0.0")

    # Handle using cache so that users can easily override via UI or command-line

    # Could use crazy amounts of file system searching to check for every Qt root under the standard Qt install
    # location for each platform (i.e. C:/Program Files/Qt/6.3.0/msvc2019/) and then add those as PATHS to the
    # below commands, but for now, lets not

    # Locate qhelpgenerator
    find_file(QT_HELP_GEN_PATH
        NAMES
            "qhelpgenerator"
            "qhelpgenerator.exe"
        HINTS
            "${qt_prefix}"
        PATH_SUFFIXES
            "bin"
            "libexec"
        DOC "Path to the qhelpgenerator executable"
        NO_DEFAULT_PATH
    )

    if(QT_HELP_GEN_PATH)
        message(STATUS "qhelpgenerator found at: ${QT_HELP_GEN_PATH}")
    else()
        message(WARNING "Could not find qhelpgenerator. Please set QT_HELP_GEN_PATH to its location if you want to generate a .qch file for documentation.")
    endif()

    # Locate Qt documentation
    find_path(QT_DOCS_DIR
        NAMES
            "qtcore.qch"
            "qtcore"
        HINTS
            "${qt_prefix}/doc"
        PATHS
            "C:/Program Files/Qt/Docs/Qt-${Qt6_VERSION}"
        DOC "Path to Qt documentation"
        NO_DEFAULT_PATH
    )

    if(QT_DOCS_DIR)
        message(STATUS "Qt documentation found at: ${QT_DOCS_DIR}")
    else()
        message(WARNING "Could not find documentation for the in-use Qt version. Please set QT_DOCS_DIR to its location if you want the generated documentation to reference Qt.")
    endif()
endfunction()

# Adds tag if missing
macro(__ob_ensure_triplet_tag triplet_var)
    if(NOT ${triplet_var} MATCHES "^#")
        string(PREPEND triplet_var "#")
    endif()
endmacro()

# Scales S or L of a color
function(__ob_scale_color_prop prop_var dir percent return)
    __ob_internal_command(__ob_scale_color_prop "3.7.0")

    # Expand
    set(prop ${${prop_var}})

    __ob_assert(prop GREATER_EQUAL 0 AND prop LESS_EQUAL 100)
    __ob_assert(percent GREATER_EQUAL 0 AND percent LESS_EQUAL 100)

    # Currently this function doesn't round before dividing so the result might
    # be off by 1 due to integer division; however, since this is just to scale
    # proportionally it barely matters at all.
    if(dir STREQUAL "UP")
        if(prop LESS 100)
            math(EXPR prop "${prop} + ((100 - ${prop}) * ${percent})/100")
        endif()
    elseif(dir STREQUAL "DOWN")
        if(prop GREATER 0)
            math(EXPR prop "${prop} - (${prop} * ${percent})/100")
        endif()
    else()
        message(FATAL_ERROR "Direction must be 'UP' or 'DOWN'")
    endif()

    set(${return} ${prop} PARENT_SCOPE)
endfunction()

# Scales HSL lightness to Doxygen gamma
function(__ob_hsl_lit_to_doxy_gam lit return)
    __ob_internal_command(__ob_hsl_lit_to_doxy_gam "3.0.0")

    # Transform is an asymmetric triangle. 50 is lightness midpoint,
    # while 100 is gamma midpoint, but lightness min/max is 0/100, yet
    # gamma min/max is 40/240, so gamma has a higher upper range.
    #
    # A good way to map this other than the triangle is a quadratic
    # equation that just so happens to perfectly fit all three known
    # points:
    #
    # (S: 0,   G: 40)
    # (S: 50,  G: 100)
    # (s: 100, G: 240)
    #
    # Which is y=0.016x^2 +0.4x+40.
    #
    # To avoid floating point math, we use:
    #
    # y = (16x^2 + 400x + 40000)/1000
    include(OB/Math)
    math(EXPR gamma_s "16 * ${lit} * ${lit} + 400 * ${lit} + 40000")
    ob_round(${gamma_s} 3 gamma_s)
    math(EXPR gamma "${gamma_s}/1000")

    set(${return} ${gamma} PARENT_SCOPE)
endfunction()

# Generates a CSS file with color settings for Doxygen Awesome based on input
# Also returns the HSL of the primary color
function(__ob_generate_color_css output_dir r_ph r_ps r_pl)
    __ob_internal_command(__ob_generate_color_css "3.0.0")

    include(OB/Color)

    # Implementation relies on NIGHT_PRIMARY coming before other nights!
    set(colors
        PRIMARY
        PRIMARY_DARK
        PRIMARY_LIGHT
        NIGHT_PRIMARY
        NIGHT_PRIMARY_DARK
        NIGHT_PRIMARY_LIGHT
    )

    # Additional Function inputs
    set(oneValueArgs
        ${colors}
    )

    set(multiValueArgs
    )

    set(requiredArgs
        PRIMARY
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(COLORS "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Setup default maps
    set(DEF_ADJ_S_PRIMARY) # Unused
    set(DEF_ADJ_L_PRIMARY) # Unused
    set(DEF_ADJ_S_PRIMARY_DARK
        "COLORS_PRIMARY_S" "DOWN" 35
    )
    set(DEF_ADJ_L_PRIMARY_DARK
        "COLORS_PRIMARY_L" "DOWN" 28
    )
    set(DEF_ADJ_S_PRIMARY_LIGHT
        "COLORS_PRIMARY_S" "DOWN" 5
    )
    set(DEF_ADJ_L_PRIMARY_LIGHT
        "COLORS_PRIMARY_L" "UP" 35
    )
    set(DEF_ADJ_S_NIGHT_PRIMARY
        "COLORS_PRIMARY_S" "UP" 5
    )
    set(DEF_ADJ_L_NIGHT_PRIMARY
        "COLORS_PRIMARY_L" "UP" 7
    )
    set(DEF_ADJ_S_NIGHT_PRIMARY_DARK
        "COLORS_NIGHT_PRIMARY_S" "DOWN" 20
    )
    set(DEF_ADJ_L_NIGHT_PRIMARY_DARK
        "COLORS_NIGHT_PRIMARY_L" "UP" 18 # Dark is light in night mode
    )
    set(DEF_ADJ_S_NIGHT_PRIMARY_LIGHT
        "COLORS_NIGHT_PRIMARY_S" "DOWN" 38
    )
    set(DEF_ADJ_L_NIGHT_PRIMARY_LIGHT
        "COLORS_NIGHT_PRIMARY_L" "DOWN" 33 # Light is dark in night mode
    )

    # Handle defaults
    foreach(color ${colors})
        set(input_name "COLORS_${color}")
        if(NOT ${input_name})
            # Get adjust args
            set(s_key "DEF_ADJ_S_${color}")
            set(l_key "DEF_ADJ_L_${color}")
            __ob_assert(DEFINED ${s_key} AND DEFINED ${l_key})

            # Prepare input args
            set(def_adj_s ${${s_key}})
            set(def_adj_l ${${l_key}})

            # Create adjusted color
            set(h ${COLORS_PRIMARY_H})
            __ob_scale_color_prop(${def_adj_s} s)
            __ob_scale_color_prop(${def_adj_l} l)

            # Convert
            ob_hsl_to_rgb(${h} ${s} ${l} r g b)
            ob_rgb_to_hex(${r} ${g} ${b} triplet)
            set(${input_name} "${triplet}")
        else()
            # Get RGB/HSL of given value
            __ob_ensure_triplet_tag(${input_name})
            set(input ${${input_name}})
            ob_hex_to_rgb("${input}" r g b)
            ob_rgb_to_hsl(${r} ${g} ${b} h s l)
        endif()

        # Define color components for colors that may derive from this one
        set(${input_name}_R ${r})
        set(${input_name}_G ${g})
        set(${input_name}_B ${b})
        set(${input_name}_H ${h})
        set(${input_name}_S ${s})
        set(${input_name}_L ${l})
    endforeach()

    # Generate css
    set(filename "__doc_theme_color_customization.css")
    set(template_file "${__OB_CMAKE_PRIVATE}/templates/${filename}.in")
    set(generated_path "${output_dir}/${filename}")
    configure_file("${template_file}"
        "${generated_path}"
        @ONLY
        NEWLINE_STYLE UNIX
    )

    # Return primary HSL
    set(${r_ph} ${COLORS_PRIMARY_H} PARENT_SCOPE)
    set(${r_ps} ${COLORS_PRIMARY_S} PARENT_SCOPE)
    set(${r_pl} ${COLORS_PRIMARY_L} PARENT_SCOPE)
endfunction()

function(__ob_generate_doc_theme_header)
    __ob_internal_command(__ob_generate_doc_theme_header "3.0.0")

    find_package(Git)

    if(Git_FOUND)
        # Describe repo
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" remote get-url --push origin
            WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
            COMMAND_ERROR_IS_FATAL ANY
            RESULT_VARIABLE res
            OUTPUT_VARIABLE GIT_REMOTE_URL
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )

        # Check for result
        if(GIT_REMOTE STREQUAL "")
            message(FATAL_ERROR "Git returned an empty remote for documentation!")
        endif()
    else()
        message(FATAL_ERROR "Need Git to get remote URL for documentation!")
    endif()

    set(filename "__doc_theme_header.html")
    set(template_file "${__OB_CMAKE_PRIVATE}/templates/${filename}.in")
    set(generated_path "${DOC_GEN_RESOURCE_PATH}/${filename}")
    configure_file("${template_file}"
        "${generated_path}"
        @ONLY
    )
endfunction()

# Configures a documentation target for the project
#
# TODO: Make this more flexible via function arguments,
# though doing this in an effective way without making
# it a total argument mess will be tricky
#
# Assumes the following layout of the directory (best
# dedicated to the documentation target) containing the
# CMakeLists.txt that invokes this function, with 'doc'
# being the root of said folder:
#
# doc/cmake/file_templates
# doc/res/images (for DOXYGEN_IMAGE_PATH)
# doc/res/snippets (for DOXYGEN_EXAMPLE_PATH)
# doc/general (automatically added to Doxygen input list)
# doc/CMakeLists.txt
#
# Assumes the following files/directories specifically
# are available:
#
# doc/cmake/file_templates/mainpage.md.in
# doc/res/logo.svg (optional)
# doc/res/DoxygenLayout.xml
# doc/res/header.html
#
# Doxygen variables can be overridden in the standard manner before
# calling this function.
#
# Other:
# - Uses Doxygen Awesome
# - Assumes PROJECT_VERSION_VERBOSE is available
# - Uses TOP_PROJ_INCLUDE_IN_ALL to include the documentation in the
#   all target
# - Sets the install component for the docs to the provided target name
# - Only installs docs for Release configuration
# - Uses SUB_PROJ_EXCLUDE_FROM_ALL to exclude the doc install from the
#   default component
#
# Arguments:
# - TARGET_NAME: name of the doc target that is created
# - DOXY_VER: version of Doxygen to request
# - THEME_VER: version of Doxygen Awesome to fetch, other than default
# - PROJ_NAME: value for DOXYGEN_PROJ_NAME, defaults to "PROJ_NAME"
# - INSTALL_DESTINATION: Where to install the generated documentation,
#                        defaults to 'doc' folder relative to CMAKE_INSTALL_PREFIX
# - INPUT_LIST: Paths for Doxygen to search
# - QT_PREFIX: Path to Qt installation prefix. Providing this argument enables:
#   > Generation of a .qch file for the documentation
#   > References/links to the Qt documentation, see the following argument
#   > If qhelpgenerator and the Qt docs directory cannot be located automatically,
#     the user can provide them directly via the QT_HELP_GEN_PATH and QT_DOCS_DIR
#     variables respectively
# - ADDITIONAL_ROOTS: List of additional doc roots to check for the following
#                     folders that get treated as shown above
#                     ./general
#                     ./res/images
#                     ./res/snippets
# - QT_MODULES: List of Qt modules to link to via .tag files (i.e. qtcore, qtquick, etc).
#   Ignored if no QT_PREFIX was provided.
# - THEME_COLORS:
#     Inner Form:
#           THEME_COLORS
#               PRIMARY
#               PRIMARY_DARK
#               PRIMARY_LIGHT
#               NIGHT_PRIMARY
#               NIGHT_PRIMARY_DARK
#               NIGHT_PRIMARY_LIGHT
#
#   This argument sets the colors for the Doxygen Awesome theme, as well as any relevant
#   standard Doxygen colors. PRIMARY is required, but the rest are optional, and will
#   be derived from PRIMARY if not provided. THE DARK_ prefixed values are for dark
#   mode. Each is to be specified as an hexadecimal RBG triplet.
function(ob_standard_documentation target)
    __ob_command(ob_standard_documentation "3.12.0")

    #---------------- Function Setup ----------------------
    # Const variables

    # Additional Function inputs
    set(oneValueArgs
        DOXY_VER
        THEME_VER
        PROJ_NAME
        INSTALL_DESTINATION
        QT_PREFIX
    )

    set(multiValueArgs
        INPUT_LIST
        ADDITIONAL_ROOTS
        QT_MODULES
        THEME_COLORS
    )

    set(requiredArgs
        THEME_COLORS
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_DOCS "" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})

    # Handle undefineds
    if(STD_DOCS_DOXY_VER)
        set(doxygen_version "${STD_DOCS_DOXY_VER}")
    else()
        set(doxygen_version "1.9.10")
    endif()

    if(STD_DOCS_THEME_VER)
        set(theme_version "${STD_DOCS_THEME_VER}")
    else()
        set(theme_version "v2.3.3")
    endif()

    if(STD_DOCS_PROJ_NAME)
        set(doc_proj_name "${STD_DOCS_PROJ_NAME}")
    else()
        set(doc_proj_name "${PROJECT_NAME}")
    endif()

    if(STD_DOCS_INSTALL_DESTINATION)
        set(doc_install_dest "${STD_DOCS_INSTALL_DESTINATION}")
    else()
        set(doc_install_dest "doc")
    endif()

    #--------------------- Define Doc Paths -----------------------
    set(DOC_MAIN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
    set(DOC_MAIN_SCRIPTS_PATH "${DOC_MAIN_ROOT}/cmake")
    set(DOC_GEN_ROOT "${CMAKE_CURRENT_BINARY_DIR}/gen")

    # Source
    set(DOC_MAIN_RESOURCE_PATH "${DOC_MAIN_ROOT}/res")
    set(DOC_GEN_INPUT_PATH "${DOC_GEN_ROOT}/input")
    set(DOC_GEN_RESOURCE_PATH "${DOC_GEN_ROOT}/res")

    # Build
    set(DOC_BUILD_PATH "${CMAKE_CURRENT_BINARY_DIR}/doc")

    # Cmake related
    set(DOC_MAIN_TEMPLATES_PATH "${DOC_MAIN_SCRIPTS_PATH}/file_templates")

    #----------------------- Prepare Theme -----------------------

    # Fetch
    include(OB/FetchDoxygenAwesome)
    ob_fetch_doxygen_awesome("${theme_version}" DOC_THEME_PATH)

    # Generate color css
    __ob_generate_color_css(
        "${DOC_GEN_RESOURCE_PATH}"
        primary_h
        primary_s
        primary_l
        ${STD_DOCS_THEME_COLORS}
    )

    # Set Doxygen colorstyle if not already
    if(NOT DEFINED DOXYGEN_HTML_COLORSTYLE_HUE)
        set(DOXYGEN_HTML_COLORSTYLE_HUE ${primary_h})
    endif()
    if(NOT DEFINED DOXYGEN_HTML_COLORSTYLE_SAT)
        set(DOXYGEN_HTML_COLORSTYLE_SAT ${primary_s})
    endif()
    if(NOT DEFINED DOXYGEN_HTML_COLORSTYLE_GAMMA)
        __ob_hsl_lit_to_doxy_gam(${primary_l} doxy_gamma)
        set(DOXYGEN_HTML_COLORSTYLE_GAMMA ${doxy_gamma})
    endif()

    # Generate header
    __ob_generate_doc_theme_header()

    #------------------- Configure Documentation -----------------

    # Load static defaults
    include(${__OB_CMAKE_PRIVATE}/__default_doc_settings.cmake)

    # Set project name
    set(DOXYGEN_PROJECT_NAME "${doc_proj_name}")

    # Set project version using verbose version, if available
    if(DEFINED PROJECT_VERSION_VERBOSE)
        set(DOXYGEN_PROJECT_NUMBER "${PROJECT_VERSION_VERBOSE}")
    endif()

    # Set logo, if available
    set(logo_path "${DOC_MAIN_RESOURCE_PATH}/logo.svg")
    if(EXISTS "${logo_path}")
        set(DOXYGEN_PROJECT_LOGO "${logo_path}")
    endif()

    # Set custom layout file, if available
    set(layout_path "${DOC_MAIN_RESOURCE_PATH}/DoxygenLayout.xml")
    if(EXISTS "${layout_path}")
        set(DOXYGEN_LAYOUT_FILE "${layout_path}")
    endif()

    # Set custom header, if available
    set(header_path "${DOC_MAIN_RESOURCE_PATH}/header.xml")
    if(EXISTS "${header_path}")
        set(DOXYGEN_LAYOUT_FILE "${header_path}")
    endif()

    # Create tag file
    set(DOXYGEN_GENERATE_TAGFILE "${DOC_BUILD_PATH}/${PROJECT_NAME}.tag")

    #---------------------- Configure Qt Link ---------------------
    if(STD_DOCS_QT_PREFIX)
        # Try to get Qt doc information
        ob_find_qt_doc_resources("${STD_DOCS_QT_PREFIX}")

        # Link to docs
        if(QT_DOCS_DIR)
            # Ensure root exists
            if(NOT IS_DIRECTORY ${QT_DOCS_DIR})
                message(FATAL_ERROR "Qt docs path: '${QT_DOCS_DIR}' does not exist!")
            endif()

            # Process tags
            foreach(doc_module ${STD_DOCS_QT_MODULES})
                list(APPEND DOXYGEN_TAGFILES
                    ${QT_DOCS_DIR}/${doc_module}/${doc_module}.tags=https://doc.qt.io/qt-6/
                )
            endforeach()
        endif()

        # Setup Qt Creator help file creation
        if(QT_HELP_GEN_PATH)
            set(DOXYGEN_GENERATE_QHP YES)
            set(DOXYGEN_QCH_FILE "../${PROJECT_NAME}.qch")
            set(DOXYGEN_QHG_LOCATION ${QT_HELP_GEN_PATH})
        endif()
    endif()

    #------------------------- Setup Input ------------------------

    # Configure files
    configure_file("${DOC_MAIN_TEMPLATES_PATH}/mainpage.md.in"
        "${DOC_GEN_INPUT_PATH}/mainpage.md"
        @ONLY
    )

    # Doc Input
    set(DOC_INPUT_LIST
        "${DOC_GEN_INPUT_PATH}/mainpage.md"
        "${STD_DOCS_INPUT_LIST}"
    )

    # Cover roots for additional input
    list(APPEND all_roots
        "${DOC_MAIN_ROOT}"
        ${STD_DOCS_ADDITIONAL_ROOTS}
    )

    foreach(root ${all_roots})
        set(root_res_path "${root}/res")
        set(root_general_path "${root}/general")

        # Add regular input paths
        if(EXISTS "${root_general_path}")
            list(APPEND DOC_INPUT_LIST "${root_general_path}")
        endif()

        # Add extra input paths
        set(root_snippets "${root_res_path}/snippets")
        if(EXISTS "${root_snippets}")
            list(APPEND DOXYGEN_EXAMPLE_PATH "${root_snippets}")
        endif()

        set(root_images "${root_res_path}/images")
        if(EXISTS "${root_images}")
            list(APPEND DOXYGEN_IMAGE_PATH "${root_images}")
        endif()
    endforeach()

    #---------------------- Setup Doxygen ------------------------

    # Find Doxygen package
    find_package(Doxygen "${doxygen_version}" REQUIRED
        COMPONENTS dot
    )

    # Add Doxygen target
    doxygen_add_docs(${target}
        ${DOC_INPUT_LIST}
        ${TOP_PROJ_INCLUDE_IN_ALL}
    )

    #------------------------- Install ---------------------------
    install(DIRECTORY ${DOC_BUILD_PATH}/
        COMPONENT ${target}
        DESTINATION "${doc_install_dest}"
        CONFIGURATIONS Release
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )

    message(STATUS "Doxygen configured for ${PROJECT_NAME}. Build target '${target}' to build the documentation specifically, or simply build 'all'.")
endfunction()