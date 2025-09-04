/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

//云台（Gimbal）指示器和控制面板
// 在主界面显示云台状态（图标 + 姿态数值）
// 点击后弹出一个控制面板，可以执行常用云台动作（居中、锁定、倾斜 90°、回家等）
// 支持多云台选择（如果有多个云台设备）
// 提供云台的详细设置面板（控制模式、FOV、速度、是否在地图上显示方位等）
// 实时显示云台的姿态数据（Pitch、Yaw/Azimuth）
Item {
    id:             control
    width:          gimbalIndicatorIcon.width * 1.1 + gimbalTelemetryLayout.childrenRect.width + margins
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

    property var    activeVehicle:              QGroundControl.multiVehicleManager.activeVehicle
    property var    gimbalController:           activeVehicle.gimbalController  //该飞行器上的云台控制器对象
    property bool   showIndicator:              true//gimbalController && gimbalController.gimbals.count //是否显示云台指示器（有云台设备时才显示）
    property var    activeGimbal:               gimbalController.activeGimbal //当前激活的云台对象
    property var    multiGimbalSetup:           gimbalController.gimbals.count > 1 //是否有多个云台
    property bool   joystickButtonsAvailable:   activeVehicle.joystickEnabled

    property var    margins:                    ScreenTools.defaultFontPixelWidth
    property var    panelRadius:                ScreenTools.defaultFontPixelWidth * 0.5
    property var    buttonHeight:               height * 1.6
    property var    squareButtonPadding:        ScreenTools.defaultFontPixelWidth
    property var    separatorHeight:            buttonHeight * 0.9
    property var    settingsPanelVisible:       false

    // Popup panel, appears when clicking top toolbar gimbal indicator
    //点击图标时会弹出
    Component {
        id: gimbalControlsPage

        ToolIndicatorPage {
            contentComponent: GridLayout {
                // Label indicating the purpose of the panel and active gimbal instance
                //面板标题,显示 Gimbal ID + Controls（多云台时显示 ID）
                QGCLabel {
                    text:                   qsTr("云台 ") +
                                                (multiGimbalSetup ? activeGimbal.deviceId.rawValue : "") + 
                                                    qsTr("<br> Controls")

                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.preferredWidth:  buttonHeight * 1.1
                    font.weight:            Font.DemiBold
                }

                // These are simple buttons that can be grouped on this Repeater
                //云台控制按钮
                Repeater {
                    id: simpleGimbalButtonsRepeater
                    property var hasControl:              gimbalController && gimbalController.activeGimbal && gimbalController.activeGimbal.gimbalHaveControl
                    property var acqControlButtonEnabled: QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAcquireReleaseControl.rawValue

                    model: [
                        {id: "yawLock",   text: activeGimbal.yawLock ? qsTr("Yaw <br> Follow") : qsTr("Yaw <br> Lock")  , visible: true                    },/*切换云台的偏航模式*/
                        {id: "center",    text: qsTr("Center")                                                          , visible: true                    },/*云台回中*/
                        {id: "tilt90",    text: qsTr("Tilt 90")                                                         , visible: true                    },/*云台俯仰到 -90°*/
                        {id: "pointHome", text: qsTr("Point <br> Home")                                                 , visible: true                    },/*指向家的位置*/
                        {id: "retract",   text: qsTr("Retract")                                                         , visible: true                    },/*收回云台*/
                        {id: "acqControl",text: hasControl ? qsTr("Release <br> Control") : qsTr("Acquire <br> Control"), visible: acqControlButtonEnabled }/*获取或释放云台控制权*/
                    ]

                    QGCButton {
                        property var callbackList: [
                           {"yawLock":      function(){ gimbalController.toggleGimbalYawLock(!activeGimbal.yawLock) }   },
                           {"center":       function(){ gimbalController.centerGimbal() }                               },
                           {"tilt90":       function(){ gimbalController.sendPitchBodyYaw(-90, 0) }                     },
                           {"pointHome":    function(){ activeVehicle.guidedModeROI(activeVehicle.homePosition) }       },
                           {"retract":      function(){ gimbalController.toggleGimbalRetracted(true) }                  },
                           // This button changes its action depending on gimbal being under control or not
                           {"acqControl":   function(){ simpleGimbalButtonsRepeater.hasControl ? 
                                                            gimbalController.releaseGimbalControl() : 
                                                                gimbalController.acquireGimbalControl() }               }
                        ]

                        Layout.preferredWidth: Layout.preferredHeight
                        Layout.preferredHeight: buttonHeight
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        text: modelData.text
                        fontWeight: Font.DemiBold
                        visible: modelData.visible
                        pointSize: ScreenTools.smallFontPointSize
                        backRadius: panelRadius * 0.5
                        leftPadding: squareButtonPadding
                        rightPadding: squareButtonPadding
                        onClicked: {
                            var callback = callbackList.find(function(item) {
                                return item.hasOwnProperty(modelData.id);
                            });
                            if (callback !== undefined) {
                                callback[modelData.id]();
                            }
                        }
                    }
                }

                // Separator          
                // 多云台选择器
                // 如果有多个云台，会显示“Active Gimbal”标签和“Select Gimbal”按钮
                // 点击按钮展开一个面板，列出所有云台（Repeater 生成），点击切换激活的云台
                Rectangle {
                    Layout.leftMargin:      margins
                    Layout.preferredWidth:  2
                    Layout.preferredHeight: separatorHeight
                    color:                  qgcPal.windowShade
                    visible:                multiGimbalSetup
                }

                // Active gimbal selector section
                QGCLabel {
                    text:                   qsTr("Active <br> Gimbal: ") + activeGimbal.deviceId.rawValue
                    font.pointSize:         ScreenTools.smallFontPointSize
                    Layout.preferredWidth:  buttonHeight * 1.1
                    Layout.leftMargin:      margins
                    font.weight:            Font.DemiBold
                    visible:                multiGimbalSetup
                }
                QGCButton {
                    id:                     gimbalSelectorButton
                    Layout.preferredWidth:  Layout.preferredHeight
                    Layout.preferredHeight: buttonHeight
                    Layout.alignment:       Qt.AlignHCenter | Qt.AlignBottom
                    text:                   qsTr("Select <br> Gimbal")
                    fontWeight:             Font.DemiBold
                    pointSize:              ScreenTools.smallFontPointSize
                    backRadius:             panelRadius * 0.5
                    visible:                multiGimbalSetup
                    checkable:              true

                    // This rectangle is to hide the "roundness" of panels when showing the dropdown, in the join between the 2 panels
                    Rectangle {
                        id:                         hideRoundCornersRectangle
                        anchors.verticalCenter:     gimbalSelectorPanel.top
                        anchors.horizontalCenter:   gimbalSelectorPanel.horizontalCenter
                        width:                      gimbalSelectorPanel.width
                        height:                     panelRadius * 2
                        color:                      qgcPal.window
                        visible:                    gimbalSelectorPanel.visible
                    }
                    
                    Rectangle {
                        id:                         gimbalSelectorPanel
                        width:                      buttonHeight + margins * 2
                        height:                     gimbalSelectorContentGrid.childrenRect.height + margins * 2
                        visible:                    gimbalSelectorButton.checked
                        color:                      qgcPal.window
                        radius:                     panelRadius
                        // We only show border if the extended settings panel is visible
                        border.color:               settingsPanelVisible ? qgcPal.windowShade : qgcPal.window
                        border.width:               5

                        anchors.top:                parent.bottom
                        anchors.horizontalCenter:   parent.horizontalCenter
                        anchors.topMargin:          margins

                        property var buttonWidth:    width - margins * 2
                        property var panelHeight:    gimbalSelectorContentGrid.childrenRect.height + margins * 2
                        property var gridRowSpacing: margins
                        property var buttonFontSize: ScreenTools.smallFontPointSize * 0.9

                        GridLayout {
                            id:               gimbalSelectorContentGrid
                            width:            parent.width
                            rowSpacing:       gimbalSelectorPanel.gridRowSpacing
                            columns:          1

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top:              parent.top
                            anchors.topMargin:        margins

                            Repeater {
                                model: gimbalController && gimbalController.gimbals ? gimbalController.gimbals : undefined
                                delegate: QGCButton {
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    Layout.preferredHeight: buttonHeight
                                    Layout.alignment:       Qt.AlignHCenter | Qt.AlignVCenter
                                    fontWeight:             Font.DemiBold
                                    pointSize:              ScreenTools.smallFontPointSize
                                    backRadius:             panelRadius * 0.5
                                    text:                   qsTr("Gimbal ") + object.deviceId.rawValue
                                    checked:                activeGimbal === object
                                    onClicked: {
                                        gimbalController.activeGimbal = object
                                        gimbalSelectorButton.checked = false
                                    }
                                }
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    Layout.leftMargin:      margins
                    Layout.preferredWidth:  2
                    Layout.preferredHeight: separatorHeight
                    color:                  qgcPal.windowShade
                }

                // Show settings button. It is thought for persisting popup close actions, hence the visibility
                // based on a control.settingsPanelVisible It is interesting as users calibrating onscreen controls 
                // will be testing and adjusting these frequently, so this way it is handier for them
                //Settings 设置面板
                QGCButton {
                    id:                     extendedOptionsButton
                    Layout.leftMargin:      margins
                    Layout.preferredWidth:  Layout.preferredHeight
                    Layout.preferredHeight: buttonHeight
                    Layout.alignment:       Qt.AlignHCenter | Qt.AlignBottom
                    text:                   qsTr("Settings")
                    fontWeight:             Font.DemiBold
                    pointSize:              ScreenTools.smallFontPointSize
                    backRadius:             panelRadius * 0.5
                    checkable:              true
                    checked:                control.settingsPanelVisible
                    leftPadding:            squareButtonPadding
                    rightPadding:           squareButtonPadding
                    onCheckedChanged: {
                        if (checked !== control.settingsPanelVisible) {
                            control.settingsPanelVisible = checked
                        }
                    }
                }

                // Settings panel

                // GridLayout {
                //     Layout.row:         2
                //     Layout.columnSpan:  8
                //     Layout.fillWidth:   true
                //     height:             buttonHeight * 1.5
                //     visible:            settingsPanelVisible
                //     columns:            2
                //     rowSpacing:         margins

                //     // Click on screen settings
                //     FactCheckBox {
                //         //是否启用屏幕上的云台控制
                //         id:                 enableOnScreenControlCheckbox
                //         text:               "  " + QGroundControl.settingsManager.gimbalControllerSettings.EnableOnScreenControl.shortDescription
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.EnableOnScreenControl
                //         checkedValue:       1
                //         uncheckedValue:     0
                //         Layout.columnSpan:  2
                //     }

                //     //控制方式（角度控制 / 速度控制）
                //     QGCLabel {
                //         id:                 controlTypeLabel
                //         text:               qsTr("Control type: ")
                //         visible:            enableOnScreenControlCheckbox.checked
                //     }
                //     FactComboBox {
                //         id:                 controlTypeCombo
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.ControlType
                //         visible:            enableOnScreenControlCheckbox.checked
                //     }

                //     QGCLabel {
                //         //角度模式
                //         text:               qsTr("Horizontal FOV")
                //         visible:            enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
                //     }
                //     FactTextField {
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.CameraHFov
                //         visible:            enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
                //     }

                //     QGCLabel {
                //         text:               qsTr("Vertical FOV")
                //         visible:            enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
                //     }
                //     FactTextField {
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.CameraVFov
                //         visible:            enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
                //     }

                //     //速度模式
                //     QGCLabel {
                //         text:               qsTr("Max speed:")
                //         visible:            enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 1
                //     }
                //     FactTextField {
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.CameraSlideSpeed
                //         visible:            enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 1
                //     }

                //     // Separator
                //     Rectangle {
                //         Layout.columnSpan:       2
                //         Layout.preferredHeight:  2
                //         Layout.preferredWidth:   gimbalAzimuthMapCheckbox.width
                //         Layout.margins:          margins
                //         color:                   qgcPal.windowShade
                //     }

                //     QGCLabel {
                //         //摇杆按钮控制速度
                //         text:               qsTr("Joystick buttons speed:")
                //         visible:            joystickButtonsAvailable && QGroundControl.settingsManager.gimbalControllerSettings.visible
                //     }
                //     FactTextField {
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.joystickButtonsSpeed
                //         visible:            joystickButtonsAvailable && QGroundControl.settingsManager.gimbalControllerSettings.visible
                //         showHelp:           true
                //     }

                //     // Separator
                //     Rectangle {
                //         Layout.columnSpan:       2
                //         Layout.preferredHeight:  2
                //         Layout.preferredWidth:   gimbalAzimuthMapCheckbox.width
                //         Layout.margins:          margins
                //         color:                   qgcPal.windowShade
                //         visible:                 joystickButtonsAvailable && QGroundControl.settingsManager.gimbalControllerSettings.visible
                //     }

                //     FactCheckBox {
                //         id:                 gimbalAzimuthMapCheckbox
                //         text:               "  " + qsTr("Show gimbal Azimuth indicator in map")
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.showAzimuthIndicatorOnMap
                //         Layout.columnSpan:  2
                //         checkedValue:       1
                //         uncheckedValue:     0
                //     }

                //     FactCheckBox {
                //         id:                 gimbalAzimutIndicatorCheckbox
                //         text:               "  " + qsTr("Use Azimuth instead of local yaw on top toolbar indicator")
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAzimuth
                //         Layout.columnSpan:  2
                //         checkedValue:       1
                //         uncheckedValue:     0
                //     }

                //     FactCheckBox {
                //         id:                 showAcquireControlCheckbox
                //         text:               "  " + qsTr("Show Acquire/Release control button")
                //         fact:               QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAcquireReleaseControl
                //         Layout.columnSpan:  2
                //         checkedValue:       1
                //         uncheckedValue:     0
                //     }
                // }
            }
        }
    }

    // Icon plus active instance indicator
    QGCColoredImage {
        id:                      gimbalIndicatorIcon
        width:                   height
        anchors.top:             parent.top
        anchors.bottom:          parent.bottom
        source:                  "/gimbal/payload.svg"
        fillMode:                Image.PreserveAspectFit
        sourceSize.height:       height
        color:                   qgcPal.buttonText

        // Current active gimbal indicator
        //如果是多云台，在图标上方右侧显示云台 ID
        QGCLabel {
            id:                  gimbalInstanceIndicatorLabel
            text:                activeGimbal ? activeGimbal.deviceId.rawValue : ""
            visible:             multiGimbalSetup
            anchors.top:         parent.top
            anchors.topMargin:   -margins * 0.5
            anchors.right:       parent.right
            anchors.rightMargin: -margins * 0.5
        }
    }

    // Telemetry and status indicator
//顶部工具栏中云台姿态和状态的 telemetry 区域，主要功能就是实时显示云台的状态、俯仰角和偏航角/方位角
    GridLayout {
        id:                        gimbalTelemetryLayout
        anchors.left:              gimbalIndicatorIcon.right
        anchors.leftMargin:        margins
        anchors.verticalCenter:    parent.verticalCenter
        columns:                   2
        rows:                      2
        rowSpacing:                0
        columnSpacing:             margins
        property bool showAzimuth: QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAzimuth.rawValue

        //云台收回，偏航锁定，偏航跟随
        QGCLabel {
            id:                     statusLabel
            text:                   activeGimbal && activeGimbal.retracted ? 
                                        qsTr("Retracted") :
                                        (activeGimbal && activeGimbal.yawLock ? qsTr("Yaw locked") : qsTr("Yaw follow"))
               font.pointSize:ScreenTools.largeFontPointSize*0.5
            Layout.columnSpan:      2
            Layout.alignment:       Qt.AlignHCenter
        }
        //显示云台俯仰角（Pitch），实时刷新，当云台对象存在时才显示，例如：P: 12.3
        QGCLabel {
            id:                     pitchLabel
            text:                   activeGimbal ? qsTr("P: ") + activeGimbal.absolutePitch.rawValue.toFixed(1) : ""
               font.pointSize:ScreenTools.largeFontPointSize*0.5
        }
        //偏航角 / 方位角标签
        //显示内容取决于 showAzimuth
        // showAzimuth = true → 显示绝对方位角 absoluteYaw，标签前缀 "Az:"
        // showAzimuth = false → 显示机体偏航 bodyYaw，标签前缀 "Y:"
        // 例如：Az: 123.4 或 Y: 45.6
        QGCLabel {
            id:                     panLabel
            text:                   activeGimbal ? 
                                        gimbalTelemetryLayout.showAzimuth ? (qsTr("Az: ") + activeGimbal.absoluteYaw.rawValue.toFixed(1)) :
                                            (qsTr("Y: ") + activeGimbal.bodyYaw.rawValue.toFixed(1)) :
                                                ""
          font.pointSize:ScreenTools.largeFontPointSize*0.5
        }
    }

        //点击图标会在 QGC 主窗口右侧或顶部弹出控制面板。
    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(gimbalControlsPage, control)
    }//gimbalControlsPage是加载的组件，Popup 会贴近control显示，就是一个侧面小面板

    //  // 弹出提示框，询问是否请求控制权，如果当前云台控制权被其他人占用，弹出对话框询问是否申请控制权
    Connections {
        id:                         acquirePopupConnection
        property bool isPopupOpen:  false
        target:                     gimbalController
        onShowAcquireGimbalControlPopup: {
            if(!acquirePopupConnection.isPopupOpen){
                acquirePopupConnection.isPopupOpen = true;
                mainWindow.showMessageDialog(
                    "Request Gimbal Control?",
                    "Command not sent. Another user has control of the gimbal.",
                    Dialog.Yes | Dialog.No,
                    gimbalController.acquireGimbalControl,
                    function() { acquirePopupConnection.isPopupOpen = false }
                )
            }
        }
    }
}
