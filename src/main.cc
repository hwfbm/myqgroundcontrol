/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include <QtQuick/QQuickWindow>
#include <QtWidgets/QApplication>

//通过 Q_OS_* 宏区分不同平台代码，确保各平台特有逻辑互不干扰
#ifdef Q_OS_MACOS
    #include <QtCore/QProcessEnvironment>
#endif

#include "QGCApplication.h"
#include "AppMessages.h"
#include "CmdLineOptParser.h"

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    #include <QtWidgets/QMessageBox>
    #include "RunGuard.h"     // 移动端不需要单例检测
#endif

#ifdef Q_OS_ANDROID
    #include "AndroidInterface.h"
#endif

#ifdef QT_DEBUG
#ifdef QGC_UNITTEST_BUILD
    #include "UnitTestList.h"
#endif

#ifdef Q_OS_WIN

#include <crtdbg.h>
#include <windows.h>
#include <iostream>

/// @brief CRT Report Hook installed using _CrtSetReportHook. We install this hook when
/// we don't want asserts to pop a dialog on windows.
/// 在 CI/CD 环境中避免断言弹窗阻塞流程
int WindowsCrtReportHook(int reportType, char* message, int* returnValue)
{
    Q_UNUSED(reportType);

    std::cerr << message << std::endl;  // 重定向到控制台
    *returnValue = 0;                   // 禁止弹出错误对话框
    return true;                        // We handled this fully ourselves
}

#endif // Q_OS_WIN

#endif // QT_DEBUG

#ifdef Q_OS_LINUX
#ifndef Q_OS_ANDROID

#include <csignal>

void sigHandler(int s)
{
    std::signal(s, SIG_DFL);
   // qgcApp() 全局函数提供应用单例访问入口（工厂模式）
    if(qgcApp()) {
        qgcApp()->mainRootWindow()->close(); // 优雅关闭主窗口
        QEvent event{QEvent::Quit};//通过 QEvent 机制处理系统信号（观察者模式）
        qgcApp()->event(&event); // 发送退出事件
    }
}

#endif /* Q_OS_ANDROID */
#endif /* Q_OS_LINUX */

//-----------------------------------------------------------------------------
/**
 * @brief Starts the application
 *
 * @param argc Number of commandline arguments
 * @param argv Commandline arguments
 * @return exit code, 0 for normal exit and !=0 for error cases
 */

int main(int argc, char *argv[])
{
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    // We make the runguard key different for custom and non custom
    // builds, so they can be executed together in the same device.
    // Stable and Daily have same QGC_APP_NAME so they would
    // not be able to run at the same time
    const QString runguardString = QStringLiteral("%1 RunGuardKey").arg(QGC_APP_NAME);

    //通过 RunGuard 确保同一时间只有一个 QGC 实例运行。基于系统锁、文件锁或共享内存检测重复启动。
    RunGuard guard(runguardString);
    if (!guard.tryToRun()) {
        QApplication errorApp(argc, argv);
        QMessageBox::critical(nullptr, QObject::tr("Error"),
            QObject::tr("A second instance of %1 is already running. Please close the other instance and try again.").arg(QGC_APP_NAME)
        );
        return -1;
    }
#endif



//Linux 非 root 运行
//以 root 运行可能导致权限问题或安全隐患。
#ifdef Q_OS_LINUX
#ifndef Q_OS_ANDROID
    if (getuid() == 0) {
        QApplication errorApp(argc, argv);
        QMessageBox::critical(nullptr, QObject::tr("Error"),
            QObject::tr("You are running %1 as root. "
                "You should not do this since it will cause other issues with %1."
                "%1 will now exit.<br/><br/>").arg(QGC_APP_NAME)
        );
        return -1;
    }
#endif
#endif

#ifdef Q_OS_UNIX
    if (!qEnvironmentVariableIsSet("QT_LOGGING_TO_CONSOLE")) {
        qputenv("QT_LOGGING_TO_CONSOLE", "1");
    }
#endif

    AppMessages::installHandler();

//MacOS 禁用 App Nap，防止 macOS 的 App Nap 机制降低 QGC 后台性能
#ifdef Q_OS_MACOS
    // Prevent Apple's app nap from screwing us over
    // tip: the domain can be cross-checked on the command line with <defaults domains>
    QProcess::execute("defaults", {"write org.qgroundcontrol.qgroundcontrol NSAppSleepDisabled -bool YES"});
#endif

//Windows OpenGL 渲染器选择，允许命令行指定 OpenGL 实现（硬件加速或软件渲染）
#ifdef Q_OS_WIN
    // Set our own OpenGL buglist
    // qputenv("QT_OPENGL_BUGLIST", ":/opengl/resources/opengl/buglist.json");

    // Allow for command line override of renderer
    for (int i = 0; i < argc; i++) {
        const QString arg(argv[i]);
        if (arg == QStringLiteral("-desktop")) {
            QCoreApplication::setAttribute(Qt::AA_UseDesktopOpenGL);
            break;
        } else if (arg == QStringLiteral("-swrast")) {
            QCoreApplication::setAttribute(Qt::AA_UseSoftwareOpenGL);
            break;
        }
    }
#endif

    bool runUnitTests = false;
    bool simpleBootTest = false;

#ifdef QT_DEBUG
    // We parse a small set of command line options here prior to QGCApplication in order to handle the ones
    // which need to be handled before a QApplication object is started.

    bool stressUnitTests = false;       // Stress test unit tests
    bool quietWindowsAsserts = false;   // Don't let asserts pop dialog boxes


    //--unittest：运行单元测试。
    //--unittest-stress：压力测试模式。
    //--no-windows-assert-ui：禁用 Windows 断言弹窗（用于 CI/CD）。
    QString unitTestOptions;
    //新增命令行参数，在rgCmdLineOptions添加条目
    CmdLineOpt_t rgCmdLineOptions[] = {
        { "--unittest",             &runUnitTests,          &unitTestOptions },
        { "--unittest-stress",      &stressUnitTests,       &unitTestOptions },
        { "--no-windows-assert-ui", &quietWindowsAsserts,   nullptr },
        //在对应位置处理参数逻辑
    };

    ParseCmdLineOptions(argc, argv, rgCmdLineOptions, std::size(rgCmdLineOptions), false);
    if (stressUnitTests) {
        runUnitTests = true;
    }

#ifdef Q_OS_WIN
    if (quietWindowsAsserts) {
        _CrtSetReportHook(WindowsCrtReportHook);
    }

    if (runUnitTests) {
        // Don't pop up Windows Error Reporting dialog when app crashes. This prevents TeamCity from
        // hanging.
        const DWORD dwMode = SetErrorMode(SEM_NOGPFAULTERRORBOX);
        SetErrorMode(dwMode | SEM_NOGPFAULTERRORBOX);
    }

#endif // Q_OS_WIN
#else
    CmdLineOpt_t rgCmdLineOptions[] = {
        { "--simple-boot-test", &simpleBootTest, nullptr },
    };
    ParseCmdLineOptions(argc, argv, rgCmdLineOptions, std::size(rgCmdLineOptions), false);
#endif // QT_DEBUG

    QGCApplication app(argc, argv, runUnitTests || simpleBootTest);

//捕获 Ctrl+C (SIGINT) 和终止信号 (SIGTERM)，优雅退出
#ifdef Q_OS_LINUX
#ifndef Q_OS_ANDROID
    std::signal(SIGINT, sigHandler);
    std::signal(SIGTERM, sigHandler);
#endif
#endif

    //预加载资源：在 app.init() 中异步加载重型资源，延迟初始化：非关键模块按需加载
    app.init();//初始化日志系统、加载配置、创建主窗口等

    int exitCode = 0;


    //添加新平台支持
    //实现平台特定的初始化/清理逻辑
    //条件编译：仅在调试版本或单元测试构建时启用。
    //runTests：执行 Google Test 或 Qt Test 框架的测试用例。
#ifdef QGC_UNITTEST_BUILD
    if (runUnitTests) {
        exitCode = runTests(stressUnitTests, unitTestOptions);
    } else
#endif
    {
        #ifdef Q_OS_ANDROID
            AndroidInterface::checkStoragePermissions();
        #endif

        if (!simpleBootTest) {
            exitCode = app.exec();
        }
    }

    app.shutdown();//清理资源，保存状态

    qDebug() << "Exiting main";

    return exitCode;
}
