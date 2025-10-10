/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQml.Models

import QGroundControl.Controls
import QGroundControl.ScreenTools

//管理一组预飞行检查按钮作为一个整体实体
//检查系统的核心协调者，负责管理组内检查项的状态聚合和视觉呈现
/// A PreFlightCheckGroup manages a set of PreFlightCheckButtons as a single entity.
Column  {
    property string name// 检查组名称
    property bool   passed: false// 整个组是否通过
    property bool   failed: false// 整个组是否失败

    spacing: ScreenTools.defaultFontPixelHeight / 2

    property alias _checked: header.checked// 控制组是否展开

    //当组的通过状态变化时，通知父组件（ObjectModel）更新状态
    onPassedChanged: parent.groupPassedChanged(ObjectModel.index, passed)


    // 动态子项管理
    //将第3个及之后的子项（索引2+）移动到innerColumn中
    //这是因为前两个子项是：SectionHeader和innerColumn本身
    //这样所有检查按钮都成为innerColumn的子项
    Component.onCompleted: {
        enabled = _checked
        var moveList = []
        var i = 0
        for (i = 2; i < children.length; i++) {
            moveList.push(children[i])
        }
        for (i = 0; i < moveList.length; i++) {
            moveList[i].parent = innerColumn
        }
    }

    //重置功能
    function reset()
    {
        for (var i=0; i<innerColumn.children.length; i++) {
            innerColumn.children[i].reset() // 重置所有检查按钮
        }
    }

    SectionHeader {
        id:             header
        anchors.left:   parent.left
        anchors.right:  parent.right
        text:           name + (passed ? qsTr(" (passed)") : "")// 动态显示状态
        // 根据状态显示不同颜色：
        // 失败：红色
        // 通过：绿色
        // 待定：默认色
        color:          failed ? qgcPal.statusFailedText : (passed ? qgcPal.statusPassedText : qgcPal.statusPendingText)
    }

     // 根据标题展开状态显示/隐藏
    Column {
        id:         innerColumn
        spacing:    ScreenTools.defaultFontPixelHeight / 2
        visible:    header.checked

        function buttonPassedChanged() {
            for (var i=0; i<children.length; i++) {
                if (!children[i].passed) {
                    passed = false
                    // 继承第一个失败项的状态
                    failed = children[i].failed
                    return
                }
            }
            // 所有子项都通过
            failed = false
            passed = true
        }
    }
}
