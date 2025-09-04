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

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

// Label control whichs pop up a flight mode change menu when clicked
//继承自 QGCLabel，作用是作为一个可点击的 Label，点击后会弹出一个菜单供用户选择当前飞机的飞行模式（比如“Stabilize”、“Loiter”、“RTL”等）
//显示当前飞行模式的小标签（例如 “Stabilize”），点击后弹出菜单切换飞行模式
QGCLabel {
    id:     _root
    //如果有飞机连上，就显示其当前飞行模式；否则显示 "N/A"
    text:   currentVehicle ? currentVehicle.flightMode : qsTr("N/A", "No data to display")

    //绑定当前的活跃飞机实例对象
    property var    currentVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property real   mouseAreaLeftMargin:    0

    //Qt 的 Menu 是继承自 Popup 的
    // 默认情况下，Qt 只启用一个风格，根据你的平台决定。例如：
    // Android 默认使用 Material
    // Windows 上可能默认是 Fusion
    Menu {
        id: flightModesMenu
    }

    Component {
        id: flightModeMenuItemComponent

        //每个 MenuItem 就是一个可选飞行模式，点击后设置飞机的 flightMode
        MenuItem {
            //enabled 是 QML 中所有 Item 和 Control 组件的通用属性，表示这个组件是否处于“启用状态”,默认是true
            enabled: true
            //onTriggered 是 QML 中菜单项（MenuItem）等控件的 信号处理器（signal handler），用于响应用户点击操作
            onTriggered: currentVehicle.flightMode = text
        }
    }

    property var flightModesMenuItems: []

    //动态更新菜单
    // 先清除旧的 menuItems；
    // 遍历 currentVehicle.flightModes 创建新的；
    // 插入到 Menu 中；
    // 在以下事件发生时触发这个函数：
    // Component.onCompleted（初始化时）
    // onActiveVehicleChanged
    // onFlightModesChanged
    function updateFlightModesMenu() {
        if (currentVehicle && currentVehicle.flightModeSetAvailable) {
            var i;
            // Remove old menu items
            for (i = 0; i < flightModesMenuItems.length; i++) {
                flightModesMenu.removeItem(flightModesMenuItems[i])
            }
            flightModesMenuItems.length = 0
            // Add new items
            for (i = 0; i < currentVehicle.flightModes.length; i++) {
                var menuItem = flightModeMenuItemComponent.createObject(null, { "text": currentVehicle.flightModes[i] })
                flightModesMenuItems.push(menuItem)
                flightModesMenu.insertItem(i, menuItem)
            }
        }
    }

    Component.onCompleted: _root.updateFlightModesMenu()

    Connections {
        target:                 QGroundControl.multiVehicleManager
        function onActiveVehicleChanged(activeVehicle) { _root.updateFlightModesMenu() }
    }

    Connections {
        target: currentVehicle
        function onFlightModesChanged() { _root.updateFlightModesMenu() }
    }

    MouseArea {
        id:                 mouseArea
        visible:            currentVehicle && currentVehicle.flightModeSetAvailable
        anchors.leftMargin: mouseAreaLeftMargin
        anchors.fill:       parent
        //居中弹出一个 Menu，菜单项是所有可用的 flightModes
        onClicked:          flightModesMenu.popup((_root.width - flightModesMenu.width) / 2, _root.height)
    }
}
