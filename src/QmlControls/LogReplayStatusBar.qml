import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Palette
import QGroundControl.ScreenTools

// QGroundControl 的日志回放控制面板（Log Replay UI），用于在 UI 上操作、加载和控制回放 .tlog 日志文件的组件
//这是 QGC 的一个内置功能，允许加载过去的飞行日志，模拟回放历史数据，就像真的在飞
Rectangle {
    height: visible ? (rowLayout.height + (_margins * 2)) : 0 // 如果 visible 为 false，该组件高度为 0，完全隐藏
    color: qgcPal.window// 使用 QGC 统一配色


    property real _margins: ScreenTools.defaultFontPixelHeight / 4
    property var _logReplayLink: null

    function pickLogFile() {
        if (globals.activeVehicle)
        {
            // 当前已连接车辆，不允许回放
            mainWindow.showMessageDialog(qsTr("Log Replay"), qsTr("You must close all connections prior to replaying a log."))
            return
        }

        filePicker.openForLoad() // 打开文件选择器
    }

    QGCPalette { id: qgcPal }


    //文件选择器
    QGCFileDialog {
        id: filePicker
        title: qsTr("Select Telemetery Log")
        nameFilters: [ qsTr("Telemetry Logs (*.%1)").arg(_logFileExtension), qsTr("All Files (*)") ] //专用于日志文件
        folder: QGroundControl.settingsManager.appSettings.telemetrySavePath
        onAcceptedForLoad: (file) => {
                               //startLogReplay(file)启动一个新的回放链接
            controller.link = QGroundControl.linkManager.startLogReplay(file)//选择完文件，调用 startLogReplay(file) 创建日志链接并开始播放
           //controller.link 是这个虚拟日志链路对象
            close()
        }

        property string _logFileExtension: QGroundControl.settingsManager.appSettings.telemetryFileExtension
    }


    //控制整个 Replay 的对象
    // .link：当前日志 replay 链路
    // .isPlaying：是否在播放中
    // .playheadTime：当前播放时间（比如 00:05）
    // .totalTime：总时间
    // .playbackSpeed：回放速度
    // .percentComplete：百分比（进度条用）
    LogReplayLinkController {
        id: controller

        // LogReplayLinkController.percentComplete 发生变化（比如从 0% → 10% → 50%），自动调用 slider.updatePercentComplete(percentComplete)
        //它就会更新进度条的 UI 值（通过 value = percentComplete）
        onPercentCompleteChanged: (percentComplete) => slider.updatePercentComplete(percentComplete)
    }


    //整个控制区域
    RowLayout {
        id: rowLayout
        anchors {
            margins: _margins
            top: parent.top
            left: parent.left
            right: parent.right
        }

        //播放/暂停按钮
        QGCButton {
            enabled: controller.link
            text: controller.isPlaying ? qsTr("Pause") : qsTr("Play")
            onClicked: controller.isPlaying = !controller.isPlaying
        }

        //速度选择：
        QGCComboBox {
            textRole: "text"
            currentIndex: 3

            model: ListModel {
                ListElement { text: "0.1";  value: 0.1 }
                ListElement { text: "0.25"; value: 0.25 }
                ListElement { text: "0.5";  value: 0.5 }
                ListElement { text: "1x";   value: 1 }
                ListElement { text: "2x";   value: 2 }
                ListElement { text: "5x";   value: 5 }
                ListElement { text: "10x";  value: 10 }
            }

            onActivated: (index) => { controller.playbackSpeed = model.get(currentIndex).value }
        }

        QGCLabel { text: controller.playheadTime }

        //进度条（Slider）：
        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0
            to: 100
            enabled: controller.link //是 LogReplayLink 的实例

            //Slider 的 value 变化会触发 onValueChanged，而有时候是程序自动设置 value，而不是用户拖动滑块
            property bool manualUpdate: false //用了 manualUpdate 标记，设置标志：现在是“手动更新”，防止手动拖动时与 onPercentCompleteChanged 冲突
             property bool isUserDragging: false  // 新增标志位

            onPressedChanged: {
                    if (pressed) {
                        isUserDragging = true
                    } else {
                        isUserDragging = false
                    }
                }

            onValueChanged: {
                if (!manualUpdate && isUserDragging) {
                    controller.percentComplete = value //// 仅用户拖动时才执行
                }
            }
        }

        function updatePercentComplete(percentComplete1) {
            manualUpdate = true // 表示“程序在更新 UI”，不要触发用户操作逻辑
            value = percentComplete1 // 设值（不想触发 onValueChanged）
            manualUpdate = false// 恢复为“正常用户操作”

        }
        //时间标签：
        QGCLabel { text: controller.totalTime }


        // 载入和关闭按钮：
        QGCButton {
            text: qsTr("Load Telemetry Log") //加载遥测日志
            onClicked: pickLogFile()
            visible: !controller.link
        }

        QGCButton {
            text: qsTr("Close")
            onClicked: {
                var activeVehicle = QGroundControl.multiVehicleManager.activeVehicle
                if (activeVehicle) {
                    activeVehicle.closeVehicle()
                }
                QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue = false //表示强制设置 QGC 的 Fact 值（用于设置开关等）
            }
        }
    }
}
