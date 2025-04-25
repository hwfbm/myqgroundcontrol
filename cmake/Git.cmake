#这段 CMake 脚本的主要作用是：获取 Git 仓库信息、提取版本号信息、并将其用于构建流程中


find_package(Git) #查找 Git 并更新子模块

if(GIT_FOUND AND EXISTS "${CMAKE_SOURCE_DIR}/.git") #确认当前目录是一个 Git 仓库
    option(GIT_SUBMODULE "Check submodules during build" OFF) #定义一个可选项，用来决定是否在构建过程中自动初始化/更新 Git 子模块
    if(GIT_SUBMODULE)#如果启用了 GIT_SUBMODULE，就执行：git submodule update --init --recursive

        message(STATUS "Submodule update")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
            RESULT_VARIABLE GIT_SUBMODULE_RESULT
            OUTPUT_VARIABLE GIT_SUBMODULE_OUTPUT
            ERROR_VARIABLE GIT_SUBMODULE_ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(NOT GIT_SUBMODULE_RESULT EQUAL 0) #若子模块更新失败，则报错终止构建
            cmake_print_variables(GIT_SUBMODULE_RESULT GIT_SUBMODULE_OUTPUT GIT_SUBMODULE_ERROR)
            message(FATAL_ERROR "git submodule update --init failed with ${GIT_SUBMODULE_RESULT}, please checkout submodules")
        endif()
    endif()
endif()


#打印分支、提交哈希、版本标签等信息
include(CMakePrintHelpers) #引入一个方便的打印模块 cmake_print_variables，用于调试变量值

#当前 Git 分支名
#获取当前分支名，保存为 QGC_GIT_BRANCH
execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref @
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE QGC_GIT_BRANCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
cmake_print_variables(QGC_GIT_BRANCH)

#当前 Git 提交的短哈希
#获取当前提交的短哈希，保存为 QGC_GIT_HASH
execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse --short @
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE QGC_GIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
cmake_print_variables(QGC_GIT_HASH)

#最近一次的 tag（带距离信息）
#比如输出可能是：v4.3.2-15-gd8e9d1c
execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --always --tags
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE QGC_APP_VERSION_STR
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
cmake_print_variables(QGC_APP_VERSION_STR)

#最近一次的 tag（不带距离）
#输出示例：v4.3.2
execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --always --abbrev=0
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE QGC_APP_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
cmake_print_variables(QGC_APP_VERSION)

#获取该 tag 的最后一次提交时间
execute_process(
    COMMAND ${GIT_EXECUTABLE} log -1 --format=%aI ${QGC_APP_VERSION}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE QGC_APP_DATE #返回 ISO 格式的日期，如：2024-11-05T16:28:33+00:00
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
cmake_print_variables(QGC_APP_DATE)


#格式化版本号信息
string(FIND ${QGC_APP_VERSION} "v" QGC_APP_VERSION_VALID) #检查版本字符串是否以 v 开头，例如 v4.3.2
if(QGC_APP_VERSION_VALID GREATER -1)
    string(REPLACE "v" "" QGC_APP_VERSION ${QGC_APP_VERSION}) #如果是，就去掉 v
else()
    set(QGC_APP_VERSION "0.0.0")  #如果不是（例如没打 tag），就设置默认值
endif()

#解析主版本号/次版本号/修订版本号，使用正则表达式提取出版本号三部分：主版本号、次版本号、修订号
# 示例：
# QGC_APP_VERSION = 4.3.2
# QGC_APP_VERSION_MAJOR = 4
# QGC_APP_VERSION_MINOR = 3
# QGC_APP_VERSION_PATCH = 2


string(REGEX MATCH "([0-9]+)\\.([0-9]+)\\.([0-9]+)" QGC_APP_VERSION_MATCH ${QGC_APP_VERSION})
set(QGC_APP_VERSION_MAJOR ${CMAKE_MATCH_1})
set(QGC_APP_VERSION_MINOR ${CMAKE_MATCH_2})
set(QGC_APP_VERSION_PATCH ${CMAKE_MATCH_3})
cmake_print_variables(QGC_APP_VERSION QGC_APP_VERSION_MAJOR QGC_APP_VERSION_MINOR QGC_APP_VERSION_PATCH)
