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

import QGroundControl.Palette
import QGroundControl.ScreenTools


//AbstractButton是QtQuick.Controls 中的基础类，所有按钮控件（Button、CheckBox、RadioButton 等）都继承自它
AbstractButton   {
    id:             control
    checkable:      true
    padding:        0

    property bool   _showBorder: qgcPal.globalTheme === QGCPalette.Light

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    //是整个按钮的可视部分
    contentItem: Item {
        implicitWidth:  (label.visible ? label.contentWidth + ScreenTools.defaultFontPixelWidth : 0) + indicator.width
        implicitHeight: label.contentHeight

        QGCLabel {
            id:             label
            anchors.left:   parent.left
            text:           visible ? control.text : "X"
            visible:        control.text !== ""
        }
    
        //是滑块，内部有一个小矩形表示开关位置
        Rectangle {
            id:                     indicator
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter
            height:                 ScreenTools.defaultFontPixelHeight
            width:                  height * 2.2
            radius:                 height / 2
            color:                  control.checked ? "#7FFF00" : "transparent"/*qgcPal.primaryButton : qgcPal.button*/
            border.width:           _showBorder ? 1 : 0
            border.color:            control.checked ? "#7FFF00" : qgcPal.buttonBorder//qgcPal.buttonBorder
            Rectangle {
                         id: knob
                         anchors.verticalCenter: parent.verticalCenter
                         width: indicator.height - 2
                         height: indicator.height - 2
                         radius: width / 2
                         color: qgcPal.buttonText

                         // 移动动画
                         Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                         x: control.checked ? indicator.width - width - 1 : 1

                         // // 缩放动画
                         // Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                         // scale: control.checked ? 1.3 : 1.0
                     }
            // Rectangle {
            //         id: knob
            //         anchors.verticalCenter: parent.verticalCenter
            //         width: indicator.height - 2
            //         height: indicator.height - 2
            //         radius: width / 2
            //         color: qgcPal.buttonText

            //         // 平滑移动动画
            //         Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
            //         x: control.checked ? indicator.width - width - 1 : 1

            //         // 轻微缩放效果
            //         Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
            //         scale: control.checked ? 1.05 : 1.0
            //     }
            // Rectangle {
            //     anchors.verticalCenter: parent.verticalCenter
            //     x:                      checked ? indicator.width - width - 1: 1
            //     height:                 parent.height - 2
            //     width:                  height
            //     radius:                 height / 2
            //     color:                  qgcPal.buttonText
            // }
        }
    }
}
