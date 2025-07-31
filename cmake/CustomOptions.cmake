#定义了项目的构建选项、平台特定设置和功能开关

include(CMakeDependentOption)
# The following options can be overriden by custom builds using the CustomOverrides.cmake file
#定义应用元数据，用于安装包、平台部署和用户界面显示
# App
set(QGC_APP_NAME "QGroundControl" CACHE STRING "App Name") #CACHE STRING 表示这些变量可被用户覆盖（通过命令行或 GUI 工具）
set(QGC_APP_COPYRIGHT "Copyright (c) 2024 QGroundControl. All rights reserved." CACHE STRING "Copyright") #版权信息
set(QGC_APP_DESCRIPTION "Open Source Ground Control App" CACHE STRING "Description") # 应用描述
set(QGC_ORG_NAME "QGroundControl.org" CACHE STRING "Org Name")  # 组织名称
set(QGC_ORG_DOMAIN "org.qgroundcontrol" CACHE STRING "Domain")   # 域名（用于平台包标识）
# 设置版本号（不兼容变更时需递增），QGC_SETTINGS_VERSION 用于管理配置文件的向后兼容性
set(QGC_SETTINGS_VERSION "9" CACHE STRING "Settings Version") # If you need to make an incompatible changes to stored settings, bump this version number up by 1. This will caused store settings to be cleared on next boot.

# Build
option(BUILD_SHARED_LIBS "Build using shared libraries" OFF) # 默认静态链接
option(QGC_STABLE_BUILD "Stable Build" OFF)  # 是否稳定版构建
option(QGC_USE_CACHE "Use Build Caching" ON) # 启用构建缓存
# 调试模式下启用测试和 QML 调试
#cmake_dependent_option 实现条件化选项（仅在 Debug 构建时启用测试和 QML 调试）
#默认禁用动态库（BUILD_SHARED_LIBS=OFF），可能出于部署简化考虑
cmake_dependent_option(QGC_BUILD_TESTING "Enable testing" ON "CMAKE_BUILD_TYPE STREQUAL Debug" OFF)
cmake_dependent_option(QGC_DEBUG_QML "Build QGroundControl with QML debugging/profiling support." OFF "CMAKE_BUILD_TYPE STREQUAL Debug" OFF)


#按需启用/禁用特定功能，减少不必要的依赖
#部分选项（如 QGC_VIEWER3D）依赖 Qt 模块（如 Qt6Quick3D），需检查 _FOUND 变量
# Features
option(QGC_UTM_ADAPTER "Enable UTM Adapter" OFF)   # UTM（无人机交通管理）适配器
option(QGC_VIEWER3D "Enable Viewer3D" ON) # Qt6Quick3D_FOUND 3D 视图支持
# option(QGC_DISABLE_MAVLINK_INSPECTOR "Disable Mavlink Inspector" OFF) # This removes QtCharts which is GPL licensed

# Comms
option(QGC_ENABLE_BLUETOOTH "Enable Bluetooth Links" ON) # Qt6Bluetooth_FOUND   # 蓝牙通信
option(QGC_ZEROCONF_ENABLED "Enable ZeroConf Compatibility" OFF)
option(QGC_AIRLINK_DISABLED "Disable AIRLink" ON)
option(QGC_NO_SERIAL_LINK "Disable Serial Links" OFF) # NOT IOS AND Qt6SerialPort_FOUND

# Video
option(QGC_ENABLE_UVC "Enable UVC Devices" ON) # Qt6Multimedia_FOUND
option(QGC_ENABLE_GST_VIDEOSTREAMING "Enable GStreamer Video Backend" ON) # GStreamer 视频流
option(QGC_ENABLE_QT_VIDEOSTREAMING "Enable QtMultimedia Video Backend" OFF) # Qt6Multimedia_FOUND




# MAVLink
##指定 MAVLink 协议库的源码仓库和固定版本（确保协议兼容性）
# set(QGC_MAVLINK_GIT_REPO "https://github.com/mavlink/c_library_v2.git" CACHE STRING "URL to MAVLink Git Repo")
# set(QGC_MAVLINK_GIT_TAG "7ea034366ee7f09f3991a5b82f51f0c259023b38" CACHE STRING "Tag of MAVLink Git Repo")
set(QGC_MAVLINK_GIT_REPO "https://github.com/hwfbm/my_ibrary_v2.git" CACHE STRING "URL to MAVLink Git Repo")
set(QGC_MAVLINK_GIT_TAG "4d80aaa8d3760a1803281b41516eb81ba13e70d0" CACHE STRING "Tag of MAVLink Git Repo")



#允许用户排除对特定飞控（如 APM、PX4）的支持，减少二进制体积
# APM
option(QGC_DISABLE_APM_MAVLINK "Disable APM Dialect" OFF)
option(QGC_DISABLE_APM_PLUGIN "Disable APM Plugin" OFF)  # 禁用 ArduPilot 插件
option(QGC_DISABLE_APM_PLUGIN_FACTORY "Disable APM Plugin Factory" OFF)

# PX4
option(QGC_DISABLE_PX4_PLUGIN "Disable PX4 Plugin" OFF) # 禁用 PX4 插件
option(QGC_DISABLE_PX4_PLUGIN_FACTORY "Disable PX4 Plugin Factory" OFF)



# Android
#根据 Qt 版本动态调整最低 SDK 版本（Qt ≥6.7.0 要求 API 28+）
#包名与组织域名分离
if(QT_VERSION VERSION_GREATER_EQUAL 6.7.0)
    set(QGC_QT_ANDROID_MIN_SDK_VERSION "28" CACHE STRING "Android Min SDK Version")  # 最低 SDK 版本（Android 9+）
else() # Allow building for Android 7.1 if supported
    set(QGC_QT_ANDROID_MIN_SDK_VERSION "25" CACHE STRING "Android Min SDK Version")
endif()
set(QGC_QT_ANDROID_TARGET_SDK_VERSION "35" CACHE STRING "Android Target SDK Version")   # 目标 SDK 版本（Android 14）
set(QGC_ANDROID_PACKAGE_NAME "org.mavlink.qgroundcontrol" CACHE STRING "Android Package Name") # 包名
set(QGC_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android" CACHE PATH "Android Package Path")
set(QT_ANDROID_DEPLOYMENT_TYPE "" CACHE STRING "Forces Signing if Set to Release")

option(QT_ANDROID_SIGN_APK "Enable Signing APK" OFF) # APK 签名开关
option(QT_ANDROID_SIGN_AAB "Enable Signing AAB" OFF)
option(QT_USE_TARGET_ANDROID_BUILD_DIR "Use Target Android Build Dir" OFF)

# MacOS
#定义 macOS 应用的唯一标识和资源路径
set(QGC_BUNDLE_ID "org.qgroundcontrol.QGroundControl" CACHE STRING "MacOS Bundle ID") # MACOS
set(QGC_MACOS_ICON_PATH "${CMAKE_SOURCE_DIR}/deploy/macos" CACHE PATH "MacOS Icon Path") # MACOS 图标路径

# Linux
set(QGC_APPIMAGE_ICON_PATH "${CMAKE_SOURCE_DIR}/resources/icons/qgroundcontrol.png" CACHE FILEPATH "AppImage Icon Path") # Linux AppImage 图标路径

# Windows
set(QGC_WINDOWS_INSTALL_HEADER_PATH "${CMAKE_SOURCE_DIR}/deploy/windows/installheader.bmp" CACHE FILEPATH "Windows Install Header Path")
set(QGC_WINDOWS_ICON_PATH "${CMAKE_SOURCE_DIR}/deploy/windows/WindowsQGC.ico" CACHE FILEPATH "Windows Icon Path") # Windows 图标路径

# CPM
#使用 CPM 管理第三方依赖，缓存目录加速后续构建
set(CPM_SOURCE_CACHE ${CMAKE_BINARY_DIR}/cpm_modules CACHE PATH "Directory to download CPM dependencies") # 依赖缓存目录

# Qt
#严格限制 Qt 版本范围（避免兼容性问题）
#QML 资源输出到构建目录，便于调试和部署
set(QGC_QT_MINIMUM_VERSION "6.6.3" CACHE STRING "Minimum Supported Qt Version") # 最低 Qt 版本
set(QGC_QT_MAXIMUM_VERSION "6.8.3" CACHE STRING "Maximum Supported Qt Version") # 最高 Qt 版本
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml" CACHE PATH "Install path for QML")  # QML 输出目录
set(QML_IMPORT_PATH "${QT_QML_OUTPUT_DIRECTORY}" CACHE STRING "Extra QML Import Paths") # QML 导入调试
option(QML_IMPORT_TRACE "Debug QML Imports" OFF)
option(QT_SILENCE_MISSING_DEPENDENCY_TARGET_WARNING "Silence Missing Dependency Warnings" OFF)
option(QT_ENABLE_VERBOSE_DEPLOYMENT "Verbose Deployment" OFF)
