#配置 QGroundControl 项目（或其他 Qt 项目）在不同平台的安装与部署流程，并根据平台进行打包（例如生成 AppImage、DMG、Windows 安装程序等）
# 功能	说明
# 安装项目产物	安装动态库、可执行文件、bundle
# 自动生成部署脚本	支持 Qt 项目的部署
# 平台特定处理	Linux: AppImage，Windows: 安装程序，macOS: DMG
# 图标与启动项支持	.desktop 文件、图标、AppStream 元信息


include(InstallRequiredSystemLibraries) #包含系统库的安装规则，确保必要的系统依赖库可以被正确打包。

#安装可执行目标
#这段表示将项目编译出来的目标文件安装到对应目录：
# .so/.dll → LIBRARY
# 可执行文件 → RUNTIME
# .a/.lib → ARCHIVE
# macOS 的 .app bundle → BUNDLE

install(
    TARGETS ${CMAKE_PROJECT_NAME}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    BUNDLE  DESTINATION .
)

#配置部署参数（如用于 macdeployqt）
# -qmldir：指定 QML 文件路径。
# macOS 签名支持，如果有 MACOS_SIGNING_IDENTITY 会添加 -sign-for-notarization 参数。
# 注意这里拼写错了：应为 deploy_tool_options_arg，但用了 deplay_tool_options_arg，是个 bug。

set(deploy_tool_options_arg "")
if(MACOS OR WIN32)
    set(deploy_tool_options_arg "-qmldir=${CMAKE_SOURCE_DIR}")
    if(MACOS_SIGNING_IDENTITY)
        message(STATUS "Signing MacOS Bundle")
        set(deploy_tool_options_arg "${deploy_tool_options_arg} -sign-for-notarization=${MACOS_SIGNING_IDENTITY}")
    endif()
endif()




# Set extra deploy QML app script options for Qt 6.7.0 and above
# Qt 6.7+ 特殊处理
#Qt 6.7 起支持通过 qt_generate_deploy_qml_app_script() 添加部署参数
set(EXTRA_DEPLOY_QML_APP_SCRIPT_OPTIONS)
if(QT_VERSION VERSION_GREATER_EQUAL 6.7.0)
    list(APPEND EXTRA_DEPLOY_QML_APP_SCRIPT_OPTIONS DEPLOY_TOOL_OPTIONS ${deploy_tool_options_arg})
endif()


#自动生成部署脚本
#使用 qt_generate_deploy_qml_app_script 创建部署脚本（如调用 windeployqt, macdeployqt, androiddeployqt 等），并作为安装脚本执行
qt_generate_deploy_qml_app_script(
    TARGET ${CMAKE_PROJECT_NAME}
    OUTPUT_SCRIPT deploy_script
    ${EXTRA_DEPLOY_QML_APP_SCRIPT_OPTIONS}
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})

# Android
#原本意图处理 QT_ANDROID_DEPLOYMENT_SETTINGS_FILE，但被注释了
if(ANDROID)
    # get_target_property(QGC_ANDROID_DEPLOY_FILE ${CMAKE_PROJECT_NAME} QT_ANDROID_DEPLOYMENT_SETTINGS_FILE)
    # cmake_print_variables(QGC_ANDROID_DEPLOY_FILE)

#Linux 平台 AppImage 配置
# Linux 上：
# 生成 .desktop 启动器文件
# 复制图标
# 生成 metainfo 描述文件（如 AppStream）
# 安装 AppRun 启动脚本
# 最终调用 CreateAppImage.cmake 来生成 AppImage


elseif(LINUX)
    configure_file(
        ${CMAKE_SOURCE_DIR}/deploy/linux/org.mavlink.qgroundcontrol.desktop.in
        ${CMAKE_BINARY_DIR}/org.mavlink.qgroundcontrol.desktop
        @ONLY
    )
    install(
        FILES ${CMAKE_BINARY_DIR}/org.mavlink.qgroundcontrol.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )
    install(
        FILES ${QGC_APPIMAGE_ICON_PATH}
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/128x128/apps/
        RENAME org.mavlink.qgroundcontrol.png
    )
    configure_file(
        ${CMAKE_SOURCE_DIR}/deploy/linux/org.mavlink.qgroundcontrol.metainfo.xml.in
        ${CMAKE_BINARY_DIR}/metainfo/org.mavlink.qgroundcontrol.metainfo.xml
        @ONLY
    )
    install(
        FILES ${CMAKE_BINARY_DIR}/metainfo/org.mavlink.qgroundcontrol.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo/
    )
    install(
        FILES ${CMAKE_SOURCE_DIR}/deploy/linux/AppRun
        DESTINATION ${CMAKE_BINARY_DIR}
    )
    install(SCRIPT "${CMAKE_SOURCE_DIR}/cmake/CreateAppImage.cmake")

#Windows 安装程序打包
elseif(WIN32)
    install(SCRIPT "${CMAKE_SOURCE_DIR}/cmake/CreateWinInstaller.cmake") #调用脚本生成 .exe 安装程序。
elseif(MACOS)
#macOS DMG 打包
# 设置打包参数和工具路径
# 调用 CreateMacDMG.cmake 脚本生成 .dmg 安装包
    install(CODE "set(TARGET_APP_NAME ${QGC_APP_NAME})")
    install(CODE "set(MACDEPLOYQT ${Qt6_DIR}/../../../bin/macdeployqt)")
    install(SCRIPT "${CMAKE_SOURCE_DIR}/cmake/CreateMacDMG.cmake")
endif()
