/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtCore

import QGroundControl
import QGroundControl.ScreenTools

//这段代码是 QGroundControl (QGC) 中用于管理主窗口位置和状态的组件，主要功能是持久化保存和恢复主窗口的位置、大小和显示状态

Item {
    property Window window  //需要被管理的窗口对象


    //控制功能是否启用，满足两个条件：不是移动设备 (!ScreenTools.isMobile)，核心插件启用了该功能 (options.enableSaveMainWindowPosition)
    property bool _enabled: !ScreenTools.isMobile && QGroundControl.corePlugin.options.enableSaveMainWindowPosition


    //使用 Qt 的 Settings 组件持久化存储
    Settings {
        id:         s
        category:   "MainWindowState" //category 指定配置分组为 "MainWindowState"

        //存储5个关键属性：
        property int x
        property int y //窗口位置
        property int width  //窗口尺寸
        property int height
        property int visibility //窗口状态（正常/最大化/全屏）
    }



    //初始化加载
    Component.onCompleted: {
        //检查条件：功能启用 (_enabled)，存在有效存储的尺寸 (s.width && s.height)
        if (_enabled && s.width && s.height) {
            window.x = s.x;
            window.y = s.y;
            window.width = s.width;
            window.height = s.height;
            window.visibility = s.visibility;
        }
    }


//变化监听：监听窗口5种状态变化，每次变化都触发防抖定时器重启
    Connections {
        target:                         window
        function onXChanged()           { if(_enabled) saveSettingsTimer.restart() }
        function onYChanged()           { if(_enabled) saveSettingsTimer.restart() }
        function onWidthChanged()       { if(_enabled) saveSettingsTimer.restart() }
        function onHeightChanged()      { if(_enabled) saveSettingsTimer.restart() }
        function onVisibilityChanged()  { if(_enabled) saveSettingsTimer.restart() }
    }

    //防抖定时器：避免窗口拖动时高频写入
    //关键设计：避免频繁写入配置文件，在最后一次变化后1秒才实际保存
    Timer {
        id:             saveSettingsTimer
        interval:       1000
        repeat:         false
        onTriggered:    saveSettings()
    }


    //保存逻辑：差异化保存策略
    function saveSettings() {
        if(_enabled) {
            switch(window.visibility) {
                //窗口模式：保存全部属性
            case ApplicationWindow.Windowed:
                s.x = window.x;
                s.y = window.y;
                s.width = window.width;
                s.height = window.height;
                s.visibility = window.visibility;
                break;
                //全屏/最大化：仅保存状态（不保存位置尺寸）
            case ApplicationWindow.FullScreen:
                s.visibility = window.visibility;
                break;
            case ApplicationWindow.Maximized:
                s.visibility = window.visibility;
                break;
            }
        }
    }
}
