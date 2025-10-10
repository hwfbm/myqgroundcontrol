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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Controllers
//单个遥控器的多通道监视器，显示遥控器通道的实时PWM信号值
//多个通道 → 多个控制功能
Item {
    id:     _root
    height: monitorColumn.height

    property bool twoColumn: false//布尔值，控制是否使用两列布局

    //PWM信号的最小/最大值（800-2200μs）
    readonly property int _pwmMin:      800
    readonly property int _pwmMax:      2200
    readonly property int _pwmRange:    _pwmMax - _pwmMin//PWM信号范围（1400μs）

    //这是后端控制器，负责与实际的RC通道数据交互
    RCChannelMonitorController {
        id:             controller
    }

    // Live channel monitor control component

    Component {
        id: channelMonitorDisplayComponent

        Item {
            height: ScreenTools.defaultFontPixelHeight

            property int    rcValue:    1500

            property int            __lastRcValue:      1500
            readonly property int   __rcValueMaxJitter: 2
            property color          __barColor:         qgcPal.windowShade

            // Bar
            // 条形图显示PWM信号的相对位置
            Rectangle {
                id:                     bar
                anchors.verticalCenter: parent.verticalCenter
                radius:3
                width:                  parent.width
                height:                 parent.height / 2
                border.color: "#888888"
                border.width:0.8
                color:                   "transparent"
            }

            // Center point
            //标记中心位置（1500μs）
            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                width:                      ScreenTools.defaultFontPixelWidth / 2
                height:                     parent.height
                color:                      qgcPal.window
            }

            // Indicator
            //指示器: 圆形标记，显示当前信号位置
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width:                  parent.height * 0.75
                height:                 width
                //x:                      (((reversed ? _pwmMax - rcValue : rcValue - _pwmMin) / _pwmRange) * parent.width) - (width / 2)
                property real normalizedRC: Math.min(Math.max(reversed ? (_pwmMax - rcValue) : (rcValue - _pwmMin), 0), _pwmRange) / _pwmRange
                x: normalizedRC * bar.width - width / 2//修改
                radius:                 width / 2
                color:                  "#7FFF00"
                visible:                mapped
            }

            //未映射提示: 当通道未映射时显示提示文本
            QGCLabel {
                anchors.fill:           parent
                horizontalAlignment:    Text.AlignHCenter
                verticalAlignment:      Text.AlignVCenter
                text:                   qsTr("Not Mapped")
                visible:                !mapped
            }

            ColorAnimation {
                id:         barAnimation
                target:     bar
                property:   "color"
                from:       "yellow"
                to:         __barColor
                duration:   1500
            }
        }
    } // Component - channelMonitorDisplayComponent

    GridLayout {
        id:         monitorColumn
        width:      parent.width
        columns:    twoColumn ? 2 : 1

        QGCLabel {
            Layout.columnSpan:  parent.columns
            text:               qsTr("Channel Monitor")
        }

        Connections {
            target: controller

           // 更新对应通道的显示值
            onChannelRCValueChanged: (channel, rcValue) => {
                if (channelMonitorRepeater.itemAt(channel)) {
                    channelMonitorRepeater.itemAt(channel).loader.item.rcValue = rcValue
                }
            }
        }

        // 为每个通道创建显示项
        //根据通道数量动态创建相应数量的显示组件
        Repeater {
            id:     channelMonitorRepeater
            model:  controller.channelCount

            RowLayout {
                // Need this to get to loader from Connections above
                property Item loader: theLoader

                QGCLabel {
                    id:     channelLabel
                    text:   modelData + 1
                }

                Loader {
                    id:                 theLoader
                    Layout.fillWidth:   true
                    //height:                 ScreenTools.defaultFontPixelHeight
                    //width:                  parent.width - anchors.leftMargin - ScreenTools.defaultFontPixelWidth
                    sourceComponent:        channelMonitorDisplayComponent

                    property bool mapped:               true
                    readonly property bool reversed:    false
                }
            }
        }
    }
}
