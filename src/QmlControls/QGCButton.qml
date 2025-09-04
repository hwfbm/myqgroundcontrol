import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.Palette
import QGroundControl.ScreenTools

/// Standard push button control:
///     If there is both an icon and text the icon will be to the left of the text
///     If icon only, icon will be centered
Button {
    id:             control
    hoverEnabled:   !ScreenTools.isMobile
    topPadding:     _verticalPadding
    bottomPadding:  _verticalPadding
    leftPadding:    _horizontalPadding
    rightPadding:   _horizontalPadding
    focusPolicy:    Qt.ClickFocus
    font.family:    ScreenTools.normalFontFamily
    text:           ""

    property bool   primary:        false                               ///< primary button for a group of buttons
    property bool   showBorder:     qgcPal.globalTheme === QGCPalette.Light
    property real   backRadius:     ScreenTools.buttonBorderRadius
    property real   heightFactor:   0.4
    property string iconSource:     ""
    property real   fontWeight:     Font.Normal // default for qml Text
    property real   pointSize:      ScreenTools.defaultFontPointSize
    property alias setsize: text. font.pointSize
   // property alias fontpis: text. Layout.alignment

    property alias wrapMode:            text.wrapMode
    property alias horizontalAlignment: text.horizontalAlignment
    property alias backgroundColor:     backRect.color
    property alias textColor:           text.color

    property bool   _showHighlight:     enabled && (pressed | checked)
    property alias bordercolor: backRect.border.color
    property alias backcolor:  backRect.color

    property int _horizontalPadding:    ScreenTools.defaultFontPixelWidth*1.3
    property int _verticalPadding:      Math.round(ScreenTools.defaultFontPixelHeight * heightFactor)

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    background: Rectangle {
        id:             backRect
        radius:         backRadius
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: ScreenTools.implicitButtonHeight
        border.width:   control.showBorder ? 1 : 1//一直有边框
        //border.color:   "#bbbbbb"//*/qgcPal.buttonBorder
        border.color: {
            //如果是主要按钮
            if (primary)
                return "#3399ff"    // 高亮蓝色
            //如果按钮可用且悬浮
            else if (control.enabled && control.hovered)
                return "#3399ff"    // 悬浮蓝色
            else
                return "#888888"    // 默认灰
        }
        color:          primary ? "#0066ff" : "transparent" // 如果是主要按钮,也就是设置了primary属性,就是蓝色，其他透明色/* qgcPal.primaryButton : qgcPal.button*/

        Rectangle {
            anchors.fill:   parent
            color:           "#3399ff"//qgcPal.buttonHighlight
            //透明度,若是可用且点击,不透明,悬停且可用,半透明,其他时候透明
            opacity:        _showHighlight ? 1 : control.enabled && control.hovered ? 0.2 : 0
            radius:         parent.radius
        }
    }

    contentItem: RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            QGCColoredImage {
                id:                     icon
                Layout.alignment:       Qt.AlignHCenter
                source:                 control.iconSource
                height:                 text.height
                width:                  height
                color:                  text.color
                fillMode:               Image.PreserveAspectFit
                sourceSize.height:      height
                visible:                control.iconSource !== ""
            }

            QGCLabel {
                id:                     text
                Layout.alignment:       Qt.AlignHCenter
                text:                   control.text
                font.pointSize:         control.pointSize
                font.family:            control.font.family
                font.weight:            fontWeight
                color:                  _showHighlight ? qgcPal.buttonHighlightText : (primary ?qgcPal.primaryButtonText : qgcPal.buttonText)
                opacity:        /*_showHighlight ? 1 : */control.enabled && control.hovered ? 0.5 :1
                visible:                control.text !== ""
            }
    }
}
