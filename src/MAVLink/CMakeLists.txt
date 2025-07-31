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
# 只添加 MAVLinkLib.h 所在的路径
# target_include_directories(${CMAKE_PROJECT_NAME}
#     PRIVATE
#         ${CMAKE_CURRENT_SOURCE_DIR}/MAVLink
# )

# file(GLOB_RECURSE MAVLINK_CUSTOM_HEADERS "${MAVLINK_BUILD_DIR}/custom/include/*.h")

# file(COPY ${MAVLINK_CUSTOM_HEADERS} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/custom/include/)

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

#用 CPM 拉取一个叫 mavlink 的远程 Git 仓库
#仓库地址是 QGC_MAVLINK_GIT_REPO（现在改成自己fork的了）
#Git 分支/标签是 QGC_MAVLINK_GIT_TAG（现在是 master）
# target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE
#     MAVLINK_EXTERNAL_XML_PATH="${CMAKE_BINARY_DIR}/cpm_modules/mavlink/6310d9671f0fcccf93191def08497ae2d5443499/message_definitions"
# )
# set(MAVLINK_XML_DIR "${CMAKE_BINARY_DIR}/cpm_modules/mavlink/6310d9671f0fcccf93191def08497ae2d5443499/message_definitions")
# target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE MAVLINK_EXTERNAL_XML_PATH="${MAVLINK_XML_DIR}")


CPMAddPackage(
    NAME mavlink
    GIT_REPOSITORY ${QGC_MAVLINK_GIT_REPO}
    GIT_TAG ${QGC_MAVLINK_GIT_TAG}
)

#拉下来的路径就放到 mavlink_SOURCE_DIR 变量里
# For QGC all dialects means common and development. Though use of development mavlink code should be restricted to debug builds only.
#包含 MAVLink 消息路径
#把 mavlink_SOURCE_DIR 加到项目头文件搜索路径
#单独把 /all、/common、/development 这些子目录都加上
# 编译器会自动在这些目录里去找#include 的头文件。
# 而自定义的 custom/include/battery/mavlink_msg_hydrogen_battery.h 正好也在 ${mavlink_SOURCE_DIR} 下面，所以能直接找到
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




