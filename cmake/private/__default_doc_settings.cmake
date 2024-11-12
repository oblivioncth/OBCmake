#-----------Main Doxygen Options-----------------------------

# Here we only replace single value options if they aren't defined,
# and append to list based options when possible in order to not
# trample user set overrides, unless a certain value is imperative

# General
if(NOT DEFINED DOXYGEN_REPEAT_BRIEF)
    set(DOXYGEN_REPEAT_BRIEF NO)
endif()
if(NOT DEFINED DOXYGEN_WARN_AS_ERROR)
    set(DOXYGEN_WARN_AS_ERROR YES)
endif()
if(NOT DEFINED DOXYGEN_GENERATE_TREEVIEW)
    set(DOXYGEN_GENERATE_TREEVIEW YES)
endif()
if(NOT DEFINED DOXYGEN_ENABLE_PREPROCESSING)
    set(DOXYGEN_ENABLE_PREPROCESSING YES)
endif()
if(NOT DEFINED DOXYGEN_MACRO_EXPANSION)
    set(DOXYGEN_MACRO_EXPANSION YES)
endif()
if(NOT DEFINED DOXYGEN_EXPAND_ONLY_PREDEF)
    set(DOXYGEN_EXPAND_ONLY_PREDEF YES)
endif()
if(NOT DEFINED DOXYGEN_BUILTIN_STL_SUPPORT)
    set(DOXYGEN_BUILTIN_STL_SUPPORT YES)
endif()
if(NOT DEFINED DOXYGEN_GROUP_NESTED_COMPOUND)
    set(DOXYGEN_GROUP_NESTED_COMPOUND YES)
endif()
if(NOT DEFINED DOXYGEN_ENUM_VALUES_PER_LINE)
    set(DOXYGEN_ENUM_VALUES_PER_LINE 1)
endif()
if(NOT DEFINED DOXYGEN_EXT_LINKS_IN_WINDOW)
    set(DOXYGEN_EXT_LINKS_IN_WINDOW YES)
endif()
if(NOT DEFINED DOXYGEN_CLASS_GRAPH)
    set(DOXYGEN_CLASS_GRAPH NO)
endif()
if(NOT DEFINED DOXYGEN_TREEVIEW_WIDTH)
    set(DOXYGEN_TREEVIEW_WIDTH 340)
endif()
if(NOT DEFINED DOXYGEN_SORT_BRIEF_DOCS)
    set(DOXYGEN_SORT_BRIEF_DOCS YES)
endif()
if(NOT DEFINED DOXYGEN_SORT_MEMBERS_CTORS_1ST)
    SET(DOXYGEN_SORT_MEMBERS_CTORS_1ST YES)
endif()
if(NOT DEFINED DOXYGEN_FULL_PATH_NAMES)
    SET(DOXYGEN_FULL_PATH_NAMES NO)
endif()
if(NOT DEFINED DOXYGEN_FULL_PATH_NAMES)
    SET(DOXYGEN_FULL_PATH_NAMES NO)
endif()
if(NOT DEFINED DOXYGEN_ALLEXTERNALS)
    SET(DOXYGEN_ALLEXTERNALS NO)
endif()
if(NOT DEFINED DOXYGEN_EXTERNAL_GROUPS)
    SET(DOXYGEN_EXTERNAL_GROUPS NO)
endif()
if(NOT DEFINED DOXYGEN_EXTERNAL_PAGES)
    SET(DOXYGEN_EXTERNAL_PAGES NO)
endif()

# Configure custom command/macro processing
list(APPEND DOXYGEN_ALIASES
	[[qflag{2}="@typedef \1^^<p>The \1 type is a typedef for QFlags\<\2\>. It stores an OR combination of \2 values.</p>"]]
    "component{2}=\"@par Import:^^@code find_package(${PROJECT_NAME} REQUIRED COMPONENTS \\1)@endcode ^^@par Link:^^@code target_link_libraries(target_name ${PROJECT_NAME}::\\1)@endcode ^^@par Include:^^@code #include <${PROJECT_NAME_LC}/\\2>@endcode\""
)

# Workarounds for
# 1) Doxygen doesn't understand Q_DECLARE_FLAGS fully
# 2) Doxygen doesn't understand Q_DECLARE_OPERATORS_FOR_FLAGS fully
# 3) Doxygen doesn't understand QX_ERROR_TYPE fully
# 4) Doxygen doesn't understand Q_DECLARE_METATYPE fully
# 5) Ignore declspec attributes, causes issues with source located documentation
# 6) Always document Win dependent things
# 7) Always document Linux dependent things
list(APPEND DOXYGEN_PREDEFINED
    "QX_ERROR_TYPE(Type,name,code)=Type final : public Qx::AbstractError<name, code>"
	"Q_DECLARE_FLAGS(flagsType,enumType)=typedef QFlags<enumType> flagsType\;"
    "Q_DECLARE_OPERATORS_FOR_FLAGS(flagsType)="
    "Q_DECLARE_METATYPE(x)="
    "__declspec(x)="
    "_WIN32"
    "__linux__"
)

# Prevent unwanted quoting
set(DOXYGEN_VERBATIM_VARS DOXYGEN_ALIASES)

# Set output paths
set(DOXYGEN_OUTPUT_DIRECTORY ${DOC_BUILD_PATH})

#-------------Doxygen Awsome Options--------------

# Base Theme
set(DOXYGEN_GENERATE_TREEVIEW YES)
set(DOXYGEN_DISABLE_INDEX NO)
set(DOXYGEN_FULL_SIDEBAR NO)
set(DOXYGEN_HTML_COLORSTYLE LIGHT)
list(APPEND DOXYGEN_HTML_EXTRA_STYLESHEET
    "${DOC_THEME_PATH}/doxygen-awesome.css"
    "${DOC_THEME_PATH}/doxygen-awesome-sidebar-only.css"
)

# Customization
list(APPEND DOXYGEN_HTML_EXTRA_STYLESHEET
    "${__OB_CMAKE_PRIVATE}/__doc_static_theme_customization.css"
    "${DOC_GEN_RESOURCE_PATH}/__doc_theme_color_customization.css"
)

# Extensions - General
set(DOXYGEN_HTML_HEADER "${DOC_GEN_RESOURCE_PATH}/__doc_theme_header.html")

# Extensions - Dark Mode Toggle
list(APPEND DOXYGEN_HTML_EXTRA_FILES "${DOC_THEME_PATH}/doxygen-awesome-darkmode-toggle.js")
list(APPEND DOXYGEN_HTML_EXTRA_STYLESHEET "${DOC_THEME_PATH}/doxygen-awesome-sidebar-only-darkmode-toggle.css")

# Extensions - Fragment Copy Button
list(APPEND DOXYGEN_HTML_EXTRA_FILES "${DOC_THEME_PATH}/doxygen-awesome-fragment-copy-button.js")

# Extensions - Paragraph Linking
list(APPEND DOXYGEN_HTML_EXTRA_FILES "${DOC_THEME_PATH}/doxygen-awesome-paragraph-link.js")

# Best matching class diagram options
set(DOXYGEN_DOT_IMAGE_FORMAT svg)
set(DOXYGEN_DOT_TRANSPARENT YES)