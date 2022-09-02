# OBCMake

For personal use. Use them if you want.

Will add real documentation if this expands to be large enough.

## Usage

Grab [FetchOBCMake.cmake](https://github.com/oblivioncth/OBCmake/blob/master/consumer/FetchOBCMake.cmake), place it in a location visible to `CMAKE_MODULE_PATH`, and then:

```````````````````````````````````
include(FetchOBCMake)
fetch_ob_cmake(<GIT_REF_HERE>)

# Modules are now available
include(OB/...)
```````````````````````````````````