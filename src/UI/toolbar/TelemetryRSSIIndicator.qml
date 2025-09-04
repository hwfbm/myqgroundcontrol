/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette

//-------------------------------------------------------------------------
//-- Telemetry RSSI
//显示当前无人机与地面站之间 数传链路的信号质量
Item {
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          telemIcon.width * 1.1

    property bool showIndicator:true// _hasTelemetry

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    property bool _hasTelemetry:    true//_activeVehicle.telemetryLRSSI !== 0 //如果你没有连接数传模块（比如用 Wi-Fi / USB），它一般是 0，就不会显示

    QGCColoredImage {
        id:                 telemIcon
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        width:             ScreenTools.defaultFontPixelHeight*1.5 //height
        sourceSize.height:  height
        source:             "/qmlimages/datachange.svg"/*"/qmlimages/TelemRSSI.svg"*/
        fillMode:           Image.PreserveAspectFit
        color:              qgcPal.buttonText
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(telemRSSIInfoPage, control)
    }

    Component {
        id: telemRSSIInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("Telemetry RSSI Status")

                LabelledLabel {
                    label:      qsTr("Local RSSI:")
                    labelText:  _activeVehicle.telemetryLRSSI + " " + qsTr("dBm")
                }

                LabelledLabel {
                    label:      qsTr("Remote RSSI:")
                    labelText:  _activeVehicle.telemetryRRSSI + " " + qsTr("dBm")
                }

                LabelledLabel {
                    label:      qsTr("RX Errors:")
                    labelText:  _activeVehicle.telemetryRXErrors
                }

                LabelledLabel {
                    label:      qsTr("Errors Fixed:")
                    labelText:  _activeVehicle.telemetryFixed
                }

                LabelledLabel {
                    label:      qsTr("TX Buffer:")
                    labelText:  _activeVehicle.telemetryTXBuffer
                }

                LabelledLabel {
                    label:      qsTr("Local Noise:")
                    labelText:  _activeVehicle.telemetryLNoise
                }

                LabelledLabel {
                    label:      qsTr("Remote Noise:")
                    labelText:  _activeVehicle.telemetryRNoise
                }
            }
        }
    }
}
