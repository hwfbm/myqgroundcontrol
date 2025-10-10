/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
//传统 RC 遥控器（手持发射机）
//通过无线信号（如 PPM、SBUS、CRSF、DSM）发送到飞机
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
//import QGroundControl.AutoPilotPlugin
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Controllers
import QGroundControl.Palette

SetupPage {
    id:             radioPage
    pageComponent:  pageComponent

    Component {
        id: pageComponent

        Loader {
                   id: vehicleLoader
                   // width:  parent.width
                   // height: item ? item.height : 0

                   // 选择加载的组件
                   sourceComponent: QGroundControl.multiVehicleManager.activeVehicle
                                    ? vehicleComponent
                                    : noVehicleComponent
               }
        }

   //当没有飞机连接时
    Component {
        id: noVehicleComponent

        Rectangle {
            width: radioPage.availableWidth//parent.width
            height:width
            color:"transparent" //Qt.rgba(0, 0, 0, 0.8)

            QGCLabel {
                anchors.margins:        ScreenTools.defaultFontPixelWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text: qsTr("App未连接到飞机,连接后可设置")/*.arg(QGroundControl.appName)*/
            }
        }
    }

    //当有飞机连接时
    Component {
            id: vehicleComponent

        Item {
            width:  radioPage.availableWidth//parent.width
            height: Math.max(leftColumn.height, rightColumn.height)


            function setupPageCompleted() {
                controller.start()
                updateChannelCount()
            }

            function updateChannelCount()
            {
            }



            QGCPalette { id: qgcPal; colorGroupEnabled: radioPage.enabled }

            RadioComponentController {
                id:             controller
                statusText:     statusText
                cancelButton:   cancelButton
                nextButton:     nextButton
                skipButton:     skipButton
                onChannelCountChanged:              updateChannelCount()
                onFunctionMappingChangedAPMReboot:  mainWindow.showMessageDialog(qsTr("Reboot required"), qsTr("Your stick mappings have changed, you must reboot the vehicle for correct operation."))
                onThrottleReversedCalFailure:       mainWindow.showMessageDialog(qsTr("Throttle channel reversed"), qsTr("Calibration failed. The throttle channel on your transmitter is reversed. You must correct this on your transmitter in order to complete calibration."))
            }

            // Rectangle {
            //     id: statusPanel
            //     width: parent.width * 0.4
            //     height: parent.height
            //     color: "#333333"
            //     ancehors.top: parent.top
            //     anchors.bottom: parent.bottom
            //     x: parent.width   // 默认在屏幕外
            //     z: 100   // 保证在最上层

            //     QGCLabel {
            //         id: statusText
            //         anchors.fill: parent
            //         anchors.margins: 10
            //         wrapMode: Text.WordWrap
            //         color: "white"
            //     }

            //     // 滑入滑出动画
            //     Behavior on x {
            //         NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            //     }

            //     // 当文字变化时，自动开关
            //     Connections {
            //         target: statusText
            //         onTextChanged: {
            //             if (statusText.text && statusText.text !== "")
            //                 statusPanel.x = parent.width - statusPanel.width   // 滑入
            //             else
            //                 statusPanel.x = parent.width   // 滑出
            //         }
            //     }
            // }

            Component {
                id: spektrumBindDialogComponent

                QGCPopupDialog {
                    title:      qsTr("Spektrum Bind")
                    buttons:    Dialog.Ok | Dialog.Cancel

                    onAccepted: { controller.spektrumBindMode(radioGroup.checkedButton.bindMode) }

                    ButtonGroup { id: radioGroup }

                    ColumnLayout {
                        spacing: ScreenTools.defaultFontPixelHeight / 2

                        QGCLabel {
                            wrapMode:   Text.WordWrap
                            text:       qsTr("Click Ok to place your Spektrum receiver in the bind mode.")
                        }

                        QGCLabel {
                            wrapMode:   Text.WordWrap
                            text:       qsTr("Select the specific receiver type below:")
                        }

                        QGCRadioButton {
                            text:               qsTr("DSM2 Mode")
                            ButtonGroup.group:  radioGroup
                            property int bindMode: RadioComponentController.DSM2
                        }

                        QGCRadioButton {
                            text:               qsTr("DSMX (7 channels or less)")
                            ButtonGroup.group:  radioGroup
                            property int bindMode: RadioComponentController.DSMX7
                        }

                        QGCRadioButton {
                            checked:            true
                            text:               qsTr("DSMX (8 channels or more)")
                            ButtonGroup.group:  radioGroup
                            property int bindMode: RadioComponentController.DSMX8
                        }
                    }
                }
            }

            //通道
            Component {
                            id: channelMonitorDisplayComponent

                            Item {
                                property int    rcValue:    1500


                                property int            __lastRcValue:      1500
                                readonly property int   __rcValueMaxJitter: 2
                                property color          __barColor:         qgcPal.windowShade

                                readonly property int _pwmMin:      800
                                readonly property int _pwmMax:      2200
                                readonly property int _pwmRange:    _pwmMax - _pwmMin

                                // Bar
                                Rectangle {
                                    id:                     bar
                                    anchors.verticalCenter: parent.verticalCenter
                                    width:                  parent.width
                                    height:                 parent.height / 2
                                    border.color: "#888888"
                                    border.width:0.8
                                    radius:3
                                    color:                  "transparent"/*__barColor*/
                                }

                                // Center point
                                Rectangle {
                                    anchors.horizontalCenter:   parent.horizontalCenter
                                    width:                      globals.defaultTextWidth / 2
                                    height:                     parent.height
                                    color:                      qgcPal.window
                                }

                                // Indicator
                                    Rectangle {
                                        //anchors.verticalCenter: parent.verticalCenter
                                        y: (parent.height - height) / 2
                                        width:                  parent.height * 0.75
                                        height:                 width
                                        radius:                 width / 2
                                        color:                 "#7FFF00"/* qgcPal.text*/
                                        visible:                mapped
                                        x:                      (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * parent.width) - (width / 2)

                                        //x: bar.x + (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * bar.width) - (width / 2)


                                        //property real normalizedRC: Math.min(Math.max(reversed ? (_pwmMax - rcValue) : (rcValue - _pwmMin), 0), _pwmRange) / _pwmRange
                                        //x: bar.x + normalizedRC * bar.width - (width / 2)
                                       // x: bar.width > 0 ? (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * bar.width) - (width / 2) : 0

                                    }

                                QGCLabel {
                                    anchors.fill:           parent
                                    horizontalAlignment:    Text.AlignHCenter
                                    verticalAlignment:      Text.AlignVCenter
                                    font.pointSize: ScreenTools.largeFontPointSize*0.5
                                    text:                   qsTr("Not Mapped")
                                    visible:                !mapped
                                }

                                ColorAnimation {
                                    id:         barAnimation
                                    target:     bar
                                    property:   "color"
                                    from:       "yellow"
                                    to:         __barColor
                                    duration:   1500
                                }
                            }
                        } // Component - channelMonitorDisplayComponent



            // zuoc
            Column {
                id:             leftColumn
                anchors.left:   parent.left
                anchors.right:  columnSpacer.left
                spacing:        10

                // Attitude Controls
                Column {
                    width:      parent.width
                    spacing:  ScreenTools.defaultFontPixelWidth
                    QGCLabel { text: qsTr("Attitude Controls") }

                    Item {
                        width:  parent.width
                        height: globals.defaultTextHeight * 2

                        QGCLabel {
                            id:     rollLabel
                            width:  globals.defaultTextWidth * 5
                            text:   qsTr("Roll")
                        }

                        Loader {
                            id:                 rollLoader
                            anchors.left:       rollLabel.right
                            anchors.right:      parent.right
                            height:             globals.defaultTextHeight
                            width:              100
                            sourceComponent:    channelMonitorDisplayComponent

                            property bool mapped:           controller.rollChannelMapped
                            property bool reversed:         controller.rollChannelReversed
                        }

                        Connections {
                            target: controller

                            onRollChannelRCValueChanged: (rcValue) => rollLoader.item.rcValue = rcValue
                        }
                    }

                    Item {
                        width:  parent.width
                        height: globals.defaultTextHeight * 2

                        QGCLabel {
                            id:     pitchLabel
                            width:  globals.defaultTextWidth * 5
                            text:   qsTr("Pitch")
                        }

                        Loader {
                            id:                 pitchLoader
                            anchors.left:       pitchLabel.right
                            anchors.right:      parent.right
                            height:             globals.defaultTextHeight
                            width:              100
                            sourceComponent:    channelMonitorDisplayComponent

                            property bool mapped:           controller.pitchChannelMapped
                            property bool reversed:         controller.pitchChannelReversed
                        }

                        Connections {
                            target: controller

                            onPitchChannelRCValueChanged: (rcValue) => pitchLoader.item.rcValue = rcValue
                        }
                    }

                    Item {
                        width:  parent.width
                        height: globals.defaultTextHeight * 2

                        QGCLabel {
                            id:     yawLabel
                            width:  globals.defaultTextWidth * 5
                            text:   qsTr("Yaw")
                        }

                        Loader {
                            id:                 yawLoader
                            anchors.left:       yawLabel.right
                            anchors.right:      parent.right
                            height:             globals.defaultTextHeight
                            width:              100
                            sourceComponent:    channelMonitorDisplayComponent

                            property bool mapped:           controller.yawChannelMapped
                            property bool reversed:         controller.yawChannelReversed
                        }

                        Connections {
                            target: controller

                            onYawChannelRCValueChanged: (rcValue) => yawLoader.item.rcValue = rcValue
                        }
                    }

                    Item {
                        width:  parent.width
                        height: globals.defaultTextHeight * 2

                        QGCLabel {
                            id:     throttleLabel
                            width:  globals.defaultTextWidth * 5
                            text:   qsTr("Throttle")
                        }

                        Loader {
                            id:                 throttleLoader
                            anchors.left:       throttleLabel.right
                            anchors.right:      parent.right
                            height:             globals.defaultTextHeight
                            width:              100
                            sourceComponent:    channelMonitorDisplayComponent

                            property bool mapped:           controller.throttleChannelMapped
                            property bool reversed:         controller.throttleChannelReversed
                        }

                        Connections {
                            target:                             controller
                            onThrottleChannelRCValueChanged:    (rcValue) => throttleLoader.item.rcValue = rcValue
                        }
                    }
                } // Column - Attitude Control labels

                // Command Buttons
                Row {
                    spacing: 10

                    QGCButton {
                        id:         skipButton
                        text:       qsTr("跳过")
                        onClicked:  controller.skipButtonClicked()
                    }

                    QGCButton {
                        id:         cancelButton
                        text:       qsTr("取消")
                        onClicked:  controller.cancelButtonClicked()
                    }

                    QGCButton {
                        id:         nextButton
                        primary:    true
                        text:       qsTr("校准")

                        onClicked: {
                            if (text === qsTr("校准")) {
                                if (controller.channelCount < controller.minChannelCount) {
                                    mainWindow.showMessageDialog(qsTr("遥控器还未准备好"),
                                                                 controller.channelCount == 0 ? qsTr("Please turn on transmitter.") :
                                                                                                (controller.channelCount < controller.minChannelCount ?
                                                                                                     qsTr("%1 channels or more are needed to fly.").arg(controller.minChannelCount) :
                                                                                                     qsTr("Ready to calibrate.")))
                                } else {
                                    mainWindow.showMessageDialog(qsTr("零微调"),
                                                                 qsTr("在校准之前，你应该将所有的微调和辅助微调量设为零。单击确定开始校准.\n\n%1").arg(
                                                                     (QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ? "" : qsTr("请确保断开所有电机电源，并且从飞机上卸下所有螺旋桨"))),
                                                                 Dialog.Ok,
                                                                 function() { controller.nextButtonClicked() })
                                }
                            } else {
                                controller.nextButtonClicked()
                            }
                        }
                    }
                } // Row - Buttons

                // Status Text

                QGCLabel {
                    id:         statusText
                    width:      parent.width
                    wrapMode:   Text.WordWrap
                }

                Rectangle {
                    width:          parent.width
                    height:         1
                    border.color:   qgcPal.text
                    border.width:   1
                }

                QGCLabel { text: qsTr("Additional Radio setup:") }


                Column{

               spacing:ScreenTools.defaultFontPixelWidth
                ColumnLayout {
                    QGCButton {
                        id:         bindButton
                        text:       qsTr("接收机绑定")
                        onClicked:  spektrumBindDialogComponent.createObject(mainWindow).open()
                    }

                    QGCButton {
                        text:       qsTr("Copy Trims")
                        onClicked:  mainWindow.showMessageDialog(qsTr("Copy Trims"),
                                                                 qsTr("把你的操纵杆放在中间，一直向下移动油门，然后按“确定”复制修剪。按下“确定”后，将遥控器上的微调复位为零"),
                                                                 Dialog.Ok | Dialog.Cancel,
                                                                 function() { controller.copyTrims() })
                    }

                    QGCButton {
                        text:       qsTr("CRSF绑定")
                        onClicked:  mainWindow.showMessageDialog(qsTr("CRSF Bind"),
                                                                 qsTr("单击确定将CRSF接收器置于绑定模式"),
                                                                 Dialog.Ok | Dialog.Cancel,
                                                                 function() { controller.crsfBindMode() })
                    }


                }

                //动态生成一堆「参数映射设置行」
            //     /*GridLayout*/ColumnLayout {
            //         id:                 switchSettingsGrid
            //         // anchors.left:       parent.left
            //         // anchors.right:      parent.right
            //        // columns:            2
            //         //columnSpacing:      ScreenTools.defaultFontPixelWidth
            // spacing:ScreenTools.defaultFontPixelWidth
            //         Repeater {
            //             model: QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
            //                        (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
            //                             [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"] :
            //                             [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"]) :
            //                        0

            //             RowLayout {
            //                 Layout.fillWidth: true

            //                 property Fact fact: controller.getParameterFact(-1, modelData)

            //                 QGCLabel {
            //                     Layout.fillWidth:   true
            //                     text:               fact.shortDescription
            //                 }
            //                 FactComboBox {
            //                     width:      ScreenTools.defaultFontPixelWidth * 15
            //                     fact:       parent.fact
            //                     indexModel: false
            //                 }
            //             }
            //         }
            //     }
           }//row
            } // Column - Left Column

            Item {
                id:             columnSpacer
                anchors.right:  rightColumn.left
                width:          20
            }

            // Right side column
            Column {
                id:             rightColumn
                anchors.top:    parent.top
                anchors.right:  parent.right
                width:           parent.width*0.5//ScreenTools.defaultFontPixelWidth *20
                spacing:        ScreenTools.defaultFontPixelHeight / 2

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    QGCRadioButton {
                        text:       qsTr("日本手")
                        checked:    controller.transmitterMode == 1
                        onClicked:  controller.transmitterMode = 1
                    }

                    QGCRadioButton {
                        text:       qsTr("美国手")
                        checked:    controller.transmitterMode == 2
                        onClicked:  controller.transmitterMode = 2
                    }
                }

                Image {
                    width:      parent.width
                    fillMode:   Image.PreserveAspectFit
                    smooth:     true
                    source:     controller.imageHelp
                }

                RCChannelMonitor {
                    width:      parent.width
                    twoColumn:  true
                }
            } // Column - Right Column
        } // Item
     }
    //} // Component - pageComponent
} // SetupPage


/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

// import QtQuick
// import QtQuick.Controls
// import QtQuick.Dialogs
// import QtQuick.Layouts

// import QGroundControl
// import QGroundControl.FactSystem
// import QGroundControl.FactControls
// import QGroundControl.Controls
// import QGroundControl.ScreenTools
// import QGroundControl.Controllers
// import QGroundControl.Palette



// SetupPage {
//     id:             radioPage
//     pageComponent:  pageComponent
//       property var    vehicleComponent   ///< QGC 注入进来的，不能自己删

//     Component {
//         id: pageComponent


//         Item {
//             id:allcomponent

//             width:  availableWidth
//             height: Math.max(leftColumn.height, rightColumn.height)



//             //钩子函数，SetupPage 会在页面加载完成后调用这个函数（QGC 约定）
//             //这里启动 RadioComponentController 的状态机（controller.start()），并更新一次通道数
//             //updateChannelCount() 目前是空的，作为将来 UI 随通道数联动的扩展点

//             function setupPageCompleted() {
//                 controller.start()
//                 updateChannelCount()
//             }

//             function updateChannelCount()
//             {
//             }

//             QGCPalette { id: qgcPal; colorGroupEnabled: radioPage.enabled }



//             // 读取 RC 通道值、映射关系（roll/pitch/yaw/throttle 是否已映射、是否反向等）
//             // 校准流程状态（nextButtonClicked/skip/cancel）
//             // 绑定功能（Spektrum、CRSF）、拷贝 Trim、获取参数 Fact、帮助图片 imageHelp 等
//             RadioComponentController {
//                 id:             controller
//                 statusText:     statusText
//                 cancelButton:   cancelButton
//                 nextButton:     nextButton
//                 skipButton:     skipButton
//                 onChannelCountChanged:              updateChannelCount()
//                 //stick 映射变化时提示“需要重启
//                 onFunctionMappingChangedAPMReboot:  mainWindow.showMessageDialog(qsTr("Reboot required"), qsTr("Your stick mappings have changed, you must reboot the vehicle for correct operation."))
//                 //油门反相时提示“需要在遥控上修正”
//                 onThrottleReversedCalFailure:       mainWindow.showMessageDialog(qsTr("Throttle channel reversed"), qsTr("Calibration failed. The throttle channel on your transmitter is reversed. You must correct this on your transmitter in order to complete calibration."))
//             }

//             Component {
//                 id: spektrumBindDialogComponent

//                 QGCPopupDialog {
//                     title:      qsTr("Spektrum Bind")
//                     buttons:    Dialog.Ok | Dialog.Cancel

//                     onAccepted: { controller.spektrumBindMode(radioGroup.checkedButton.bindMode) }

//                     ButtonGroup { id: radioGroup }
//                     //通过 ButtonGroup 互斥，默认勾选 DSMX8
//                     ColumnLayout {
//                         spacing: ScreenTools.defaultFontPixelHeight / 2

//                         QGCLabel {
//                             wrapMode:   Text.WordWrap
//                             text:       qsTr("Click Ok to place your Spektrum receiver in the bind mode.")
//                         }

//                         QGCLabel {
//                             wrapMode:   Text.WordWrap
//                             text:       qsTr("Select the specific receiver type below:")
//                         }

//                         QGCRadioButton {
//                             text:               qsTr("DSM2 Mode")
//                             ButtonGroup.group:  radioGroup
//                             property int bindMode: RadioComponentController.DSM2
//                         }

//                         QGCRadioButton {
//                             text:               qsTr("DSMX (7 channels or less)")
//                             ButtonGroup.group:  radioGroup
//                             property int bindMode: RadioComponentController.DSMX7
//                         }

//                         QGCRadioButton {
//                             checked:            true
//                             text:               qsTr("DSMX (8 channels or more)")
//                             ButtonGroup.group:  radioGroup
//                             property int bindMode: RadioComponentController.DSMX8
//                         }
//                     }
//                 }
//             }

//             // Live channel monitor control component

//             //通道监视器子组件
//             //每个通道（Roll/Pitch/Yaw/Throttle）右侧的水平条 + 圆点指示器

//             function mapValue(value, inMin, inMax, outMin, outMax) {
//                 return (value - inMin) / (inMax - inMin) * (outMax - outMin) + outMin
//             }

//             Component {
//                 id: channelMonitorDisplayComponent

//                 Item {
//                     property int    rcValue:    1500


//                     property int            __lastRcValue:      1500
//                     readonly property int   __rcValueMaxJitter: 2
//                     property color          __barColor:         qgcPal.windowShade

//                     readonly property int _pwmMin:      800
//                     readonly property int _pwmMax:      2200
//                     readonly property int _pwmRange:    _pwmMax - _pwmMin

//                     // Bar
//                     Rectangle {
//                         id:                     bar
//                         anchors.verticalCenter: parent.verticalCenter
//                         width:                  parent.width
//                         height:                 parent.height / 2
//                         border.color: "#888888"
//                         border.width:0.8
//                         radius:3
//                         color:                  "transparent"/*__barColor*/
//                     }

//                     // Center point
//                     Rectangle {
//                         anchors.horizontalCenter:   parent.horizontalCenter
//                         width:                      globals.defaultTextWidth / 2
//                         height:                     parent.height
//                         color:                      qgcPal.window
//                     }

//                     // Indicator
//                         Rectangle {
//                             //anchors.verticalCenter: parent.verticalCenter
//                             y: (parent.height - height) / 2
//                             width:                  parent.height * 0.75
//                             height:                 width
//                             radius:                 width / 2
//                             color:                 "#7FFF00"/* qgcPal.text*/
//                             visible:                mapped
//                             x:                      (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * parent.width) - (width / 2)

//                             //x: bar.x + (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * bar.width) - (width / 2)


//                             //property real normalizedRC: Math.min(Math.max(reversed ? (_pwmMax - rcValue) : (rcValue - _pwmMin), 0), _pwmRange) / _pwmRange
//                             //x: bar.x + normalizedRC * bar.width - (width / 2)
//                            // x: bar.width > 0 ? (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * bar.width) - (width / 2) : 0

//                         }

//                     QGCLabel {
//                         anchors.fill:           parent
//                         horizontalAlignment:    Text.AlignHCenter
//                         verticalAlignment:      Text.AlignVCenter
//                         font.pointSize: ScreenTools.largeFontPointSize*0.5
//                         text:                   qsTr("Not Mapped")
//                         visible:                !mapped
//                     }

//                     ColorAnimation {
//                         id:         barAnimation
//                         target:     bar
//                         property:   "color"
//                         from:       "yellow"
//                         to:         __barColor
//                         duration:   1500
//                     }
//                 }
//             } // Component - channelMonitorDisplayComponent



//             QGCFlickable {
//                         id: flick
//                         width:  parent.width/*availableWidth*/
//                         height:parent.height// Math.max(leftColumn.height, rightColumn.height)
//                         // width: allcomponent.implicitWidth
//                         // height: allcomponent.implicitHeight

//                         // width:  availableWidth
//                         // height: Math.max(leftColumn.height, rightColumn.height)

//                         clip: true

//                         // 内容大小 = 左右两列 + 边距
//                         contentWidth:  leftColumn.width + rightColumn.width + columnSpacer.width
//                         contentHeight: Math.max(leftColumn.height, rightColumn.height)


//            //模式



//             Column {
//                 id:             rightColumn
//                 // anchors.top:    parent.top
//                 anchors.right:  parent.right
//                 anchors.left:  columnSpacer.right
//                 height:  ScreenTools.defaultFontPixelWidth * 20
//                 //width:          ScreenTools.defaultFontPixelWidth * 10
//                 spacing:        ScreenTools.defaultFontPixelHeight / 2

//                 Row {
//                     spacing: ScreenTools.defaultFontPixelWidth

//                     QGCRadioButton {
//                         text:       qsTr("Mode 1")
//                         checked:    controller.transmitterMode == 1
//                         onClicked:  controller.transmitterMode = 1
//                     }

//                     QGCRadioButton {
//                         text:       qsTr("Mode 2")
//                         checked:    controller.transmitterMode == 2
//                         onClicked:  controller.transmitterMode = 2
//                     }
//                 }

//                 Image {
//                     width:      parent.width*0.5
//                     fillMode:   Image.PreserveAspectFit
//                     smooth:     true
//                     source:     controller.imageHelp
//                 }

//                 RCChannelMonitor {
//                     width:      parent.width
//                     twoColumn:  true
//                 }
//             }
//             // Left side column
//             Column {
//                 id:             leftColumn
//                  anchors.left:   parent.left
//                  anchors.top:   parent.top
//                  anchors.right:   columnSpacer.left

//                 //width: parent.width*0.5
//                 height:ScreenTools.defaultFontPixelWidth * 20
//                 //anchors.right:  columnSpacer.left
//                 spacing:        10

//                 // Attitude Controls
//                 Column {
//                     id:mapping
//                     width:      parent.width//*2/3
//                     spacing:    5
//                     QGCLabel { text: qsTr("Attitude Controls") }

//                     Item {
//                         width:  parent.width
//                         height: globals.defaultTextHeight * 2

//                         QGCLabel {
//                             id:     rollLabel
//                             width:  globals.defaultTextWidth * 6
//                             text:   qsTr("Roll")
//                         }

//                         Loader {
//                             id:                 rollLoader
//                             anchors.left:       rollLabel.right
//                             anchors.right:      parent.right
//                             height:             globals.defaultTextHeight
//                             // width:              100
//                             sourceComponent:    channelMonitorDisplayComponent

//                             property bool mapped:           controller.rollChannelMapped
//                             property bool reversed:         controller.rollChannelReversed
//                         }


//                         Connections {
//                             target: controller

//                             onRollChannelRCValueChanged: (rcValue) => rollLoader.item.rcValue = rcValue
//                         }
//                     }

//                     Item {
//                         width:  parent.width
//                         height: globals.defaultTextHeight * 2


//                         QGCLabel {
//                             id:     pitchLabel
//                             width:  globals.defaultTextWidth *6
//                             text:   qsTr("Pitch")
//                         }

//                         Loader {
//                             id:                 pitchLoader
//                             anchors.left:       pitchLabel.right
//                             anchors.right:      parent.right
//                             height:             globals.defaultTextHeight
//                             width:              100
//                             sourceComponent:    channelMonitorDisplayComponent

//                             property bool mapped:           controller.pitchChannelMapped
//                             property bool reversed:         controller.pitchChannelReversed
//                         }


//                         Connections {
//                             target: controller

//                             onPitchChannelRCValueChanged: (rcValue) => pitchLoader.item.rcValue = rcValue
//                         }
//                     }

//                     Item {
//                         width:  parent.width
//                         height: globals.defaultTextHeight * 2


//                         QGCLabel {
//                             id:     yawLabel
//                             width:  globals.defaultTextWidth * 6
//                             text:   qsTr("Yaw")
//                         }

//                         Loader {
//                             id:                 yawLoader
//                             anchors.left:       yawLabel.right
//                             anchors.right:      parent.right
//                             height:             globals.defaultTextHeight
//                             width:              100
//                             sourceComponent:    channelMonitorDisplayComponent

//                             property bool mapped:           controller.yawChannelMapped
//                             property bool reversed:         controller.yawChannelReversed
//                         }


//                         Connections {
//                             target: controller

//                             onYawChannelRCValueChanged: (rcValue) => yawLoader.item.rcValue = rcValue
//                         }
//                     }

//                     Item {
//                         width: parent.width
//                         height: globals.defaultTextHeight * 2

//                         QGCLabel {
//                             id:     throttleLabel
//                             width:  globals.defaultTextWidth * 6
//                             text:   qsTr("Throttle")
//                         }

//                         Loader {
//                             id:                 throttleLoader
//                             anchors.left:       throttleLabel.right
//                             anchors.right:      parent.right
//                             height:             globals.defaultTextHeight
//                             width:              100
//                             sourceComponent:    channelMonitorDisplayComponent

//                             property bool mapped:           controller.throttleChannelMapped
//                             property bool reversed:         controller.throttleChannelReversed
//                         }

//                         Connections {
//                             target:                             controller
//                             onThrottleChannelRCValueChanged:    (rcValue) => throttleLoader.item.rcValue = rcValue
//                         }
//                     }
//                 } // Column - Attitude Control labels

//                 // Command Buttons
//                 //遥控器校准按钮
//                 Row {
//                     id:button
//                     spacing: 10
//                     //anchors.top:      mapping.bottom
//                     height:parent.height*0.2

//                     QGCButton {
//                         id:         skipButton
//                         // width:ScreenTools.defaultFontPixelWidth*6
//                         // height:width*0.6
//                         text:       qsTr("跳过")

//                         onClicked:  controller.skipButtonClicked()
//                     }

//                     QGCButton {
//                         id:         cancelButton
//                         text:       qsTr("取消")
//                         onClicked:  controller.cancelButtonClicked()
//                     }

//                     QGCButton {
//                         id:         nextButton
//                         primary:    true
//                         text:       qsTr("校准")

//                         onClicked: {
//                             if (text === qsTr("校准")) {
//                                 if (controller.channelCount < controller.minChannelCount) {
//                                     mainWindow.showMessageDialog(qsTr("遥控器还未准备好"),
//                                                                  controller.channelCount == 0 ? qsTr("请打开发送机") :
//                                                                                                 (controller.channelCount < controller.minChannelCount ?
//                                                                                                      qsTr("%1 需要更多通道才能飞行").arg(controller.minChannelCount) :
//                                                                                                      qsTr("准备校准")))
//                                 } else {
//                                     mainWindow.showMessageDialog(qsTr("零微调"),
//                                                                  qsTr("在校准之前，你应该将所有的微调和辅助微调量设为零。单击确定开始校准\n\n%1").arg(
//                                                                      (QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ? "" : qsTr("请确保断开所有电机电源，并且从飞机上卸下所有螺旋桨"))),
//                                                                  Dialog.Ok,
//                                                                  function() { controller.nextButtonClicked() })
//                                 }
//                             } else {
//                                 controller.nextButtonClicked()
//                             }
//                         }
//                     }
//                 } // Row - Buttons

//                 // Status Text
//                 QGCLabel {
//                     id:         statusText
//                     width:      parent.width
//                     //anchors.top:       button.bottom

//                     wrapMode:   Text.WordWrap
//                 }

//                 Rectangle {
//                     id:clip
//                     // anchors.top:       statusText.bottom
//                     width:          parent.width*2/3
//                     height:         1
//                     color:   "#888888"

//                 }

//                 QGCLabel {
//                    id:label
//                     //anchors.top:       clip.bottom
//                     text: qsTr("Additional Radio setup:")
//                 }

//                 GridLayout {
//                     id:                 switchSettingsGrid
//                     //anchors.left:       parent.left
//                    width:parent.width*2/3
//                     //anchors.top:      label.bottom
//                     height:parent.height*0.2
//                     columns:           2
//                     columnSpacing:      ScreenTools.defaultFontPixelWidth

//                     Repeater {
//                         model: QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
//                                    (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
//                                         [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"] :
//                                         [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"]) :
//                                    0

//                         RowLayout {
//                             Layout.fillWidth: true

//                             property Fact fact: controller.getParameterFact(-1, modelData)

//                             QGCLabel {
//                                 Layout.fillWidth:   true
//                                 text:               fact.shortDescription
//                             }
//                             FactComboBox {
//                                 width:      ScreenTools.defaultFontPixelWidth * 15
//                                 fact:       parent.fact
//                                 indexModel: false
//                             }
//                         }
//                     }
//                 }

//                 RowLayout {
//                     // anchors.left:       parent.left
//                     // anchors.right:      parent.right
//                     // anchors.top:      switchSettingsGrid.bottom
//                     QGCButton {
//                         id:         bindButton
//                         text:       qsTr("接收机绑定")
//                         onClicked:  spektrumBindDialogComponent.createObject(mainWindow).open()
//                     }

//                     QGCButton {
//                         text:       qsTr("CRSF绑定")
//                         onClicked:  mainWindow.showMessageDialog(qsTr("CRSF绑定"),
//                                                                  qsTr("单击确定将CRSF接收器置于绑定模式"),
//                                                                  Dialog.Ok | Dialog.Cancel,
//                                                                  function() { controller.crsfBindMode() })
//                     }

//                     QGCButton {
//                         text:       qsTr("Copy Trims")
//                         onClicked:  mainWindow.showMessageDialog(qsTr("Copy Trims"),
//                                                                  qsTr("把你的操纵杆放在中间，一直向下移动油门，然后按“确定”复制修剪。按下“确定”后，将遥控器上的微调复位为零"),
//                                                                  Dialog.Ok | Dialog.Cancel,
//                                                                  function() { controller.copyTrims() })
//                     }
//                 }
//             } // Column - Left Column



//             Item {
//                 id:             columnSpacer
//                  anchors.right:  rightColumn.left
//                 // anchors.left:leftColumn.right
//                 width: 10

//             }

//             // Right side column
//     // Column - Right Column
//          } //Flickable
//         }// Item
//     } // Component - pageComponent
// } // SetupPage


// SetupPage {
//     id: radioPage
//    /* property var vehicleComponent: QtObject {
//         // 可以加默认字段，避免内部逻辑访问时报错
//         property string name: ""
//         property string description: ""
//         property bool allowSetupWhileArmed: false
//         property bool allowSetupWhileFlying: false
//     }*/
//     pageComponent: pageComponent
//   Component {
//         id: pageComponent

//         Item {
//             width: availableWidth

//             QGCPalette { id: qgcPal; colorGroupEnabled: radioPage.enabled }

//             function setupPageCompleted() {

//                            controller.start()
//                 console.log("setupPageCompleted called")
//                            updateChannelCount()
//                        }
//             function updateChannelCount()
//             {
//                         }
//             RadioComponentController {
//                 id: controller
//                 statusText: statusText
//                 cancelButton: cancelButton
//                 nextButton: nextButton
//                 skipButton: skipButton
//                 onChannelCountChanged:              updateChannelCount()
//                //stick 映射变化时提示“需要重启
//                onFunctionMappingChangedAPMReboot:  mainWindow.showMessageDialog(qsTr("Reboot required"), qsTr("Your stick mappings have changed, you must reboot the vehicle for correct operation."))
//                //油门反相时提示“需要在遥控上修正”
//                onThrottleReversedCalFailure:       mainWindow.showMessageDialog(qsTr("Throttle channel reversed"), qsTr("Calibration failed. The throttle channel on your transmitter is reversed. You must correct this on your transmitter in order to complete calibration."))
//             }

//             StackView {
//                 id: stackView
//                 anchors.fill: parent
//                 initialItem: buttonPageComponent
//             }

//             // ------------------- 按钮页 -------------------
//             Component {
//                 id: buttonPageComponent

//                 Column {
//                     spacing: 3
//                     width: parent.width

//                     // 遥控器校准
//                     Leftbutton {
//                         text: qsTr("遥控器校准")
//                         width: parent.width
//                         onClicked: stackView.push(calibrationPageComponent)
//                     }
//                     Rectangle {
//                         width: parent.width
//                         height:1
//                         opacity: 0.6
//                         color: "#888888"
//                     }

//                     // 摇杆模式
//                     Leftbutton {
//                         text: qsTr("摇杆模式")
//                         width: parent.width
//                         onClicked: stackView.push(moderemoteComponent)
//                     }
//                     Rectangle {
//                         width: parent.width
//                         height:1
//                         opacity: 0.6
//                         color: "#888888"
//                     }

//                     // Spektrum
//                     Leftbutton {
//                         text: qsTr("Spektrum 绑定")
//                         width: parent.width
//                         onClicked: stackView.push(spektrumBindDialogComponent)
//                     }
//                     Rectangle {
//                         width: parent.width
//                         height:1
//                         opacity: 0.6
//                         color: "#888888"
//                     }
//                     // 其他设置
//                     Leftbutton {
//                         text: qsTr("其他设置")
//                         width: parent.width
//                         onClicked: stackView.push(additionComponent)
//                     }
//                     Rectangle {
//                         width: parent.width
//                         height:1
//                         opacity: 0.6
//                         color: "#888888"
//                     }
//                 }
//             }
// //---------------按钮组件--------------

//             //遥控器校准+按钮组件
//             Component {
//                 id: calibrationPageComponent
//                 ColumnLayout {
//                     spacing: 40

//                     // 顶部 Back 按钮和分割线
//                     ColumnLayout {
//                         Layout.fillWidth: true
//                         spacing: 1 // 按钮和线之间间隔

//                         QGCButton {
//                             id: back
//                             text: qsTr("返回")
//                             onClicked: stackView.pop()
//                         }


//                     }

//                     // Loader 占满剩余空间
//                     Loader {
//                         id: leftColumnLoader
//                         sourceComponent: leftColumnComponent
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                     }
//                 }
//             }
//             //摇杆模式组件+按钮
//             Component {
//                 id: moderemoteComponent
//                 ColumnLayout {
//                     spacing: 10

//                     // 顶部 Back 按钮和分割线
//                     ColumnLayout {
//                         Layout.fillWidth: true
//                         spacing: 1 // 按钮和线之间间隔

//                         QGCButton {
//                             id: back
//                             text: qsTr("返回")
//                             //width:parent.width
//                             //horizontalAlignment: Qt.AlignLeft
//                             //Layout.fillWidth: true
//                             //Layout.preferredHeight: ScreenTools.defaultFontPointSize * 3
//                             //Layout.minimumWidth: 50
//                             // setsize: ScreenTools.defaultFontPointSize*1.5
//                             // bordercolor: "transparent"
//                             // backcolor: "transparent"
//                             onClicked: stackView.pop()
//                         }


//                     }

//                     // Loader 占满剩余空间
//                     Loader {
//                         id: leftColumnLoader
//                         sourceComponent: moderemote
//                         Layout.fillWidth: true
//                         Layout.fillHeight: true
//                     }
//                 }
//             }
//             //摇杆模式组件+按钮
//             Component {
//                 id: spektrumBindDialogComponent
//                 ColumnLayout {
//                     spacing: 10

//                     // 顶部 Back 按钮和分割线
//                     ColumnLayout {
//                         Layout.fillWidth: true
//                         spacing: 1 // 按钮和线之间间隔

//                         QGCButton {
//                             id: back
//                             text: qsTr("返回")
//                             onClicked: stackView.pop()
//                         }


//                     }

//                     // Loader 占满剩余空间
//                     Loader {
//                         id: leftColumnLoader
//                         sourceComponent: spektrumBindPage
//                         Layout.fillHeight: true
//                     }
//                 }
//             }
//             Component {
//                 id: additionComponent
//                 ColumnLayout {
//                     spacing: 10

//                     // 顶部 Back 按钮和分割线
//                     ColumnLayout {
//                         Layout.fillWidth: true
//                         spacing: 1 // 按钮和线之间间隔

//                         QGCButton {
//                             id: back
//                             text: qsTr("返回")
//                             onClicked: stackView.pop()
//                         }


//                     }

//                     // Loader 占满剩余空间
//                     Loader {
//                         id: leftColumnLoader
//                         sourceComponent: addition
//                         Layout.fillHeight: true
//                     }
//                 }
//             }
// //-----------------按钮所加载的组件-----------

//             //其他遥控器设置
//             Component {
//                 id: addition
//                 Item {
//                     anchors.left:   parent.left
//                     anchors.right:  parent.right
//                     anchors.top:    parent.top

//                     Column {
//                         width: parent.width
//                         spacing: ScreenTools.defaultFontPixelHeight

//                         // 没有连接飞机时，显示提示
//                         QGCLabel {

//                             visible: QGroundControl.multiVehicleManager.activeVehicle === null
//                             text: qsTr("请连接飞机以显示更多遥控器设置")
//                             //font.pointSize:  ScreenTools.defaultFontPixelHeight*1.
//                             color: "#7FFF00"
//                         }

//                         // 有飞机时显示原有设置
//                         Column {
//                             visible: QGroundControl.multiVehicleManager.activeVehicle !== null
//                             spacing: ScreenTools.defaultFontPixelHeight

//                             QGCLabel { text: qsTr("Additional Radio setup:") }

//                             GridLayout {
//                                 id:                 switchSettingsGrid
//                                 anchors.left:       parent.left
//                                 anchors.right:      parent.right
//                                 columns:            2
//                                 columnSpacing:      ScreenTools.defaultFontPixelWidth

//                                 Repeater {
//                                     model: QGroundControl.multiVehicleManager.activeVehicle &&
//                                            QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ?
//                                                (QGroundControl.multiVehicleManager.activeVehicle.multiRotor ?
//                                                     [ "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"] :
//                                                     [ "RC_MAP_FLAPS", "RC_MAP_AUX1", "RC_MAP_AUX2", "RC_MAP_PARAM1", "RC_MAP_PARAM2", "RC_MAP_PARAM3"]) :
//                                                0

//                                     RowLayout {
//                                         Layout.fillWidth: true

//                                         property Fact fact: controller.getParameterFact(-1, modelData)

//                                         QGCLabel {
//                                             Layout.fillWidth:   true
//                                             text:               fact.shortDescription
//                                         }
//                                         FactComboBox {
//                                             width:      ScreenTools.defaultFontPixelWidth * 15
//                                             fact:       parent.fact
//                                             indexModel: false
//                                         }
//                                     }
//                                 }
//                             }

//                             RowLayout {
//                                 QGCButton {
//                                     id:         bindButton
//                                     text:       qsTr("Spektrum Bind")
//                                     onClicked:  spektrumBindDialogComponent.createObject(mainWindow).open()
//                                 }

//                                 QGCButton {
//                                     text:       qsTr("CRSF Bind")
//                                     onClicked:  mainWindow.showMessageDialog(qsTr("CRSF Bind"),
//                                                                              qsTr("Click Ok to place your CRSF receiver in the bind mode."),
//                                                                              Dialog.Ok | Dialog.Cancel,
//                                                                              function() { controller.crsfBindMode() })
//                                 }

//                                 QGCButton {
//                                     text:       qsTr("Copy Trims")
//                                     onClicked:  mainWindow.showMessageDialog(qsTr("Copy Trims"),
//                                                                              qsTr("Center your sticks and move throttle all the way down, then press Ok to copy trims. After pressing Ok, reset the trims on your radio back to zero."),
//                                                                              Dialog.Ok | Dialog.Cancel,
//                                                                              function() { controller.copyTrims() })
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }



//             //Spektrum绑定
//             // 摇杆模式设置页面组件
//             Component {
//                 id: spektrumBindPage

//                 //Item {
//                     // 主列布局
//                     ColumnLayout {
//                         anchors.right: parent.right
//                         anchors.left: parent.left
//                         spacing: 10

//                         // 顶部返回按钮


//                         // 标题
//                         // QGCLabel {
//                         //     text: qsTr("Spektrum 遥控器绑定")
//                         //     font.pointSize: ScreenTools.largeFontPointSize
//                         //     Layout.alignment: Qt.AlignHCenter
//                         //    // Layout.topMargin: 20
//                         //}

//                         // 说明文字
//                         QGCLabel {
//                             Layout.fillWidth: true
//                             wrapMode: Text.WordWrap
//                             text: qsTr("点击\"开始绑定\"按钮将您的Spektrum接收器置于绑定模式。")
//                             Layout.topMargin: 10
//                         }

//                         QGCLabel {
//                             Layout.fillWidth: true
//                             wrapMode: Text.WordWrap
//                             text: qsTr("请在下方选择特定的接收器类型：")
//                             Layout.bottomMargin: 10
//                         }

//                         // 单选按钮组
//                         ButtonGroup {
//                             id: radioGroup
//                             onCheckedButtonChanged: {
//                                 // 选择变化时可以在这里处理
//                             }
//                         }

//                         ColumnLayout {
//                             Layout.fillWidth: true
//                             spacing: 12

//                             QGCRadioButton {
//                                 text: qsTr("DSM2 模式")
//                                 ButtonGroup.group: radioGroup
//                                 property int bindMode: RadioComponentController.DSM2// 用实际的值替换 RadioComponentController.DSM2
//                             }

//                             QGCRadioButton {
//                                 text: qsTr("DSMX (7通道或更少)")
//                                 ButtonGroup.group: radioGroup
//                                 property int bindMode:  RadioComponentController.DSMX7 // 用实际的值替换 RadioComponentController.DSMX7
//                             }

//                             QGCRadioButton {
//                                 checked: true
//                                 text: qsTr("DSMX (8通道或更多)")
//                                 ButtonGroup.group: radioGroup
//                                 property int bindMode:RadioComponentController.DSMX8 // 用实际的值替换 RadioComponentController.DSMX8
//                             }
//                         }


//                         // 底部按钮行
//                         RowLayout {
//                             Layout.fillWidth: true
//                             spacing: 10

//                             // 取消按钮
//                             QGCButton {
//                                 text: qsTr("取消")
//                                 //Layout.fillWidth: true
//                                 onClicked: stackView.pop() // 直接返回上一页
//                             }

//                             // 开始绑定按钮
//                             QGCButton {
//                                 text: qsTr("开始绑定")
//                                 //Layout.fillWidth: true
//                                 primary: true // 主要操作按钮

//                                 onClicked: {
//                                     if (radioGroup.checkedButton) {
//                                         // 执行绑定操作
//                                         controller.spektrumBindMode(radioGroup.checkedButton.bindMode)

//                                         // 显示操作完成提示（可选）
//                                         // mainWindow.showMessage(qsTr("绑定操作已开始"))

//                                         // 可以选择自动返回或者停留在此页面
//                                         // stackView.pop() // 立即返回
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                // }
//             }
//             // Component {
//             //                id: spektrumBindDialog

//             //                QGCPopupDialog {
//             //                    title:      qsTr("Spektrum Bind")
//             //                    buttons:    Dialog.Ok | Dialog.Cancel

//             //                    onAccepted: { controller.spektrumBindMode(radioGroup.checkedButton.bindMode) }

//             //                    ButtonGroup { id: radioGroup }
//             //                    //通过 ButtonGroup 互斥，默认勾选 DSMX8
//             //                    ColumnLayout {
//             //                        spacing: ScreenTools.defaultFontPixelHeight / 2

//             //                        QGCLabel {
//             //                            wrapMode:   Text.WordWrap
//             //                            text:       qsTr("Click Ok to place your Spektrum receiver in the bind mode.")
//             //                        }

//             //                        QGCLabel {
//             //                            wrapMode:   Text.WordWrap
//             //                            text:       qsTr("Select the specific receiver type below:")
//             //                        }

//             //                        QGCRadioButton {
//             //                            text:               qsTr("DSM2 Mode")
//             //                            ButtonGroup.group:  radioGroup
//             //                            property int bindMode: RadioComponentController.DSM2
//             //                        }

//             //                        QGCRadioButton {
//             //                            text:               qsTr("DSMX (7 channels or less)")
//             //                            ButtonGroup.group:  radioGroup
//             //                            property int bindMode: RadioComponentController.DSMX7
//             //                        }

//             //                        QGCRadioButton {
//             //                            checked:            true
//             //                            text:               qsTr("DSMX (8 channels or more)")
//             //                            ButtonGroup.group:  radioGroup
//             //                            property int bindMode: RadioComponentController.DSMX8
//             //                        }
//             //                    }
//             //                }
//             //            }
//             //摇杆模式组件，被加载
//             Component {
//                 id: moderemote

//                 Column {
//                     id: rightColumn
//                     anchors.top: parent.top
//                     anchors.left: parent.left
//                     anchors.right: parent.right
//                     spacing: ScreenTools.defaultFontPixelHeight / 2

//                     Row {
//                         spacing: ScreenTools.defaultFontPixelWidth

//                         QGCRadioButton {
//                             text: qsTr("Mode 1")
//                             checked: controller.transmitterMode == 1
//                             onClicked: controller.transmitterMode = 1
//                         }

//                         QGCRadioButton {
//                             text: qsTr("Mode 2")
//                             checked: controller.transmitterMode == 2
//                             onClicked: controller.transmitterMode = 2
//                         }
//                     }

//                     // 图片居中，宽度自适应父项
//                     Image {
//                         source: controller.imageHelp
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         fillMode: Image.PreserveAspectFit
//                         smooth: true
//                         width: parent.width * 0.5   // 可根据需求调整宽度比例
//                         height: parent.width * 0.3  // 或者根据比例计算高度
//                     }

//                     // RC 通道监控
//                     RCChannelMonitor {
//                         width: parent.width
//                         twoColumn: true
//                     }
//                 }
//             }





//           //遥控器校准通道，被加载
//             //todo:没接飞机的时候不加载
//             Component {
//                 id: leftColumnComponent

//                 Column {
//                     width: parent.width
//                     spacing: 10

//                     // // 占位属性，用 Loader 加载后赋值
//                     // property var controller
//                     // property var qgcPal

//                     QGCLabel { text: qsTr("Attitude Controls") }

//                     Item {
//                         width: parent.width
//                         height: globals.defaultTextHeight * 2

//                         QGCLabel
//                         {
//                             id: rollLabel;
//                             text: qsTr("Roll");
//                             width:  globals.defaultTextWidth *6
//                         }

//                         Loader {
//                             id: rollLoader
//                             anchors.left: rollLabel.right
//                             anchors.right: parent.right
//                             height: globals.defaultTextHeight
//                             width: 80
//                             sourceComponent: channelMonitorDisplayComponent
//                             // property bool mapped: controller.rollChannelMapped
//                             // property bool reversed: controller.rollChannelReversed
//                             property bool mapped: controller ? controller.rollChannelMapped : false
//                             property bool reversed: controller ? controller.rollChannelReversed : false
//                         }

//                         Connections {
//                             target: controller
//                             onRollChannelRCValueChanged: rcValue => rollLoader.item.rcValue = rcValue
//                         }
//                     }
//                     Item {
//                                             width:  parent.width
//                                             height: globals.defaultTextHeight * 2

//                                             QGCLabel {
//                                                 id:     pitchLabel
//                                                 width:  globals.defaultTextWidth *6
//                                                 text:   qsTr("Pitch")
//                                             }

//                                             Loader {
//                                                 id:                 pitchLoader
//                                                 anchors.left:       pitchLabel.right
//                                                 anchors.right:      parent.right
//                                                 height:             globals.defaultTextHeight
//                                                 width:             80
//                                                 sourceComponent:    channelMonitorDisplayComponent

//                                                 property bool mapped:           controller.pitchChannelMapped
//                                                 property bool reversed:         controller.pitchChannelReversed
//                                             }

//                                             Connections {
//                                                 target: controller

//                                                 onPitchChannelRCValueChanged: (rcValue) => pitchLoader.item.rcValue = rcValue
//                                             }
//                                         }
//                     Item {
//                                             width:  parent.width
//                                             height: globals.defaultTextHeight * 2

//                                             QGCLabel {
//                                                 id:     yawLabel
//                                                 width:  globals.defaultTextWidth * 6
//                                                 text:   qsTr("Yaw")
//                                             }

//                                             Loader {
//                                                 id:                 yawLoader
//                                                 anchors.left:       yawLabel.right
//                                                 anchors.right:      parent.right
//                                                 height:             globals.defaultTextHeight
//                                                 width:              80
//                                                 sourceComponent:    channelMonitorDisplayComponent

//                                                 property bool mapped:           controller.yawChannelMapped
//                                                 property bool reversed:         controller.yawChannelReversed
//                                             }

//                                             Connections {
//                                                 target: controller

//                                                 onYawChannelRCValueChanged: (rcValue) => yawLoader.item.rcValue = rcValue
//                                             }
//                                         }
//                     Item {
//                                       width:  parent.width
//                                       height: globals.defaultTextHeight * 2

//                                       QGCLabel {
//                                           id:     throttleLabel
//                                           width:  globals.defaultTextWidth * 6
//                                           text:   qsTr("Throttle")
//                                       }

//                                       Loader {
//                                           id:                 throttleLoader
//                                           anchors.left:       throttleLabel.right
//                                           anchors.right:      parent.right
//                                           height:             globals.defaultTextHeight
//                                           width:              80
//                                           sourceComponent:    channelMonitorDisplayComponent

//                                           property bool mapped:           controller.throttleChannelMapped
//                                           property bool reversed:         controller.throttleChannelReversed
//                                       }

//                                       Connections {
//                                           target:                             controller
//                                           onThrottleChannelRCValueChanged:    (rcValue) => throttleLoader.item.rcValue = rcValue
//                                       }
//                                   }

//                     Row {
//                                        spacing: 10

//                                        QGCButton {
//                                            id:         skipButton
//                                            // width:ScreenTools.defaultFontPixelWidth*6
//                                            // height:width*0.6
//                                            text:       qsTr("Skip")

//                                            onClicked:  controller.skipButtonClicked()
//                                        }

//                                        QGCButton {
//                                            id:         cancelButton
//                                            text:       qsTr("Cancel")
//                                            onClicked:  controller.cancelButtonClicked()
//                                        }

//                                        QGCButton {
//                                            id:         nextButton
//                                            primary:    true
//                                            text:       qsTr("Calibrate")

//                                            onClicked: {
//                                                if (text === qsTr("Calibrate")) {
//                                                    if (controller.channelCount < controller.minChannelCount) {
//                                                        mainWindow.showMessageDialog(qsTr("Radio Not Ready"),
//                                                                                     controller.channelCount == 0 ? qsTr("Please turn on transmitter.") :
//                                                                                                                    (controller.channelCount < controller.minChannelCount ?
//                                                                                                                         qsTr("%1 channels or more are needed to fly.").arg(controller.minChannelCount) :
//                                                                                                                         qsTr("Ready to calibrate.")))
//                                                    } else {
//                                                        mainWindow.showMessageDialog(qsTr("Zero Trims"),
//                                                                                     qsTr("Before calibrating you should zero all your trims and subtrims. Click Ok to start Calibration.\n\n%1").arg(
//                                                                                         (QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ? "" : qsTr("Please ensure all motor power is disconnected AND all props are removed from the vehicle."))),
//                                                                                     Dialog.Ok,
//                                                                                     function() { controller.nextButtonClicked() })
//                                                    }
//                                                } else {
//                                                    controller.nextButtonClicked()
//                                                }
//                                            }
//                                        }
//                                    } // Row - Buttons

//                                    // Status Text
//                                    QGCLabel {
//                                        id:         statusText
//                                        width:      parent.width
//                                        wrapMode:   Text.WordWrap
//                                    }
//                               }



//                     // pitch/yaw/throttle 同理
//                 }
//             //}

//             // ------------------- 通道条 -------------------
//             Component {
//                 id: channelMonitorDisplayComponent
//                 Item {
//                     property int rcValue: 1500
//                     property color __barColor: qgcPal.windowShade
//                     readonly property int   __rcValueMaxJitter: 2
//                     readonly property int _pwmMin: 800
//                     readonly property int _pwmMax: 2200
//                     readonly property int _pwmRange: _pwmMax - _pwmMin

//                     Rectangle {
//                         id: bar
//                         anchors.verticalCenter: parent.verticalCenter
//                         width: parent.width
//                         height: parent.height / 2
//                         border.color: "#888888"
//                         border.width: 0.8
//                         radius: 3
//                         color: "transparent"
//                     }

//                     Rectangle {
//                         anchors.horizontalCenter: parent.horizontalCenter
//                         width: globals.defaultTextWidth / 2
//                         height: parent.height
//                         color: qgcPal.window
//                     }

//                     Rectangle {
//                         anchors.verticalCenter: parent.verticalCenter
//                         width: parent.height * 0.75
//                         height: width
//                         radius: width / 2
//                         color: "#7FFF00"
//                         visible: mapped
//                         x: (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * parent.width) - (width / 2)
//                     }

//                     QGCLabel {
//                         anchors.fill: parent
//                         horizontalAlignment: Text.AlignHCenter
//                         verticalAlignment: Text.AlignVCenter
//                         text: qsTr("Not Mapped")
//                         font.pointSize: ScreenTools.largeFontPointSize*0.5
//                         visible: !mapped
//                     }
//                     ColorAnimation {
//                                            id:         barAnimation
//                                            target:     bar
//                                            property:   "color"
//                                            from:       "yellow"
//                                            to:         __barColor
//                                            duration:   1500
//                                        }
//                 }
//             }
//         }
//     }
// }

//my type
// SetupPage {
//     id: radioPage
//     pageComponent: pageComponent

//     Component {
//         id: pageComponent
//         Item {
//             width: availableWidth

//             QGCPalette { id: qgcPal; colorGroupEnabled: radioPage.enabled }

//             function setupPageCompleted() {
//                 controller.start()
//                 console.log("setupPageCompleted called")
//                 updateChannelCount()
//             }
//             function updateChannelCount() {}

//             RadioComponentController {
//                 id: controller
//                 statusText: statusText
//                 cancelButton: cancelButton
//                 nextButton: nextButton
//                 skipButton: skipButton
//                 onChannelCountChanged: updateChannelCount()
//                 onFunctionMappingChangedAPMReboot: mainWindow.showMessageDialog(qsTr("Reboot required"), qsTr("Your stick mappings have changed, you must reboot the vehicle for correct operation."))
//                 onThrottleReversedCalFailure: mainWindow.showMessageDialog(qsTr("Throttle channel reversed"), qsTr("Calibration failed. The throttle channel on your transmitter is reversed. You must correct this on your transmitter in order to complete calibration."))
//             }

//             // ----------------- StackLayout 替代 StackView -----------------
//             StackLayout {
//                 id: stackLayout
//                 anchors.fill: parent
//                 currentIndex: 0

//                 // 0 - Button Page
//                 Column {
//                     spacing: 3
//                     width: parent.width

//                     Leftbutton {
//                         text: qsTr("遥控器校准")
//                         width: parent.width
//                         onClicked: stackLayout.currentIndex = 1
//                     }
//                     Rectangle { width: parent.width; height: 1; opacity: 0.6; color: "#888888" }

//                     Leftbutton {
//                         text: qsTr("摇杆模式")
//                         width: parent.width
//                         onClicked: stackLayout.currentIndex = 2
//                     }
//                     Rectangle { width: parent.width; height: 1; opacity: 0.6; color: "#888888" }

//                     Leftbutton {
//                         text: qsTr("Spektrum 绑定")
//                         width: parent.width
//                         onClicked: stackLayout.currentIndex = 3
//                     }
//                     Rectangle { width: parent.width; height: 1; opacity: 0.6; color: "#888888" }

//                     Leftbutton {
//                         text: qsTr("其他设置")
//                         width: parent.width
//                         onClicked: stackLayout.currentIndex = 4
//                     }
//                     Rectangle { width: parent.width; height: 1; opacity: 0.6; color: "#888888" }
//                 }

//                 // 1 - Calibration Page
//                 ColumnLayout {
//                     spacing: 40
//                     QGCButton {
//                         text: qsTr("返回")
//                         onClicked: stackLayout.currentIndex = 0
//                     }
//                     Loader { id: leftColumnLoader; sourceComponent: leftColumnComponent; Layout.fillWidth: true; Layout.fillHeight: true }
//                 }

//                 // 2 - Mode Remote Page
//                 ColumnLayout {
//                     spacing: 10
//                     QGCButton {
//                         text: qsTr("返回")
//                         onClicked: stackLayout.currentIndex = 0
//                     }
//                     Loader { id: moderemoteLoader; sourceComponent: moderemote; Layout.fillWidth: true; Layout.fillHeight: true }
//                 }

//                 // 3 - Spektrum Bind Page
//                 ColumnLayout {
//                     spacing: 10
//                     QGCButton {
//                         text: qsTr("返回")
//                         onClicked: stackLayout.currentIndex = 0
//                     }
//                     Loader { id: spektrumBindLoader; sourceComponent: spektrumBindPage; Layout.fillWidth: true; Layout.fillHeight: true }
//                 }

//                 // 4 - Addition Page
//                 ColumnLayout {
//                     spacing: 10
//                     QGCButton {
//                         text: qsTr("返回")
//                         onClicked: stackLayout.currentIndex = 0
//                     }
//                     Loader { id: additionLoader; sourceComponent: addition; Layout.fillWidth: true; Layout.fillHeight: true }
//                 }
//             }

//             // ----------------- 共享按钮行 -----------------
//             Row {
//                 spacing: 10
//                 QGCButton { id: skipButton; text: qsTr("Skip"); onClicked: controller.skipButtonClicked() }
//                 QGCButton { id: cancelButton; text: qsTr("Cancel"); onClicked: controller.cancelButtonClicked() }
//                 QGCButton {
//                     id: nextButton
//                     primary: true
//                     text: qsTr("Calibrate")
//                     onClicked: {
//                         if (text === qsTr("Calibrate")) {
//                             if (controller.channelCount < controller.minChannelCount) {
//                                 mainWindow.showMessageDialog(
//                                     qsTr("Radio Not Ready"),
//                                     controller.channelCount === 0 ? qsTr("Please turn on transmitter.") :
//                                     qsTr("%1 channels or more are needed to fly.").arg(controller.minChannelCount)
//                                 )
//                             } else {
//                                 mainWindow.showMessageDialog(
//                                     qsTr("Zero Trims"),
//                                     qsTr("Before calibrating you should zero all your trims and subtrims. Click Ok to start Calibration."),
//                                     Dialog.Ok,
//                                     function() { controller.nextButtonClicked() }
//                                 )
//                             }
//                         } else {
//                             controller.nextButtonClicked()
//                         }
//                     }
//                 }
//             }

//             QGCLabel { id: statusText; width: parent.width; wrapMode: Text.WordWrap }

//             // ----------------- 原来的 Loader 页面组件 -----------------
//             // Component { id: leftColumnComponent; /* ... 保留原 leftColumnComponent 内容 ... */ }
//             Component {
//                            id: leftColumnComponent

//                            Column {
//                                width: parent.width
//                                spacing: 10

//                                // // 占位属性，用 Loader 加载后赋值
//                                // property var controller
//                                // property var qgcPal

//                                QGCLabel { text: qsTr("Attitude Controls") }

//                                Item {
//                                    width: parent.width
//                                    height: globals.defaultTextHeight * 2

//                                    QGCLabel
//                                    {
//                                        id: rollLabel;
//                                        text: qsTr("Roll");
//                                        width:  globals.defaultTextWidth *6
//                                    }

//                                    Loader {
//                                        id: rollLoader
//                                        anchors.left: rollLabel.right
//                                        anchors.right: parent.right
//                                        height: globals.defaultTextHeight
//                                        width: 80
//                                        sourceComponent: channelMonitorDisplayComponent
//                                        // property bool mapped: controller.rollChannelMapped
//                                        // property bool reversed: controller.rollChannelReversed
//                                        property bool mapped: controller ? controller.rollChannelMapped : false
//                                        property bool reversed: controller ? controller.rollChannelReversed : false
//                                    }

//                                    Connections {
//                                        target: controller
//                                        onRollChannelRCValueChanged: rcValue => rollLoader.item.rcValue = rcValue
//                                    }
//                                }
//                                Item {
//                                                        width:  parent.width
//                                                        height: globals.defaultTextHeight * 2

//                                                        QGCLabel {
//                                                            id:     pitchLabel
//                                                            width:  globals.defaultTextWidth *6
//                                                            text:   qsTr("Pitch")
//                                                        }

//                                                        Loader {
//                                                            id:                 pitchLoader
//                                                            anchors.left:       pitchLabel.right
//                                                            anchors.right:      parent.right
//                                                            height:             globals.defaultTextHeight
//                                                            width:             80
//                                                            sourceComponent:    channelMonitorDisplayComponent

//                                                            property bool mapped:           controller.pitchChannelMapped
//                                                            property bool reversed:         controller.pitchChannelReversed
//                                                        }

//                                                        Connections {
//                                                            target: controller

//                                                            onPitchChannelRCValueChanged: (rcValue) => pitchLoader.item.rcValue = rcValue
//                                                        }
//                                                    }
//                                Item {
//                                                        width:  parent.width
//                                                        height: globals.defaultTextHeight * 2

//                                                        QGCLabel {
//                                                            id:     yawLabel
//                                                            width:  globals.defaultTextWidth * 6
//                                                            text:   qsTr("Yaw")
//                                                        }

//                                                        Loader {
//                                                            id:                 yawLoader
//                                                            anchors.left:       yawLabel.right
//                                                            anchors.right:      parent.right
//                                                            height:             globals.defaultTextHeight
//                                                            width:              80
//                                                            sourceComponent:    channelMonitorDisplayComponent

//                                                            property bool mapped:           controller.yawChannelMapped
//                                                            property bool reversed:         controller.yawChannelReversed
//                                                        }

//                                                        Connections {
//                                                            target: controller

//                                                            onYawChannelRCValueChanged: (rcValue) => yawLoader.item.rcValue = rcValue
//                                                        }
//                                                    }
//                                Item {
//                                                  width:  parent.width
//                                                  height: globals.defaultTextHeight * 2

//                                                  QGCLabel {
//                                                      id:     throttleLabel
//                                                      width:  globals.defaultTextWidth * 6
//                                                      text:   qsTr("Throttle")
//                                                  }

//                                                  Loader {
//                                                      id:                 throttleLoader
//                                                      anchors.left:       throttleLabel.right
//                                                      anchors.right:      parent.right
//                                                      height:             globals.defaultTextHeight
//                                                      width:              80
//                                                      sourceComponent:    channelMonitorDisplayComponent

//                                                      property bool mapped:           controller.throttleChannelMapped
//                                                      property bool reversed:         controller.throttleChannelReversed
//                                                  }

//                                                  Connections {
//                                                      target:                             controller
//                                                      onThrottleChannelRCValueChanged:    (rcValue) => throttleLoader.item.rcValue = rcValue
//                                                  }
//                                              }

//                                Row {
//                                                   spacing: 10

//                                                   QGCButton {
//                                                       id:         skipButton
//                                                       // width:ScreenTools.defaultFontPixelWidth*6
//                                                       // height:width*0.6
//                                                       text:       qsTr("Skip")

//                                                       onClicked:  controller.skipButtonClicked()
//                                                   }

//                                                   QGCButton {
//                                                       id:         cancelButton
//                                                       text:       qsTr("Cancel")
//                                                       onClicked:  controller.cancelButtonClicked()
//                                                   }

//                                                   QGCButton {
//                                                       id:         nextButton
//                                                       primary:    true
//                                                       text:       qsTr("Calibrate")

//                                                       onClicked: {
//                                                           if (text === qsTr("Calibrate")) {
//                                                               if (controller.channelCount < controller.minChannelCount) {
//                                                                   mainWindow.showMessageDialog(qsTr("Radio Not Ready"),
//                                                                                                controller.channelCount == 0 ? qsTr("Please turn on transmitter.") :
//                                                                                                                               (controller.channelCount < controller.minChannelCount ?
//                                                                                                                                    qsTr("%1 channels or more are needed to fly.").arg(controller.minChannelCount) :
//                                                                                                                                    qsTr("Ready to calibrate.")))
//                                                               } else {
//                                                                   mainWindow.showMessageDialog(qsTr("Zero Trims"),
//                                                                                                qsTr("Before calibrating you should zero all your trims and subtrims. Click Ok to start Calibration.\n\n%1").arg(
//                                                                                                    (QGroundControl.multiVehicleManager.activeVehicle.px4Firmware ? "" : qsTr("Please ensure all motor power is disconnected AND all props are removed from the vehicle."))),
//                                                                                                Dialog.Ok,
//                                                                                                function() { controller.nextButtonClicked() })
//                                                               }
//                                                           } else {
//                                                               controller.nextButtonClicked()
//                                                           }
//                                                       }
//                                                   }
//                                               } // Row - Buttons

//                                               // Status Text
//                                               QGCLabel {
//                                                   id:         statusText
//                                                   width:      parent.width
//                                                   wrapMode:   Text.WordWrap
//                                               }
//                                          }



//                                // pitch/yaw/throttle 同理
//                            }
//                        //}
//             // Component { id: moderemote; /* ... 保留原 moderemote 内容 ... */ }
//             // Component { id: spektrumBindPage; /* ... 保留原 spektrumBindPage 内容 ... */ }
//             // Component { id: addition; /* ... 保留原 addition 内容 ... */ }
//         }
//     }
// }

