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
import QtQuick.Layouts

import QGroundControl
import QGroundControl.AutoPilotPlugin
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager

Rectangle {
    id:     setupView
    color:   Qt.rgba(0, 0, 0, 0.8)//qgcPal.windowShade
    //border.color: "white"
    z:      QGroundControl.zOrderTopMost

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    ButtonGroup { id: setupButtonGroup }

    readonly property real      _defaultTextHeight: ScreenTools.defaultFontPixelHeight
    readonly property real      _defaultTextWidth:  ScreenTools.defaultFontPixelWidth
    readonly property real      _horizontalMargin:  _defaultTextWidth / 2
    readonly property real      _verticalMargin:    _defaultTextHeight / 2
    readonly property real      _buttonWidth:       _defaultTextWidth * 18
    readonly property string    _armedVehicleText:  qsTr("This operation cannot be performed while the vehicle is armed.")

    //当前飞控是否解锁
    property bool   _vehicleArmed:                  QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.armed : false
    property string _messagePanelText:              qsTr("missing message panel text") // 消息面板文本
   //当前飞控参数是否完整可用
    property bool   _fullParameterVehicleAvailable: QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable && !QGroundControl.multiVehicleManager.activeVehicle.parameterManager.missingParameters
    property var    _corePlugin:                    QGroundControl.corePlugin// 核心插件引用

    function showSummaryPanel() {
        if (mainWindow.allowViewSwitch()) {
            _showSummaryPanel()
        }
    }

    //展示概述界面，连接和未连接有区别
    function _showSummaryPanel() {
        //车辆没有组件
        if (_fullParameterVehicleAvailable) {
            if (QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents.length === 0)
            {
                panelLoader.setSourceComponent(noComponentsVehicleSummaryComponent)
            } else {
                panelLoader.setSource("VehicleSummary.qml")
            }
            //参数不完整
        } else if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable) {
            panelLoader.setSourceComponent(missingParametersVehicleSummaryComponent)
        } else {
            panelLoader.setSourceComponent(disconnectedVehicleSummaryComponent)
        }
        summaryButton.checked = true
    }

    // 显示指定QML面板
    function showPanel(button, qmlSource) {
        if (mainWindow.allowViewSwitch()) {
            button.checked = true
            panelLoader.setSource(qmlSource)
        }
    }

     // 显示车辆组件面板
    function showVehicleComponentPanel(vehicleComponent)
    {
        if (mainWindow.allowViewSwitch()) {
            var autopilotPlugin = QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin
            var prereq = autopilotPlugin.prerequisiteSetup(vehicleComponent)
            if (prereq !== "") {
                _messagePanelText = qsTr("%1 setup must be completed prior to %2 setup.").arg(prereq).arg(vehicleComponent.name)
                panelLoader.setSourceComponent(messagePanelComponent)
            } else {
                panelLoader.setSource(vehicleComponent.setupSource, vehicleComponent)
                for(var i = 0; i < componentRepeater.count; i++) {
                    var obj = componentRepeater.itemAt(i);
                    if (obj.text === vehicleComponent.name) {
                        obj.checked = true
                        break;
                    }
                }
            }
        }
    }

      // 显示参数编辑器
    function showParametersPanel() {
        if (mainWindow.allowViewSwitch()) {
            parametersButton.checked = true
            panelLoader.setSource("SetupParameterEditor.qml")
        }
    }

    //展示概述界面
    Component.onCompleted: _showSummaryPanel()

    Connections {
        target: QGroundControl.corePlugin
        onShowAdvancedUIChanged: {
            if(!QGroundControl.corePlugin.showAdvancedUI) {
                _showSummaryPanel()
            }
        }
    }

    //在以下情况下显示/重新加载“摘要”面板：
    //一辆新车出现，摘要面板已显示，活动车辆消失，活动车辆消失，我们不在固件面板上。
    Connections {
        target: QGroundControl.multiVehicleManager
        onParameterReadyVehicleAvailableChanged: {
            if (QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable || summaryButton.checked || setupButtonGroup.current != firmwareButton) {
                // Show/Reload the Summary panel when:
                //      A new vehicle shows up
                //      The summary panel is already showing and the active vehicle goes away
                //      The active vehicle goes away and we are not on the Firmware panel.
                summaryButton.checked = true
                _showSummaryPanel()
            }
        }
    }
//用于右侧面板不同状态显示提示信息
//未连接时显示的面板
    Component {
        id: noComponentsVehicleSummaryComponent
        Rectangle {
            color:  Qt.rgba(0, 0, 0, 0.8)/*qgcPal.windowShade*/
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("%1 does not currently support setup of your vehicle type. ").arg(QGroundControl.appName) +
                                        "If your vehicle is already configured you can still Fly."
                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    //未连接时面板
    Component {
        id: disconnectedVehicleSummaryComponent
        Rectangle {
            color: Qt.rgba(0, 0, 0, 0.8) /*qgcPal.windowShade*/
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.largeFontPointSize
                text:                   qsTr("Vehicle settings and info will display after connecting your vehicle.") +
                                        (ScreenTools.isMobile || !_corePlugin.options.showFirmwareUpgrade ? "" : " Click Firmware on the left to upgrade your vehicle.")

                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    //参数不完整时显示
    Component {
        id: missingParametersVehicleSummaryComponent

        Rectangle {
            color: Qt.rgba(0, 0, 0, 0.8)//qgcPal.windowShade

            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   qsTr("You are currently connected to a vehicle but it did not return the full parameter list. ") +
                                        qsTr("As a result, the full set of vehicle setup options are not available.")

                onLinkActivated: (link) => Qt.openUrlExternally(link)
            }
        }
    }

    // 车辆连接/断开时自动更新显示
    Component {
        id: messagePanelComponent

        Item {
            QGCLabel {
                anchors.margins:        _defaultTextWidth * 2
                anchors.fill:           parent
                verticalAlignment:      Text.AlignVCenter
                horizontalAlignment:    Text.AlignHCenter
                wrapMode:               Text.WordWrap
                font.pointSize:         ScreenTools.mediumFontPointSize
                text:                   _messagePanelText
            }
        }
    }

    QGCFlickable {
        id:                 buttonScroll
        width:              buttonColumn.width
        anchors.topMargin:  _defaultTextHeight / 2
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _horizontalMargin
        anchors.left:       parent.left
        contentHeight:      buttonColumn.height
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        ColumnLayout {
            id:         buttonColumn
            spacing:    ScreenTools.defaultFontPixelHeight / 4

            // 概述按钮
            ConfigButton {
                id:                 summaryButton
                icon.source:        "/qmlimages/VehicleSummaryIcon.png"
                checked:            true
                text:               qsTr("Summary")
                Layout.fillWidth:   true

                onClicked: showSummaryPanel()
            }

            // 光学Flow配置
            //这个按钮是打开「光学流传感器配置面板」的，用于设置无人机上安装的光学 Flow 传感器参数。光学 Flow 可以帮助无人机在没有 GPS 的环境下保持位置稳定
            ConfigButton {
                //根据 activeVehicle.flowImageIndex 判断,只有当前有飞机连接，并且飞机上安装了 Flow 传感器，按钮才显示
                visible:           QGroundControl.multiVehicleManager.activeVehicle ? QGroundControl.multiVehicleManager.activeVehicle.flowImageIndex > 0 : false
                text:               qsTr("Optical Flow")
                Layout.fillWidth:   true
                onClicked:          showPanel(this, "OpticalFlowSensor.qml")
            }

            // 摇杆配置,电脑上的 USB/蓝牙摇杆或者键盘按键,直接通过操作系统输入（JoystickManager 管理）qgc
            //用于打开「遥控器/摇杆配置面板」，可以设置外接摇杆或者遥控器的参数
            //也就是只有当前有飞机，并且系统检测到至少一个摇杆设备，按钮才显示
            ConfigButton {
                id:                 joystickButton
                icon.source:      "/qmlimages/Joystick.png"
                setupComplete:      _activeJoystick ? _activeJoystick.calibrated || _buttonsOnly : false
                visible:            _fullParameterVehicleAvailable && joystickManager.joysticks.length !== 0
                text:               _forcedToButtonsOnly ? qsTr("Buttons") : qsTr("Joystick")
                Layout.fillWidth:   true
                onClicked:          showPanel(this, "JoystickConfig.qml")

                property var    _activeJoystick:        joystickManager.activeJoystick
                property bool   _buttonsOnly:           _activeJoystick ? _activeJoystick.axisCount == 0 : false
                property bool   _forcedToButtonsOnly:   !QGroundControl.corePlugin.options.allowJoystickSelection && _buttonsOnly
            }

             // 动态车辆组件按钮
            Repeater {
                id:     componentRepeater
                model:  _fullParameterVehicleAvailable ? QGroundControl.multiVehicleManager.activeVehicle.autopilotPlugin.vehicleComponents : 0

                ConfigButton {
                    icon.source:      modelData.iconResource
                    setupComplete:      modelData.setupComplete
                    text:               modelData.name
                    visible:            modelData.setupSource.toString() !== ""
                    Layout.fillWidth:   true
                    onClicked:          showVehicleComponentPanel(componentUrl)

                    property var componentUrl: modelData
                }
            }

            // 参数编辑器
            ConfigButton {
                id:                 parametersButton
                // 高级UI模式且非高延迟链路时可见
                visible:            QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable &&
                                    !QGroundControl.multiVehicleManager.activeVehicle.usingHighLatencyLink &&
                                    _corePlugin.showAdvancedUI
                text:               qsTr("Parameters")
                Layout.fillWidth:   true
                icon.source:        "/qmlimages/subMenuButtonImage.png"
                onClicked:          showPanel(this, "SetupParameterEditor.qml")
            }

            // 固件升级
            ConfigButton {
                id:                 firmwareButton
                icon.source:      "/qmlimages/FirmwareUpgradeIcon.png"
                //非移动端且允许固件升级时可见
                visible:            !ScreenTools.isMobile && _corePlugin.options.showFirmwareUpgrade
                text:               qsTr("Firmware")
                Layout.fillWidth:   true

                onClicked: showPanel(this, "FirmwareUpgrade.qml")
            }
        }
    }

    Rectangle {
        id:                     divider
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.leftMargin:     _horizontalMargin
        anchors.left:           buttonScroll.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        width:                  1
        color:  "white "          /* qgcPal.windowShade*/
    }

    //右侧内容面板 (panelLoader)
    Loader {
        id:                     panelLoader
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.leftMargin:     _horizontalMargin
        anchors.rightMargin:    _horizontalMargin
        anchors.left:           divider.right
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom

        // 动态加载不同的配置页面
        function setSource(source, vehicleComponent) {
            panelLoader.source = ""
            panelLoader.vehicleComponent = vehicleComponent
            panelLoader.source = source
        }

        function setSourceComponent(sourceComponent, vehicleComponent) {
            panelLoader.sourceComponent = undefined
            panelLoader.vehicleComponent = vehicleComponent
            panelLoader.sourceComponent = sourceComponent
        }

        property var vehicleComponent
    }
}
