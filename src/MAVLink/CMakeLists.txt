#源文件添加，这些是 QGC MAVLink 相关的实现类
#QGCMAVLink.* 是核心类，负责处理消息发送、接收等
#MAVLinkFTP.* 处理文件传输
#StatusTextHandler.* 处理 STATUSTEXT 消息
#这些都与消息处理和解析机制息息相关

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        ImageProtocolManager.cc
        ImageProtocolManager.h
        MAVLinkFTP.cc
        MAVLinkFTP.h
        MAVLinkLib.h
        MAVLinkSigning.cc
        MAVLinkSigning.h
        MAVLinkStreamConfig.cc
        MAVLinkStreamConfig.h
        QGCMAVLink.cc
        QGCMAVLink.h
        StatusTextHandler.cc
        StatusTextHandler.h
        SysStatusSensorInfo.cc
        SysStatusSensorInfo.h
)

#头文件包含路径配置
#包含当前 MAVLink 目录，使头文件可被引用
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

#===========================================================================#

#信息输出，编译时会输出一条消息：-- Building MAVLink，仅用于调试观察构建过程
message(STATUS "Building MAVLink")

# TODO:
# CPMAddPackage(
#     NAME mavlink
#     GITHUB_REPOSITORY mavlink/mavlink
#     GIT_TAG master
#     OPTIONS
#         "MAVLINK_DIALECT all"
#         "MAVLINK_VERSION 2.0"
# )

#MAVLink 库的获取与引入
#使用 CPM（类似 CMake 的包管理工具）从远程仓库拉取 mavlink/mavlink
#GIT_REPOSITORY 和 GIT_TAG 来自 QGC 的顶层 CMake 中的变量，一般是：
# set(QGC_MAVLINK_GIT_REPO "https://github.com/mavlink/mavlink.git")
# set(QGC_MAVLINK_GIT_TAG "master" 或 具体版本)

CPMAddPackage(
    NAME mavlink
    GIT_REPOSITORY ${QGC_MAVLINK_GIT_REPO}
    GIT_TAG ${QGC_MAVLINK_GIT_TAG}
)

# For QGC all dialects means common and development. Though use of development mavlink code should be restricted to debug builds only.
#包含 MAVLink 消息路径
target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${mavlink_SOURCE_DIR}
        ${mavlink_SOURCE_DIR}/all
        ${mavlink_SOURCE_DIR}/common
        ${mavlink_SOURCE_DIR}/development
)

# if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
#   target_compile_options(comm PRIVATE -Wno-address-of-packed-member)
# endif()

add_subdirectory(LibEvents)#LibEvents 子模块，构建另一个子模块 LibEvents，用于 MAVLink 日志或事件相关处理。




