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
import QGroundControl.Palette
import QGroundControl.ScreenTools

// Important Note: Toolbar buttons must manage their checked state manually in order to support
// view switch prevention. This means they can't be checkable or autoExclusive.

Button {
    id:                 button
    height:             ScreenTools.defaultFontPixelHeight * 2
    leftPadding:        _horizontalMargin
    rightPadding:       _horizontalMargin
    checkable:          false
    hoverEnabled:   !ScreenTools.isMobile// 移动设备禁用悬停
    //定义了两个动态颜色属性（正常时候和按下或选择时候）
    property color _currentContentColor:  (checked || pressed) ? qgcPal.buttonHighlightText : qgcPal.buttonText
    property color _currentContentColorSecondary:  (checked || pressed) ? qgcPal.buttonText : qgcPal.buttonHighlight


    property bool logo: false

    property real _horizontalMargin: ScreenTools.defaultFontPixelWidth

    onCheckedChanged: checkable = false

    // background: Rectangle {
    //     anchors.fill:   parent
    //     color:          button.checked ? qgcPal.buttonHighlight : Qt.rgba(0,0,0,0)
    //     border.color:   "white"
    //     border.width:   QGroundControl.corePlugin.showTouchAreas ? 3 : 0
    // }
    //背景设计 (background)
    // 背景颜色根据状态变化：
    // 选中/按下状态：高亮色
    // 悬停状态：悬停色
    // 默认状态：工具条背景色
    background: Rectangle {
        id:             buttonBkRect
        // color:          (button.checked || button.pressed) ?
        //                     qgcPal.buttonHighlight :
        //                     (button.hovered ? qgcPal.toolStripHoverColor : qgcPal.toolbarBackground)
        color:"transparent"         /* (button.checked || button.pressed) ?
                            qgcPal.toolStripHoverColor :"transparent"*/
        /*qgcPal.toolbarBackground*/
        anchors.fill:   parent
              border.width:   QGroundControl.corePlugin.showTouchAreas ? 3 : 0
    }

    contentItem: Row {
        spacing:                ScreenTools.defaultFontPixelWidth
        anchors.verticalCenter: button.verticalCenter
        QGCColoredImage {
            id:                     _icon
            height:                 ScreenTools.defaultFontPixelHeight /** 2*/
            width:                  height
            sourceSize.height:      parent.height
            fillMode:               Image.PreserveAspectFit
            //当 logo 为真时完全透明；否则如果按钮被选中就用高亮色，未被选中就用普通色#/*2196F3*/
            color:                   (button.pressed || button.hovered) ? "#ADFF2F" : "transparent"
             // color:                  logo ? "transparent" : (button.checked ?qgcPal.buttonHighlightText:" qgcPal.buttonText)
            source:                 button.icon.source
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            id:                     _label
            visible:                text !== ""
            text:                   button.text
            color:                  button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
            anchors.verticalCenter: parent.verticalCenter
        }
    }


}
