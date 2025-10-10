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
//ObjectModel组件，用于存储和管理多个预飞行检查组（PreFlightCheckGroup）
//组件创建完成后自动调用reset()方法进行初始化
ObjectModel {
    //// 所有直接子项都会被添加到模型中
    id: _root
    property bool enforceOrder: true//// 是否强制按顺序检查
    //当enforceOrder=true时：只有第一组启用和展开，其他组禁用
    //当enforceOrder=false时：所有组都启用，但只有第一组展开

    function reset() {
        for (var i=0; i<_root.count; i++) // 获取第i个组
        {
            var group = _root.get(i)
            group.reset()// 重置该组的所有检查项
            if (enforceOrder) {
                group.enabled = i === 0// 只有第一个组启用
            } else {
                group.enabled = true// 所有组都启用
            }
            group._checked = i === 0// 只有第一个组展开
        }
    }

    //检查所有组是否通过
    function isPassed() {
        for (var i = 0; i < _root.count; i++) {
            var group = _root.get(i)
            if(!group.passed) {
                return false// 只要有一个组未通过就返回false
            }
        }
        return true// 所有组都通过
    }

    Component.onCompleted: reset()

}
