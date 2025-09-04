import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

// Important Note: SubMenuButtons must manage their checked state manually in order to support 子菜单必须手动管理他的选中状态
// view switch prevention. This means they can't be checkable or autoExclusive.防止试图切换，这意味着它们不能被检查或自动独占

//自定义的 QML Button 组件，主要用于 QGroundControl 项目中的子菜单按钮
//带图标 + 文字的按钮布局
Button {
    id:             control
    text:           "Button"
    focusPolicy:    Qt.ClickFocus
    hoverEnabled:   !ScreenTools.isMobile //移动端禁用悬停效果
    implicitHeight: ScreenTools.defaultFontPixelHeight * 2.5 //高度基于系统字体基准

    property bool   setupComplete:  true   //控制完成状态指示（true=正常色，false=红色）                                  ///< true: setup complete indicator shows as completed
    property var    imageColor: undefined //图标颜色（默认使用文字颜色）
    property string imageResource:  ""    //默认不显示图标 "/qmlimages/subMenuButtonImage.png"  //图标资源路径    ///< Button image
    property bool   largeSize:      false //是否使用大尺寸（未在代码中使用）
    property bool   showHighlight:  control.pressed | control.checked //高亮显示条件（按下或选中状态）

    property size   sourceSize:     Qt.size(ScreenTools.defaultFontPixelHeight * 2, ScreenTools.defaultFontPixelHeight * 2)//图标尺寸（默认 2x2 字体像素高度

    property ButtonGroup buttonGroup:    null //可选的按钮组管理
    //允许外部传入 ButtonGroup 实现互斥选择，注释明确指出需要手动管理选中状态
    onButtonGroupChanged: {
        if (buttonGroup) {
            buttonGroup.addButton(control)
        }
    }

    onCheckedChanged: checkable = false//禁用自动选中

    QGCPalette {
        id:                 qgcPal
        colorGroupEnabled:  control.enabled
    }

    //背景
    background: Rectangle {
        id:     innerRect
        color:  "transparent"/*qgcPal.windowShade*/
        implicitWidth: titleBar.x + titleBar.contentWidth + ScreenTools.defaultFontPixelWidth
        // 高亮层
        // Rectangle {
        //     anchors.fill:   parent
        //     color:          qgcPal.buttonHighlight
        //     opacity:        showHighlight ? 1 : control.enabled && control.hovered ? .2 : 0//按下/选中：100% 高亮，悬停：20% 高亮
        // }
        // 图标
        QGCColoredImage {
            id:                     image
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
            //anchors.left:           parent.left
            anchors.horizontalCenter: parent.horizontalCenter  // 横向居中
               anchors.verticalCenter:   parent.verticalCenter     // 纵向居中
            //anchors.verticalCenter: parent.verticalCenter
            width:                  ScreenTools.defaultFontPixelHeight/* * 1.5*/
            height:               ScreenTools.defaultFontPixelHeight /** 1.5*/
            fillMode:               Image.PreserveAspectFit
            mipmap:                 true
            //color:                  imageColor ? imageColor : (control.setupComplete ? titleBar.color : "red")
            color: showHighlight//#2196F3
                  ? "#7FFF00"  // 蓝色，表示点击或选中状态
                  : (imageColor ? imageColor : (control.setupComplete ? titleBar.color : "red"))

            source:                 control.imageResource
            sourceSize:             control.sourceSize
        }
         // 文字
        QGCLabel {
            id:                     titleBar
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
            anchors.left:           image.right
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment:      TextEdit.AlignVCenter
            color:                  showHighlight ? qgcPal.buttonHighlightText : qgcPal.buttonText
            text:                   control.text
        }
    }

    contentItem: Item {}
}
