# CPM.cmake - CMake's missing package manager
# ===========================================
# See https://github.com/cpm-cmake/CPM.cmake for usage and update instructions.
#
# MIT License
# -----------
#[[
  Copyright (c) 2019-2023 Lars Melchior and contributors

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]

#set 是 CMake 中用来设置变量的命令。它将给定的值赋给指定的变量名。
#创建动态的变量名
# set(prefix "myProject")
# set(propertyName "${prefix}_sourceDir")
# 在这个例子中，propertyName 的值将会是 myProject_sourceDir。


cmake_minimum_required(VERSION 3.14 FATAL_ERROR) #要求 CMake 最低版本为 3.14，若不满足则报错（FATAL_ERROR）

# Initialize logging prefix如果未定义 CPM_INDENT（日志前缀），则设置为 "CPM:"，并标记为 INTERNAL（内部变量，用户不可见）
if(NOT CPM_INDENT)
  set(CPM_INDENT
      "CPM:"
      CACHE INTERNAL ""
  )
endif()
#如果未定义 cpm_message 函数，则创建一个简单的包装函数，直接调用 CMake 的 message()
if(NOT COMMAND cpm_message)
  function(cpm_message)
    message(${ARGV})
  endfunction()
endif()


# 如果定义了 EXTRACTED_CPM_VERSION（例如从外部传入），则使用它（拼接可能的开发版本标记 CPM_DEVELOPMENT）。
# 否则默认版本为 0.40.8。

if(DEFINED EXTRACTED_CPM_VERSION)
  set(CURRENT_CPM_VERSION "${EXTRACTED_CPM_VERSION}${CPM_DEVELOPMENT}")
else()
  set(CURRENT_CPM_VERSION 0.40.8)
endif()

#获取当前 CPM 脚本的绝对路径 CPM_CURRENT_DIRECTORY
get_filename_component(CPM_CURRENT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" REALPATH)
if(CPM_DIRECTORY)
  if(NOT CPM_DIRECTORY STREQUAL CPM_CURRENT_DIRECTORY)
    if(CPM_VERSION VERSION_LESS CURRENT_CPM_VERSION)#若当前项目的 CPM 版本较旧，发出警告提示升级
      message(
        AUTHOR_WARNING
          "${CPM_INDENT} \
A dependency is using a more recent CPM version (${CURRENT_CPM_VERSION}) than the current project (${CPM_VERSION}). \
It is recommended to upgrade CPM to the most recent version. \
See https://github.com/cpm-cmake/CPM.cmake for more information."
      )
    endif()
    if(${CMAKE_VERSION} VERSION_LESS "3.17.0")  #如果 CMake 版本低于 3.17，强制引入 FetchContent（兼容旧版本）
      include(FetchContent)
    endif()
    return() #直接 return() 退出，避免重复初始化
  endif()

  #检查全局属性 CPM_INITIALIZED 是否已设置，若已初始化则直接退出
  get_property(
    CPM_INITIALIZED GLOBAL ""
    PROPERTY CPM_INITIALIZED
    SET
  )
  if(CPM_INITIALIZED)
    return()
  endif()
endif()

#如果当前版本标记为开发版（如 development-version），提示用户可能不稳定
if(CURRENT_CPM_VERSION MATCHES "development-version")
  message(
    WARNING "${CPM_INDENT} Your project is using an unstable development version of CPM.cmake. \
Please update to a recent release if possible. \
See https://github.com/cpm-cmake/CPM.cmake for details."
  )
endif()

set_property(GLOBAL PROPERTY CPM_INITIALIZED true) #设置全局属性 CPM_INITIALIZED=true，标记 CPM 已初始化

#定义了一个 CMake 宏（macro） cpm_set_policies，用于设置一些关键的 CMake 策略（policies），以确保 CPM 在管理依赖时的行为符合预期
# the policy allows us to change set(CACHE) without caching。CMP0077 策略：允许修改选项而不缓存
# 作用：
# 默认情况下，CMake 会缓存 option() 的值，导致后续修改无效。启用 NEW 行为后，允许在 add_subdirectory() 或 FetchContent 中覆盖选项（如 BUILD_SHARED_LIBS），而不受缓存影响。
# 适用场景：
# 当依赖项需要覆盖父项目的某些编译选项时（如静态/动态库构建选项）。
macro(cpm_set_policies)
  # the policy allows us to change options without caching
  cmake_policy(SET CMP0077 NEW)
  set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)

  #允许修改 set(CACHE) 而不缓存
  # 作用：
  # 在 CMake ≥3.25 中引入。默认情况下，set(var CACHE TYPE "") 会强制缓存变量，即使之前已定义过。NEW 行为允许后续代码覆盖缓存变量。
  # 适用场景：
  # 避免因缓存变量冲突导致依赖项的配置无法被覆盖。
  if(POLICY CMP0126)
    cmake_policy(SET CMP0126 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0126 NEW)
  endif()

  # The policy uses the download time for timestamp, instead of the timestamp in the archive. This
  # allows for proper rebuilds when a projects url changes 使用下载时间作为文件时间戳
  # 作用：
  # 在 CMake ≥3.24 中引入。默认情况下，解压归档文件（如 .tar.gz）时会使用归档内文件的时间戳，可能导致不必要的重新构建。NEW 行为改为使用下载时间戳，确保 URL 变更时触发重新构建。
  # 适用场景：
  # 当依赖项的下载地址（URL）更新时，强制重新下载并构建。
  if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0135 NEW)
  endif()

  # treat relative git repository paths as being relative to the parent project's remote 相对 Git 仓库路径相对于父项目
  # 作用：
  # 在 CMake ≥3.27 中引入。默认情况下，GIT_REPOSITORY 的相对路径（如 ../libfoo）是相对于当前项目的。NEW 行为改为相对于父项目的 Git 仓库路径。
  # 适用场景：
  # 当依赖项通过相对路径引用同一仓库中的其他子模块时，确保路径解析正确。
  if(POLICY CMP0150)
    cmake_policy(SET CMP0150 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0150 NEW)
  endif()
endmacro()
cpm_set_policies()#实际执行上述策略设置




# 这些选项允许用户控制 CPM 如何获取和管理依赖项。每个选项都可以通过：
# CMake 命令行（如 -DCPM_USE_LOCAL_PACKAGES=ON）
# 环境变量（如 export CPM_USE_LOCAL_PACKAGES=ON）


# 优先尝试用系统的 find_package() 查找依赖，如果找不到再下载源码。
# 适用场景：
# 如果系统已安装某些库（如 Boost、OpenCV），避免重复下载
option(CPM_USE_LOCAL_PACKAGES "Always try to use `find_package` to get dependencies"
       $ENV{CPM_USE_LOCAL_PACKAGES}
)


# 作用：
# 强制只使用 find_package()，绝不下载源码。如果找不到依赖，直接报错。
# 适用场景：
# 确保所有依赖都来自系统/包管理器（如 vcpkg、apt）。
option(CPM_LOCAL_PACKAGES_ONLY "Only use `find_package` to get dependencies"
       $ENV{CPM_LOCAL_PACKAGES_ONLY}
)


# 作用：
# 强制总是下载源码，即使系统已安装该库。
# 适用场景：
# 确保所有依赖版本一致，避免系统库版本冲突。
option(CPM_DOWNLOAD_ALL "Always download dependencies from source" $ENV{CPM_DOWNLOAD_ALL})




# 作用：
# 默认情况下，CPM 会修改 CMAKE_MODULE_PATH 以帮助 find_package 查找依赖。此选项禁用该行为。
# 适用场景：
# 如果用户希望完全控制 find_package 的搜索路径。
option(CPM_DONT_UPDATE_MODULE_PATH "Don't update the module path to allow using find_package"
       $ENV{CPM_DONT_UPDATE_MODULE_PATH}
)



# 作用：
# 禁用生成 CPMPackageLock.cmake 文件（该文件记录所有依赖的版本信息）。
# 适用场景：
# 减少构建目录中的文件，或避免锁文件冲突。
option(CPM_DONT_CREATE_PACKAGE_LOCK "Don't create a package lock file in the binary path"
       $ENV{CPM_DONT_CREATE_PACKAGE_LOCK}
)



# 作用：
# 在 CPMPackageLock.cmake 中记录所有依赖（默认只记录顶级依赖）。
# 适用场景：
# 需要完全可复现的构建环境（如 CI/CD）。
option(CPM_INCLUDE_ALL_IN_PACKAGE_LOCK
       "Add all packages added through CPM.cmake to the package lock"
       $ENV{CPM_INCLUDE_ALL_IN_PACKAGE_LOCK}
)


# 作用：
# 在 CPM_SOURCE_CACHE 目录下，为每个依赖创建带名称的子目录（避免路径冲突）。
# 适用场景：
# 当多个项目依赖同名但不同版本的库时（如 fmt-8.0 和 fmt-10.0）。
option(CPM_USE_NAMED_CACHE_DIRECTORIES
       "Use additional directory of package name in cache on the most nested level."
       $ENV{CPM_USE_NAMED_CACHE_DIRECTORIES}
)



# CPM 内部变量（Internal Cache Variables）
# 这些变量由 CPM 内部使用，用户通常不需要修改。

#记录当前 CPM 的版本（如 0.40.8），用于版本检查
set(CPM_VERSION
    ${CURRENT_CPM_VERSION}
    CACHE INTERNAL ""
)

#存储 CPM.cmake 所在的目录路径，防止重复初始化
set(CPM_DIRECTORY
    ${CPM_CURRENT_DIRECTORY}
    CACHE INTERNAL ""
)

#存储 CPM.cmake 的完整路径，用于调试或内部引用
set(CPM_FILE
    ${CMAKE_CURRENT_LIST_FILE}
    CACHE INTERNAL ""
)

#存储所有通过 CPMAddPackage() 添加的依赖列表（用于生成 PackageLock）
set(CPM_PACKAGES
    ""
    CACHE INTERNAL ""
)


#如果设为 ON，CPM 仅检查依赖但不实际下载或构建（用于测试或调试）
set(CPM_DRY_RUN
    OFF
    CACHE INTERNAL "Don't download or configure dependencies (for testing)"
)



#CPM_SOURCE_CACHE：依赖下载缓存目录
# 团队协作：多个项目共享同一缓存目录，避免重复下载依赖（如 CI/CD 环境）。
# 离线开发：提前下载依赖到本地缓存，减少网络请求。
# 通过环境变量设置缓存目录
# export CPM_SOURCE_CACHE="$HOME/.cache/cpm"
# cmake -B build

# # 或通过 CMake 变量设置
# cmake -B build -DCPM_SOURCE_CACHE="$HOME/.cache/cpm"


if(DEFINED ENV{CPM_SOURCE_CACHE})
  set(CPM_SOURCE_CACHE_DEFAULT $ENV{CPM_SOURCE_CACHE})#允许用户通过 环境变量 CPM_SOURCE_CACHE 或 CMake 变量 指定一个共享的依赖下载缓存目录
else()
  set(CPM_SOURCE_CACHE_DEFAULT OFF)#如果未定义 CPM_SOURCE_CACHE，则默认为 OFF（不启用缓存）
endif()

set(CPM_SOURCE_CACHE
    ${CPM_SOURCE_CACHE_DEFAULT}
    CACHE PATH "Directory to download CPM dependencies"
)

#CPM_MODULE_PATH：自定义 find_package 搜索路径
#CPM_DONT_UPDATE_MODULE_PATH	禁用修改 CMAKE_MODULE_PATH
#如果设置了 CPM_DONT_UPDATE_MODULE_PATH 或 CMAKE_FIND_PACKAGE_REDIRECTS_DIR，则跳过此逻辑
#在构建目录（${CMAKE_BINARY_DIR}）下创建 CPM_modules 目录，用于存储 CPM 生成的 Find<Package>.cmake 文件
#将该目录添加到 CMAKE_MODULE_PATH 的最前面，确保 CPM 管理的依赖优先于系统全局安装的版本
# 为什么需要这个？
# 默认情况下，find_package() 会优先搜索系统路径（如 /usr/lib/cmake）。
# CPM 通过自定义模块路径，确保项目使用的依赖版本与 CPMAddPackage 指定的版本一致，避免冲突。
#假设项目依赖 fmt，但系统已安装旧版本：CPMAddPackage("gh:fmtlib/fmt#10.0.0")  # 优先使用 10.0.0，而非系统版本

# 谨慎使用 CPM_DONT_UPDATE_MODULE_PATH：
# 仅在需要完全控制 find_package 行为时禁用
if(NOT CPM_DONT_UPDATE_MODULE_PATH AND NOT DEFINED CMAKE_FIND_PACKAGE_REDIRECTS_DIR)
  set(CPM_MODULE_PATH
      "${CMAKE_BINARY_DIR}/CPM_modules"
      CACHE INTERNAL ""
  )
  # remove old modules  删除旧模块并创建新目录
  file(REMOVE_RECURSE ${CPM_MODULE_PATH})
  file(MAKE_DIRECTORY ${CPM_MODULE_PATH})
  # locally added CPM modules should override global packages  让本地 CPM 模块优先于全局包
  set(CMAKE_MODULE_PATH "${CPM_MODULE_PATH};${CMAKE_MODULE_PATH}")
endif()



#CPM_PACKAGE_LOCK_FILE：包锁定文件
#CPM_DONT_CREATE_PACKAGE_LOCK	禁用生成锁定文件
# 在构建目录下生成 cpm-package-lock.cmake 文件，记录所有通过 CPMAddPackage 添加的依赖及其版本。
# 如果设置了 CPM_DONT_CREATE_PACKAGE_LOCK，则禁用此功能。
# 为什么需要包锁定文件？
# 可复现构建：锁定依赖版本，避免未来因依赖更新导致构建失败。
# 版本控制：建议将该文件提交到 Git，确保所有开发者使用相同的依赖版本。
#文件内容示例
# # CPM Package Lock
# # This file should be committed to version control
# CPMDeclarePackage(fmt "10.0.0" "gh:fmtlib/fmt#10.0.0")
# CPMDeclarePackage(catch2 "3.3.2" "gh:catchorg/Catch2@v3.3.2")
if(NOT CPM_DONT_CREATE_PACKAGE_LOCK)
  set(CPM_PACKAGE_LOCK_FILE
      "${CMAKE_BINARY_DIR}/cpm-package-lock.cmake"
      CACHE INTERNAL ""
  )
  file(WRITE ${CPM_PACKAGE_LOCK_FILE}
       "# CPM Package Lock\n# This file should be committed to version control\n\n"
  )
endif()

include(FetchContent)

# Try to infer package name from git repository uri (path or url)
#定义了一个 CMake 函数 cpm_package_name_from_git_uri，用于从 Git 仓库的 URI（路径或 URL）中推断出包名
# 正则表达式 ([^/:]+)/?.git/?$ 解析：
# ([^/:]+)：匹配最后一个 / 或 : 之后的所有字符（即仓库名）。
# /?\.git/?：可选的 .git 后缀（支持 / 或直接结尾）。
# $：匹配字符串末尾。
# https://github.com/fmtlib/fmt.git → fmt
# git@github.com:catchorg/Catch2.git → Catch2
# ../local-repo → local-repo
function(cpm_package_name_from_git_uri URI RESULT)
  if("${URI}" MATCHES "([^/:]+)/?.git/?$") #URI：Git 仓库的路径或 URL（如 https://github.com/fmtlib/fmt.git 或 ../local-repo）。
    set(${RESULT} #RESULT：输出变量，存储解析出的包名
        ${CMAKE_MATCH_1}
        PARENT_SCOPE  #结果存储：通过 PARENT_SCOPE 将匹配到的包名（CMAKE_MATCH_1）返回给父作用域
    )
  else()#如果 URI 不符合模式（如无 .git 或格式错误），则清除 RESULT 变量
    unset(${RESULT} PARENT_SCOPE)
  endif()
endfunction()



# Try to infer package name and version from a url
#此函数用于自动解析通过 URL 下载的依赖项信息
#这段代码定义了一个 CMake 函数 cpm_package_name_and_ver_from_url，用于从下载 URL 中推断出包名（outName）和版本号（outVer）
#它主要用于解析压缩包（如 .tar.gz, .zip）形式的依赖项 URL，并尝试提取其中的名称和版本信息
# [/\\?]：匹配 URL 中的 / 或 ?（分隔符）。
# ([a-zA-Z0-9_\\.-]+)：提取文件名（允许字母、数字、下划线、点、短横线）。
# \.(tar|tar\.gz|tar\.bz2|zip|ZIP)：匹配常见的压缩包后缀。
# (\\?|/|$)：匹配 URL 的结尾或查询参数。
# https://example.com/fmt-10.0.0.tar.gz → 匹配 fmt-10.0.0。
# https://github.com/foo/bar/releases/download/v1.2.3/bar-1.2.3.zip → 匹配 bar-1.2.3。
function(cpm_package_name_and_ver_from_url url outName outVer)#下载 URL（如 https://github.com/fmtlib/fmt/archive/refs/tags/10.0.0.tar.gz）。outName：输出变量，存储解析出的包名（如 fmt）。outVer：输出变量，存储解析出的版本号（如 10.0.0）

  if(url MATCHES "[/\\?]([a-zA-Z0-9_\\.-]+)\\.(tar|tar\\.gz|tar\\.bz2|zip|ZIP)(\\?|/|$)")
    # We matched an archive
    set(filename "${CMAKE_MATCH_1}")

    #提取包名和版本号
    if(filename MATCHES "([a-zA-Z0-9_\\.-]+)[_-]v?(([0-9]+\\.)*[0-9]+[a-zA-Z0-9]*)")
      # We matched <name>-<version> (ie foo-1.2.3)
      set(${outName}
          "${CMAKE_MATCH_1}"
          PARENT_SCOPE
      )
      set(${outVer}
          "${CMAKE_MATCH_2}"
          PARENT_SCOPE
      )
  #仅匹配版本号
  # 如果文件名中没有明确的包名，但包含版本号（如 1.2.3.tar.gz）：
  # 只返回版本号（outVer），outName 为空
    elseif(filename MATCHES "(([0-9]+\\.)+[0-9]+[a-zA-Z0-9]*)")
      # We couldn't find a name, but we found a version
      #
      # In many cases (which we don't handle here) the url would look something like
      # `irrelevant/ACTUAL_PACKAGE_NAME/irrelevant/1.2.3.zip`. In such a case we can't possibly
      # distinguish the package name from the irrelevant bits. Moreover if we try to match the
      # package name from the filename, we'd get bogus at best.
      unset(${outName} PARENT_SCOPE)
      set(${outVer}
          "${CMAKE_MATCH_1}"
          PARENT_SCOPE
      )
    else() #默认情况：文件名作为包名，如果无法提取版本号，则将整个文件名作为包名（如 foo.tar.gz → outName=foo）
      # Boldly assume that the file name is the package name.
      #
      # Yes, something like `irrelevant/ACTUAL_NAME/irrelevant/download.zip` will ruin our day, but
      # such cases should be quite rare. No popular service does this... we think.
      set(${outName}
          "${filename}"
          PARENT_SCOPE
      )
      unset(${outVer} PARENT_SCOPE)
    endif()
  else()#非压缩包 URL 处理、
      #如果 URL 不是压缩包（如 Git 仓库、普通文件），则清空输出变量
    # No ideas yet what to do with non-archives
    unset(${outName} PARENT_SCOPE)
    unset(${outVer} PARENT_SCOPE)
  endif()
endfunction()
#通过启发式规则从 URL 中提取信息，适用于大多数标准格式的压缩包，但对非标准路径（如 irrelevant/name/irrelevant/1.2.3.zip）可能失效，此时需手动指定名称和版本







#是 CPM.cmake 中用于桥接系统包和源码依赖的关键函数
#定义了一个 CMake 函数 cpm_find_package，它是 CPM.cmake 依赖管理工具的一部分，用于封装 CMake 原生的 find_package 命令，并添加了一些额外的功能
# 使用场景
# CPM_USE_LOCAL_PACKAGES 配合
# 当启用 CPM_USE_LOCAL_PACKAGES 时，CPM 会优先调用此函数查找本地包。
# 优先使用系统已安装的包

function(cpm_find_package NAME VERSION)   # NAME：要查找的包名称（如 Boost、OpenCV）。# VERSION：期望的包版本（可选）。# ARGN：额外的 find_package 参数（如 COMPONENTS、REQUIRED）
  string(REPLACE " " ";" EXTRA_ARGS "${ARGN}")    #处理额外参数，将空格分隔的额外参数（ARGN）转换为 CMake 列表格式（分号分隔），以便传递给 find_package。
  find_package(${NAME} ${VERSION} ${EXTRA_ARGS} QUIET)#调用 CMake 原生的 find_package 命令，QUIET 选项抑制未找到包时的警告信息，其他参数（如 COMPONENTS）通过 EXTRA_ARGS 传递
  if(${CPM_ARGS_NAME}_FOUND)# 检查包是否找到，检查 ${NAME}_FOUND 变量（CMake 标准变量，表示包是否找到），CPM_ARGS_NAME 是 CPM 内部使用的变量，通常与 NAME 相同
    if(DEFINED ${CPM_ARGS_NAME}_VERSION) #获取包的实际版本
      set(VERSION ${${CPM_ARGS_NAME}_VERSION}) #如果包定义了版本变量（如 OpenCV_VERSION），则覆盖输入的 VERSION
    endif()
    #注册包并输出日志
    cpm_message(STATUS "${CPM_INDENT} Using local package ${CPM_ARGS_NAME}@${VERSION}") #输出日志（格式为 CPM: Using local package <name>@<version>）
    CPMRegisterPackage(${CPM_ARGS_NAME} "${VERSION}")#将包信息记录到 CPM 的内部管理中（用于生成 cpm-package-lock.cmake）

    #设置返回值，如果包找到，设置 CPM_PACKAGE_FOUND=YES 并返回给父作用域
    set(CPM_PACKAGE_FOUND
        YES
        PARENT_SCOPE
    )
  else()#如果包未找到，设置 CPM_PACKAGE_FOUND=NO
    set(CPM_PACKAGE_FOUND
        NO
        PARENT_SCOPE
    )
  endif()
endfunction()



#与 CPM_USE_LOCAL_PACKAGES 协作。若启用 CPM_USE_LOCAL_PACKAGES，此函数会确保即使系统存在同名包，也优先使用 CPM 管理的版本。
# Create a custom FindXXX.cmake module for a CPM package This prevents `find_package(NAME)` from
# finding the system library
# 防止系统包干扰假设项目通过 CPM 使用特定版本的 OpenCV：
# CPMAddPackage("gh:opencv/opencv#4.5.5")
# cpm_create_module_file(OpenCV)
# 生成的 FindOpenCV.cmake 会优先于系统的 /usr/lib/cmake/OpenCV。
#支持 find_package 重定向，在 CMake ≥3.24 中，生成的 opencv-config.cmake 会确保：find_package(OpenCV REQUIRED) 总是找到 CPM 管理的版本
#用于为 CPM 管理的依赖包创建自定义的 Find<Package>.cmake 或 <package>-config.cmake 文件。它的核心目的是防止系统安装的包干扰 CPM 管理的包，确保项目使用正确版本的依赖
function(cpm_create_module_file Name)#Name：包名（如 Boost、OpenCV），用于生成对应的查找模块文件
  if(NOT CPM_DONT_UPDATE_MODULE_PATH)#检查是否启用模块路径更新，如果 CPM_DONT_UPDATE_MODULE_PATH 为 OFF（默认），则继续生成模块文件；否则跳过
    if(DEFINED CMAKE_FIND_PACKAGE_REDIRECTS_DIR)#处理 CMAKE_FIND_PACKAGE_REDIRECTS_DIR
      #在 CMake ≥3.24 中，FetchContent 可以通过 OVERRIDE_FIND_PACKAGE 将 find_package 重定向到 CPM 管理的包。此分支生成 <package>-config.cmake 文件，确保 find_package 优先使用 CPM 的版本
      # Redirect find_package calls to the CPM package. This is what FetchContent does when you set
      # OVERRIDE_FIND_PACKAGE. The CMAKE_FIND_PACKAGE_REDIRECTS_DIR works for find_package in CONFIG
      # mode, unlike the Find${Name}.cmake fallback. CMAKE_FIND_PACKAGE_REDIRECTS_DIR is not defined
      # in script mode, or in CMake < 3.24.
      # https://cmake.org/cmake/help/latest/module/FetchContent.html#fetchcontent-find-package-integration-examples


      string(TOLOWER ${Name} NameLower)#生成 <package>-config.cmake
      #尝试加载可选的额外配置文件（如 opencv-extra.cmake 或 OpenCVExtra.cmake）
      #文件名转换为小写（CMake 的 CONFIG 模式要求）
      file(WRITE ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/${NameLower}-config.cmake
           "include(\"\${CMAKE_CURRENT_LIST_DIR}/${NameLower}-extra.cmake\" OPTIONAL)\n"
           "include(\"\${CMAKE_CURRENT_LIST_DIR}/${Name}Extra.cmake\" OPTIONAL)\n"
      )
      #生成 <package>-config-version.cmake
      #强制声明版本兼容，避免 CMake 检查版本冲突
      file(WRITE ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/${NameLower}-config-version.cmake
           "set(PACKAGE_VERSION_COMPATIBLE TRUE)\n" "set(PACKAGE_VERSION_EXACT TRUE)\n"
      )
      #回退到 Find<Package>.cmake、
      # 文件内容：
      # 包含 CPM.cmake 自身（${CPM_FILE}）。
      # 插入调用时传递的额外内容（${ARGN}）。
      # 直接设置 ${Name}_FOUND=TRUE，假装包已找到。
      # 目的：
      # 覆盖系统默认的 Find<Package>.cmake，强制使用 CPM 管理的版本。
    else()
      file(WRITE ${CPM_MODULE_PATH}/Find${Name}.cmake
           "include(\"${CPM_FILE}\")\n${ARGN}\nset(${Name}_FOUND TRUE)"
      )
    endif()
  endif()
endfunction()






# Find a package locally or fallback to CPMAddPackage
#  基础用法
# CPMFindPackage(
#   NAME fmt
#   VERSION 10.0.0
#   GIT_TAG 10.0.0
#   FIND_PACKAGE_ARGUMENTS REQUIRED
# )
# 优先查找本地安装的 fmt 10.0.0，找不到则从 GitHub 下载。
# 指定组件
# CPMFindPackage(
#   NAME Boost
#   VERSION 1.75.0
#   FIND_PACKAGE_ARGUMENTS COMPONENTS system filesystem REQUIRED
# )
# 强制下载
# bash
# # 通过环境变量强制下载
# export CPM_DOWNLOAD_fmt=ON
# cmake -B build
#它是 CPM.cmake 工具的一部分，用于智能地查找依赖包：优先尝试本地查找，找不到再通过 CPM 下载
function(CPMFindPackage)
  set(oneValueArgs NAME VERSION GIT_TAG FIND_PACKAGE_ARGUMENTS)   #NAME：包名（必需，如 Boost）。VERSION：期望版本（可选），GIT_TAG：Git 引用（如分支/tag，用于推断版本），FIND_PACKAGE_ARGUMENTS：传递给 find_package 的额外参数（如 COMPONENTS）

  cmake_parse_arguments(CPM_ARGS "" "${oneValueArgs}" "" ${ARGN})

  #版本推断（如果未显式指定，但提供了 GIT_TAG（如 v1.2.3），则从中提取版本号）
  if(NOT DEFINED CPM_ARGS_VERSION)
    if(DEFINED CPM_ARGS_GIT_TAG)
      cpm_get_version_from_git_tag("${CPM_ARGS_GIT_TAG}" CPM_ARGS_VERSION)
    endif()
  endif()


  #检查是否强制下载
  set(downloadPackage ${CPM_DOWNLOAD_ALL})
  if(DEFINED CPM_DOWNLOAD_${CPM_ARGS_NAME})#如果 CPM_DOWNLOAD_ALL=ON，强制下载所有依赖
    set(downloadPackage ${CPM_DOWNLOAD_${CPM_ARGS_NAME}})
  elseif(DEFINED ENV{CPM_DOWNLOAD_${CPM_ARGS_NAME}})#如果定义了包特定的 CPM_DOWNLOAD_<NAME> 或环境变量 CPM_DOWNLOAD_<NAME>，则仅强制下载该包
    set(downloadPackage $ENV{CPM_DOWNLOAD_${CPM_ARGS_NAME}})
  endif()
  if(downloadPackage)
    CPMAddPackage(${ARGN})#若需强制下载，直接调用 CPMAddPackage 并返回
    cpm_export_variables(${CPM_ARGS_NAME})
    return()
  endif()

  #尝试本地查找
  #调用内部函数 cpm_find_package，尝试通过 find_package 查找本地安装的包。
  #传递版本和额外参数（如 COMPONENTS
  cpm_find_package(${CPM_ARGS_NAME} "${CPM_ARGS_VERSION}" ${CPM_ARGS_FIND_PACKAGE_ARGUMENTS})


  # 回退到下载
  if(NOT CPM_PACKAGE_FOUND)#如果本地未找到包（CPM_PACKAGE_FOUND=NO），则调用 CPMAddPackage 从源码下载
    CPMAddPackage(${ARGN})
    cpm_export_variables(${CPM_ARGS_NAME}) #cpm_export_variables 将包的相关变量（如 _FOUND、_VERSION）导出到父作用域
  endif()

endfunction()




# checks if a package has been added before
#检查依赖是否已添加，依赖重复检查，检查指定名称和版本的包是否已被添加到当前项目中，避免重复引入
#依赖去重：配合 cpm_check_if_package_already_added 实现
# 典型场景
# CPMAddPackage("gh:fmtlib/fmt#10.0.0")  # 第一次添加
# CPMAddPackage("gh:fmtlib/fmt#10.0.0")  # 第二次调用时跳过
function(cpm_check_if_package_already_added CPM_ARGS_NAME CPM_ARGS_VERSION)#CPM_ARGS_NAME：包名称（如 fmt），CPM_ARGS_VERSION：请求的版本号
  if("${CPM_ARGS_NAME}" IN_LIST CPM_PACKAGES)#检查是否已存在，从全局变量 CPM_PACKAGES（记录所有已添加包）中查找
    CPMGetPackageVersion(${CPM_ARGS_NAME} CPM_PACKAGE_VERSION)#版本比对，若已存在但版本过低，发出警告
    if("${CPM_PACKAGE_VERSION}" VERSION_LESS "${CPM_ARGS_VERSION}")

      message(
        WARNING
          "${CPM_INDENT} Requires a newer version of ${CPM_ARGS_NAME} (${CPM_ARGS_VERSION}) than currently included (${CPM_PACKAGE_VERSION})."
      )
    endif()#返回结果，
    cpm_get_fetch_properties(${CPM_ARGS_NAME})
    set(${CPM_ARGS_NAME}_ADDED NO)
    #若存在：设置 CPM_PACKAGE_ALREADY_ADDED=YES 并导出包变量。
    set(CPM_PACKAGE_ALREADY_ADDED
        YES
        PARENT_SCOPE
    )
    cpm_export_variables(${CPM_ARGS_NAME})
  else()
    #若不存在：设置 CPM_PACKAGE_ALREADY_ADDED=NO。
    set(CPM_PACKAGE_ALREADY_ADDED
        NO
        PARENT_SCOPE
    )
  endif()
endfunction()

# Parse the argument of CPMAddPackage in case a single one was provided and convert it to a list of
# arguments which can then be parsed idiomatically. For example gh:foo/bar@1.2.3 will be converted
# to: GITHUB_REPOSITORY;foo/bar;VERSION;1.2.3
#简化声明解析，将简写的依赖声明（如 gh:foo/bar@1.2.3）转换为 CPM 的标准CMake FetchContent 参数列表
# 格式示例	解析结果
# gh:user/repo@1.2.3	GITHUB_REPOSITORY;user/repo;VERSION;1.2.3
# gl:user/repo#main	GITLAB_REPOSITORY;user/repo;GIT_TAG;main
# https://.../repo.git@v1.0	GIT_REPOSITORY;https://...;VERSION;v1.0
function(cpm_parse_add_package_single_arg arg outArgs)#arg：简写的依赖声明字符串，outArgs：输出的解析后参数列表
  # Look for a scheme
  if("${arg}" MATCHES "^([a-zA-Z]+):(.+)$")  #提取协议前缀，识别 gh:（GitHub）、gl:（GitLab）、bb:（Bitbucket）等协议
    string(TOLOWER "${CMAKE_MATCH_1}" scheme) #如 "gh"
    set(uri "${CMAKE_MATCH_2}") # 如 "foo/bar@1.2.3"

    # Check for CPM-specific schemes
    #支持三种代码托管平台的简写
    if(scheme STREQUAL "gh") # GitHub
      set(out "GITHUB_REPOSITORY;${uri}")#将协议映射为对应的 FetchContent 参数
      set(packageType "git")
    elseif(scheme STREQUAL "gl")   # GitLab
      set(out "GITLAB_REPOSITORY;${uri}")
      set(packageType "git")
    elseif(scheme STREQUAL "bb") # Bitbucket
      set(out "BITBUCKET_REPOSITORY;${uri}")
      set(packageType "git")
      # A CPM-specific scheme was not found. Looks like this is a generic URL so try to determine
      # type
      #通用 Git 仓库处理，匹配包含 .git 的 URL，示例："https://example.com/repo.git"
    elseif(arg MATCHES ".git/?(@|#|$)")
      set(out "GIT_REPOSITORY;${arg}")
      set(packageType "git")
    else() # 普通归档文件处理
      # Fall back to a URL
      set(out "URL;${arg}") #默认回退到普通 URL 下载，适用于 .zip/.tar.gz 等归档文件
      set(packageType "archive")

      # We could also check for SVN since FetchContent supports it, but SVN is so rare these days.
      # We just won't bother with the additional complexity it will induce in this function. SVN is
      # done by multi-arg
    endif()
  else()
    if(arg MATCHES ".git/?(@|#|$)")
      set(out "GIT_REPOSITORY;${arg}")
      set(packageType "git")
    else()
      # Give up
      message(FATAL_ERROR "${CPM_INDENT} Can't determine package type of '${arg}'")#无法识别的格式
    endif()
  endif()

  # For all packages we interpret @... as version. Only replace the last occurrence. Thus URIs
  # containing '@' can be used
  #提取版本/标签
  #@1.2.3 → VERSION;1.2.3
  #main → GIT_TAG;main
  string(REGEX REPLACE "@([^@]+)$" ";VERSION;\\1" out "${out}")#提取最后出现的 @version 作为版本号

  # Parse the rest according to package type
  if(packageType STREQUAL "git")
    # For git repos we interpret #... as a tag or branch or commit hash
    string(REGEX REPLACE "#([^#]+)$" ";GIT_TAG;\\1" out "${out}")# Git 标签提取，提取最后出现的 #tag 作为 Git 引用，示例："gl:user/repo#main" → "GITLAB_REPOSITORY;user/repo;GIT_TAG;main"
  elseif(packageType STREQUAL "archive")
    # For archives we interpret #... as a URL hash.
    string(REGEX REPLACE "#([^#]+)$" ";URL_HASH;\\1" out "${out}")
    # We don't try to parse the version if it's not provided explicitly. cpm_get_version_from_url
    # should do this at a later point
  else()
    # We should never get here. This is an assertion and hitting it means there's a problem with the
    # code above. A packageType was set, but not handled by this if-else.
    message(FATAL_ERROR "${CPM_INDENT} Unsupported package type '${packageType}' of '${arg}'")#未处理的 packageType
  endif()

  set(${outArgs}
      ${out}
      PARENT_SCOPE
  )
endfunction()




#Check that the working directory for a git repo is cleanCPM.cmake 工具中用于检查 Git 仓库工作目录是否干净（无修改）的实用函数
#没有未提交的更改（包括未暂存和已暂存但未提交的更改）
#与指定标签/提交（gitTag）相比没有已提交的更改
#在 CPM 的依赖管理流程中，这个函数用于：当使用本地 Git 仓库作为依赖源时（如开发调试期间），确保依赖的本地修改不会被意外覆盖。在需要更新依赖时提供安全警告
function(cpm_check_git_working_dir_is_clean repoPath gitTag isClean)#repoPath：Git 仓库的本地路径，gitTag：要对比的 Git 引用（tag/commit hash/branch），isClean：输出参数，返回检查结果（TRUE/FALSE）

  find_package(Git REQUIRED)
  if(NOT GIT_EXECUTABLE)#检查 Git 是否可用
      #如果系统没有安装 Git，默认返回 TRUE（保守策略）
    # No git executable, assume directory is clean
    set(${isClean}
        TRUE
        PARENT_SCOPE
    )
    return()
  endif()

  # check for uncommitted changes检查未提交的更改
  execute_process(
    COMMAND ${GIT_EXECUTABLE} status --porcelain #使用 git status --porcelain 获取简洁的状态输出
    RESULT_VARIABLE resultGitStatus
    OUTPUT_VARIABLE repoStatus
    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
    WORKING_DIRECTORY ${repoPath}
  )
  if(resultGitStatus)
    # not supposed to happen, assume clean anyway
    message(WARNING "${CPM_INDENT} Calling git status on folder ${repoPath} failed")
    set(${isClean}
        TRUE
        PARENT_SCOPE
    )
    return()
  endif()

  if(NOT "${repoStatus}" STREQUAL "")  #如果输出非空，表示有未提交更改，立即返回 FALSE
    set(${isClean}
        FALSE
        PARENT_SCOPE
    )
    return()
  endif()

  # check for committed changes检查已提交的更改
  execute_process(
    COMMAND ${GIT_EXECUTABLE} diff -s --exit-code ${gitTag}#使用 git diff --exit-code 对比工作目录和指定标签
    RESULT_VARIABLE resultGitDiff
    OUTPUT_STRIP_TRAILING_WHITESPACE OUTPUT_QUIET
    WORKING_DIRECTORY ${repoPath}
  )

  if(${resultGitDiff} EQUAL 0) #返回码为 0 表示没有差异（干净），否则返回 FALSE
    set(${isClean}
        TRUE
        PARENT_SCOPE
    )
  else()
    set(${isClean}
        FALSE
        PARENT_SCOPE
    )
  endif()

endfunction()

# Add PATCH_COMMAND to CPM_ARGS_UNPARSED_ARGUMENTS. This method consumes a list of files in ARGN
# then generates a `PATCH_COMMAND` appropriate for `ExternalProject_Add()`. This command is appended
# to the parent scope's `CPM_ARGS_UNPARSED_ARGUMENTS`.
#为 CPM 管理的依赖项生成 PATCH_COMMAND 命令序列，用于在构建过程中自动应用一个或多个补丁文件
function(cpm_add_patches)
  # Return if no patch files are supplied.
  if(NOT ARGN)
    return()
  endif()
#补丁工具检测
  # Find the patch program.首先查找系统 patch 程序
  find_program(PATCH_EXECUTABLE patch)
  if(CMAKE_HOST_WIN32 AND NOT PATCH_EXECUTABLE)
    # The Windows git executable is distributed with patch.exe. Find the path to the executable, if
    # it exists, then search `../usr/bin` and `../../usr/bin` for patch.exe.
    find_package(Git QUIET)#Windows 特殊处理：在 Git 安装目录的 usr/bin 子目录中查找 patch.exe
    if(GIT_EXECUTABLE)
      get_filename_component(extra_search_path ${GIT_EXECUTABLE} DIRECTORY)
      get_filename_component(extra_search_path_1up ${extra_search_path} DIRECTORY)
      get_filename_component(extra_search_path_2up ${extra_search_path_1up} DIRECTORY)
      find_program(
        PATCH_EXECUTABLE patch HINTS "${extra_search_path_1up}/usr/bin"
                                     "${extra_search_path_2up}/usr/bin"
      )
    endif()
  endif()
  if(NOT PATCH_EXECUTABLE)#找不到则报错终止
    message(FATAL_ERROR "Couldn't find `patch` executable to use with PATCHES keyword.")
  endif()

  # Create a temporary
  set(temp_list ${CPM_ARGS_UNPARSED_ARGUMENTS})

  # Ensure each file exists (or error out) and add it to the list.
  set(first_item True)
  foreach(PATCH_FILE ${ARGN})
    # Make sure the patch file exists, if we can't find it, try again in the current directory.
    if(NOT EXISTS "${PATCH_FILE}")  #检查每个补丁文件是否存在（先尝试原路径，再尝试相对当前 CMake 文件的路径）
      if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/${PATCH_FILE}")
        message(FATAL_ERROR "Couldn't find patch file: '${PATCH_FILE}'")
      endif()
      set(PATCH_FILE "${CMAKE_CURRENT_LIST_DIR}/${PATCH_FILE}")  #将补丁文件路径转换为绝对路径
    endif()

    # Convert to absolute path for use with patch file command.
    get_filename_component(PATCH_FILE "${PATCH_FILE}" ABSOLUTE)  #为每个补丁文件生成对应的 patch 命令

    # The first patch entry must be preceded by "PATCH_COMMAND". Subsequent
    # commands are preceeded by "COMMAND".
    #命令序列构建
    if(first_item)
      set(first_item False)
      list(APPEND temp_list "PATCH_COMMAND") #第一个补丁使用 PATCH_COMMAND 前缀
    else()
      list(APPEND temp_list "COMMAND") #后续补丁使用 COMMAND 前缀
    endif()
    # Add the patch command to the list
    list(APPEND temp_list "${PATCH_EXECUTABLE}" "-p1" "-i" "${PATCH_FILE}") #每个补丁命令格式：patch -p1 -i /path/to/patch
  endforeach()

  # Move temp out into parent scope.
  #将生成的命令序列追加到 CPM_ARGS_UNPARSED_ARGUMENTS 变量
  #通过 PARENT_SCOPE 返回给父作用域
  set(CPM_ARGS_UNPARSED_ARGUMENTS
      ${temp_list}
      PARENT_SCOPE
  )

endfunction()




# method to overwrite internal FetchContent properties, to allow using CPM.cmake to overload
# FetchContent calls. As these are internal cmake properties, this method should be used carefully
# and may need modification in future CMake versions. Source:
# https://github.com/Kitware/CMake/blob/dc3d0b5a0a7d26d43d6cfeb511e224533b5d188f/Modules/FetchContent.cmake#L1152
# 与现有 FetchContent 调用集成
# 当项目中同时使用 CPM 和原生 FetchContent 时，避免重复下载：
# cmake
# # 假设某个模块内部调用了 FetchContent_Declare(foo...)
# cpm_override_fetchcontent(foo
#     SOURCE_DIR ${CMAKE_BINARY_DIR}/_deps/foo-src
#     BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/foo-build
# )

# 接管系统包管理
# 强制使用 CPM 管理的版本替代系统找到的包：
# cmake
# find_package(Boost QUIET)
# if(Boost_FOUND)
#     cpm_override_fetchcontent(Boost
#         SOURCE_DIR ${Boost_DIR}
#         BINARY_DIR ${CMAKE_BINARY_DIR}/_deps/boost-build
#     )
# endif()
#cpm_override_fetchcontent 函数是 CPM.cmake 中用于覆盖 FetchContent 内部属性的高级功能函数
#通过直接修改 CMake 内部属性，强制让 FetchContent 系统认为某个依赖项已经完成下载和配置，从而允许 CPM 接管对特定依赖项的管理控制
function(cpm_override_fetchcontent contentName)  #contentName：要覆盖的依赖项名称（区分大小写）。SOURCE_DIR：指定替代的源代码目录，BINARY_DIR：指定替代的构建目录
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "SOURCE_DIR;BINARY_DIR" "")
  if(NOT "${arg_UNPARSED_ARGUMENTS}" STREQUAL "")#严格验证输入参数：
    message(FATAL_ERROR "${CPM_INDENT} Unsupported arguments: ${arg_UNPARSED_ARGUMENTS}")
  endif()

  #使用 FetchContent 的内部命名约定
  #将依赖名称转为小写
  #添加 _FetchContent_ 前缀
  string(TOLOWER ${contentName} contentNameLower)
  set(prefix "_FetchContent_${contentNameLower}")


  #设置三个关键属性
  set(propertyName "${prefix}_sourceDir")
  define_property(
    GLOBAL
    PROPERTY ${propertyName}
    BRIEF_DOCS "Internal implementation detail of FetchContent_Populate()"
    FULL_DOCS "Details used by FetchContent_Populate() for ${contentName}"
  )
  set_property(GLOBAL PROPERTY ${propertyName} "${arg_SOURCE_DIR}")#模拟 FetchContent 的正常完成状态：

  set(propertyName "${prefix}_binaryDir")

  #属性文档声明
  #为每个属性添加文档说明以保持兼容性
  define_property(
    GLOBAL
    PROPERTY ${propertyName}
    BRIEF_DOCS "Internal implementation detail of FetchContent_Populate()"
    FULL_DOCS "Details used by FetchContent_Populate() for ${contentName}"
  )
  set_property(GLOBAL PROPERTY ${propertyName} "${arg_BINARY_DIR}")#模拟 FetchContent 的正常完成状态：

  set(propertyName "${prefix}_populated")
  #属性文档声明
  #为每个属性添加文档说明以保持兼容性
  define_property(
    GLOBAL
    PROPERTY ${propertyName}
    BRIEF_DOCS "Internal implementation detail of FetchContent_Populate()"
    FULL_DOCS "Details used by FetchContent_Populate() for ${contentName}"
  )
  set_property(GLOBAL PROPERTY ${propertyName} TRUE)#模拟 FetchContent 的正常完成状态：
endfunction()





# Download and add a package from source
#是 CPM.cmake 的核心功能，负责处理依赖包的下载和集成。
# 核心功能
# 依赖声明与下载：支持从 Git、URL 等多种来源获取依赖
# 版本管理：自动解析版本号，支持语义化版本控制
# 缓存机制：利用本地缓存避免重复下载
# 系统集成：与 CMake 的 find_package 和 FetchContent 无缝协作

## GitHub简写
# CPMAddPackage("gh:fmtlib/fmt#10.0.0")
# # 完整Git仓库
# CPMAddPackage(
#   NAME googletest
#   GIT_REPOSITORY https://github.com/google/googletest.git
#   GIT_TAG release-1.12.1
# )
# # 直接URL
# CPMAddPackage(
#   NAME boost
#   URL https://boost.org/.../boost-1.82.0.tar.gz
# )

# 补丁支持
# cmake
# CPMAddPackage(
#   NAME mylib
#   GIT_REPOSITORY ...
#   PATCHES ${CMAKE_CURRENT_DIR}/patches/fix1.patch
# )
# 自定义构建选项
# cmake
# CPMAddPackage(
#   NAME mylib
#   OPTIONS "BUILD_TESTS=OFF"
# )
# 包锁定
# cmake
# if(CPM_PACKAGE_LOCK_ENABLED)
#   cpm_add_to_package_lock(...)
# endif()

# 典型使用场景
# 基础使用
# cmake
# CPMAddPackage("gh:fmtlib/fmt#10.0.0")
# 复杂配置
# cmake
# CPMAddPackage(
#   NAME myproject
#   GIT_REPOSITORY https://example.com/myproject.git
#   GIT_TAG dev-branch
#   OPTIONS
#     "BUILD_TESTS=OFF"
#     "ENABLE_FEATURE_X=ON"
#   EXCLUDE_FROM_ALL YES
# )
# 本地开发
# cmake
# CPMAddPackage(
#   NAME mylib
#   SOURCE_DIR ../mylib
# )
function(CPMAddPackage)
  cpm_set_policies()

  list(LENGTH ARGN argnLength)
  if(argnLength EQUAL 1)  # 解析简写语法（如 gh:user/repo@1.0）
    cpm_parse_add_package_single_arg("${ARGN}" ARGN)

    # The shorthand syntax implies EXCLUDE_FROM_ALL and SYSTEM
    set(ARGN "${ARGN};EXCLUDE_FROM_ALL;YES;SYSTEM;YES;")
  endif()

  # 定义支持的参数
  set(oneValueArgs
      NAME
      FORCE
      VERSION
      GIT_TAG
      DOWNLOAD_ONLY
      GITHUB_REPOSITORY
      GITLAB_REPOSITORY
      BITBUCKET_REPOSITORY
      GIT_REPOSITORY
      SOURCE_DIR
      FIND_PACKAGE_ARGUMENTS
      NO_CACHE
      SYSTEM
      GIT_SHALLOW
      EXCLUDE_FROM_ALL
      SOURCE_SUBDIR
      CUSTOM_CACHE_KEY
  )

  set(multiValueArgs URL OPTIONS DOWNLOAD_COMMAND PATCHES) # 定义支持的参数

  cmake_parse_arguments(CPM_ARGS "" "${oneValueArgs}" "${multiValueArgs}" "${ARGN}") # 定义支持的参数

  # Set default values for arguments
# 版本推断
  if(NOT DEFINED CPM_ARGS_VERSION)
    if(DEFINED CPM_ARGS_GIT_TAG)
      cpm_get_version_from_git_tag("${CPM_ARGS_GIT_TAG}" CPM_ARGS_VERSION)
    endif()
  endif()

  if(CPM_ARGS_DOWNLOAD_ONLY)
    set(DOWNLOAD_ONLY ${CPM_ARGS_DOWNLOAD_ONLY})
  else()
    set(DOWNLOAD_ONLY NO)
  endif()

  #仓库URL处理
  if(DEFINED CPM_ARGS_GITHUB_REPOSITORY)
    set(CPM_ARGS_GIT_REPOSITORY "https://github.com/${CPM_ARGS_GITHUB_REPOSITORY}.git")
  elseif(DEFINED CPM_ARGS_GITLAB_REPOSITORY)
    set(CPM_ARGS_GIT_REPOSITORY "https://gitlab.com/${CPM_ARGS_GITLAB_REPOSITORY}.git")
  elseif(DEFINED CPM_ARGS_BITBUCKET_REPOSITORY)
    set(CPM_ARGS_GIT_REPOSITORY "https://bitbucket.org/${CPM_ARGS_BITBUCKET_REPOSITORY}.git")
  endif()

  if(DEFINED CPM_ARGS_GIT_REPOSITORY)
    list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS GIT_REPOSITORY ${CPM_ARGS_GIT_REPOSITORY})
    if(NOT DEFINED CPM_ARGS_GIT_TAG)
      set(CPM_ARGS_GIT_TAG v${CPM_ARGS_VERSION})
    endif()

    # If a name wasn't provided, try to infer it from the git repo
    if(NOT DEFINED CPM_ARGS_NAME)
      cpm_package_name_from_git_uri(${CPM_ARGS_GIT_REPOSITORY} CPM_ARGS_NAME)
    endif()
  endif()

  set(CPM_SKIP_FETCH FALSE)

  if(DEFINED CPM_ARGS_GIT_TAG)
    list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS GIT_TAG ${CPM_ARGS_GIT_TAG})
    # If GIT_SHALLOW is explicitly specified, honor the value.
    if(DEFINED CPM_ARGS_GIT_SHALLOW)
      list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS GIT_SHALLOW ${CPM_ARGS_GIT_SHALLOW})
    endif()
  endif()

  if(DEFINED CPM_ARGS_URL)
    # If a name or version aren't provided, try to infer them from the URL
    list(GET CPM_ARGS_URL 0 firstUrl)
    cpm_package_name_and_ver_from_url(${firstUrl} nameFromUrl verFromUrl)
    # If we fail to obtain name and version from the first URL, we could try other URLs if any.
    # However multiple URLs are expected to be quite rare, so for now we won't bother.

    # If the caller provided their own name and version, they trump the inferred ones.
    if(NOT DEFINED CPM_ARGS_NAME)
      set(CPM_ARGS_NAME ${nameFromUrl})
    endif()
    if(NOT DEFINED CPM_ARGS_VERSION)
      set(CPM_ARGS_VERSION ${verFromUrl})
    endif()

    list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS URL "${CPM_ARGS_URL}")
  endif()

  # Check for required arguments

  if(NOT DEFINED CPM_ARGS_NAME)
    message(
      FATAL_ERROR
        "${CPM_INDENT} 'NAME' was not provided and couldn't be automatically inferred for package added with arguments: '${ARGN}'"
    )
  endif()

  # Check if package has been added before 依赖查重，检查依赖是否已添加
  cpm_check_if_package_already_added(${CPM_ARGS_NAME} "${CPM_ARGS_VERSION}")
  if(CPM_PACKAGE_ALREADY_ADDED)
    cpm_export_variables(${CPM_ARGS_NAME})
    return()
  endif()

  # Check for manual overrides
  if(NOT CPM_ARGS_FORCE AND NOT "${CPM_${CPM_ARGS_NAME}_SOURCE}" STREQUAL "")
    set(PACKAGE_SOURCE ${CPM_${CPM_ARGS_NAME}_SOURCE})
    set(CPM_${CPM_ARGS_NAME}_SOURCE "")
    CPMAddPackage(
      NAME "${CPM_ARGS_NAME}"
      SOURCE_DIR "${PACKAGE_SOURCE}"
      EXCLUDE_FROM_ALL "${CPM_ARGS_EXCLUDE_FROM_ALL}"
      SYSTEM "${CPM_ARGS_SYSTEM}"
      PATCHES "${CPM_ARGS_PATCHES}"
      OPTIONS "${CPM_ARGS_OPTIONS}"
      SOURCE_SUBDIR "${CPM_ARGS_SOURCE_SUBDIR}"
      DOWNLOAD_ONLY "${DOWNLOAD_ONLY}"
      FORCE True
    )
    cpm_export_variables(${CPM_ARGS_NAME})
    return()
  endif()

  # Check for available declaration
  if(NOT CPM_ARGS_FORCE AND NOT "${CPM_DECLARATION_${CPM_ARGS_NAME}}" STREQUAL "")
    set(declaration ${CPM_DECLARATION_${CPM_ARGS_NAME}})
    set(CPM_DECLARATION_${CPM_ARGS_NAME} "")
    CPMAddPackage(${declaration})
    cpm_export_variables(${CPM_ARGS_NAME})
    # checking again to ensure version and option compatibility
    cpm_check_if_package_already_added(${CPM_ARGS_NAME} "${CPM_ARGS_VERSION}")
    return()
  endif()

  #本地包优先
  if(NOT CPM_ARGS_FORCE)
    if(CPM_USE_LOCAL_PACKAGES OR CPM_LOCAL_PACKAGES_ONLY)
      cpm_find_package(${CPM_ARGS_NAME} "${CPM_ARGS_VERSION}" ${CPM_ARGS_FIND_PACKAGE_ARGUMENTS})

      if(CPM_PACKAGE_FOUND)
        cpm_export_variables(${CPM_ARGS_NAME})
        return()
      endif()

      if(CPM_LOCAL_PACKAGES_ONLY)
        message(
          SEND_ERROR
            "${CPM_INDENT} ${CPM_ARGS_NAME} not found via find_package(${CPM_ARGS_NAME} ${CPM_ARGS_VERSION})"
        )
      endif()
    endif()
  endif()

  CPMRegisterPackage("${CPM_ARGS_NAME}" "${CPM_ARGS_VERSION}")

  if(DEFINED CPM_ARGS_GIT_TAG)
    set(PACKAGE_INFO "${CPM_ARGS_GIT_TAG}")
  elseif(DEFINED CPM_ARGS_SOURCE_DIR)
    set(PACKAGE_INFO "${CPM_ARGS_SOURCE_DIR}")
  else()
    set(PACKAGE_INFO "${CPM_ARGS_VERSION}")
  endif()

  if(DEFINED FETCHCONTENT_BASE_DIR)
    # respect user's FETCHCONTENT_BASE_DIR if set
    set(CPM_FETCHCONTENT_BASE_DIR ${FETCHCONTENT_BASE_DIR})
  else()
    set(CPM_FETCHCONTENT_BASE_DIR ${CMAKE_BINARY_DIR}/_deps)
  endif()

  cpm_add_patches(${CPM_ARGS_PATCHES})

  if(DEFINED CPM_ARGS_DOWNLOAD_COMMAND)
    list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS DOWNLOAD_COMMAND ${CPM_ARGS_DOWNLOAD_COMMAND})
  elseif(DEFINED CPM_ARGS_SOURCE_DIR)
    list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS SOURCE_DIR ${CPM_ARGS_SOURCE_DIR})
    if(NOT IS_ABSOLUTE ${CPM_ARGS_SOURCE_DIR})
      # Expand `CPM_ARGS_SOURCE_DIR` relative path. This is important because EXISTS doesn't work
      # for relative paths.
      get_filename_component(
        source_directory ${CPM_ARGS_SOURCE_DIR} REALPATH BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}
      )
    else()
      set(source_directory ${CPM_ARGS_SOURCE_DIR})
    endif()
    if(NOT EXISTS ${source_directory})
      string(TOLOWER ${CPM_ARGS_NAME} lower_case_name)
      # remove timestamps so CMake will re-download the dependency
      file(REMOVE_RECURSE "${CPM_FETCHCONTENT_BASE_DIR}/${lower_case_name}-subbuild")
    endif()
    #缓存处理
  elseif(CPM_SOURCE_CACHE AND NOT CPM_ARGS_NO_CACHE)
    string(TOLOWER ${CPM_ARGS_NAME} lower_case_name)
    set(origin_parameters ${CPM_ARGS_UNPARSED_ARGUMENTS})
    list(SORT origin_parameters)
    if(CPM_ARGS_CUSTOM_CACHE_KEY)
      # Application set a custom unique directory name
      set(download_directory ${CPM_SOURCE_CACHE}/${lower_case_name}/${CPM_ARGS_CUSTOM_CACHE_KEY})
    elseif(CPM_USE_NAMED_CACHE_DIRECTORIES)
      string(SHA1 origin_hash "${origin_parameters};NEW_CACHE_STRUCTURE_TAG")
      set(download_directory ${CPM_SOURCE_CACHE}/${lower_case_name}/${origin_hash}/${CPM_ARGS_NAME})
    else()
      string(SHA1 origin_hash "${origin_parameters}")
      set(download_directory ${CPM_SOURCE_CACHE}/${lower_case_name}/${origin_hash})
    endif()
    # Expand `download_directory` relative path. This is important because EXISTS doesn't work for
    # relative paths.
    get_filename_component(download_directory ${download_directory} ABSOLUTE)
    list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS SOURCE_DIR ${download_directory})

    if(CPM_SOURCE_CACHE)
      file(LOCK ${download_directory}/../cmake.lock)
    endif()
#   # 使用缓存
    if(EXISTS ${download_directory})
      if(CPM_SOURCE_CACHE)
        file(LOCK ${download_directory}/../cmake.lock RELEASE)
      endif()

      cpm_store_fetch_properties(
        ${CPM_ARGS_NAME} "${download_directory}"
        "${CPM_FETCHCONTENT_BASE_DIR}/${lower_case_name}-build"
      )
      cpm_get_fetch_properties("${CPM_ARGS_NAME}")

      if(DEFINED CPM_ARGS_GIT_TAG AND NOT (PATCH_COMMAND IN_LIST CPM_ARGS_UNPARSED_ARGUMENTS))
        # warn if cache has been changed since checkout
        cpm_check_git_working_dir_is_clean(${download_directory} ${CPM_ARGS_GIT_TAG} IS_CLEAN)
        if(NOT ${IS_CLEAN})
          message(
            WARNING "${CPM_INDENT} Cache for ${CPM_ARGS_NAME} (${download_directory}) is dirty"
          )
        endif()
      endif()

      cpm_add_subdirectory(
        "${CPM_ARGS_NAME}"
        "${DOWNLOAD_ONLY}"
        "${${CPM_ARGS_NAME}_SOURCE_DIR}/${CPM_ARGS_SOURCE_SUBDIR}"
        "${${CPM_ARGS_NAME}_BINARY_DIR}"
        "${CPM_ARGS_EXCLUDE_FROM_ALL}"
        "${CPM_ARGS_SYSTEM}"
        "${CPM_ARGS_OPTIONS}"
      )
      set(PACKAGE_INFO "${PACKAGE_INFO} at ${download_directory}")

      # As the source dir is already cached/populated, we override the call to FetchContent.
      set(CPM_SKIP_FETCH TRUE)
      cpm_override_fetchcontent(
        "${lower_case_name}" SOURCE_DIR "${${CPM_ARGS_NAME}_SOURCE_DIR}/${CPM_ARGS_SOURCE_SUBDIR}"
        BINARY_DIR "${${CPM_ARGS_NAME}_BINARY_DIR}"
      )

    else() #下载到缓存
      # Enable shallow clone when GIT_TAG is not a commit hash. Our guess may not be accurate, but
      # it should guarantee no commit hash get mis-detected.
      if(NOT DEFINED CPM_ARGS_GIT_SHALLOW)
        cpm_is_git_tag_commit_hash("${CPM_ARGS_GIT_TAG}" IS_HASH)
        if(NOT ${IS_HASH})
          list(APPEND CPM_ARGS_UNPARSED_ARGUMENTS GIT_SHALLOW TRUE)
        endif()
      endif()

      # remove timestamps so CMake will re-download the dependency
      file(REMOVE_RECURSE ${CPM_FETCHCONTENT_BASE_DIR}/${lower_case_name}-subbuild)
      set(PACKAGE_INFO "${PACKAGE_INFO} to ${download_directory}")
    endif()
  endif()

  if(NOT "${DOWNLOAD_ONLY}")
    cpm_create_module_file(${CPM_ARGS_NAME} "CPMAddPackage(\"${ARGN}\")")
  endif()

  if(CPM_PACKAGE_LOCK_ENABLED)
    if((CPM_ARGS_VERSION AND NOT CPM_ARGS_SOURCE_DIR) OR CPM_INCLUDE_ALL_IN_PACKAGE_LOCK)
      cpm_add_to_package_lock(${CPM_ARGS_NAME} "${ARGN}")
    elseif(CPM_ARGS_SOURCE_DIR)
      cpm_add_comment_to_package_lock(${CPM_ARGS_NAME} "local directory")
    else()
      cpm_add_comment_to_package_lock(${CPM_ARGS_NAME} "${ARGN}")
    endif()
  endif()

  cpm_message(
    STATUS "${CPM_INDENT} Adding package ${CPM_ARGS_NAME}@${CPM_ARGS_VERSION} (${PACKAGE_INFO})"
  )

  if(NOT CPM_SKIP_FETCH)
    # CMake 3.28 added EXCLUDE, SYSTEM (3.25), and SOURCE_SUBDIR (3.18) to FetchContent_Declare.
    # Calling FetchContent_MakeAvailable will then internally forward these options to
    # add_subdirectory. Up until these changes, we had to call FetchContent_Populate and
    # add_subdirectory separately, which is no longer necessary and has been deprecated as of 3.30.
    # A Bug in CMake prevents us to use the non-deprecated functions until 3.30.3.
    set(fetchContentDeclareExtraArgs "")
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.30.3")
      if(${CPM_ARGS_EXCLUDE_FROM_ALL})
        list(APPEND fetchContentDeclareExtraArgs EXCLUDE_FROM_ALL)
      endif()
      if(${CPM_ARGS_SYSTEM})
        list(APPEND fetchContentDeclareExtraArgs SYSTEM)
      endif()
      if(DEFINED CPM_ARGS_SOURCE_SUBDIR)
        list(APPEND fetchContentDeclareExtraArgs SOURCE_SUBDIR ${CPM_ARGS_SOURCE_SUBDIR})
      endif()
      # For CMake version <3.28 OPTIONS are parsed in cpm_add_subdirectory
      if(CPM_ARGS_OPTIONS AND NOT DOWNLOAD_ONLY)
        foreach(OPTION ${CPM_ARGS_OPTIONS})
          cpm_parse_option("${OPTION}")
          set(${OPTION_KEY} "${OPTION_VALUE}")
        endforeach()
      endif()
    endif()
    #实际下载
    cpm_declare_fetch(
      "${CPM_ARGS_NAME}" ${fetchContentDeclareExtraArgs} "${CPM_ARGS_UNPARSED_ARGUMENTS}"
    )

    cpm_fetch_package("${CPM_ARGS_NAME}" ${DOWNLOAD_ONLY} populated ${CPM_ARGS_UNPARSED_ARGUMENTS})
    if(CPM_SOURCE_CACHE AND download_directory)
      file(LOCK ${download_directory}/../cmake.lock RELEASE)
    endif()
    #项目集成
    if(${populated} AND ${CMAKE_VERSION} VERSION_LESS "3.30.3")
      cpm_add_subdirectory(
        "${CPM_ARGS_NAME}"
        "${DOWNLOAD_ONLY}"
        "${${CPM_ARGS_NAME}_SOURCE_DIR}/${CPM_ARGS_SOURCE_SUBDIR}"
        "${${CPM_ARGS_NAME}_BINARY_DIR}"
        "${CPM_ARGS_EXCLUDE_FROM_ALL}"
        "${CPM_ARGS_SYSTEM}"
        "${CPM_ARGS_OPTIONS}"
      )
    endif()
    cpm_get_fetch_properties("${CPM_ARGS_NAME}")
  endif()

  set(${CPM_ARGS_NAME}_ADDED YES)
  cpm_export_variables("${CPM_ARGS_NAME}")
endfunction()

# Fetch a previously declared package
macro(CPMGetPackage Name)
  if(DEFINED "CPM_DECLARATION_${Name}")
    CPMAddPackage(NAME ${Name})
  else()
    message(SEND_ERROR "${CPM_INDENT} Cannot retrieve package ${Name}: no declaration available")
  endif()
endmacro()

# export variables available to the caller to the parent scope expects ${CPM_ARGS_NAME} to be set
macro(cpm_export_variables name)
  set(${name}_SOURCE_DIR
      "${${name}_SOURCE_DIR}"
      PARENT_SCOPE
  )
  set(${name}_BINARY_DIR
      "${${name}_BINARY_DIR}"
      PARENT_SCOPE
  )
  set(${name}_ADDED
      "${${name}_ADDED}"
      PARENT_SCOPE
  )
  set(CPM_LAST_PACKAGE_NAME
      "${name}"
      PARENT_SCOPE
  )
endmacro()

# declares a package, so that any call to CPMAddPackage for the package name will use these
# arguments instead. Previous declarations will not be overridden.
macro(CPMDeclarePackage Name)
  if(NOT DEFINED "CPM_DECLARATION_${Name}")
    set("CPM_DECLARATION_${Name}" "${ARGN}")
  endif()
endmacro()




# CPM.cmake 中用于管理依赖锁文件的关键函数
#将当前包的声明信息写入 cpm-package-lock.cmake 文件，用于实现可重复的依赖解析
# 设计意图
# 1.可重现构建:锁定所有依赖的精确版本, 确保不同环境下的构建一致性
# 2.显式依赖管理:提供项目依赖关系的清晰声明,方便审查和版本升级
# 3.版本控制友好:生成的锁文件适合纳入版本控制.清晰的差异对比
# 典型的锁文件内容：
# cmake
# # fmt
# CPMDeclarePackage(fmt
#   "10.0.0"
#   "gh:fmtlib/fmt#10.0.0"
# )

# # catch2
# CPMDeclarePackage(catch2
#   "3.3.2"
#   "gh:catchorg/Catch2@v3.3.2"
# )
function(cpm_add_to_package_lock Name) #Name：包名称（如 "fmt"、"catch2"），ARGN：包的所有声明参数（如版本、Git仓库等）
  if(NOT CPM_DONT_CREATE_PACKAGE_LOCK)#锁文件检查，检查是否禁用了锁文件生成（通过 CPM_DONT_CREATE_PACKAGE_LOCK 选项）
    cpm_prettify_package_arguments(PRETTY_ARGN false ${ARGN})#参数格式化，调用辅助函数美化参数格式，false 参数表示不保留原始换行符
    file(APPEND ${CPM_PACKAGE_LOCK_FILE} "# ${Name}\nCPMDeclarePackage(${Name}\n${PRETTY_ARGN})\n")#写入文件，追加写入格式化的包声明，包含注释形式的包名作为可读性标记,CPM_PACKAGE_LOCK_FILE:自定义锁文件路径
  endif()
endfunction()






# CPM.cmake 中用于处理未版本化依赖的特殊函数，它通过注释形式将依赖信息写入锁文件
#将无法确定版本的依赖项以注释形式记录到 cpm-package-lock.cmake 文件中，保持锁文件的完整性同时明确标识未版本化的依赖
# 设计意图
# 1.透明化记录:即使无法锁定版本，也完整记录所有依赖项,避免"隐藏依赖"导致团队协作问题
# 2.安全隔离:通过注释确保不会意外参与构建,保持锁文件的可预测性
# 3.问题诊断:明确标识潜在的版本风险点,为后续版本固化提供依据
# 生成文件示例
# 对于本地路径依赖：
# cmake
# # mylib (unversioned)
# # CPMDeclarePackage(mylib
# #   ""
# #   "SOURCE_DIR;/path/to/local/mylib"
# # )
# 对于未指定版本的Git依赖：
# cmake
# # myproject (unversioned)
# # CPMDeclarePackage(myproject
# #   ""
# #   "GIT_REPOSITORY;https://example.com/repo.git"
# #   "GIT_TAG;main"
# # )
function(cpm_add_comment_to_package_lock Name)
  if(NOT CPM_DONT_CREATE_PACKAGE_LOCK)#锁文件检查,尊重全局锁文件开关设置

    cpm_prettify_package_arguments(PRETTY_ARGN true ${ARGN}) #参数格式化,true 参数保留原始换行和格式,适合注释内容需要保持可读性的场景
    file(APPEND ${CPM_PACKAGE_LOCK_FILE}#注释写入,添加明确的 (unversioned) 标记,整段声明被注释符号 # 包裹,保持与原声明相同的缩进结构
         "# ${Name} (unversioned)\n# CPMDeclarePackage(${Name}\n${PRETTY_ARGN}#)\n"
    )
  endif()
endfunction()



# includes the package lock file if it exists and creates a target `cpm-update-package-lock` to
# update it
#这个 CPMUsePackageLock 宏是 CPM.cmake 中用于管理依赖锁文件的核心机制
# 核心功能
# 锁文件加载：自动包含已存在的包锁文件
# 更新机制：创建可更新锁文件的自定义目标
# 状态标记：启用包锁定功能
# 典型的锁文件交互流程：
# 构建目录/
# ├─ _deps/
# │  └─ cpm-package-lock.cmake (临时生成)
# └─ cpm-package-lock.cmake (用户版本

#基础使用：# CMakeLists.txt中。CPMUsePackageLock(${CMAKE_SOURCE_DIR}/cpm-package-lock.cmake)
#更新锁文件：cmake --build . --target cpm-update-package-lock
#禁用功能：set(CPM_DONT_CREATE_PACKAGE_LOCK ON)

macro(CPMUsePackageLock file) #file：指定的锁文件路径（通常为 cpm-package-lock.cmake）

  if(NOT CPM_DONT_CREATE_PACKAGE_LOCK) #条件检查，仅在未禁用锁文件功能时执行（CPM_DONT_CREATE_PACKAGE_LOCK为OFF）
    get_filename_component(CPM_ABSOLUTE_PACKAGE_LOCK_PATH ${file} ABSOLUTE)#路径处理，将输入路径转换为绝对路径，存储在CPM_ABSOLUTE_PACKAGE_LOCK_PATH
    if(EXISTS ${CPM_ABSOLUTE_PACKAGE_LOCK_PATH})#锁文件加载，如果锁文件存在，则包含（引入其中定义的依赖项）
      include(${CPM_ABSOLUTE_PACKAGE_LOCK_PATH})
    endif()
    if(NOT TARGET cpm-update-package-lock)# 更新目标创建，创建名为cpm-update-package-lock的自定义目标，执行时将生成的临时锁文件复制到指定位置
      add_custom_target(
        cpm-update-package-lock COMMAND ${CMAKE_COMMAND} -E copy ${CPM_PACKAGE_LOCK_FILE}
                                        ${CPM_ABSOLUTE_PACKAGE_LOCK_PATH}
      )
    endif()
    set(CPM_PACKAGE_LOCK_ENABLED true)#状态标记，激活包锁定功能，影响后续CPMAddPackage的行为
  endif()
endmacro()



# registers a package that has been added to CPM
#CPM.cmake 依赖管理工具中的核心注册机制，用于内部记录所有已添加的依赖包信息
#数据结构示例：假设注册两个包后
# cmake
# CPMRegisterPackage(fmt "10.0.0")
# CPMRegisterPackage(catch2 "3.3.2")
# 内存中将生成：

# CPM_PACKAGES = ["fmt", "catch2"]
# CPM_PACKAGE_fmt_VERSION = "10.0.0"
# CPM_PACKAGE_catch2_VERSION = "3.3.2"
function(CPMRegisterPackage PACKAGE VERSION) #PACKAGE：要注册的包名（如 "fmt"），VERSION：包的精确版本（如 "10.0.0"）

  list(APPEND CPM_PACKAGES ${PACKAGE}) #包列表更新，使用 APPEND 追加新包名到全局列表，CACHE INTERNAL 确保：变量跨作用域持久化、对用户不可见（不可通过 ccmake 修改），存储保证全局可访问
  set(CPM_PACKAGES
      ${CPM_PACKAGES}
      CACHE INTERNAL ""
  )
  set("CPM_PACKAGE_${PACKAGE}_VERSION"   #版本信息存储，生成包专属版本变量（如 CPM_PACKAGE_fmt_VERSION），同样采用 CACHE INTERNAL 持久化
      ${VERSION}
      CACHE INTERNAL ""
  )
endfunction()

# retrieve the current version of the package to ${OUTPUT}
# CPM.cmake 中用于获取已注册包版本信息的工具函数
#从 CPM 内部注册系统中检索指定包的版本号，并将结果输出到指定变量
# 典型用法示例
# cmake
# CPMGetPackageVersion(fmt FMT_VERSION)
# message(STATUS "fmt version: ${FMT_VERSION}")
# 输出示例：fmt version: 10.0.0
function(CPMGetPackageVersion PACKAGE OUTPUT)  #PACKAGE：要查询的包名（如 "fmt"），OUTPUT：接收版本号的变量名
    #变量名解析，例如查询 fmt 包时，实际访问的是 CPM_PACKAGE_fmt_VERSION
    #版本检索，通过 ${} 解引用获取值
  set(${OUTPUT}
      "${CPM_PACKAGE_${PACKAGE}_VERSION}"
      PARENT_SCOPE #结果返回，使用 PARENT_SCOPE 将结果传递到父作用域，PARENT_SCOPE 实现跨函数传递
  )
endfunction()




# declares a package in FetchContent_Declare
#CPM.cmake 中封装底层 FetchContent_Declare 的中间层函数
#典型场景：依赖关系分析、CI 预检查等不需要实际下载的场景
# 设计意图：
# 1.调试支持:通过 dry-run 模式实现依赖关系图谱生成、构建环境预检、无网络环境下的配置检查
# 2.功能扩展点:为未来可能的增强提供拦截层：声明前/后的回调处理、自定义声明逻辑注入、跨平台适配预处理
# 3.统一日志：确保所有包声明操作都有标准化的日志输出格式
function(cpm_declare_fetch PACKAGE)#PACKAGE：包名称标识符（如 "fmt"），ARGN	：传递给 FetchContent_Declare 的额外参数（URL、GIT_TAG 等）
  if(${CPM_DRY_RUN}) #执行控制：支持模拟运行模式（dry-run）的包声明跳过。当 CPM_DRY_RUN=ON 时：
    cpm_message(STATUS "${CPM_INDENT} Package not declared (dry run)") #输出模拟日志（带 CPM 缩进格式）
    return() #立即返回不执行实际声明
  endif()

  FetchContent_Declare(${PACKAGE} ${ARGN})  # 条件声明： 实际声明，在非 dry-run 模式下将包声明委托给 CMake 原生的 FetchContent_Declareb#，透传所有参数到 CMake 原生函数，保持原始 FetchContent 的全部功能特性
endfunction()




# returns properties for a package previously defined by cpm_declare_fetch
# CPM.cmake 工具链中的关键组成部分，主要用于安全地获取已通过 CPM 管理的依赖包属性信息
# 核心设计目的：
# 属性暴露接口：提供标准化方式获取包的源码和构建目录路径
# dry-run兼容：在模拟执行模式下静默跳过
# 作用域安全：确保路径变量正确传递到调用方作用域

# 隐式输出变量
# cmake
# ${PACKAGE}_SOURCE_DIR  # 包源码绝对路径（对应FetchContent的_SOURCE_DIR）
# ${PACKAGE}_BINARY_DIR  # 包构建目录路径（对应FetchContent的_BINARY_DIR）
function(cpm_get_fetch_properties PACKAGE)  #PACKAGE：目标依赖包名称（如fmt）
  if(${CPM_DRY_RUN}) #Dry-run 快速通道，短路逻辑：当全局CPM_DRY_RUN启用时立即返回，避免在依赖分析阶段产生副作用，节省约90%函数执行时间（仅1次变量查找）
    return()
  endif()

  #双重嵌套变量展开。先展开${PACKAGE}得到包名（如fmt），再构造完整变量名CPM_PACKAGE_fmt_SOURCE_DIR
  set(${PACKAGE}_SOURCE_DIR
      "${CPM_PACKAGE_${PACKAGE}_SOURCE_DIR}"
      PARENT_SCOPE  #使用PARENT_SCOPE确保变量对调用方可见
  )
  set(${PACKAGE}_BINARY_DIR
      "${CPM_PACKAGE_${PACKAGE}_BINARY_DIR}"
      PARENT_SCOPE
  )
endfunction()



#CPM.cmake 工具链中的关键存储管理函数，负责持久化保存依赖包的路径信息
# 核心功能
# 路径持久化：将包的源码和构建目录路径存储到CMake缓存
# Dry-run兼容：在模拟运行模式下静默跳过
# 隔离存储：使用带命名空间的内部缓存变量
# 对于fmt包的存储
# cmake
# CPM_PACKAGE_fmt_SOURCE_DIR = "/path/to/build/_deps/fmt-src"
# CPM_PACKAGE_fmt_BINARY_DIR = "/path/to/build/_deps/fmt-build"

function(cpm_store_fetch_properties PACKAGE source_dir binary_dir)#PACKAGE：目标包名（如"fmt"），source_dir：包源码目录绝对路径，binary_dir：包构建目录绝对路径
  if(${CPM_DRY_RUN})#Dry-run 短路逻辑，设计意图：确保模拟运行时不污染缓存，性能影响：仅1次变量查找即可快速返回
    return()
  endif()
# 缓存变量存储，变量命名规则：CPM_PACKAGE_<name>_SOURCE_DIR/BINARY_DIR
# INTERNAL：对用户不可见，避免意外修改
# 全局作用域：跨CMake子目录可用
# 持久化：在整个配置阶段保持有效
  set(CPM_PACKAGE_${PACKAGE}_SOURCE_DIR
      "${source_dir}"
      CACHE INTERNAL ""
  )
  set(CPM_PACKAGE_${PACKAGE}_BINARY_DIR
      "${binary_dir}"
      CACHE INTERNAL ""
  )
endfunction()



# adds a package as a subdirectory if viable, according to provided options
#CPM.cmake 中负责将依赖包集成到主项目的关键函数
# 核心功能
# 条件集成：仅在满足条件时添加子目录
# 选项传递：处理 EXCLUDE_FROM_ALL 和 SYSTEM 等构建选项
# 参数转发：将自定义选项传递给子项目
# 日志控制：维护缩进格式的调试输出

# 基础集成
# cmake
# cpm_add_subdirectory(
#   fmt
#   FALSE
#   ${fmt_SOURCE_DIR}
#   ${fmt_BINARY_DIR}
#   TRUE  # EXCLUDE
#   FALSE # SYSTEM
#   "BUILD_SHARED_LIBS=OFF;FMT_TEST=OFF"
# )
# 仅下载模式
# cmake
# cpm_add_subdirectory(
#   googletest
#   TRUE  # DOWNLOAD_ONLY
#   ${gtest_SOURCE_DIR}
#   ${gtest_BINARY_DIR}
#   ...
# )

#PACKAGE：包标识名（如 "fmt"），DOWNLOAD_ONLY：是否仅下载不构建，SOURCE_DIR：包源码目录路径，BINARY_DIR：包构建目录路径，EXCLUDE：是否从ALL目标中排除，SYSTEM：是否标记为系统依赖，OPTIONS：传递给子项目的CMake选项（格式为"KEY=VALUE"）

function(
  cpm_add_subdirectory
  PACKAGE
  DOWNLOAD_ONLY
  SOURCE_DIR
  BINARY_DIR
  EXCLUDE
  SYSTEM
  OPTIONS
)
#前置条件检查：双重验证：DOWNLOAD_ONLY=FALSE（需要构建），存在有效的CMakeLists.txt文件。避免无效的目录添加操作

  if(NOT DOWNLOAD_ONLY AND EXISTS ${SOURCE_DIR}/CMakeLists.txt)
    set(addSubdirectoryExtraArgs "")
    if(EXCLUDE)
      list(APPEND addSubdirectoryExtraArgs EXCLUDE_FROM_ALL)
    endif()
    if("${SYSTEM}" AND "${CMAKE_VERSION}" VERSION_GREATER_EQUAL "3.25")  #版本感知：SYSTEM 选项需要 CMake ≥ 3.25
      # https://cmake.org/cmake/help/latest/prop_dir/SYSTEM.html#prop_dir:SYSTEM
      list(APPEND addSubdirectoryExtraArgs SYSTEM) #选项合并：动态构建 add_subdirectory 的参数列表
    endif()
    if(OPTIONS) #自定义选项解析
      foreach(OPTION ${OPTIONS})
        cpm_parse_option("${OPTION}")
        set(${OPTION_KEY} "${OPTION_VALUE}") #选项必须为 KEY=VALUE 格式，在当前函数域设置变量，影响子项目
      endforeach()
    endif()#日志缩进管理
    #在日志中形成树状缩进结构
    #使用临时变量保存当前缩进
    set(CPM_OLD_INDENT "${CPM_INDENT}")
    set(CPM_INDENT "${CPM_INDENT} ${PACKAGE}:")
    #子目录添加，参数转发（标准参数：源码目录和构建目录，额外选项：EXCLUDE_FROM_ALL 和 SYSTEM）
    add_subdirectory(${SOURCE_DIR} ${BINARY_DIR} ${addSubdirectoryExtraArgs})
    set(CPM_INDENT "${CPM_OLD_INDENT}")
  endif()
endfunction()




# downloads a previously declared package via FetchContent and exports the variables
# `${PACKAGE}_SOURCE_DIR` and `${PACKAGE}_BINARY_DIR` to the parent scope
#通过 FetchContent 模块下载和管理依赖包
function(cpm_fetch_package PACKAGE DOWNLOAD_ONLY populated)#PACKAGE: 要下载的包名，DOWNLOAD_ONLY: 布尔值，指示是否仅下载而不构建，populated: 输出变量，用于返回包是否已被填充(populated)
  set(${populated}#初始化输出变量，默认设置 populated 为 FALSE。
      FALSE
      PARENT_SCOPE
  )
  if(${CPM_DRY_RUN}) #干运行检查，如果处于干运行模式(CPM_DRY_RUN)，则跳过下载并返回
    cpm_message(STATUS "${CPM_INDENT} Package ${PACKAGE} not fetched (dry run)")
    return()
  endif()

  FetchContent_GetProperties(${PACKAGE}) #获取指定包的 FetchContent 属性

  string(TOLOWER "${PACKAGE}" lower_case_name) #检查包是否已填充，将包名转换为小写并检查是否已经填充

  #下载和处理包
  if(NOT ${lower_case_name}_POPULATED)
      #若是CMake 3.30.3+ 版本
    if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.30.3")
      if(DOWNLOAD_ONLY)#如果 DOWNLOAD_ONLY 为真，仅下载不构建（仅下载依赖而不自动添加到构建系统）

        # MakeAvailable will call add_subdirectory internally which is not what we want when
        # DOWNLOAD_ONLY is set. Populate will only download the dependency without adding it to the
        # build
        FetchContent_Populate(
          ${PACKAGE}
          SOURCE_DIR "${CPM_FETCHCONTENT_BASE_DIR}/${lower_case_name}-src"
          BINARY_DIR "${CPM_FETCHCONTENT_BASE_DIR}/${lower_case_name}-build"
          SUBBUILD_DIR "${CPM_FETCHCONTENT_BASE_DIR}/${lower_case_name}-subbuild"
          ${ARGN}
        )
      else()#否则，下载并构建包
        FetchContent_MakeAvailable(${PACKAGE})
      endif()
    else()#旧版本 CMake：直接填充包内容
      FetchContent_Populate(${PACKAGE})
    endif()
    #设置输出变量：如果包被成功填充，设置 populated 为 TRUE
    set(${populated}
        TRUE
        PARENT_SCOPE
    )
  endif()
  #存储包属性：存储包的源目录和二进制目录
  cpm_store_fetch_properties(
    ${CPM_ARGS_NAME} ${${lower_case_name}_SOURCE_DIR} ${${lower_case_name}_BINARY_DIR}
  )
  #导出变量到父作用域：将包的源目录和二进制目录变量导出到父作用域
  set(${PACKAGE}_SOURCE_DIR
      ${${lower_case_name}_SOURCE_DIR}
      PARENT_SCOPE
  )
  set(${PACKAGE}_BINARY_DIR
      ${${lower_case_name}_BINARY_DIR}
      PARENT_SCOPE
  )
endfunction()





# splits a package option
#解析包选项（通常是以空格分隔的键值对），统一处理用户提供的包配置选项
# 示例行为
# 输入 "VERSION 1.2.3" → 输出 OPTION_KEY="VERSION", OPTION_VALUE="1.2.3"
# 输入 "ENABLE_TESTS" → 输出 OPTION_KEY="ENABLE_TESTS", OPTION_VALUE="ON"
# 输入 "CMAKE_ARGS -Dfoo=bar" → 输出 OPTION_KEY="CMAKE_ARGS", OPTION_VALUE="-Dfoo=bar"
function(cpm_parse_option OPTION) #OPTION: 输入的选项字符串，通常是类似 "KEY VALUE" 的格式
  string(REGEX MATCH "^[^ ]+" OPTION_KEY "${OPTION}")#提取选项键(KEY):使用正则表达式匹配第一个非空格字符序列作为选项键
  string(LENGTH "${OPTION}" OPTION_LENGTH)#检查是否有值(VALUE)，计算整个选项字符串和键的长度
  string(LENGTH "${OPTION_KEY}" OPTION_KEY_LENGTH)
  if(OPTION_KEY_LENGTH STREQUAL OPTION_LENGTH)#处理无值情况：如果键长度等于整个字符串长度，说明没有提供值，默认设为 "ON"（类似 CMake 的 option() 行为）
    # no value for key provided, assume user wants to set option to "ON"
    set(OPTION_VALUE "ON")
  else()#处理有值情况:否则，跳过键和空格，提取剩余部分作为值
    math(EXPR OPTION_KEY_LENGTH "${OPTION_KEY_LENGTH}+1")
    string(SUBSTRING "${OPTION}" "${OPTION_KEY_LENGTH}" "-1" OPTION_VALUE)
  endif()#返回结果:将解析出的键和值设置到父作用域
  set(OPTION_KEY
      "${OPTION_KEY}"
      PARENT_SCOPE
  )
  set(OPTION_VALUE
      "${OPTION_VALUE}"
      PARENT_SCOPE
  )
endfunction()






# guesses the package version from a git tag
#用于从 Git 标签中提取版本号

# 示例行为
# 输入 "v1.2.3" → 输出 "1.2.3"
# 输入 "2.0.1-alpha" → 输出 "2.0.1"
# 输入 "release_3.1" → 输出 "3.1"
# 输入 "f1d2d2f924e986ac86fdf7b36c94bcdf32beec15"（40字符哈希）→ 输出 "0"

function(cpm_get_version_from_git_tag GIT_TAG RESULT)#GIT_TAG: 输入的 Git 标签字符串，RESULT: 输出变量名，用于返回提取的版本号
  string(LENGTH ${GIT_TAG} length) #检查是否是 Git 哈希值:
  if(length EQUAL 40)#检查标签长度是否为 40 个字符（标准的 Git commit SHA-1 哈希长度）
    # GIT_TAG is probably a git hash
    set(${RESULT}#如果是哈希值，则返回版本号 0（表示无法从哈希中提取有意义版本）
        0
        PARENT_SCOPE
    )
  else() #从标签提取版本号
    string(REGEX MATCH "v?([0123456789.]*).*" _ ${GIT_TAG})#使用正则表达式匹配版本号模式，模式解释：v? 表示可选的 'v' 前缀，([0123456789.]*) 捕获数字和点组成的版本号
    set(${RESULT} #将匹配到的版本号（第一捕获组）通过 RESULT 返回
        ${CMAKE_MATCH_1}
        PARENT_SCOPE
    )
  endif()
endfunction()







#用于判断给定的 Git 标签是否是一个有效的提交哈希值（而不是分支名或标签名，更专注于哈希的识别）
# 示例行为
# 输入 "f1d2d2f"（7位十六进制）→ 输出 1
# 输入 "f1d2d2f924e986ac86fdf7b36c94bcdf32beec15"（40位）→ 输出 1
# 输入 "v1.0" → 输出 0
# 输入 "master" → 输出 0
# 输入 "123"（太短）→ 输出 0

# guesses if the git tag is a commit hash or an actual tag or a branch name.
function(cpm_is_git_tag_commit_hash GIT_TAG RESULT)#GIT_TAG: 输入的 Git 引用字符串（可能是哈希、标签或分支名），RESULT: 输出变量名，返回判断结果（1 表示是哈希，0 表示不是）
  string(LENGTH "${GIT_TAG}" length)
  # full hash has 40 characters, and short hash has at least 7 characters.
  if(length LESS 7 OR length GREATER 40)#长度检查:Git 完整哈希是 40 字符，短哈希至少 7 字符
    set(${RESULT}
        0
        PARENT_SCOPE
    )
  else()#如果长度不在 7-40 范围内，直接判定不是哈希（返回 0）
    if(${GIT_TAG} MATCHES "^[a-fA-F0-9]+$")  #字符格式检查:检查字符串是否只包含十六进制字符（a-f, A-F, 0-9）
        #如果是则判定为哈希（返回 1），否则不是（返回 0）
      set(${RESULT}
          1
          PARENT_SCOPE
      )
    else()
      set(${RESULT}
          0
          PARENT_SCOPE
      )
    endif()
  endif()
endfunction()





#用于格式化和美化 CPM（CMake Package Manager）包参数的输出
# 示例输出
# 当 IS_IN_COMMENT 为 FALSE 时：

#   NAME MyPackage
#   VERSION 1.2.3
#   GIT_TAG v1.2.3
#   OPTIONS
#     "ENABLE_TESTS OFF"
#     "BUILD_SHARED_LIBS ON"
# 当 IS_IN_COMMENT 为 TRUE 时：

# #  NAME MyPackage
# #  VERSION 1.2.3
# #  GIT_TAG v1.2.3
# #  OPTIONS
# #    "ENABLE_TESTS OFF"
# #    "BUILD_SHARED_LIBS ON"

function(cpm_prettify_package_arguments OUT_VAR IS_IN_COMMENT) #OUT_VAR: 输出变量名，用于存储格式化后的字符串，IS_IN_COMMENT: 布尔值，指示是否将输出作为注释（每行前加 #）
  #定义参数类型
    set(oneValueArgs
      NAME
      FORCE
      VERSION
      GIT_TAG
      DOWNLOAD_ONLY
      GITHUB_REPOSITORY
      GITLAB_REPOSITORY
      BITBUCKET_REPOSITORY
      GIT_REPOSITORY
      SOURCE_DIR
      FIND_PACKAGE_ARGUMENTS
      NO_CACHE
      SYSTEM
      GIT_SHALLOW
      EXCLUDE_FROM_ALL
      SOURCE_SUBDIR
  )
  set(multiValueArgs URL OPTIONS DOWNLOAD_COMMAND)#明确哪些参数是单值的，哪些是多值的
  cmake_parse_arguments(CPM_ARGS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})#使用 CMake 内置命令解析输入的参数

  #处理单值参数
  foreach(oneArgName ${oneValueArgs})
    if(DEFINED CPM_ARGS_${oneArgName})
      if(${IS_IN_COMMENT})#根据 IS_IN_COMMENT 决定是否添加注释符 #
        # 特殊处理 SOURCE_DIR 参数（替换路径为变量）
        string(APPEND PRETTY_OUT_VAR "#")
      endif()
      if(${oneArgName} STREQUAL "SOURCE_DIR") #特殊处理 SOURCE_DIR，将绝对路径替换为 ${CMAKE_SOURCE_DIR} 变量
        string(REPLACE ${CMAKE_SOURCE_DIR} "\${CMAKE_SOURCE_DIR}" CPM_ARGS_${oneArgName}
                       ${CPM_ARGS_${oneArgName}}
        )
      endif()
      string(APPEND PRETTY_OUT_VAR "  ${oneArgName} ${CPM_ARGS_${oneArgName}}\n") #为每个定义的参数添加格式化输出
    endif()
  endforeach()
#处理多值参数：多值参数会分行显示，每个值单独一行并加引号
  foreach(multiArgName ${multiValueArgs})
    if(DEFINED CPM_ARGS_${multiArgName})
         # 添加参数名
      if(${IS_IN_COMMENT})
        string(APPEND PRETTY_OUT_VAR "#")
      endif()
      string(APPEND PRETTY_OUT_VAR "  ${multiArgName}\n")
      foreach(singleOption ${CPM_ARGS_${multiArgName}})
        if(${IS_IN_COMMENT})
          string(APPEND PRETTY_OUT_VAR "#")
        endif()
        string(APPEND PRETTY_OUT_VAR "    \"${singleOption}\"\n")
      endforeach()
    endif()
  endforeach()

  #处理未解析参数：将所有未解析参数放在一行
  if(NOT "${CPM_ARGS_UNPARSED_ARGUMENTS}" STREQUAL "")

    if(${IS_IN_COMMENT})
      string(APPEND PRETTY_OUT_VAR "#")
    endif()
    string(APPEND PRETTY_OUT_VAR " ")
    foreach(CPM_ARGS_UNPARSED_ARGUMENT ${CPM_ARGS_UNPARSED_ARGUMENTS})
      string(APPEND PRETTY_OUT_VAR " ${CPM_ARGS_UNPARSED_ARGUMENT}")
    endforeach()
    string(APPEND PRETTY_OUT_VAR "\n")
  endif()

  set(${OUT_VAR}
      ${PRETTY_OUT_VAR}
      PARENT_SCOPE
  )

endfunction()
