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
//-- RC RSSI Indicator
//遥控器信号
Item {
    id:             control
    width:          rssiRow.width * 1.1
    anchors.top:    parent.top
    anchors.bottom: parent.bottom

//只有飞控支持遥控输入 (supportsRadio) 且 rcRSSI 在 (0, 100] 范围内时才显示
    property bool showIndicator:true// _activeVehicle.supportsRadio && _rcRSSIAvailable
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    //防止数据异常（如 -1 或 255）导致显示错误
    property bool   _rcRSSIAvailable:true // _activeVehicle.rcRSSI > 0 && _activeVehicle.rcRSSI <= 100

    Component {
        id: rcRSSIInfoPage

        ToolIndicatorPage {
            showExpand: false

            contentComponent: SettingsGroupLayout {
                heading: qsTr("RC RSSI Status")

                LabelledLabel {
                    label:      qsTr("RSSI")
                    labelText:  _activeVehicle.rcRSSI + "%"
                }
            }
        }
    }

    Row {
        id:             rssiRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        spacing:        ScreenTools.defaultFontPixelWidth*0.3

        QGCColoredImage {
            width:              ScreenTools.defaultFontPixelWidth * 2// height
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            sourceSize.height:  height/*/qmlimages/RC.svg*/
            source:             "/qmlimages/remote_control.svg"
            fillMode:           Image.PreserveAspectFit
            opacity:            _rcRSSIAvailable ? 1 : 0.5
            color:              qgcPal.buttonText
        }


        //类似 WiFi 信号格的动画，显示 RSSI 百分比
        SignalStrength {
            anchors.verticalCenter: parent.verticalCenter
            size:                  ScreenTools.defaultFontPixelWidth * 2 /*parent.height*/ /** 0.7*/
            percent:                _rcRSSIAvailable ? _activeVehicle.rcRSSI : 0
        }
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      mainWindow.showIndicatorDrawer(rcRSSIInfoPage, control)
    }
}
