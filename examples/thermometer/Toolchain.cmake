SET(CMAKE_SYSTEM_NAME Generic)

SET(AZURE_SPHERE_CMAKE_PATH "C:/Program Files (x86)/Microsoft Azure Sphere SDK/CMakeFiles")
SET(AZURE_SPHERE_SDK_PATH "C:/Program Files (x86)/Microsoft Azure Sphere SDK" CACHE INTERNAL "Path to the Azure Sphere SDK")

IF(NOT ${CMAKE_GENERATOR} STREQUAL "Ninja")
    MESSAGE(FATAL_ERROR "Azure Sphere CMake projects must use the Ninja generator")
ENDIF()

# Force CMake to generate paths with forward slashes to work around response file generation errors
SET(CMAKE_COMPILER_IS_MINGW 1)

SET(AZURE_SPHERE_MAKE_IMAGE_FILE "${AZURE_SPHERE_CMAKE_PATH}/AzureSphereMakeImage.cmake" CACHE INTERNAL "Path to the MakeImage CMake target")

# Get API set from environment set from input variables
IF(DEFINED AZURE_SPHERE_TARGET_API_SET)
    SET(ENV{AzureSphereTargetApiSet} ${AZURE_SPHERE_TARGET_API_SET})
ENDIF()
SET(AZURE_SPHERE_TARGET_API_SET $ENV{AzureSphereTargetApiSet})

# Get available API sets
FILE(GLOB AZURE_SPHERE_AVAILABLE_API_SETS RELATIVE "${AZURE_SPHERE_SDK_PATH}/Sysroots" "${AZURE_SPHERE_SDK_PATH}/Sysroots/*")

# Set include paths and check if given API set is valid
SET(AZURE_SPHERE_API_SET_VALID 0)
FOREACH(AZURE_SPHERE_API_SET ${AZURE_SPHERE_AVAILABLE_API_SETS})
    SET(ENV{INCLUDE} "${AZURE_SPHERE_SDK_PATH}/Sysroots/${AZURE_SPHERE_API_SET}/usr/include;$ENV{INCLUDE}")
    IF("${AZURE_SPHERE_TARGET_API_SET}" STREQUAL "${AZURE_SPHERE_API_SET}")
        SET(AZURE_SPHERE_API_SET_VALID 1)
    ENDIF()
ENDFOREACH()

IF(NOT AZURE_SPHERE_API_SET_VALID)
    # Create API set list
    SET(AZURE_SPHERE_API_SET_LIST "[\"${AZURE_SPHERE_AVAILABLE_API_SETS}\"]")
    STRING(REPLACE ";" "\", \"" AZURE_SPHERE_API_SET_LIST "${AZURE_SPHERE_API_SET_LIST}")
    # Change error message depending on whether it's set
    IF("${AZURE_SPHERE_TARGET_API_SET}" STREQUAL "")
        MESSAGE(FATAL_ERROR "Variable AZURE_SPHERE_TARGET_API_SET is not set. "
            "Variable AZURE_SPHERE_TARGET_API_SET is not set correctly. Set this variable to one of the available API sets: ${AZURE_SPHERE_API_SET_LIST}. "
            "To do this, use CMakeSettings.json (if using Visual Studio), .vscode/settings.json (if using Visual Studio Code), or -DAZURE_SPHERE_TARGET_API_SET=<value> (if using command line build).")
    ELSE()
        MESSAGE(FATAL_ERROR "API set \"${AZURE_SPHERE_TARGET_API_SET}\" is not valid. "
            "Valid API sets are: ${AZURE_SPHERE_API_SET_LIST}")
    ENDIF()
ENDIF()

SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Disable linking during try_compile since our link options cause the generation to fail
SET(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY CACHE INTERNAL "Disable linking for try_compile")

# Add ComponentId to app_manifest if necessary
IF(EXISTS "${CMAKE_SOURCE_DIR}/app_manifest.json")
    FILE(READ "${CMAKE_SOURCE_DIR}/app_manifest.json" AZURE_SPHERE_APP_MANIFEST_CONTENTS)
    STRING(REGEX MATCH "\"ComponentId\": \"([^\"]*)\"" AZURE_SPHERE_COMPONENTID "${AZURE_SPHERE_APP_MANIFEST_CONTENTS}")
    SET(AZURE_SPHERE_COMPONENTID_VALUE "${CMAKE_MATCH_1}")
    # CMake Regex doesn't support syntax for matching exact number of characters, so we get to do guid matching the fun way
    SET(AZURE_SPHERE_GUID_REGEX "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_2 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_3 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_4 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    SET(AZURE_SPHERE_GUID_REGEX_5 "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]")
    STRING(APPEND AZURE_SPHERE_GUID_REGEX "-" ${AZURE_SPHERE_GUID_REGEX_2} "-" ${AZURE_SPHERE_GUID_REGEX_3} "-" ${AZURE_SPHERE_GUID_REGEX_4} "-" ${AZURE_SPHERE_GUID_REGEX_5})
    STRING(REGEX MATCH "${AZURE_SPHERE_GUID_REGEX}" AZURE_SPHERE_COMPONENTID_GUID "${AZURE_SPHERE_COMPONENTID_VALUE}")
    IF("${AZURE_SPHERE_COMPONENTID_GUID}" STREQUAL "")
        # Generate random GUID
        STRING(RANDOM LENGTH 8 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID)
        STRING(RANDOM LENGTH 4 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_2)
        STRING(RANDOM LENGTH 4 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_3)
        STRING(RANDOM LENGTH 4 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_4)
        STRING(RANDOM LENGTH 12 ALPHABET "0123456789abcdef" AZURE_SPHERE_GUID_5)
        STRING(APPEND AZURE_SPHERE_GUID "-" ${AZURE_SPHERE_GUID_2} "-" ${AZURE_SPHERE_GUID_3} "-" ${AZURE_SPHERE_GUID_4} "-" ${AZURE_SPHERE_GUID_5})
        # Write GUID to ComponentId
        STRING(REGEX REPLACE "\"ComponentId\": \"[^\"]*\"" "\"ComponentId\": \"${AZURE_SPHERE_GUID}\"" AZURE_SPHERE_APP_MANIFEST_CONTENTS "${AZURE_SPHERE_APP_MANIFEST_CONTENTS}")
        FILE(WRITE "${CMAKE_SOURCE_DIR}/app_manifest.json" ${AZURE_SPHERE_APP_MANIFEST_CONTENTS})
    ENDIF()
ENDIF()

IF (DEFINED AZURE_SPHERE_LTO)
    IF(${CMAKE_HOST_WIN32})
        SET(STATIC_LIBRARY_OPTIONS "--plugin liblto_plugin-0.dll")
    ELSE()
        SET(STATIC_LIBRARY_OPTIONS "--plugin liblto_plugin-0")
    ENDIF()
    ADD_COMPILE_OPTIONS(-flto)
    ADD_LINK_OPTIONS(-flto)
ENDIF()

SET(AZURE_SPHERE_API_SET_DIR "${AZURE_SPHERE_SDK_PATH}/Sysroots/${AZURE_SPHERE_TARGET_API_SET}" CACHE INTERNAL "Path to the selected API set in the Azure Sphere SDK")
SET(ENV{PATH} "${AZURE_SPHERE_SDK_PATH}/Tools;${AZURE_SPHERE_API_SET_DIR}/tools/gcc;$ENV{PATH}")
SET(CMAKE_FIND_ROOT_PATH "${AZURE_SPHERE_API_SET_DIR}")

# Set up compiler and flags
IF(${CMAKE_HOST_WIN32})
    SET(CMAKE_C_COMPILER "${AZURE_SPHERE_API_SET_DIR}/tools/gcc/arm-poky-linux-musleabi-gcc.exe" CACHE INTERNAL "Path to the C compiler in the selected API set targeting High-Level core")
    SET(CMAKE_CXX_COMPILER "${AZURE_SPHERE_API_SET_DIR}/tools/gcc/arm-poky-linux-musleabi-gcc.exe" CACHE INTERNAL "Path to the C compiler in the selected API set targeting High-Level core")
    SET(CMAKE_AR "${AZURE_SPHERE_API_SET_DIR}/tools/gcc/arm-poky-linux-musleabi-ar.exe" CACHE INTERNAL "Path to the C compiler in the selected API set targeting High-Level core")
ELSE()
    SET(CMAKE_C_COMPILER "${AZURE_SPHERE_API_SET_DIR}/tools/gcc/arm-poky-linux-musleabi-gcc" CACHE INTERNAL "Path to the C compiler in the selected API set targeting High-Level core")
    SET(CMAKE_AR "${AZURE_SPHERE_API_SET_DIR}/tools/gcc/arm-poky-linux-musleabi-ar" CACHE INTERNAL "Path to the C compiler in the selected API set targeting High-Level core")
ENDIF()

SET(CMAKE_C_FLAGS_INIT "-B \"${AZURE_SPHERE_API_SET_DIR}/tools/gcc\" -march=armv7ve -mthumb -mfpu=neon -mfloat-abi=hard \
-mcpu=cortex-a7 --sysroot=\"${AZURE_SPHERE_API_SET_DIR}\"")
SET(CMAKE_CXX_FLAGS_INIT "-B \"${AZURE_SPHERE_API_SET_DIR}/tools/gcc\" -march=armv7ve -mthumb -mfpu=neon -mfloat-abi=hard \
-mcpu=cortex-a7 --sysroot=\"${AZURE_SPHERE_API_SET_DIR}\"")
SET(CMAKE_EXE_LINKER_FLAGS_INIT "-nodefaultlibs -pie -Wl,--no-undefined -Wl,--gc-sections")

SET(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES "${AZURE_SPHERE_API_SET_DIR}/usr/include")
SET(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "${AZURE_SPHERE_API_SET_DIR}/usr/include")

# Append the hardware definition directory
IF((NOT ("${AZURE_SPHERE_HW_DEFINITION}" STREQUAL "")) AND (IS_DIRECTORY "${AZURE_SPHERE_HW_DIRECTORY}/inc"))
    LIST(APPEND CMAKE_C_STANDARD_INCLUDE_DIRECTORIES "${AZURE_SPHERE_HW_DIRECTORY}/inc")
    LIST(APPEND CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES "${AZURE_SPHERE_HW_DIRECTORY}/inc")
ENDIF()

ADD_DEFINITIONS(-D_POSIX_C_SOURCE)
SET(COMPILE_DEBUG_FLAGS $<$<CONFIG:Debug>:-ggdb> $<$<CONFIG:Debug>:-O0>)
SET(COMPILE_RELEASE_FLAGS $<$<CONFIG:Release>:-g1> $<$<CONFIG:Release>:-Os>)
ADD_COMPILE_OPTIONS($<$<COMPILE_LANGUAGE:CXX>:-std=c++11> $<$<COMPILE_LANGUAGE:C>:-std=c11>
                    $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
                    ${COMPILE_DEBUG_FLAGS} ${COMPILE_RELEASE_FLAGS} -fPIC
                    -ffunction-sections -fdata-sections -fno-strict-aliasing
                    -fno-omit-frame-pointer -fno-exceptions -Wall $<$<COMPILE_LANGUAGE:C>:-Wstrict-prototypes>
                    -Wswitch -Wempty-body -Wconversion -Wreturn-type -Wparentheses
                    $<$<COMPILE_LANGUAGE:C>:-Wno-pointer-sign> -Wno-format -Wuninitialized -Wunreachable-code
                    -Wunused-function -Wunused-value -Wunused-variable
                    -Werror=implicit-function-declaration -fstack-protector-strong)

