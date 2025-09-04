/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window



//import "../QmlControls"  // 从UI目录返回到src，再进入QmlControls
import QGroundControl
import QGroundControl.Palette
//import QGroundControl.Palette 1.0  // 标准 QGC 调色板模块
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
//import "../FlightMap"
//import "../FlightDisplay"

import QGroundControl.UTMSP


/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:   mainWindow
    minimumWidth:   ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(ScreenTools.defaultFontPixelWidth * 100, Screen.width)
    minimumHeight:  ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(ScreenTools.defaultFontPixelWidth * 50, Screen.height)
    visible:        true

    property bool   _utmspSendActTrigger
    property bool   _utmspStartTelemetry
    //飞行视图的核心界面
    FlyView {
        id:                     flyView
        anchors.fill:           parent
        utmspSendActTrigger:    _utmspSendActTrigger //接收_utmspSendActTrigger信号


    }


    Component.onCompleted: {
        //-- Full screen on mobile or tiny screens判断设备类型并设置窗口尺寸
        //--如果是 移动设备 或 屏幕太小的设备（如某些嵌入式系统），就全屏显示
        if (!ScreenTools.isFakeMobile && (ScreenTools.isMobile || Screen.height / ScreenTools.realPixelDensity < 120)) {
            mainWindow.showFullScreen()
        } else
        //--否则就设置合理的 width 和 height，保证桌面体验合适
        {
            width   = ScreenTools.isMobile ? ScreenTools.screenWidth  : Math.min(250 * Screen.pixelDensity, Screen.width)
            height  = ScreenTools.isMobile ? ScreenTools.screenHeight : Math.min(150 * Screen.pixelDensity, Screen.height)
        }

        // Start the sequence of first run prompt(s)启动“首次运行引导提示”
        firstRunPromptManager.nextPrompt()
    }
        // 匿名的 QtObject，专门用来管理用户初次使用时的提示弹窗
    QtObject {
        id: firstRunPromptManager

        property var currentDialog:     null //当前正在显示的提示对话框对象
        property var rgPromptIds:       QGroundControl.corePlugin.firstRunPromptsToShow() // 存储需要显示的提示 ID 列表，从QGroundControl.corePlugin.firstRunPromptsToShow() 获取一个待显示的提示列表
        property int nextPromptIdIndex:0 //nextPromptIdIndex


        //断开当前对话框的 closed 信号与 nextPrompt 的链接（防止重复触发）
        function clearNextPromptSignal()
        {
            //当前正在显示的提示对话框对象。
            if (currentDialog) {
                currentDialog.closed.disconnect(nextPrompt)
            }
        }

        function nextPrompt() //按顺序弹出提示对话框
        {
            //rgPromptIds存储需要显示的提示 ID 列表（从 corePlugin.firstRunPromptsToShow() 获取）
            if (nextPromptIdIndex < rgPromptIds.length) {
                //每个弹窗通过 Qt.createComponent() 动态创建。
                var component = Qt.createComponent(QGroundControl.corePlugin.firstRunPromptResource(rgPromptIds[nextPromptIdIndex]));
                currentDialog = component.createObject(mainWindow)
                //每个弹窗关闭自动触发下一个提示
                currentDialog.closed.connect(nextPrompt)
                currentDialog.open()
                nextPromptIdIndex++
            } else {
                //所有提示结束后，如果设置中要求启用“飞行前检查清单”，则弹出检查表
                currentDialog = null
                showPreFlightChecklistIfNeeded()//触发检查信号
            }
        }
    }

    //定义一个只读属性，表示顶部和底部的边距，值为字体高度的一半。这个值通常用于统一界面布局时的 margin
    readonly property real      _topBottomMargins:          ScreenTools.defaultFontPixelHeight * 0.5

    //-------------------------------------------------------------------------
    //-- Global Scope Variables
    //这是 QML 中一个常见技巧：把很多常用的状态值或接口放在一个 QtObject 里，方便整个页面或子组件调用
    //提供纯粹的QML对象容器功能，替代Item当不需要可视化属性时（节省内存/渲染开销）
    //在组件初始化时做条件判断，比如是否默认展开某区域或隐藏其他选项
    QtObject {
        id: globals

        readonly property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle //当前激活的飞行器对象
        //ScreenTools 是通过 qmldir + singleton 注册的单例 QML 工具类（不是 C++）
        readonly property real defaultTextHeight: ScreenTools.defaultFontPixelHeight//默认文字高度（按字体大小）
        readonly property real defaultTextWidth:  ScreenTools.defaultFontPixelWidth//宽度
        readonly property var planMasterControllerFlyView:  flyView.planController//规划视图的任务控制器
        readonly property var guidedControllerFlyView:  flyView.guidedController//导航视图的任务控制器

        // Number of QGCTextField's with validation errors. Used to prevent closing panels with validation errors.表单验证错误的数量
        //配合 QGCTextField 使用。如果某些字段验证未通过，则禁止页面关闭或提示警告
        property int   validationErrorCount:           0//当前 UI 界面中有多少输入框校验失败，多用于防止用户在表单未填写完整时点击“确定”或“下一步”

        // Property to manage RemoteID quick access to settings page，是否从 RemoteID 入口跳转而来
        property bool  commingFromRIDIndicator:        false//表示当前页面是否是从 Remote ID 入口跳转过来的。标记从 Remote ID 页面进入，用于界面跳转。 - Remote ID：远程身份广播（FAA 要求），可能需要特殊界面
    }//这些变量都可以在其他 QML 页面中通过 globals.xxx 直接使用


    //Default color palette used throughout the UI 统一的配色方案
    //QGroundControl 的配色控制器，负责管理界面中各个控件的颜色风格（深色 / 浅色主题等，想统一更改界面风格颜色可以改QGCPalette 的定义或绑定的 colorGroupEnabled。
    //color: qgcPal.text
    //background: qgcPal.window
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    //-------------------------------------------------------------------------
    //-- Actions
    //QML 层声明的信号
    signal armVehicleRequest //请求解锁飞机（起飞准备）
    signal forceArmVehicleRequest// 强制解锁
    signal disarmVehicleRequest//请求上锁（停飞）
    signal vtolTransitionToFwdFlightRequest//VTOL 垂直起降机转换为固定翼飞行
    signal vtolTransitionToMRFlightRequest// 固定翼转为多旋翼
    signal showPreFlightChecklistIfNeeded// 请求显示飞行前检查清单
    //可以通过 emit signalName() 来触发它们，然后 C++ 那边监听这些信号进行对应动作
    //-------------------------------------------------------------------------
    //-- Global Scope Functions

    // This function is used to prevent view switching if there are validation errors
    //防止切换界面时用户输入未通过验证。
    //比如飞行参数没填完，就不能跳转页面
    function allowViewSwitch(previousValidationErrorCount = 0) {
        // Run validation on active focus control to ensure it is valid before switching views
        //Window::activeFocusControl 是 QtQuick.Window 模块中提供的一个内置属性
        //activeFocusControl: 指向当前具有输入焦点的 Item 对象。
        if (mainWindow.activeFocusControl instanceof FactTextField) //判断当前获得焦点的控件是否是 FactTextField（带验证的输入框）
        {
            //如果是，就主动调用它的 _onEditingFinished() 方法，触发验证逻辑
            mainWindow.activeFocusControl._onEditingFinished()
        }
        //然后通过 globals.validationErrorCount 检查是否允许切换视图
        return globals.validationErrorCount <= previousValidationErrorCount
    }


    //用于在“任务规划界面”与“飞行监视界面”之间切换。/
    //实现两个主界面的切换：flyView（飞行视图） 和 planView（任务规划视图）。这是主界面中“飞行”与“规划”两个 Tab 页之间的切换逻辑。
    //控制 flyView 和 planView 的显示状态。
    function showPlanView() {
        flyView.visible = false// // 隐藏飞行监视界面
        planView.visible = true//// 显示任务规划界面
       // viewer3DWindow.close()// // 关闭 3D 视图窗口（如果开启），好像是todo
    }
    function showFlyView() {
        flyView.visible = true//// 显示飞行监视界面
        planView.visible = false // 隐藏任务规划界面
    }




    //封装展示左侧工具抽屉的逻辑，传入标题、QML 页面路径和图标
    function showTool(toolTitle, toolSource, toolIcon) {

        //backIcon 依据当前是在飞行视图还是规划视图中决定使用哪种返回图标。
        toolDrawer.backIcon     = flyView.visible ? "/qmlimages/PaperPlane.svg" : "/qmlimages/Plan.svg"
        toolDrawer.toolTitle    = toolTitle//// 设置标题
        toolDrawer.toolSource   = toolSource // 设置页面路径
        toolDrawer.toolIcon     = toolIcon // 设置工具图标
        toolDrawer.visible      = true // 显示工具抽屉可见
    }


    //展示“数据分析”工具抽屉，加载页面为 AnalyzeView.qml
    function showAnalyzeTool() {
        showTool(qsTr("分析工具"), "AnalyzeView.qml", "/qmlimages/Analyze.svg")
    }





    //最后都是调用SetupView.qml里的方法
    //展示“飞行器设置”工具抽屉，加载页面为 SetupView.qml
    function showVehicleConfig() {
        showTool(qsTr("车辆配置"), "SetupView.qml", "/qmlimages/Gears.svg")
    }

    //这是一个“组合函数”，用于直接打开飞行器参数设置页，依赖 toolDrawerLoader.item 中的函数 showVehicleConfig设置的SetupView.qml里面的函数showParametersPanel()
    function showVehicleConfigParametersPage() {
        showVehicleConfig()
        toolDrawerLoader.item.showParametersPanel()
    }

    //打开“飞行器设置”工具面板（SetupView.qml），并跳转到某个具体的组件设置页（比如传感器、电源、飞行模式等）
    function showKnownVehicleComponentConfigPage(knownVehicleComponent) {
        showVehicleConfig()
        //这是 QGC 中用于根据标识查找某个“已知组件”的接口
        //返回值是某个继承自 VehicleComponent 的对象，比如：传感器、飞控等模块的配置类
        let vehicleComponent = globals.activeVehicle.autopilotPlugin.findKnownVehicleComponent(knownVehicleComponent)
        if (vehicleComponent) {
            //意思是调用加载后的 SetupView.qml 中的一个方法，传入 vehicleComponent 实例，让界面跳转到相应的配置子页
            toolDrawerLoader.item.showVehicleComponentPanel(vehicleComponent)
        }
    }






    //打开“应用设置”工具抽屉（AppSettings.qml），如果提供了具体设置页名（如 "Serial"），则自动跳转到那一页
    function showSettingsTool(settingsPage = "")
    //showTool(...) 会设置 toolDrawerLoader.source = "AppSettings.qml"，并展示左侧抽屉。
    {
        showTool(qsTr("Application Settings"), "AppSettings.qml", "/res/QGCLogoWhite.svg")
        //如果 settingsPage !== ""，则调用加载后页面的：
        if (settingsPage !== "")
        {
            toolDrawerLoader.item.showSettingsPage(settingsPage)
        }
    }



    //-------------------------------------------------------------------------
    //-- Global simple message dialog


    //弹出一个简易的提示框，比如用于提示错误、信息等
    //动态实例化一个 QML 组件（simpleMessageDialogComponent），配置对话框的标题、内容、按钮等属性，并打开对话框。
    //默认按钮是 Dialog.Ok
    //定义了一个可复用的“弹出对话框”机制，统一管理所有弹窗警告、提示、错误等信息的显示
    //动态创建对话框，设置标题、文本、按钮（如 OK / Cancel），设置点击确认或关闭时的回调函数，创建后立刻 .open() 弹出
    function showMessageDialog(dialogTitle, dialogText, buttons = Dialog.Ok, acceptFunction = null, closeFunction = null) {
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction, closeFunction: closeFunction }).open()
    }

    // This variant is only meant to be called by QGCApplication
    //这是一个对 showMessageDialog 的简化封装，用于从 C++ QGCApplication 层调用（通常用于错误提示）
    function _showMessageDialog(dialogTitle, dialogText) {
        showMessageDialog(dialogTitle, dialogText)
    }//这是一个内部封装的函数，专门用于展示消息对话框（如警告、错误等）



    //simpleMessageDialogComponent 是 QML 动态创建用的模板
    //这里定义了一个 Component 类型，它不会直接在 UI 中渲染，而是作为模板供 Qt.createComponent() / Qt.createQmlObject() 动态实例化使用
   //它只是一个组件模板，不会自动显示，用于后面 showMessageDialog函数等createObject(...) 动态创建
    Component {
        id: simpleMessageDialogComponent
//是 QGC 自定义的消息对话框，支持弹出文字提示，可能带有 OK/Cancel 按钮
        QGCSimpleMessageDialog {
            //// 内部样式、按钮、行为、颜色都由 QGC 自定义
        }
    }

    /// Saves main window position and size
    //这个组件用于保存 mainWindow 的位置和大小信息。退出时保存，在下次打开 QGC 时自动还原窗口状态
    MainWindowSavedState {
        window: mainWindow
    }

    property bool _forceClose: false //标记位，配合关闭流程使用
    //通过设置 _forceClose = true，确保即使某些检查没通过，也能强制关闭
    //完成退出的最后一步
    function finishCloseProcess() {
        _forceClose = true //强制关闭标记设为 true
        // For some reason on the Qml side Qt doesn't automatically disconnect a signal when an object is destroyed.
        // So we have to do it ourselves otherwise the signal flows through on app shutdown to an object which no longer exists.
        firstRunPromptManager.clearNextPromptSignal() //手动断开 firstRunPromptManager 的信号连接，防止退出时触发已被销毁对象的槽，这个是一个object，一些强制检查等
        QGroundControl.linkManager.shutdown() //停止所有通信链路
        QGroundControl.videoManager.stopVideo(); //停止视频流
        mainWindow.close() //关闭主窗口，触发退出
    }

    // Check for things which should prevent the app from closing
    //  Returns true if it is OK to close

    //  位掩码(Bitmask)工作原理
    // (1) 按位与(&)运算示例

    // 操作	二进制	结果	含义
    // 0x05 & 0x01	0101 & 0001	0001 (true)	跳过任务检查
    // 0x02 & 0x01	0010 & 0001	0000 (false)	不跳过任务检查
    // (2) 常用组合
    // 跳过所有检查
    // _closeChecksToSkip = 0x07  // 0111
    // // 仅跳过参数检查
    // _closeChecksToSkip = _skipPendingParameterWritesCheckMask // 0010
    // // 跳过任务和连接检查
    // _closeChecksToSkip = _skipUnsavedMissionCheckMask | _skipActiveConnectionsCheckMask // 0101

    //QGroundControl (QGC) 中用于在应用程序关闭前执行安全检查的逻辑，确保在关键操作未完成时阻止意外关闭
    //位掩码(bitmask)设计：每个检查项对应一个二进制位
    readonly property int _skipUnsavedMissionCheckMask: 0x01 //	跳过检查“未保存的任务”
    readonly property int _skipPendingParameterWritesCheckMask: 0x02 //跳过检查“参数写入”
    readonly property int _skipActiveConnectionsCheckMask: 0x04 //跳过检查“活跃链接”
    property int _closeChecksToSkip: 0 //默认行为：_closeChecksToSkip = 0 表示执行全部检查，初始不跳过任何检查

    //关闭前的检查，实现了三层次的安全检查，确保在以下情况下阻止应用关闭
    //检查跳过项由 _closeChecksToSkip 决定，是一个 bitmask
    function performCloseChecks() {
        //检查是否有未保存的任务（（航线规划））
        if (!(_closeChecksToSkip & _skipUnsavedMissionCheckMask) && !checkForUnsavedMission()) {
            return false
        }
        //检查是否有参数写入未完成（防止配置丢失）
        if (!(_closeChecksToSkip & _skipPendingParameterWritesCheckMask) && !checkForPendingParameterWrites()) {
            return false
        }
        //检查是否还有无人机连接，link是否还开着，避免意外断开
        if (!(_closeChecksToSkip & _skipActiveConnectionsCheckMask) && !checkForActiveConnections()) {
            return false
        }
        //同时提供跳过机制，允许在某些特殊情况下强制关闭。
        finishCloseProcess()//检查都通过，调用 finishCloseProcess 完成关闭
        return true
    }

    property string closeDialogTitle: qsTr("Close %1").arg(QGroundControl.appName)

    function checkForUnsavedMission()
    {
        if (planView._planMasterController.dirty) //判断当前 Mission 是否被修改但未保存，如果是，则提示用户：“关闭会丢失任务编辑，确定吗？”
        {

            //showMessageDialog(...) 是一个自定义弹窗，带有确认按钮
            showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              Dialog.Yes | Dialog.No,
                              function() { _closeChecksToSkip |= _skipUnsavedMissionCheckMask; performCloseChecks() })//用户点击“Yes”后，会跳过这个检查，继续执行 performCloseChecks()
            //如果所有检查都通过，就执行退出操作
            return false
        } else {
            return true
        }
    }

    //遍历所有连接的无人机
    function checkForPendingParameterWrites() {
        for (var index=0; index<QGroundControl.multiVehicleManager.vehicles.count; index++)
        {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites)//如果有参数变更尚未写入（pendingWrites == true）
            {
                //弹出提示，提醒用户：“参数未写入，关闭会丢失”
                mainWindow.showMessageDialog(closeDialogTitle,
                    qsTr("You have pending parameter updates to a vehicle. If you close you will lose changes. Are you sure you want to close?"),
                    Dialog.Yes | Dialog.No,
                    function() { _closeChecksToSkip |= _skipPendingParameterWritesCheckMask; performCloseChecks() })
                return false
            }
        }
        return true
    }

    //如果还有连接中的飞机（即 activeVehicle != null）
    function checkForActiveConnections() {
        if (QGroundControl.multiVehicleManager.activeVehicle)
        {
            //弹出提示：“还有飞机在连，确认要退出吗？”
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                Dialog.Yes | Dialog.No,
                function() { _closeChecksToSkip |= _skipActiveConnectionsCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    //	监听窗口关闭事件，close 是关闭事件对象，包含 .accepted 属性
    onClosing: (close) => {
        if (!_forceClose) //只有不是“强制关闭”时，才做检查， property bool _forceClose: false //标记位，配合关闭流程使用
        {
            _closeChecksToSkip = 0 //重置跳过项，确保每次关闭都是重新检查
            close.accepted = performCloseChecks() //是 Qt Quick 中窗口关闭流程的一部分：如果检查通过 → 允许关闭；否则拦截关闭
                       //如果是 false → 窗口保持不动（用户感觉“点了没反应”，其实是你拦住了）
        }
    }

    //设置主窗口背景
    background: Rectangle {
        anchors.fill:   parent //填充整个父容器
        color:   QGroundControl.globalPalette.window //使用 QGC 全局调色板的窗口底色，确保界面风格统一，支持主题切换
    }



    //任务规划视图，完整的任务规划、地理围栏和集结点管理功能
    // PlanView {
    //     id:             planView
    //     anchors.fill:   parent
    //     visible:        false //通过visible属性切换
    // }

    //底部状态栏
    //根据设置决定是否显示，FlyViewSettings.showLogReplayStatusBar
    //日志回放进度、状态信息等
    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }


    //弹出工具选择对话框
       //property bool panelShown: false
  //signal sideBarVisibleChanged(bool visible)//信号控制toolbar

    function showToolSelectDialog() {
        if (mainWindow.allowViewSwitch())//判断是否允许视图切换，可能用于避免在某些状态（如飞行中）切换视图
        {
            // flyView.showToolbar = false
            toolMenu.panelVisible = true


            //原来的
            //mainWindow.showIndicatorDrawer(toolSelectComponent, null)//showIndicatorDrawer() 是 mainWindow 的方法，用于弹出一个抽屉窗口或对话框。toolSelectComponent 是要显示的组件
            // 如果有规划视图，也可以一并隐藏
            //flyView.visible = false         // 隐藏飞行视图
            //planView.visible = false
        }
    }
    function closeToolPanel() {
        // 关闭自定义侧边面板
          //flyView.showToolbar = false
        toolMenu.panelVisible = false
        // 恢复主界面显示
        flyView.visible = true
        planView.visible = false
    }
    // Item {
    //     id: mainWindowRoot
    //     width: parent.width
    //     height: parent.height

        ToolMenu {
            id: toolMenu
            width: parent.width * 7 / 12
            toolMenuidheight: parent.height// - ScreenTools.toolbarHeight
           // toolMenuidheight: parent.height
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            z: 100
            panelVisible: false
        }

        // 遮罩层 + MouseArea
        Rectangle {
            id: overlay
            anchors.fill: parent
            color: "#00000066"
            visible: toolMenu.panelVisible
            opacity: toolMenu.panelVisible ? 1 : 0
            z: 99
            layer.enabled: true

            // Behavior on opacity {
            //     NumberAnimation {
            //         duration: 400
            //         easing.type: Easing.OutCubic
            //     }
            // }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                onClicked: (mouse) =>{
                    // 判断点击区域是否在 ToolMenu 内
                    const insideMenu = mouse.x > toolMenu.x &&
                                       mouse.y > toolMenu.y &&
                                       mouse.x < toolMenu.x + toolMenu.width &&
                                       mouse.y < toolMenu.y + toolMenu.height
                    if (!insideMenu) {
                        toolMenu.panelVisible = false
                    }
                }
            }
        }
    //}

    // // 遮罩层，动画效果
    // Rectangle {
    //     id: overlay
    //     anchors.fill: parent
    //     height:toolmenu.height
    //     width:toolmenu.width
    //     anchors.right:   parent.right
    //       anchors.bottom:   parent.bottom

    //     color: "#00000066"
    //     visible: toolmenu.panelVisible
    //     opacity: toolmenu.panelVisible ? 1 : 0
    //     z: 98
    //     layer.enabled: true

    //     Behavior on opacity {
    //         NumberAnimation {
    //             duration: 250
    //             easing.type: Easing.OutCubic
    //         }
    //     }

    //     MouseArea {
    //         anchors.fill: parent
    //         visible:toolmenu.panelVisible
    //         enabled: toolmenu.panelVisible
    //         z: toolmenu.toolPanel.z + 1
    //         propagateComposedEvents: true
    //         onClicked: (mouse) => {
    //             if (mouse.x < toolmenu.toolPantoolPanel.x) {
    //                 toolmenu.panelVisible = false
    //             }
    //         }
    //     }
    // }


//     Item {
//         id: rootItem
//         width: parent.width
//         height: parent.height



// //方案一
//         // toolPanel 外部的遮罩，只在 toolPanel 可见时启用
//        //  MouseArea {
//        //      anchors.fill: parent
//        //      visible: toolPanel.visible
//        //      enabled: toolPanel.visible
//        //      z: toolPanel.z - 1
//        //      propagateComposedEvents: true

//        //      onClicked: (mouse) => {
//        //          const clickX = mouse.x
//        //          const clickY = mouse.y
//        //          const panelLeft = toolPanel.x
//        //          const panelRight = toolPanel.x + toolPanel.width

//        //          if (clickX < panelLeft) {
//        //              // 如果要点击 panel 内也触发关闭，这里判断可以删掉
//        //              toolPanel.visible = false
//        //              flyView.visible = true
//        //              planView.visible = false
//        //          }
//        //      }
//        //  }

//        // // property
//        //  // 工具面板容器，从右滑出，占 2/3 宽度
//        //  Rectangle {
//        //      id: toolPanel
//        //      width: parent.width * 2 / 3
//        //      height: parent.height - ScreenTools.toolbarHeight//留出顶部toolbarview
//        //      anchors.right: parent.right
//        //       anchors.bottom: parent.bottom
//        //      visible: false
//        //      property alias  aliasSource:  toolLoader.source
//        //      z: 99
//        //      color:qgcPal.windowShade
//        //      x: visible ? parent.width - width : parent.width // 控制滑入滑出

//        //      // 动画
//        //      Behavior on x {
//        //          NumberAnimation {
//        //              duration: 250
//        //              easing.type: Easi    ng.OutQuad
//        //          }
//        //      }

//        //      // 内容加载 toolSelectComponent
//        //      Loader {
//        //          id: toolLoader
//        //          anchors.fill: parent
//        //          sourceComponent: toolSelectComponent
//        //      }


//        //  }



// //方案二
//             // // 背景遮罩，点击可关闭
//             // Rectangle {

//             //     id: overlay
//             //     anchors.fill: parent
//             //     color: "#00000066"

//             //     visible: toolPanel.panelShown
//             //     z: 98
//             //     Behavior on opacity { NumberAnimation { duration: 250 } }
//             //     opacity: toolPanel.panelShown ? 1 : 0

//             //     // MouseArea {
//             //     //     anchors.fill: parent
//             //     //     onClicked: {
//             //     //         panelShown = false
//             //     //         flyView.visible = true
//             //     //         planView.visible = false
//             //     //     }
//             //     // }
//             //      MouseArea {
//             //          anchors.fill: parent
//             //          // visible: toolPanel.visible
//             //          // enabled: toolPanel.visible
//             //          visible: toolPanel.panelShown
//             //         enabled: toolPanel.panelShown

//             //          z: toolPanel.z - 1
//             //          propagateComposedEvents: true

//             //          onClicked: (mouse) => {
//             //              const clickX = mouse.x
//             //              const clickY = mouse.y
//             //              const panelLeft = toolPanel.x
//             //              const panelRight = toolPanel.x + toolPanel.width

//             //              if (clickX < panelLeft) {
//             //                  // 如果要点击 panel 内也触发关闭，这里判断可以删掉
//             //                   toolPanel.panelShown = false
//             //                             //toolPanel.visible = false
//             //                  flyView.visible = true
//             //                  planView.visible = false
//             //              }

//             //          }
//             //      }
//             // }

//             // Rectangle {
//             //     id: toolPanel
//             //      property bool panelShown: false
//             //     width: parent.width * 2 / 3
//             //     height: parent.height - ScreenTools.toolbarHeight
//             //     anchors.bottom: parent.bottom
//             //     //anchors.right: parent.right
//             //     visible: internalVisible   // 控制真正渲染开关
//             //     opacity: panelShown ? 1 : 0
//             //     x: panelShown ? parent.width - width : parent.width
//             //     z: 99
//             //     color: qgcPal.windowShade

//             //     property bool internalVisible: false
//             //     property bool _componentLoaded: false

//             //     // onPanelShownChanged: {
//             //     //     if (panelShown) {
//             //     //         internalVisible = true
//             //     //         _componentLoaded = false
//             //     //         Qt.callLater(() => {
//             //     //             if (panelShown && !_componentLoaded) {
//             //     //                 toolLoader.sourceComponent = toolSelectComponent
//             //     //                 _componentLoaded = true
//             //     //             }
//             //     //         })
//             //     //     } else {
//             //     //         toolLoader.sourceComponent = null
//             //     //     }
//             //     // }
//             //     onPanelShownChanged: {
//             //         if (panelShown) {
//             //             internalVisible = true
//             //         }
//             //     }

//             //     Behavior on x { NumberAnimation { duration: 150 } }
//             //     Behavior on opacity {
//             //         NumberAnimation {
//             //             duration: 100
//             //             onStopped: {
//             //                 if (!panelShown) internalVisible = false
//             //             }
//             //         }
//             //     }

//             //     Loader {
//             //         id: toolLoader
//             //         anchors.fill: parent
//             //         sourceComponent: toolSelectComponent
//             //     }
//             // }
//         // 遮罩层
//            Rectangle {
//                id: overlay
//                anchors.fill: parent
//                color: "#00000066"
//                visible: toolPanel.panelShown
//                opacity: toolPanel.panelShown ? 1 : 0
//                z: 98
//                layer.enabled: true   // 开启图层缓存提升性能

//                Behavior on opacity {
//                    NumberAnimation {
//                        duration: 250
//                        easing.type: Easing.OutCubic
//                    }
//                }

//                MouseArea {
//                    anchors.fill: parent
//                    visible: toolPanel.panelShown
//                    enabled: toolPanel.panelShown
//                    z: toolPanel.z - 1
//                    propagateComposedEvents: true
//                    onClicked: (mouse) => {
//                        if (mouse.x < toolPanel.x) {
//                            toolPanel.panelShown = false
//                            flyView.visible = true
//                            planView.visible = false
//                        }
//                    }
//                }
//            }

//            Rectangle {
//                id: toolPanel
//                width: parent.width * 2 / 3
//                height: parent.height - ScreenTools.toolbarHeight//需要留出导航栏
//                anchors.bottom: parent.bottom
//                readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
//                readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
//                readonly property real _horizontalMargin:   _defaultTextWidth / 2
//                readonly property real _verticalMargin:     _defaultTextHeight / 2

//                color: qgcPal.windowShade
//                z: 99
//                layer.enabled: true   // 开启图层缓存提升性能

//                property bool panelShown: false
//                property bool internalVisible: false


//                visible: internalVisible
//                opacity: panelShown ? 1 : 0
//                x: panelShown ? parent.width - width : parent.width

//                // 面板横向滑动动画
//                Behavior on x {
//                    NumberAnimation {
//                        duration: 250
//                        easing.type: Easing.OutCubic
//                    }
//                }
//                // 面板透明度动画
//                Behavior on opacity {
//                    NumberAnimation {
//                        duration: 200
//                        easing.type: Easing.OutCubic
//                        onStopped: {
//                            if (!panelShown) internalVisible = false
//                        }
//                    }
//                }
//                MouseArea {
//                       anchors.fill: parent
//                       hoverEnabled: true
//                       propagateComposedEvents: true

//                       // 拦截滚轮事件，防止事件冒泡穿透
//                       onWheel: function(wheel) {
//                              wheel.accepted = true
//                          } // 吞掉事件，不让它传递下去
//                 }

//                onPanelShownChanged: {
//                    if (panelShown) {
//                        internalVisible = true
//                    }
//                }
//                RowLayout {
//                    anchors.fill: parent

//                    QGCFlickable {
//                        id: flick
//                        Layout.preferredWidth: toolLoader.item ? toolLoader.item.implicitWidth : parent.width / 2
//                        Layout.fillHeight: true
//                        clip: true
//                        flickableDirection: Flickable.VerticalFlick

//                        contentHeight: toolLoader.item ? toolLoader.item.implicitHeight + 20 : 0

//                        Loader {
//                            id: toolLoader
//                            anchors.fill: parent
//                            sourceComponent: toolSelectComponent
//                        }
//                    }

//                    Rectangle {
//                        id: divider
//                        width: 1
//                        color: "yellow"
//                        Layout.fillHeight: true
//                        height:parent.height
//                       // anchors.verticalCenter: parent.verticalCenter
//                        visible: toolLoader.item !== null
//                    }
//                }


//   }
//     //是一个半透明的浮动界面（抽屉），用来在主界面上方显示工具菜单
//     Component {
//         id: toolSelectComponent
//  //工具按钮菜单（由多个 SubMenuButton 构成），有共享的面板变量
//         ToolIndicatorPage {
//             id:         toolSelectDialog
//             //title:      qsTr("Select Tool")
//            Layout.preferredWidth: parent.width * 0.055  // 宽度大约 30%

//             property real _toolButtonHeight:    ScreenTools.defaultFontPixelHeight * 3
//             property real _margins:             ScreenTools.defaultFontPixelWidth

//      contentComponent: Component {
//                ColumnLayout {
//                     width:  innerLayout.width + (toolSelectDialog._margins * 2)
//                     height: innerLayout.height + (toolSelectDialog._margins * 2)

//                     ColumnLayout {
//                         id:             innerLayout
//                         Layout.margins: toolSelectDialog._margins
//                         spacing:        ScreenTools.defaultFontPixelWidth*10


//                         SubMenuButton {
//                             id:                 setupButton
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:                "" //qsTr("车辆配置")
//                             imageResource:      "/qmlimages/fly.svg"//"/qmlimages/Gears.svg"
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) {
//                                     mainWindow.closeToolPanel()
//                                     //mainWindow.closeIndicatorDrawer()
//                                     mainWindow.showVehicleConfig()// 打开飞控设置
//                                 }
//                             }
//                         }

//                         SubMenuButton {
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:                "" //qsTr("飞行计划")
//                             imageResource:       "/qmlimages/remote_control.svg"//"/qmlimages/Plan.svg"
//                             //Sourcesize
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) //防止切换界面时用户输入未通过验证。比如飞行参数没填完，就不能跳转页面
//                                 {
//                                     mainWindow.closeToolPanel()
//                                     //mainWindow.closeIndicatorDrawer()
//                                     mainWindow.showPlanView()// 打开任务规划
//                                 }
//                             }
//                         }

//                         SubMenuButton {
//                             id:                 analyzeButton
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:                "" //qsTr("Analyze Tools")
//                             imageResource:      "/qmlimages/signal.svg"//"/qmlimages/Analyze.svg"
//                             visible:            QGroundControl.corePlugin.showAdvancedUI
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) {
//                                     mainWindow.closeToolPanel()
//                                     //mainWindow.closeIndicatorDrawer()
//                                     mainWindow.showAnalyzeTool()// 打开分析工具
//                                 }
//                             }
//                         }


//                         SubMenuButton {
//                             id:                 settingsButton
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:              "" //qsTr("Application Settings")
//                             imageResource:     "/qmlimages/hd.svg"// "/res/QGCLogoFull.svg"
//                             imageColor:         "transparent"
//                             visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) {
//                                    mainWindow.closeToolPanel()
//                                     // drawer.close()
//                                     mainWindow.showSettingsTool() // 打开应用设置
//                                 }
//                             }
//                         }

//                         SubMenuButton {
//                             id:                 closeButton
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:                "" //qsTr("Close %1").arg(QGroundControl.appName)
//                             imageResource:      "/qmlimages/batterylogo.svg"//"/res/cancel.svg"
//                             visible:            mainWindow.visibility === Window.FullScreen
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) {
//                                     mainWindow.finishCloseProcess()// 全屏下关闭应用
//                                 }
//                             }
//                         }
//                         SubMenuButton {
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:                "" //qsTr("飞行计划")
//                             imageResource:      "/qmlimages/crama.svg"//"/qmlimages/Plan.svg"
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) //防止切换界面时用户输入未通过验证。比如飞行参数没填完，就不能跳转页面
//                                 {
//                                     mainWindow.closeToolPanel()
//                                     //mainWindow.closeIndicatorDrawer()
//                                     mainWindow.showPlanView()// 打开任务规划
//                                 }
//                             }
//                         }
//                         SubMenuButton {
//                             height:             toolSelectDialog._toolButtonHeight
//                             Layout.fillWidth:   true
//                             text:                "" //qsTr("飞行计划")
//                             imageResource:     "/qmlimages/common.svg"
//                             // "/qmlimages/Plan.svg"
//                             onClicked: {
//                                 if (mainWindow.allowViewSwitch()) //防止切换界面时用户输入未通过验证。比如飞行参数没填完，就不能跳转页面
//                                 {
//                                     mainWindow.closeToolPanel()
//                                     //mainWindow.closeIndicatorDrawer()
//                                     mainWindow.showPlanView()// 打开任务规划
//                                 }
//                             }
//                         }

//                         //标签版本号，以及显示可点击区域
//                         // ColumnLayout {
//                         //     width:                  innerLayout.width
//                         //     spacing:                0
//                         //     Layout.alignment:       Qt.AlignHCenter

//                         //     //显示当前应用名与版本号
//                         //     //这两个标签的 QGCMouseArea 上绑定了一个彩蛋交互区域（鼠标点击/长按）
//                         //     QGCLabel {
//                         //         id:                     versionLabel
//                         //         text:                   qsTr("%1 Version").arg(QGroundControl.appName)
//                         //         font.pointSize:         ScreenTools.smallFontPointSize
//                         //         wrapMode:               QGCLabel.WordWrap//wrapMode 是 QML 中 Text 或 Label 控件的属性，控制文本换行行为，Text.WrapAnywhere	任意位置断行（中文友好）
//                         //         Layout.maximumWidth:    parent.width
//                         //         Layout.alignment:       Qt.AlignHCenter
//                         //     }

//                         //     QGCLabel {
//                         //         text:                   QGroundControl.qgcVersion
//                         //         font.pointSize:         ScreenTools.smallFontPointSize
//                         //         wrapMode:               QGCLabel.WrapAnywhere //	任意位置断行（中文友好）
//                         //         Layout.maximumWidth:    parent.width
//                         //         Layout.alignment:       Qt.AlignHCenter


//                         //         // 彩蛋区域（鼠标交互）
//                         //         QGCMouseArea {
//                         //             id:                 easterEggMouseArea
//                         //             anchors.topMargin:  -versionLabel.height
//                         //             anchors.fill:       parent

//                         //             // Ctrl+点击 → 切换是否显示触控区域（调试用途）
//                         //             //鼠标长按也可以切换
//                         //             // Shift+点击 或移动端 → 弹出对话框，询问是否启用/关闭“高级模式
//                         //             onClicked: (mouse) => {
//                         //                 console.log("clicked")
//                         //                 if (mouse.modifiers & Qt.ControlModifier) // 切换 touch 区域调试
//                         //                 {
//                         //                     QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas//改变showTouchAreas的值，触发相应槽函数，显示可触控区域
//                         //                     showTouchAreasNotification.open()//告诉你已经切换了状态
//                         //                 } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) // 打开/关闭高级模式确认对话框适用于手机
//                         //                     {
//                         //                     if(!QGroundControl.corePlugin.showAdvancedUI) {
//                         //                         advancedModeOnConfirmation.open()
//                         //                     } else {
//                         //                         advancedModeOffConfirmation.open()
//                         //                     }
//                         //                 }
//                         //             }

//                         //             // This allows you to change this on mobile
//                         //             //在用户长按（Press and Hold）该区域时，切换 showTouchAreas 的布尔值，并弹出一个提示对话框
//                         //             onPressAndHold: {
//                         //                 QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
//                         //                 showTouchAreasNotification.open()
//                         //             }


//                         //             //用于提示 touch 区域已切换
//                         //             MessageDialog {
//                         //                 id:                 showTouchAreasNotification
//                         //                 title:              qsTr("Debug Touch Areas")
//                         //                 text:               qsTr("Touch Area display toggled")
//                         //                 buttons:            MessageDialog.Ok
//                         //             }

//                         //             //启用高级 UI 模式
//                         //             MessageDialog {
//                         //                 id:                 advancedModeOnConfirmation
//                         //                 title:              qsTr("Advanced Mode")
//                         //                 text:               QGroundControl.corePlugin.showAdvancedUIMessage
//                         //                 buttons:            MessageDialog.Yes | MessageDialog.No
//                         //                 //如果用户启用了高级模式，就会显示更多功能按钮
//                         //                 onButtonClicked: function (button, role) {
//                         //                     switch (button) {
//                         //                     case MessageDialog.Yes:
//                         //                         QGroundControl.corePlugin.showAdvancedUI = true
//                         //                         advancedModeOnConfirmation.close()
//                         //                         break;
//                         //                     }
//                         //                 }
//                         //             }

//                         //             //关闭高级 UI 模式
//                         //             MessageDialog {
//                         //                 id:                 advancedModeOffConfirmation
//                         //                 title:              qsTr("Advanced Mode")
//                         //                 text:               qsTr("Turn off Advanced Mode?")
//                         //                 buttons:            MessageDialog.Yes | MessageDialog.No
//                         //                 onButtonClicked: function (button, role) {
//                         //                     switch (button) {
//                         //                     case MessageDialog.Yes:
//                         //                         QGroundControl.corePlugin.showAdvancedUI = false
//                         //                         advancedModeOffConfirmation.close()
//                         //                         break;
//                         //                     case MessageDialog.No:
//                         //                         resetPrompt.close()
//                         //                         break;
//                         //                     }
//                         //                 }
//                         //             }
//                         //         }
//                         //     }
//                         // }
//                     //}
//                 }
//             }
//         }


//         // // 中间分割线
//         // Rectangle {
//         //     width: 1
//         //     color: "#888888"   // 分割线颜色
//         //     //Layout.fillWidth: true
//         //     Layout.fillHeight: true
//         // }

//         // // 右边内容区
//         // Item {
//         //     id: contentPanel
//         //     Layout.fillWidth: true
//         //     Layout.fillHeight: true
//         //     Rectangle
//         //     {
//         //      width: parent.width * 0.2
//         //       height: parent.height * 0.3
//         //     }

//         //     // 这里放右边显示的界面内容，根据左边按钮切换显示
//         // }
//     }
//    }
// }


    //QGroundControl 的左侧工具抽屉面板（Tool Drawer），是用于动态加载子工具页面的一个通用容器组件
    //点击某个按钮（如“Plan Flight”、“Analyze Tools”）时，主界面通过设置 toolDrawer.toolSource = xxx.qml 打开这个 Drawer 并加载目标页面
    //是 QML 内建控件 Drawer，侧边滑出式面板
    //它类似于对话框，但不会遮罩全屏，位置设置为：屏幕顶部中间一条横条
    //宽高设置为和 mainWindow 一样大
    //默认是关闭的（visible: false），不能通过手势打开，只能通过代码控制

        //目前我弃用这个布局
    Drawer {
        id:             toolDrawer
        width:          mainWindow.width
        height:         mainWindow.height
        edge:           Qt.LeftEdge
        dragMargin:     0
        closePolicy:    Drawer.NoAutoClose
        interactive:    false
        visible:        false

        //这些是为了接收调用者传入的参数，比如加载哪个页面、显示什么标题等
        property var backIcon
        property string toolTitle //toolTitle 会显示在标题栏
        property alias toolSource:  toolDrawerLoader.source  //toolSource 是对 Loader.source 的别名，供外部设置加载哪个 QML 页面
        property var toolIcon//toolIcon/backIcon 可用于添加图标

        // Unload the loader only after closed, otherwise we will see a "blank" loader in the meantime
        //当抽屉完全关闭时，清空 Loader 的 source
        onClosed: {
            toolDrawer.toolSource = ""
        }
        
        //工具栏标题栏
        //一个带背景色的矩形，用作顶部工具栏
        Rectangle {
            id:             toolDrawerToolbar
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         ScreenTools.toolbarHeight
            color:         "red"/* qgcPal.toolbarBackground*/

            //包含内容
            RowLayout {
                id:                 toolDrawerToolbarLayout
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left:       parent.left
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    font.pointSize: ScreenTools.largeFontPointSize
                    text:           "<" // 返回箭头
                }

                QGCLabel {
                    id:             toolbarDrawerText
                    text:           qsTr("返回") + " " + toolDrawer.toolTitle // 动态显示页面标题
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }

            //点击行为
            //点击整行（包括箭头和文字），关闭 Drawer
            QGCMouseArea {
                anchors.fill: toolDrawerToolbarLayout
                onClicked: {
                    if (mainWindow.allowViewSwitch()) {
                        toolDrawer.visible = false
                    }
                }
            }
        }

        //内容加载器：Loader + 信号监听
        //用于按需动态加载 QML 文件（即 showTool() 中的 toolSource）
        //Loader 是一个特殊的 QML 类型，它一旦设置了 source，就会立即自动加载对应的 QML 文件，不需要手动调用 .load()。
        //因为 Loader 每次只加载一个 QML 页面，toolDrawerLoader.item 始终指向当前加载的那一个页面
        Loader {
            id:             toolDrawerLoader
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    toolDrawerToolbar.bottom//上边界与 toolDrawerToolbar.bottom 对齐
            anchors.bottom: parent.bottom //这个 parent 是 toolDrawer，表示这个 Loader 是抽屉中的内容部分

            Connections {
                target:                 toolDrawerLoader.item //指向当前加载的子页面对象
                ignoreUnknownSignals:   true //表示如果当前 item 没有 onPopout 信号，也不会报错
                //Popout是一个信号
                onPopout:               toolDrawer.visible = false //信号被触发时，执行 toolDrawer.visible = false，即关闭左侧工具抽屉
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup
//property bool muteCriticalPopup:true
    function showCriticalVehicleMessage(message) //控制何时弹出
    {
        // if (muteCriticalPopup) {
        //         console.log("静音中，跳过弹窗:", message)
        //         return
        //     }

        closeToolPanel()//如果有警告，没办法打开设置界面
        //closeIndicatorDrawer()//如果有警告，没办法打开设置界面
        //如果当前弹窗已显示，或处于全屏模式，不会马上弹出新消息，而是标记为还有额外警告
        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
            // We received additional warning message while an older warning message was still displayed.
            // When the user close the older one drop the message indicator tool so they can see the rest of them.
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = true
        }
        else //否则：显示这条警告
        {
            criticalVehicleMessagePopup.criticalVehicleMessage      = message
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false
            criticalVehicleMessagePopup.open()
        }
    }



    //是 Qt Quick Controls 2 提供的一个 UI 组件类型
    //Popup 是一个可弹出的临时界面元素，常用于提示、菜单、对话框等
    // QGroundControl 用于弹出关键飞行器警告（Critical Vehicle Message）的 Popup 组件
    //当飞行器出现重要错误或警报（如 GPS 信号丢失、电池故障等）时，就会弹出这个界面，通知用户并引导后续操作
    //当飞行器发生严重故障时，这个 Popup 会显示错误信息，并提供点击关闭的机制，如果有多个错误，还会提示“Additional errors received”
    Popup {
        id:                 criticalVehicleMessagePopup
        y:                  ScreenTools.toolbarHeight + ScreenTools.defaultFontPixelHeight
        x:                  Math.round((mainWindow.width - width) * 0.5)
        width:              mainWindow.width  * 0.5
        height:             criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal:              false
        focus:              true
    Component.onCompleted: console.log("criticalVehicleMessagePopup.parent",criticalVehicleMessagePopup.parent) // 输出 true


    property alias  criticalVehicleMessage:             criticalVehicleMessageText.text
    property bool   additionalCriticalMessagesReceived: false

        //背景：Rectangle + 带圆角和边框
        background: Rectangle {
            anchors.fill:   parent
            color:          "blue"//qgcPal.alertBackground
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            border.color:   "blue"//qgcPal.alertBorder
            border.width:   2

            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.top:                parent.top
                anchors.topMargin:          -(height / 2) //把元素向上移动自身高度的一半
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:                "blue"//qgcPal.alertBorder
                border.width:               3
                width:                      vehicleWarningLabel.contentWidth + _margins
                height:                     vehicleWarningLabel.contentHeight + _margins

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                //静态文字 "Vehicle Error"，提示是系统级故障
                QGCLabel {
                    id:                 vehicleWarningLabel
                    //anchors.centerIn:   criticalVehicleMessagePopup.parent
                    anchors.centerIn:   parent
                    text:               qsTr("系统级飞行器异常")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }

            Rectangle {
                id:                         additionalErrorsIndicator
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.bottom:             parent.bottom
                anchors.bottomMargin:       -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               "blue"// qgcPal.alertBorder
                border.width:               1
                width:                      additionalErrorsLabel.contentWidth + _margins
                height:                     additionalErrorsLabel.contentHeight + _margins
                visible:                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                //底部：额外错误提示（只在有额外消息时出现）。当还有新错误时显示这个提示，引导用户继续查看
                QGCLabel {
                    id:                 additionalErrorsLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Additional errors received")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }
        }

        //显示具体错误内容，内容由showCriticalVehicleMessage方法设置
        QGCLabel {
            id:                 criticalVehicleMessageText
            width:              criticalVehicleMessagePopup.width - ScreenTools.defaultFontPixelHeight
            anchors.centerIn:   parent
            wrapMode:           Text.WordWrap
            color:              qgcPal.alertText
            textFormat:         TextEdit.RichText //textFormat: RichText 支持 HTML 样式（如 <b>、<br>）
        }


        //点击整个弹窗后关闭
        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.additionalCriticalMessagesReceived)
                {
                    //如果还有更多错误 → 调用 flyView.dropMainStatusIndicatorTool()（提示继续查看）
                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false;
                    flyView.dropMainStatusIndicatorTool();
                } else  //否则 → 重置当前车辆的错误信息状态
                {
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Drawer

    // 外部调用这个函数时，会：
    // 设置要加载的组件 sourceComponent
    // 设置定位基准 indicatorItem
    // 打开 Popup
    function showIndicatorDrawer(drawerComponent, indicatorItem)
    {
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.indicatorItem = indicatorItem //用于计算弹窗横坐标位置（Popup 会贴近这个 Item）
        indicatorDrawer.open()
    }


    //关闭面板
    function closeIndicatorDrawer() {
        indicatorDrawer.close()
    }

    //弹出的侧边小面板 Popup（Indicator Drawer），用于临时展示某个工具（如图层选择、工具菜单），带自动布局定位、加载任意组件、可点击扩展
    Popup {
        id:             indicatorDrawer
        x:              calcXPosition()
        y:              ScreenTools.toolbarHeight + _margins //是顶部工具栏的高度
        leftInset:      0
        rightInset:     0
        topInset:       0
        bottomInset:    0
        padding:        _margins * 2
        visible:        false //默认隐藏
        modal:          true //模态弹窗（阻止底层点击）
        focus:          true //获得焦点
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside//点击外部或 ESC 关闭
        dim:            false //// 背景不变暗

        property var sourceComponent //两个属性由 showIndicatorDrawer(...) 设置，供 Loader 和布局使用
        property var indicatorItem

        property bool _expanded:    false //控制是否展开（用于 UI 扩展按钮）
        property real _margins:     ScreenTools.defaultFontPixelHeight / 4 //控制边距和圆角


        //动态计算 Popup 横向位置，也就是x坐标
        function calcXPosition()
        {
            if (indicatorItem)
            {
                var xCenter = indicatorItem.mapToItem(mainWindow.contentItem, indicatorItem.width / 2, 0).x //获取 indicatorItem 横向中心坐标 xCenter
                //使 Drawer 居中于它（xCenter - drawer 宽度 / 2）且防止越界（用 Math.max 和 Math.min 处理）
                return Math.max(_margins, Math.min(xCenter - (contentItem.implicitWidth / 2), mainWindow.contentItem.width - contentItem.implicitWidth - _margins - (indicatorDrawer.padding * 2) - (ScreenTools.defaultFontPixelHeight / 2)))
            } else {
                return _margins
            }
        }

        onOpened: {
            _expanded                               = false;
            indicatorDrawerLoader.sourceComponent   = indicatorDrawer.sourceComponent
        }
        onClosed: {
            _expanded                               = false
            indicatorItem                           = undefined
            indicatorDrawerLoader.sourceComponent   = undefined
        }


        background: Item {
            Rectangle {
                id:             backgroundRect
                anchors.fill:   parent
                color:          QGroundControl.globalPalette.window
                radius:         indicatorDrawer._margins
                opacity:        0.8
            }

            Rectangle {
                //// 小圆按钮：用于展开。半透明灰色背景
                anchors.horizontalCenter:   backgroundRect.right
                anchors.verticalCenter:     backgroundRect.top
                width:                      ScreenTools.largeFontPixelHeight//*1.35
                height:                     width
                radius:                     width / 2
                color:                      Qt.rgba(0, 0, 0, 0.65)/*QGroundControl.globalPalette.button*/
                //border.color:               QGroundControl.globalPalette.buttonText
                visible:                    indicatorDrawerLoader.item && indicatorDrawerLoader.item.showExpand && !indicatorDrawer._expanded

                QGCLabel {
                    //可选的右上角扩展按钮 >，点击后设置 _expanded = true
                    anchors.centerIn:   parent
                    text:               "<"
                    color:              QGroundControl.globalPalette.buttonText
                }  

                QGCMouseArea {
                    //fillItem: indicatorDrawer.parent
                    fillItem: parent
                    onClicked: indicatorDrawer._expanded = true
                }
            }
        }


        //可以滚动，它内部的 Loader 会加载指定组件（sourceComponent）
        contentItem: QGCFlickable {
            id:             indicatorDrawerLoaderFlickable
            implicitWidth:  Math.min(mainWindow.contentItem.width - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.width)
            implicitHeight: Math.min(mainWindow.contentItem.height - ScreenTools.toolbarHeight - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.height)
            contentWidth:   indicatorDrawerLoader.width
            contentHeight:  indicatorDrawerLoader.height

            //Loader 加载内容组件
            Loader {
                id: indicatorDrawerLoader

                //并将两个属性绑定进去，这样子组件就可以访问到 drawer 和 expanded 状态
                Binding {
                    //expanded 绑定：让加载的组件能响应“展开”状态
                    target:     indicatorDrawerLoader.item
                    property:   "expanded"
                    value:      indicatorDrawer._expanded
                }

                //drawer 绑定：让加载组件能引用 indicatorDrawer 本体（如用于调用 close 等）
                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "drawer"
                    value:      indicatorDrawer
                }
            }
        }
    }

    // We have to create the popup windows for the Analyze pages here so that the creation context is rooted
    // to mainWindow. Otherwise if they are rooted to the AnalyzeView itself they will die when the analyze viewSwitch
    // closes.
//动态创建：运行时通过createObject()实例化窗口
    function createrWindowedAnalyzePage(title, source) {
        var windowedPage = windowedAnalyzePage.createObject(mainWindow)
        windowedPage.title = title  // 设置窗口标题
        windowedPage.source = source// 设置加载的QML文件路径
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width:      ScreenTools.defaultFontPixelWidth  * 100
            height:     ScreenTools.defaultFontPixelHeight * 40
            visible:    true

            property alias source: loader.source// 暴露加载接口

            Rectangle {
                color:          QGroundControl.globalPalette.window
                anchors.fill:   parent

                Loader {
                    id:             loader
                    anchors.fill:   parent
                    onLoaded:       item.popped = true  // 加载完成后标记为弹出状态
                }
            }

            onClosing: {
                visible = false // 隐藏而非销毁
                source = "" // 清空内容
            }
        }
    }

    Connections{
         target: activationbar
         function onActivationTriggered(value){
              _utmspSendActTrigger= value// 转发激活触发信号，是内部信号标记，用于控制 UTMSP 激活流程
         }
    }

    //UTMSP激活状态栏，无人机交通管理服务模块
    // 空域合规性检查：确保飞行计划符合当地空管规定
    // 实时授权管理：与空管系统通信获取飞行许可
    // 应急响应：处理突发空域管制指令
    UTMSPActivationStatusBar{
         id:                         activationbar
         activationStartTimestamp:   UTMSPStateStorage.startTimeStamp// 绑定激活开始时间，从状态存储获取
         activationApproval:         UTMSPStateStorage.showActivationTab && QGroundControl.utmspManager.utmspVehicle.vehicleActivation// 激活状态，取决于UTMSP管理器和车辆状态
         flightID:                   UTMSPStateStorage.flightID// 绑定飞行ID。当前飞行任务标识
         anchors.fill:               parent// 充满父容器
    }
}
