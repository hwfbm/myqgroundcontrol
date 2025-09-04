import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QGroundControl 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0

Item {
    id: toolMenuid
    //z:      QGroundControl.zOrderTopMost
 property alias toolMenuidheight:     toolMenuid .height
    property alias panelVisible: toolPanel.panelShown // 这里定义 alias
    property alias panelx: toolPanel.x // 这里定义 alias
    property alias panelz: toolPanel.z // 这里定义 alias
    //readonly property alias winheight:overlay.height
    //readonly property alias winwidth:overlay.width
    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
      readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
      readonly property real _horizontalMargin:   _defaultTextWidth / 2
      readonly property real _verticalMargin:     _defaultTextHeight
    readonly property real itemheight:     toolMenuid .height
    property bool _first: true

   // 遮罩层
    Rectangle {
        id: overlay
         anchors.fill: parent
        color: "#00000066"
        visible: toolPanel.panelShown
        opacity: toolPanel.panelShown ? 1 : 0
        z: 98
        layer.enabled: true

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // MouseArea {
        //     anchors.fill: parent
        //     visible: toolPanel.panelShown
        //     enabled: toolPanel.panelShown
        //     z: toolPanel.z + 1
        //     propagateComposedEvents: true
        //     onClicked: (mouse) => {
        //         if (mouse.x < toolPanel.x) {
        //             toolPanel.panelShown = false
        //         }
        //     }
        // }
    }
    Rectangle {
        id: toolPanel
        width: parent.width
        height: parent.height
        anchors.top: parent.top
        //anchors.right: parent.right
         anchors.bottom: parent.bottom
        color: Qt.rgba(0, 0, 0, 0.65)//qgcPal.windowShade
        z: 99
        layer.enabled: true

        property bool panelShown: false
        property bool internalVisible: false

        visible: internalVisible
        x: toolMenuid.width

        // 初始化显示逻辑
        onPanelShownChanged: {
            if (panelShown) {
                internalVisible = true
            }
        }

        // 结束动画后隐藏
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
                onStopped: {
                    if (!panelShown) {
                        internalVisible = false
                    }
                }
            }
        }

        // 使用 states 代替 x 绑定
        states: [
            State {
                name: "shown"
                when: toolPanel.panelShown
                PropertyChanges {
                    target: toolPanel
                    x: toolMenuid.width - toolPanel.width
                    opacity: 1
                }
            },
            State {
                name: "hidden"
                when: !toolPanel.panelShown
                PropertyChanges {
                    target: toolPanel
                    x: toolMenuid.width
                    opacity: 0
                }
            }
        ]

        // transitions: [
        //     Transition {
        //         from: "hidden"
        //         to: "shown"
        //         NumberAnimation {
        //             properties: "x"
        //             duration: 300
        //             easing.type: Easing.InOutCubic
        //         }
        //     },
        //     Transition {
        //         from: "shown"
        //         to: "hidden"
        //         NumberAnimation {
        //             properties: "x"
        //             duration: 300
        //             easing.type: Easing.InOutCubic
        //         }
        //     }
        // ]
        transitions: [
            Transition {
                from: "hidden"
                to: "shown"
                NumberAnimation { properties: "x, opacity"; duration: 250; easing.type: Easing.InOutCubic }
            },
            Transition {
                from: "shown"
                to: "hidden"
                NumberAnimation { properties: "x, opacity"; duration: 250; easing.type: Easing.InOutCubic }
            }
        ]


       // onPanelShownChanged: internalVisible = true
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onWheel: function(wheel) {
                wheel.accepted = true
            }
        }


        //默认加载界面
        Component.onCompleted: {

                rightPanel.source =  "/qml/AppSettings.qml"
        }

        // QGCFlickable {
        //     id: flick
        //     indicatorColor:"transparent"
        //     width: toolSelectDialog.width
        //     height:toolSelectDialog.height
        //     anchors.topMargin:  _verticalMargin
        //     anchors.top:        parent.top
        //     anchors.bottom:     parent.bottom
        //     anchors.leftMargin: _horizontalMargin
        //     anchors.left:       parent.left
        //    contentHeight: toolSelectDialog.height/*+ _verticalMargin*/
        //     flickableDirection: Flickable.VerticalFlick
        //     clip: true

    //  RowLayout{
          // anchors.top:parent.top
          //   anchors.bottom:parent.bottom+1000
          // width: toolPanel.width * 0.1
          // spacing:  ScreenTools.defaultFontPixelHeight * 2


            // Item {
            //     id: contentContainer
            //     width: toolPanel.width * 0.045
            //     height: toolLoader.item.implicitHeight  // ⭐ 重要：撑开容器高度

            //     Loader {
            //         id: toolLoader

            //         sourceComponent: toolSelectComponent
            //     }

            // }
        Item{

            anchors.topMargin:  _verticalMargin
            anchors.bottomMargin:  _verticalMargin
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            id:toolSelectDialogvector
            width:toolSelectDialog.width


            ToolIndicatorPage {
            id:         toolSelectDialog
            height:itemheight



            //title:      qsTr("Select Tool")
          // Layout.preferredWidth: parent.width * 0.055  // 宽度大约 30%
         //width: parent.width * 0.055
            property real _toolButtonHeight:    ScreenTools.defaultFontPixelHeight * 3
            property real _margins:             ScreenTools.defaultFontPixelWidth
            // 定义当前页面变量
            property string currentPage: ""
     contentComponent: Component {
               // ColumnLayout {
               //      width:  innerLayout.width + (toolSelectDialog._margins * 2)
               //      height: innerLayout.height + (toolSelectDialog._margins * 2)

                    ColumnLayout {
                        id:             innerLayout
                       // Layout.margins: toolSelectDialog._margins



                        // spacing:        ScreenTools.defaultFontPixelWidth*10
                        // spacing: Qt.platform.os === "windows" ? ScreenTools.defaultFontPixelWidth * 25:
                        //          Qt.platform.os === "macos" ? ScreenTools.defaultFontPixelWidth *10 :
                        //          ScreenTools.defaultFontPixelWidth * 10

                        // spacing: Screen.pixelDensity * 20
                        spacing:  toolSelectDialog.height * 0.04
                        // 间距为父容器宽度的 5%


                        // SubMenuButton {
                        //     id:                 setupButton
                        //     height:             toolSelectDialog._toolButtonHeight
                        //     Layout.fillWidth:   true
                        //     text:                "" //qsTr("车辆配置")
                        //     imageResource:      "/qmlimages/fly.svg"//"/qmlimages/Gears.svg"
                        //     onClicked: {
                        //         if (mainWindow.allowViewSwitch()) {
                        //             if (rightPanel.source !== "/qml/SetupView.qml") {
                        //                 rightPanel.source = "/qml/SetupView.qml"
                        //                 checked = true
                        //             }
                        //         }
                        //     checked=false }
                        // }

                        SubMenuButton {
                            id: setupButton
                            height: toolSelectDialog._toolButtonHeight
                            Layout.fillWidth: true
                            text: "" //qsTr("车辆配置")
                            //imageColor:
                            imageResource: "/qmlimages/fly.svg" //"/qmlimages/Gears.svg"
                            checked: toolSelectDialog.currentPage === "/qml/SetupView.qml" // 当 currentPage 是当前页面时，checked 为 true
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    if (toolSelectDialog.currentPage !== "/qml/SetupView.qml") {
                                        rightPanel.source = "/qml/SetupView.qml"
                                        toolSelectDialog.currentPage = "/qml/SetupView.qml" // 更新 currentPage
                                    }
                                }
                            }
                        }

                        SubMenuButton {
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:                ""
                            imageResource:       "/qmlimages/remote_control.svg"//"/qmlimages/Plan.svg"
                            //Sourcesize
                            // onClicked: {
                            //     if (mainWindow.allowViewSwitch()) //防止切换界面时用户输入未通过验证。比如飞行参数没填完，就不能跳转页面
                            //     {
                            //         if (rightPanel.source !=="/qml/PlanView.qml" ) {
                            //             rightPanel.source = "/qml/PlanView.qml"

                            //         }
                            //         else if(rightPanel.source !=="/qml/PlanView.qml" )
                            //              { checked = false}



                            //     }
                            // }
                                                 //qml/TelemetrySettings.qml通信连接
                            checked: toolSelectDialog.currentPage === "/qml/RadioComponent.qml" // 当 currentPage 是当前页面时，checked 为 true
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    if (toolSelectDialog.currentPage !== "/qml/RadioComponent.qml") {
                                        rightPanel.source = "/qml/RadioComponent.qml"
                                        toolSelectDialog.currentPage = "/qml/RadioComponent.qml" // 更新 currentPage
                                    }
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 analyzeButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:                "" //qsTr("Analyze Tools")
                            imageResource:      "/qmlimages/signal.svg"//"/qmlimages/Analyze.svg"
                            visible:            QGroundControl.corePlugin.showAdvancedUI
                            // onClicked: {
                            //     if (mainWindow.allowViewSwitch()) {
                            //         // mainWindow.closeToolPanel()
                            //         // //mainWindow.closeIndicatorDrawer()
                            //          //mainWindow.showAnalyzeTool()// 打开分析工具
                            //         if (rightPanel.source !=="/qml/AnalyzeView.qml" ) {
                            //             rightPanel.source = "/qml/AnalyzeView.qml"

                            //         }
                            //         else if(rightPanel.source !=="/qml/AnalyzeView.qml" )
                            //              { checked = false}



                            //     }
                            // }
                            checked: toolSelectDialog.currentPage === "/qml/AnalyzeView.qml" // 当 currentPage 是当前页面时，checked 为 true
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    if (toolSelectDialog.currentPage !== "/qml/AnalyzeView.qml") {
                                        rightPanel.source = "/qml/AnalyzeView.qml"
                                        toolSelectDialog.currentPage = "/qml/AnalyzeView.qml" // 更新 currentPage
                                    }
                                }
                            }
                        }


                        //图传
                        SubMenuButton {
                            id:                 settingsButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:              ""
                            imageResource:     "/qmlimages/hd.svg"
                            imageColor:         "transparent"
                            // checked: toolSelectDialog.currentPage === "/toolbar/GimbalSetting.qml" // 当 currentPage 是当前页面时，checked 为 true
                            // onClicked: {
                            //     if (mainWindow.allowViewSwitch()) {
                            //         if (toolSelectDialog.currentPage !== "/toolbar/GimbalSetting.qml") {
                            //             rightPanel.source = "/toolbar/GimbalSetting.qml"
                            //             toolSelectDialog.currentPage = "/toolbar/GimbalSetting.qml" // 更新 currentPage
                            //         }
                            //     }
                            // }
                        }
                       //电池
                        SubMenuButton {
                            id:                 closeButton
                            height:             toolSelectDialog._toolButtonHeight

                            Layout.fillWidth:   true
                            text:                "" //qsTr("Close %1").arg(QGroundControl.appName)
                            imageResource:      "/qmlimages/batterylogo.svg"//"/res/cancel.svg"
                            visible:            mainWindow.visibility === Window.FullScreen
                            checked: toolSelectDialog.currentPage === "/qml/QGroundControl/Controls/Batterysettingshow.qml" // 当 currentPage 是当前页面时，checked 为 true
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    if (toolSelectDialog.currentPage !== "/qml/QGroundControl/Controls/Batterysettingshow.qml") {
                                        rightPanel.source = "/qml/QGroundControl/Controls/Batterysettingshow.qml"
                                        toolSelectDialog.currentPage = "/qml/QGroundControl/Controls/Batterysettingshow.qml" // 更新 currentPage
                                    }
                                }
                            }
                        }
                        //云台
                        SubMenuButton {
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:                "" //qsTr("飞行计划")
                            imageResource:      "/qmlimages/crama.svg"//"/qmlimages/Plan.svg"
                            checked: toolSelectDialog.currentPage === "/toolbar/GimbalSetting.qml" // 当 currentPage 是当前页面时，checked 为 true
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    if (toolSelectDialog.currentPage !== "/toolbar/GimbalSetting.qml") {
                                        rightPanel.source = "/toolbar/GimbalSetting.qml"
                                        toolSelectDialog.currentPage = "/toolbar/GimbalSetting.qml" // 更新 currentPage
                                    }
                                }
                            }
                        }
                        SubMenuButton {
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:                "" //qsTr("飞行计划")
                            imageResource:     "/qmlimages/common.svg"
                            // "/qmlimages/Plan.svg"
                            // onClicked: {

                            //         // mainWindow.closeToolPanel()
                            //         // //mainWindow.closeIndicatorDrawer()
                            //         // mainWindow.showPlanView()// 打开任务规划
                            //         if (mainWindow.allowViewSwitch()) {
                            //             if (rightPanel.source !=="/qml/AppSettings.qml" ) {
                            //                 rightPanel.source = "/qml/AppSettings.qml"
                            //                 checked = true// 打开应用设置
                            //             }

                            //         }checked=false

                            // }
                            checked: toolSelectDialog.currentPage === "/qml/AppSettings.qml" // 当 currentPage 是当前页面时，checked 为 true
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    if (toolSelectDialog.currentPage !== "/qml/AppSettings.qml") {
                                        rightPanel.source = "/qml/AppSettings.qml"
                                        toolSelectDialog.currentPage = "/qml/AppSettings.qml" // 更新 currentPage
                                    }
                                }
                            }
                        }



                        //标签版本号，以及显示可点击区域
                        // ColumnLayout {
                        //     width:                  innerLayout.width
                        //     spacing:                0
                        //     Layout.alignment:       Qt.AlignHCenter

                        //     //显示当前应用名与版本号
                        //     //这两个标签的 QGCMouseArea 上绑定了一个彩蛋交互区域（鼠标点击/长按）
                        //     QGCLabel {
                        //         id:                     versionLabel
                        //         text:                   qsTr("%1 Version").arg(QGroundControl.appName)
                        //         font.pointSize:         ScreenTools.smallFontPointSize
                        //         wrapMode:               QGCLabel.WordWrap//wrapMode 是 QML 中 Text 或 Label 控件的属性，控制文本换行行为，Text.WrapAnywhere	任意位置断行（中文友好）
                        //         Layout.maximumWidth:    parent.width
                        //         Layout.alignment:       Qt.AlignHCenter
                        //     }

                        //     QGCLabel {
                        //         text:                   QGroundControl.qgcVersion
                        //         font.pointSize:         ScreenTools.smallFontPointSize
                        //         wrapMode:               QGCLabel.WrapAnywhere //	任意位置断行（中文友好）
                        //         Layout.maximumWidth:    parent.width
                        //         Layout.alignment:       Qt.AlignHCenter


                        //         // 彩蛋区域（鼠标交互）
                        //         QGCMouseArea {
                        //             id:                 easterEggMouseArea
                        //             anchors.topMargin:  -versionLabel.height
                        //             anchors.fill:       parent

                        //             // Ctrl+点击 → 切换是否显示触控区域（调试用途）
                        //             //鼠标长按也可以切换
                        //             // Shift+点击 或移动端 → 弹出对话框，询问是否启用/关闭“高级模式
                        //             onClicked: (mouse) => {
                        //                 console.log("clicked")
                        //                 if (mouse.modifiers & Qt.ControlModifier) // 切换 touch 区域调试
                        //                 {
                        //                     QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas//改变showTouchAreas的值，触发相应槽函数，显示可触控区域
                        //                     showTouchAreasNotification.open()//告诉你已经切换了状态
                        //                 } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) // 打开/关闭高级模式确认对话框适用于手机
                        //                     {
                        //                     if(!QGroundControl.corePlugin.showAdvancedUI) {
                        //                         advancedModeOnConfirmation.open()
                        //                     } else {
                        //                         advancedModeOffConfirmation.open()
                        //                     }
                        //                 }
                        //             }

                        //             // This allows you to change this on mobile
                        //             //在用户长按（Press and Hold）该区域时，切换 showTouchAreas 的布尔值，并弹出一个提示对话框
                        //             onPressAndHold: {
                        //                 QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                        //                 showTouchAreasNotification.open()
                        //             }


                        //             //用于提示 touch 区域已切换
                        //             MessageDialog {
                        //                 id:                 showTouchAreasNotification
                        //                 title:              qsTr("Debug Touch Areas")
                        //                 text:               qsTr("Touch Area display toggled")
                        //                 buttons:            MessageDialog.Ok
                        //             }

                        //             //启用高级 UI 模式
                        //             MessageDialog {
                        //                 id:                 advancedModeOnConfirmation
                        //                 title:              qsTr("Advanced Mode")
                        //                 text:               QGroundControl.corePlugin.showAdvancedUIMessage
                        //                 buttons:            MessageDialog.Yes | MessageDialog.No
                        //                 //如果用户启用了高级模式，就会显示更多功能按钮
                        //                 onButtonClicked: function (button, role) {
                        //                     switch (button) {
                        //                     case MessageDialog.Yes:
                        //                         QGroundControl.corePlugin.showAdvancedUI = true
                        //                         advancedModeOnConfirmation.close()
                        //                         break;
                        //                     }
                        //                 }
                        //             }

                        //             //关闭高级 UI 模式
                        //             MessageDialog {
                        //                 id:                 advancedModeOffConfirmation
                        //                 title:              qsTr("Advanced Mode")
                        //                 text:               qsTr("Turn off Advanced Mode?")
                        //                 buttons:            MessageDialog.Yes | MessageDialog.No
                        //                 onButtonClicked: function (button, role) {
                        //                     switch (button) {
                        //                     case MessageDialog.Yes:
                        //                         QGroundControl.corePlugin.showAdvancedUI = false
                        //                         advancedModeOffConfirmation.close()
                        //                         break;
                        //                     case MessageDialog.No:
                        //                         resetPrompt.close()
                        //                         break;
                        //                     }
                        //                 }
                        //             }
                        //         }
                        //     }
                        // }
                    //}
                }
          //  }
        }
       }
        }

       // }//flisk的
        Rectangle {
            id: divider
            width: 1
            anchors.topMargin:      _verticalMargin
            anchors.bottomMargin:   _verticalMargin
            anchors.leftMargin:     _horizontalMargin
            anchors.left:           toolSelectDialogvector.right//flick.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            //height:parent.height+1000 //超过滑条高度
            color: "#888888"



            //anchors.leftMargin: _horizontalMargin*3   // 90%宽度+两边margin
        }


        //-- Panel Contents
        Loader {
            id:                     rightPanel
            anchors.leftMargin:     _horizontalMargin
            anchors.rightMargin:    _horizontalMargin
            anchors.topMargin:      /*_verticalMargin//*/ScreenTools.toolbarHeight//露出toolbar
            anchors.bottomMargin:   _verticalMargin
            anchors.left:           divider.right
            anchors.right:          parent.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
        }


    }






 //        QGCFlickable {
 //            id: flick
 //            anchors.fill: parent
 //            clip: true
 //            flickableDirection: Flickable.VerticalFlick

 //            width:          contentContainer.width
 //            anchors.topMargin:  _verticalMargin
 //            anchors.top:        parent.top
 //            anchors.bottom:     parent.bottom
 //            anchors.leftMargin: _horizontalMargin
 //            anchors.left:       parent.left
 //            //contentHeight:      buttonColumn.height + _verticalMargin


 //            // 先不设置contentHeight，这里用一个Item作为内容容器，撑开大小
 //            contentHeight: toolLoader.item ? toolLoader.item.implicitHeight + 20 : 0

 //            Rectangle {
 //                id: contentContainer
 // width: parent.width * 0.9

 //                // RowLayout {
 //                //     id: rowLayout
 //                //     anchors.fill: parent
 //                //     spacing: ScreenTools.defaultFontPixelWidth * 2

 //                    Loader {
 //                        id: toolLoader
 //                        width: parent.width * 0.9  // 占90%
 //                        sourceComponent: toolSelectComponent
 //                    }

 //                    // Rectangle {
 //                    //     width: 1
 //                    //     color: "yellow"
 //                    //     Layout.fillHeight: true
 //                    //     // acceptedButtons: Qt.NoButton  // 不接受任何鼠标事件，事件穿透
 //                    // }
 //                }
 //            //}
 //        }
 //        Rectangle {
 //            id:                     divider
 //            anchors.topMargin:      _verticalMargin
 //            anchors.bottomMargin:   _verticalMargin
 //            anchors.leftMargin:     _horizontalMargin
 //            anchors.left:           flick.right
 //            anchors.top:            parent.top
 //            anchors.bottom:         parent.bottom
 //            width:                  1
 //            //height:parent.height
 //            color:                  "yellow"/*qgcPal.windowShade*/
 //        }

        // QGCFlickable {
        //     id: flick
        //     anchors.fill: parent
        //     clip: true
        //     flickableDirection: Flickable.VerticalFlick
        //     contentHeight: toolLoader.item ? toolLoader.item.implicitHeight + 20 : 0

        //     Loader {
        //         id: toolLoader
        //         anchors.fill: parent
        //         sourceComponent: toolSelectComponent
        //     }
        // }

        // Rectangle {
        //     id: divider
        //     anchors {
        //         topMargin: 20
        //         bottomMargin: 20
        //         left: flick.right
        //         top: parent.top
        //         bottom: parent.bottom
        //     }
        //     width: 1
        //     color: "yellow"
        // }


    QGCPalette { id: qgcPal }

    // 工具菜单内容组件
    // Component {
    //     id: toolSelectComponent






    // }
}
