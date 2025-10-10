/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQml.Models
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.Vehicle

//实现飞行前检查清单功能
ColumnLayout {
    spacing: 0.8 * ScreenTools.defaultFontPixelWidth

    property real _verticalMargin: ScreenTools.defaultFontPixelHeight / 2


    //默认模型加载
    Loader {
        id:     modelContainer
        source: "/checklists/DefaultChecklist.qml"
    }

    property bool allChecksPassed:  false // 标记所有检查是否通过
    property var  vehicleCopy:      globals.activeVehicle // 当前活动飞行器的引用

    onVehicleCopyChanged: {
        if (checkListRepeater.model) {
            checkListRepeater.model.reset()
        }
    }

    //检查状态管理，当所有检查通过时，更新飞行器的检查状态
    onAllChecksPassedChanged: {
        if (allChecksPassed) {
            globals.activeVehicle.checkListState = Vehicle.CheckListPassed
        } else {
            globals.activeVehicle.checkListState = Vehicle.CheckListFailed
        }
    }

    //分组检查逻辑
    function _handleGroupPassedChanged(index, passed) {
        if (passed) {
            // Collapse current group
            // 当前组通过后折叠，展开下一组
            var group = checkListRepeater.itemAt(index)
            group._checked = false
            // Expand next group
            if (index + 1 < checkListRepeater.count) {
                group = checkListRepeater.itemAt(index + 1)
                group.enabled = true
                group._checked = true
            }
        }

        // Walk the list and check if any group is failing
        // 检查所有组是否都通过
        var allPassed = true
        for (var i=0; i < checkListRepeater.count; i++) {
            if (!checkListRepeater.itemAt(i).passed) {
                allPassed = false
                break
            }
        }

        allChecksPassed = allPassed;
    }

    //-- Pick a checklist model that matches the current airframe type (if any)

    //根据飞行器类型动态加载不同的检查清单模型
    function _updateModel() {
        var vehicle = globals.activeVehicle
        if (!vehicle) {
            vehicle = QGroundControl.multiVehicleManager.offlineEditingVehicle
        }

        if(vehicle.multiRotor) {
            //多旋翼
            modelContainer.source = "/checklists/MultiRotorChecklist.qml"
        } else if(vehicle.vtol) {
            //VTOL
            modelContainer.source = "/checklists/VTOLChecklist.qml"
        } else if(vehicle.rover) {
            //地面车辆
            modelContainer.source = "/checklists/RoverChecklist.qml"
        } else if(vehicle.sub) {
            //水下设备
            modelContainer.source = "/checklists/SubChecklist.qml"
        } else if(vehicle.fixedWing) {
            //固定翼
            modelContainer.source = "/checklists/FixedWingChecklist.qml"
        } else {
            //默认
            modelContainer.source = "/checklists/DefaultChecklist.qml"
        }
        return
    }

    Component.onCompleted: {
        _updateModel()
    }

    onVisibleChanged: {
        if(globals.activeVehicle) {
            if(visible) {
                _updateModel()
            }
        }
    }

    // We delay the updates when a group passes so the user can see all items green for a moment prior to hiding
    //使用延迟计时器让用户有时间看到检查通过的状态：
    Timer {
        id:         delayedGroupPassed
        interval:   750

        property int index

        onTriggered: _handleGroupPassedChanged(index, true /* passed */)
    }

    function groupPassedChanged(index, passed) {
        if (passed) {
            delayedGroupPassed.index = index
            delayedGroupPassed.restart()
        } else {
            _handleGroupPassedChanged(index, passed)
        }
    }

    // Header/title of checklist
    //显示当前状态（"通过"或"进行中"）
    //重置按钮：重新开始所有检查
    RowLayout {
        Layout.fillWidth:   true
        height:             1.75 * ScreenTools.defaultFontPixelHeight
        spacing:            0

        QGCLabel {
            Layout.fillWidth:   true
            text:               allChecksPassed ? qsTr("(Passed)") : qsTr("In Progress")
            font.pointSize:     ScreenTools.mediumFontPointSize
        }
        QGCButton {
            width:              1.2 * ScreenTools.defaultFontPixelHeight
            height:             1.2 * ScreenTools.defaultFontPixelHeight
            Layout.alignment:   Qt.AlignVCenter
            onClicked:          checkListRepeater.model.reset()

            QGCColoredImage {
                source:         "/qmlimages/MapSyncBlack.svg"
                color:          qgcPal.buttonText
                anchors.fill:   parent
            }
        }
    }

    // All check list items

    Repeater {
        id:     checkListRepeater
        model:  modelContainer.item.model// 使用动态加载的模型
    }
}
