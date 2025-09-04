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

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Palette

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _mavlinkSettings:           _settingsManager.mavlinkSettings
    property var    _appSettings:               _settingsManager.appSettings
    property bool   _disableAllDataPersistence: _appSettings.disableAllPersistence.rawValue
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property string _notConnectedStr:           qsTr("Not Connected")
    property bool   _isAPM:                     _activeVehicle ? _activeVehicle.apmFirmware : true
    property bool   _showAPMStreamRates:        QGroundControl.apmFirmwareSupported && _settingsManager.apmMavlinkStreamRateSettings.visible && _isAPM
    property var    _apmStartMavlinkStreams:    _mavlinkSettings.apmStartMavlinkStreams


    //地面站的系统 ID（默认 255）。多地面站/复杂网络时需要区分；日常单机飞行几乎不改
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Ground Station")

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("MAVLink System ID")
            fact:               _mavlinkSettings.gcsMavlinkSystemID
        }

        //地面站是否向链路发心跳。大部分情况建议开启
        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Emit heartbeat")
            fact:               _mavlinkSettings.sendGCSHeartbeat
        }
    }


    //MAVLink2 签名密钥 Fact（需要安全链路传输）
    SettingsGroupLayout {
        id:                 mavlink2SigningGroup
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink 2 Signing")
        headingDescription: qsTr("Signing keys should only be sent to the vehicle over secure links.")
        visible:            _mavlink2SigningKey.visible

        property Fact _mavlink2SigningKey: _mavlinkSettings.mavlink2SigningKey
        Connections {
            target: mavlink2SigningGroup._mavlink2SigningKey
            onRawValueChanged: sendToVehiclePrompt.visible = true
        }

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            LabelledFactTextField {
                Layout.fillWidth:           true
                textFieldPreferredWidth:     ScreenTools.defaultFontPixelWidth * 25  // 改小点,这是宽度
                label:                      qsTr("Key")
                fact:                       mavlink2SigningGroup._mavlink2SigningKey
            }

            QGCButton {
                Layout.alignment: Qt.AlignRight   // 按钮靠右
                text:       qsTr("Send to Vehicle")
                enabled:    _activeVehicle
                onClicked: {
                    sendToVehiclePrompt.visible = false
                    _activeVehicle.sendSetupSigning()
                }
            }
        }

        QGCLabel {
            id:                 sendToVehiclePrompt
            Layout.fillWidth:   true
            text:               qsTr("Signing key has changed. Don't forget to send to Vehicle(s) if needed.")
            visible:            false
            wrapMode:           Text.WordWrap   // 窄屏换行
        }
    }

    // SettingsGroupLayout {
    //     id:                 mavlink2SigningGroup
    //     Layout.fillWidth:   true
    //     heading:            qsTr("MAVLink 2 Signing")
    //     headingDescription: qsTr("Signing keys should only be sent to the vehicle over secure links.")
    //     visible:            _mavlink2SigningKey.visible

    //     property Fact _mavlink2SigningKey: _mavlinkSettings.mavlink2SigningKey

    //     Connections {
    //         target:             mavlink2SigningGroup._mavlink2SigningKey
    //         onRawValueChanged:  sendToVehiclePrompt.visible = true
    //     }

    //     RowLayout {
    //         spacing: ScreenTools.defaultFontPixelWidth

    //         LabelledFactTextField {
    //             Layout.fillWidth:           true
    //             textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 32
    //             label:                      qsTr("Key")
    //             fact:                       mavlink2SigningGroup._mavlink2SigningKey
    //         }

    //         QGCButton {
    //             text:       qsTr("Send to Vehicle")
    //             enabled:    _activeVehicle

    //             onClicked: {
    //                 sendToVehiclePrompt.visible = false
    //                 _activeVehicle.sendSetupSigning()
    //             }
    //         }
    //     }

    //     QGCLabel {
    //         id:                 sendToVehiclePrompt
    //         Layout.fillWidth:   true
    //         text:               qsTr("Signing key has changed. Don't forget to send to Vehicle(s) if needed.")
    //         visible:            false
    //     }
    // }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("MAVLink Forwarding")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable")
            fact:               _mavlinkSettings.forwardMavlink
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 20//调整 输入框的宽度
            label:                      qsTr("Host name")
            fact:                       _mavlinkSettings.forwardMavlinkHostName
            visible:                    fact.visible
            enabled:                    _mavlinkSettings.forwardMavlink.rawValue
        }
    }


    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Logging")
        visible:            !_disableAllDataPersistence

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            //每次飞行后保存 telemetry log
            text:               qsTr("Save log after each flight")
            fact:               _telemetrySave
            visible:            fact.visible
            property Fact _telemetrySave: _mavlinkSettings.telemetrySave
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            //未解锁也保存（地面调试/仿真时有用）
            text:               qsTr("Save logs even if vehicle was not armed")
            fact:               _telemetrySaveNotArmed
            visible:            fact.visible
            enabled:            _mavlinkSettings.telemetrySave.rawValue
            property Fact _telemetrySaveNotArmed: _mavlinkSettings.telemetrySaveNotArmed
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            //另存 CSV 格式（体积大、但易分析）
            text:               qsTr("Save CSV log of telemetry data")
            fact:               _saveCsvTelemetry
            visible:            fact.visible
            property Fact _saveCsvTelemetry: _mavlinkSettings.saveCsvTelemetry
        }
    }

    //数据流速率，APM 专属
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Stream Rates (ArduPilot Only)")
        visible:           _showAPMStreamRates

        //勾上=由飞机端控制流；取消=由 QGC 控制，并需你在下面的各项选择速率。
        //它与 _apmStartMavlinkStreams 互斥，代码里通过 checked/onClicked 反向同步
        QGCCheckBoxSlider {
            id:                 controllerByVehicleCheckBox
            Layout.fillWidth:   true
            text:               qsTr("Controlled By vehicle")
            checked:            !_apmStartMavlinkStreams.rawValue
            onClicked:          _apmStartMavlinkStreams.rawValue = !checked
        }

        //APM 的经典 MAVLink 流，选择速率枚举（通常 0=禁、1/2/4/10/…Hz）
        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Raw Sensors")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRawSensors
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extended Status")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtendedStatus
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("RC Channels")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateRCChannels
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Position")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRatePosition
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 1")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra1
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 2")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra2
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Extra 3")
            fact:               _settingsManager.apmMavlinkStreamRateSettings.streamRateExtra3
            indexModel:         false
            enabled:            !controllerByVehicleCheckBox.checked
        }
    }

    //当前链路状态，只读,未连接时显示 _notConnectedStr
    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Link Status (Current Vehicle))")

        //已发/已收消息数
        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages sent (computed)")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkSentCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total messages received")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkReceivedCount : _notConnectedStr
        }

        //丢包量与丢包率 %（toFixed(0)）
        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Total message loss")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossCount : _notConnectedStr
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Loss rate:")
            labelText:          _activeVehicle ? _activeVehicle.mavlinkLossPercent.toFixed(0) + '%' : _notConnectedStr
        }

        //当前是否启用签名
        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Signing:")
            labelText:          _activeVehicle ? (_activeVehicle.mavlinkSigning ? "On" : "Off") : _notConnectedStr
        }
    }
}
