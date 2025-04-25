# output chosen build options
#输出当前构建的一些关键配置选项和编译器信息
#用于在配置（configure）阶段输出当前项目的构建配置、环境信息和自定义宏选项等。它主要目的是帮助开发者调试构建配置过程，便于排查问题或确认构建环境设置是否正确


macro( OptionOutput _outputstring )#这个宏用于简洁地输出布尔类型的 CMake 变量，如果这个变量为真（on或者飞控），输出yes
    if( ${ARGN} )
        set( _var "YES" )
    else( ${ARGN} )
        set( _var "NO" )
    endif( ${ARGN} )
    message( STATUS "${_outputstring}${_var}" )
endmacro( OptionOutput _outputstring )

include(CMakePrintHelpers)
# cmake_print_properties
# cmake_host_system_information

# message( STATUS "------------------------------------------------------------------" )
# message( STATUS "" )
# include(CMakePrintSystemInformation)
# message( STATUS "" )
# 基本系统与构建信息输出
# 输出 CMake 配置的一些关键变量：
# CMAKE_INSTALL_PREFIX: 安装目录
# CMAKE_GENERATOR: 使用的构建工具（如 Makefiles, Ninja）
# CMAKE_BUILD_TYPE: 构建类型（Debug / Release）
# CMAKE_CXX_COMPILER: 编译器路径
# CMAKE_PREFIX_PATH: 包查找路径
#这些内容有助于确认 CMake 是否用对了编译器、系统信息、平台设置等

message( STATUS "------------------------------------------------------------------" )
message( STATUS "" )
message( STATUS "CMAKE_INSTALL_PREFIX:        ${CMAKE_INSTALL_PREFIX}" )
message( STATUS "CMAKE_GENERATOR:             ${CMAKE_GENERATOR}" )
message( STATUS "CMAKE_GENERATOR_INSTANCE:    ${CMAKE_GENERATOR_INSTANCE}" )
message( STATUS "CMAKE_GENERATOR_PLATFORM:    ${CMAKE_GENERATOR_PLATFORM}" )
message( STATUS "CMAKE_GENERATOR_TOOLSET:     ${CMAKE_GENERATOR_TOOLSET}" )
message( STATUS "CMAKE_BUILD_TYPE:            ${CMAKE_BUILD_TYPE}" )
message( STATUS "CMAKE_CXX_COMPILER:          ${CMAKE_CXX_COMPILER_ID} (${CMAKE_CXX_COMPILER}) ; version: ${CMAKE_CXX_COMPILER_VERSION}" )
message( STATUS "CMAKE_CXX_STANDARD:          ${CMAKE_CXX_STANDARD}" )
message( STATUS "CMAKE_CXX_COMPILER_LAUNCHER: ${CMAKE_CXX_COMPILER_LAUNCHER}" )
message( STATUS "CMAKE_C_COMPILER_LAUNCHER:   ${CMAKE_C_COMPILER_LAUNCHER}" )
if(APPLE)
message( STATUS "CMAKE_OBJC_COMPILER_LAUNCHER:${CMAKE_OBJC_COMPILER_LAUNCHER}" )
endif()
message( STATUS "CMAKE_VERSION:               ${CMAKE_VERSION}" )
message( STATUS "CMAKE_PREFIX_PATH:           ${CMAKE_PREFIX_PATH}" )
message( STATUS "CMAKE_HOST_SYSTEM_NAME:      ${CMAKE_HOST_SYSTEM_NAME}" )
message( STATUS "CMAKE_HOST_SYSTEM_VERSION:   ${CMAKE_HOST_SYSTEM_VERSION}" )
message( STATUS "CMAKE_SYSTEM_NAME:           ${CMAKE_SYSTEM_NAME}" )
message( STATUS "CMAKE_SYSTEM_VERSION:        ${CMAKE_SYSTEM_VERSION}" )
message( STATUS "CMAKE_SOURCE_DIR:            ${CMAKE_SOURCE_DIR}" )
message( STATUS "CMAKE_TOOLCHAIN_FILE:        ${CMAKE_TOOLCHAIN_FILE}" )
message( STATUS "" )

#编译/链接相关信息
#输出的是当前设置的 编译器和链接器的参数，用于分析构建参数是否设置得当，例如是否启用了优化、调试信息等
message( STATUS " --- Compiler flags --- ")
message( STATUS "General:                     ${CMAKE_CXX_FLAGS}" )
message( STATUS "Extra:                       ${EXTRA_COMPILE_FLAGS}" )
message( STATUS "Debug:                       ${CMAKE_CXX_FLAGS_DEBUG}" )
message( STATUS "Release:                     ${CMAKE_CXX_FLAGS_RELEASE}" )
message( STATUS "RelWithDebInfo:              ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}" )
message( STATUS "MinSizeRel:                  ${CMAKE_CXX_FLAGS_MINSIZEREL}" )
message( STATUS "" )
message( STATUS " --- Linker flags --- ")
message( STATUS "General:                     ${CMAKE_EXE_LINKER_FLAGS}" )
message( STATUS "Debug:                       ${CMAKE_EXE_LINKER_FLAGS_DEBUG}" )
message( STATUS "Release:                     ${CMAKE_EXE_LINKER_FLAGS_RELEASE}" )
message( STATUS "RelWithDebInfo:              ${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}" )
message( STATUS "MinSizeRel:                  ${CMAKE_EXE_LINKER_FLAGS_MINSIZEREL}" )
message( STATUS "" )
message( STATUS "------------------------------------------------------------------" )

#应用信息输出
# 输出应用基本信息，如：
# 应用名称、版本、组织名等
# macOS 特有项（Bundle ID、图标路径）
# Android 特有项（NDK/SDK 路径）
message( STATUS "" )
message( STATUS "App Name:                    ${QGC_APP_NAME}" )
message( STATUS "App Copyright:               ${QGC_APP_COPYRIGHT}" )
message( STATUS "App Description:             ${QGC_APP_DESCRIPTION}" )
message( STATUS "Org Name:                    ${QGC_ORG_NAME}" )
message( STATUS "App Domain:                  ${QGC_ORG_DOMAIN}" )
message( STATUS "App Version:                 ${QGC_APP_VERSION_STR}" )
if(MACOS)
message( STATUS "MacOS Bundle ID:             ${QGC_BUNDLE_ID}" )
message( STATUS "MacOS Icon Path:             ${QGC_MACOS_ICON_PATH}" )
endif()
if(ANDROID)
message( STATUS "Android NDK Host System      ${ANDROID_NDK_HOST_SYSTEM_NAME}" )
message( STATUS "Android SDK Root             ${ANDROID_SDK_ROOT}" )
endif()

#功能开关状态输出
#列出是否启用了一些可选模块或功能，比如是否开启了蓝牙、是否支持视频流等
OptionOutput( "Stable Build:                " QGC_STABLE_BUILD )
OptionOutput( "Building Tests:              " QGC_BUILD_TESTING AND BUILD_TESTING )
OptionOutput( "Debug QML:                   " QGC_DEBUG_QML )
OptionOutput( "Disable APM Dialect:         " QGC_DISABLE_APM_MAVLINK )
OptionOutput( "Disable APM Plugin:          " QGC_DISABLE_APM_PLUGIN )
OptionOutput( "Disable APM Plugin Factory:  " QGC_DISABLE_APM_PLUGIN_FACTORY )
OptionOutput( "Disable PX4 Plugin:          " QGC_DISABLE_PX4_PLUGIN )
OptionOutput( "Disable PX4 Plugin Factory:  " QGC_DISABLE_PX4_PLUGIN_FACTORY )
OptionOutput( "Enable Bluetooth Links:      " QGC_ENABLE_BLUETOOTH )
OptionOutput( "Enable ZeroConf:             " QGC_ZEROCONF_ENABLED )
OptionOutput( "Disable AIRLink:             " QGC_AIRLINK_DISABLED )
OptionOutput( "Disable Serial Links:        " QGC_NO_SERIAL_LINK )
OptionOutput( "Enable UTM Adapter:          " QGC_UTM_ADAPTER )
OptionOutput( "Enable Viewer3D:             " QGC_VIEWER3D )
OptionOutput( "Enable UVC Devices:          " QGC_ENABLE_UVC )
OptionOutput( "Enable GStreamer:            " QGC_ENABLE_GST_VIDEOSTREAMING )
OptionOutput( "Enable QtMultimedia:         " QGC_ENABLE_QT_VIDEOSTREAMING )

#MAVLink 相关配
#说明 MAVLink 子模块的来源（repo 和版本 tag），如果你使用的是自定义 MAVLink 协议，这是非常重要的
message( STATUS "MAVLink Git Repo:            ${QGC_MAVLINK_GIT_REPO}" )
message( STATUS "MAVLink Git Tag:             ${QGC_MAVLINK_GIT_TAG}" )
message( STATUS "" )
message( STATUS "------------------------------------------------------------------" )
message( STATUS "" )


#释掉的行是一些 CMake 可用的 Android 签名与部署变量。如果是构建 Android 应用，可以取消注释来启用这些功能
# QT_ANDROID_MULTI_ABI_FORWARD_VARS
# QT_ANDROID_APPLICATION_ARGUMENTS
# QT_HOST_PATH
# QT_ANDROID_SIGN_AAB
# QT_ANDROID_SIGN_APK
# message(STATUS "QT_ANDROID_KEYSTORE_PATH $ENV{QT_ANDROID_KEYSTORE_PATH}")
# message(STATUS "QT_ANDROID_KEYSTORE_ALIAS $ENV{QT_ANDROID_KEYSTORE_ALIAS}")
# QT_ANDROID_KEYSTORE_STORE_PASS, QT_ANDROID_KEYSTORE_KEY_PASS
# QT_ANDROID_DEPLOY_RELEASE
# QT_USE_TARGET_ANDROID_BUILD_DIR
# QT_ANDROID_DEPLOYMENT_TYPE
# QT_ENABLE_VERBOSE_DEPLOYMENT

# QGC_QT_MINIMUM_VERSION
# QGC_QT_MAXIMUM_VERSION
# QT_SILENCE_MISSING_DEPENDENCY_TARGET_WARNING
