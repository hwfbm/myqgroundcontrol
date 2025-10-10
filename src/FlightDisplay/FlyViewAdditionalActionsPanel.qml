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

//实现了一个飞行视图附加动作面板
ColumnLayout {
    property var additionalActions
    property var mavlinkActions
    property var customActions

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property var  _guidedController:    globals.guidedControllerFlyView

    // Pre-defined Additional Guided Actions
    Repeater {
        // 系统动作模型
        model: additionalActions.model

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData.title
            visible:            modelData.visible

            onClicked: {
                dropPanel.hide()
                _guidedController.confirmAction(modelData.action)
            }
        }
    }

    // Custom Build Actions
    Repeater {
         // 自定义动作模型
        model: customActions.model

        QGCButton {
            Layout.fillWidth:   true
            text:               modelData.title
            visible:            modelData.visible

            onClicked: {
                dropPanel.hide()
                _guidedController.confirmAction(modelData.action)
            }
        }
    }

    // User-defined Mavlink Actions
    Repeater {
        //MAVLink协议动作，不需要用户确认：直接执行
        model: _activeVehicle ? mavlinkActions : undefined // The action list is a QmlObjectListModel

        //使用object.label而不是modelData.title
        QGCButton {
            Layout.fillWidth:   true
            text:               object.label

           //直接调用object.sendTo(_activeVehicle)发送MAVLink消息
            onClicked: {
                dropPanel.hide()
                object.sendTo(_activeVehicle)
            }
        }
    }
}
