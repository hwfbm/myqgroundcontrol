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
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.Controllers

//显示和管理飞行视图中的额外功能动作

ToolStripAction {
    id:         action
    text:       qsTr("动作")
    iconSource: "qrc:/qmlimages/HamburgerThin.svg"
    visible:    _additionalActions.anyActionAvailable || _mavlinkActions.anyActionAvailable || _customActions.anyActionAvailable
    enabled:    true

    property var _guidedController: globals.guidedControllerFlyView


    //系统预设附加动作
    property var _additionalActions: FlyViewAdditionalActionsList { 
        guidedController: _guidedController // 传递引导控制器
    }

    //MAVLink协议动作
    //从设置文件中加载MAVLink动作定义，需要活动车辆且动作数量>0时才可用
    property var _mavlinkActions: MavlinkActionManager {
        actionFileNameFact: QGroundControl.settingsManager.mavlinkActionsSettings.flyViewActionsFile

        property bool anyActionAvailable: QGroundControl.multiVehicleManager.activeVehicle && actions.count > 0
    }

    //用户自定义动作
    property var _customActions: FlyViewAdditionalCustomActionsList {
        guidedController: _guidedController
    }

    dropPanelComponent: Component {
        FlyViewAdditionalActionsPanel { 
            additionalActions:  _additionalActions // 系统动作
            mavlinkActions:     _mavlinkActions.actions // MAVLink动作
            customActions:      _customActions// 自定义动作
        }
    }
}
