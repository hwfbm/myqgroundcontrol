add_subdirectory(AirLink)
add_subdirectory(MockLink)

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        LinkConfiguration.cc
        LinkConfiguration.h
        LinkInterface.cc
        LinkInterface.h
        LinkManager.cc
        LinkManager.h
        LogReplayLink.cc
        LogReplayLink.h
        LogReplayLinkController.cc
        LogReplayLinkController.h
        MAVLinkProtocol.cc
        MAVLinkProtocol.h
        TCPLink.cc
        TCPLink.h
        UDPLink.cc
        UDPLink.h
        mqttlink.h
        mqttlink.cpp
        mavlinktojson.h
        mavlinktojson.cpp
        loginmanager.h
        loginmanager.cpp

)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

#===========================================================================#

if(QGC_NO_SERIAL_LINK)
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE QGC_NO_SERIAL_LINK)
else()
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            QGCSerialPortInfo.cc
            QGCSerialPortInfo.h
            SerialLink.cc
            SerialLink.h
            UdpIODevice.cc
            UdpIODevice.h
    )

    if(ANDROID)
        add_subdirectory(${CMAKE_SOURCE_DIR}/android/libs/qtandroidserialport qtandroidserialport.build)
        target_sources(${CMAKE_PROJECT_NAME}
            PRIVATE
                ${CMAKE_SOURCE_DIR}/android/src/AndroidSerial.cc
                ${CMAKE_SOURCE_DIR}/android/src/AndroidSerial.h
        )
        target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_SOURCE_DIR}/android/src)
    else()
        target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::SerialPort)
    endif()
endif()

#===========================================================================#

if(QGC_ENABLE_BLUETOOTH)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Bluetooth)
    target_sources(${CMAKE_PROJECT_NAME}
        PRIVATE
            BluetoothLink.cc
            BluetoothLink.h
    )
    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE QGC_ENABLE_BLUETOOTH)
endif()

#===========================================================================#

if(QGC_ZEROCONF_ENABLED)
    message(STATUS "Building QMDNSEngine")

    CPMAddPackage(
        NAME qmdnsengine
        GITHUB_REPOSITORY nitroshare/qmdnsengine
        GIT_TAG master
        OPTIONS
            "BUILD_DOC OFF"
            "BUILD_EXAMPLES OFF"
            "BUILD_TESTS OFF"
    )

    if(TARGET qmdnsengine)
        target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE qmdnsengine)
        target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE QGC_ZEROCONF_ENABLED)
    endif()
endif()

#===========================================================================#
# 添加 jwt-cpp 库
# message(STATUS "Building JWT-Cpp Library")

# CPMAddPackage(
#     NAME jwt-cpp
#     GITHUB_REPOSITORY Thalhammer/jwt-cpp
#     GIT_TAG master  # 或者选择一个稳定的标签
#     OPTIONS
#         "JWT_BUILD_EXAMPLES OFF"
#         "JWT_BUILD_TESTS OFF"
#     #[[SOURCE_SUBDIR src]]  # jwt-cpp 源文件目录
# )

# target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
#     # ${jwt-cpp_SOURCE_DIR}/include/jwt-cpp
#     # ${jwt-cpp_SOURCE_DIR}/include/picojson
#      ${jwt-cpp_SOURCE_DIR}/include)
# # 如果 jwt-cpp 拉取了 picojson 作为子依赖，CMake 应该自动处理，但你可以手动检查 picojson 的路径
# message(STATUS "PicoJSON Include Path: ${jwt-cpp_SOURCE_DIR}/include/picojson")
# # file(GLOB JWT_CPP_SOURCES "${jwt-cpp_SOURCE_DIR}/src/*")

# # # 将 jwt-cpp 源文件添加到项目中
# # target_sources(${CMAKE_PROJECT_NAME}
# #     PRIVATE
# #     ${JWT_CPP_SOURCES}
# # )

# # 添加 jwt-cpp 的头文件目录
# message(STATUS "JWT CPP Source Directory: ${jwt-cpp_SOURCE_DIR}")





# target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE QABSTRACTSOCKET_DEBUG)
