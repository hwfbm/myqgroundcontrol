#注释掉的 QML 模块配置
#这部分是 Qt 6 引入的新方式，用于注册一个 QML 模块。它目前被注释掉，可能是暂未启用或正在迁移中
# qt_add_qml_module(QGC
#     URI QGroundControl
#     VERSION 1.0
#     IMPORT_PATH ${QT_QML_OUTPUT_DIRECTORY}
# )


#主程序源文件添加
#添加了主程序启动文件、命令行参数解析类和 QGCApplication（QGC 的核心应用管理类）
target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        main.cc
        CmdLineOptParser.cc
        CmdLineOptParser.h
        QGCApplication.cc
        QGCApplication.h
)


#平台相关的源文件（非移动端）
#RunGuard 用于防止多个实例运行，仅在桌面平台上启用

if(NOT ANDROID AND NOT IOS)
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            RunGuard.cc
            RunGuard.h
    )
endif()

#链接 Qt 和项目依赖库，QGCLocation 是 QGC 自定义的一个模块或库。
#链接了大量 Qt 模块（Charts、Gui、Qml、Quick、Multimedia、Location等）。
target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        Qt6::Charts
        Qt6::Concurrent
        Qt6::Core
        Qt6::Core5Compat
        Qt6::CorePrivate
        Qt6::Gui
        Qt6::Location
        Qt6::LocationPrivate
        Qt6::Multimedia
        Qt6::MultimediaQuickPrivate
        Qt6::Network
        Qt6::Positioning
        Qt6::PositioningPrivate
        Qt6::Qml
        Qt6::QmlIntegration
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Sensors
        Qt6::Svg
        Qt6::TextToSpeech
        Qt6::Widgets
        Qt6::Xml
        QGCLocation
)
#包含头文件目录
#设置包含当前目录的头文件路径
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})


#Android 特有的源文件与库，针对 Android 平台单独添加源文件和库
if(ANDROID)
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            ${CMAKE_SOURCE_DIR}/android/src/AndroidInit.cc
            ${CMAKE_SOURCE_DIR}/android/src/AndroidInterface.cc
            ${CMAKE_SOURCE_DIR}/android/src/AndroidInterface.h
    )

    target_link_libraries(${CMAKE_PROJECT_NAME}
        PRIVATE
            Qt6::Core
            Qt6::CorePrivate
    )

    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/android/src)
endif()

# 添加子模块目录
#这是最重要的一块，告诉 CMake 去构建各个子模块，每个子模块通常都有自己的 CMakeLists.txt
add_subdirectory(ADSB)
add_subdirectory(AnalyzeView)
add_subdirectory(API)
add_subdirectory(AutoPilotPlugins)
add_subdirectory(Camera)
add_subdirectory(Comms)
add_subdirectory(FactSystem)
add_subdirectory(FirmwarePlugin)
# add_subdirectory(FirstRunPromptDialogs)
# add_subdirectory(FlightDisplay)
# add_subdirectory(FlightMap)
add_subdirectory(FollowMe)
add_subdirectory(Gimbal)
add_subdirectory(GPS)
add_subdirectory(Joystick)
add_subdirectory(MAVLink)
add_subdirectory(MissionManager)
# add_subdirectory(PlanView)
add_subdirectory(PositionManager)
add_subdirectory(QmlControls)
add_subdirectory(QtLocationPlugin)
add_subdirectory(Settings)
add_subdirectory(Terrain)
# add_subdirectory(UI)
add_subdirectory(Utilities)
add_subdirectory(UTMSP)
add_subdirectory(Vehicle)
add_subdirectory(VideoManager)
add_subdirectory(Viewer3D)


#预编译头
#设置了 QGC 常用的头文件为预编译，加快构建速度
target_precompile_headers(${CMAKE_PROJECT_NAME}
    PRIVATE
        <QtCore/QObject>
        <QtNetwork/QNetworkReply>
        <QtPositioning/QGeoCoordinate>
)
