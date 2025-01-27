# TODO: Add target common stuff here, i.e. from Executable and Library
#
# Currently there is a common "base" function that all specific functions
# can call, but we should also implement other common functions that
# "derive" from those for functionality that's shared by only some specific
# functions.
#
# Right now arguments are passed explicitly by name, but we should come up with
# a good way to be able to just pass all of the arguments directly from the top
# level all the way down, ignoring unrecognized variables (since those may
# be handled by the top level, so the top level can do unrecognized checks)
# so that they dont need to be named over and over


# Argument Notes:
#
# Fixed arguments are
#
# target -
#
function(__ob_common_target_setup target type use_qt_var)
    # This function by all means can perform the Qt detection step,
    # but then its tricky because it then needs to create the target itself,
    # which means it needs to know the library type if the target is
    # to be a library

endfunction()
