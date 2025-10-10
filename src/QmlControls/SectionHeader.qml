import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl.ScreenTools
import QGroundControl.Palette
//自定义的CheckBox组件，专门用于预飞行检查清单的分组标题
CheckBox {
    id:             control
    focusPolicy:    Qt.ClickFocus// 点击可获得焦点
    checked:        true// 默认展开状态
    leftPadding:    0// 去除左边距

    property var            color:          qgcPal.text  // 文本颜色
    property bool           showSpacer:     true// 是否显示间隔
    property ButtonGroup    buttonGroup:    null // 可选的按钮组

    // 节间距
    property real _sectionSpacer: ScreenTools.defaultFontPixelWidth / 2  // spacing between section headings

    // 自动加入按钮组
    //这允许将多个这样的复选框组成互斥组（虽然在这个场景中可能不太需要）
    onButtonGroupChanged: {
        if (buttonGroup) {
            buttonGroup.addButton(control)// 自动加入按钮组
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    contentItem: ColumnLayout {
         // 1. 顶部间隔
        Item {
            Layout.preferredHeight: control._sectionSpacer
            width:                  1
            visible:                control.showSpacer// 可控制显示/隐藏
        }

         // 2. 标题文本和下拉箭头
        QGCLabel {
            text:               control.text
            color:              control.color
            Layout.fillWidth:   true

            QGCColoredImage {
                anchors.right:          parent.right
                anchors.verticalCenter: parent.verticalCenter
                width:                  parent.height / 2
                height:                 width
                source:                 "/qmlimages/arrow-down.png"
                color:                  qgcPal.text
                visible:                !control.checked
            }
        }

          // 3. 底部分隔线
        Rectangle {
            Layout.fillWidth:   true
            height:             1
            color:              qgcPal.text
        }
    }

    indicator: Item {}
}
