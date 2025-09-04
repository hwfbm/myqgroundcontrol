// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

// import QtQuick
// import QtQuick.Window
// import QtQuick.Controls
// import QtQuick.Templates as T

// import QGroundControl.ScreenTools
// import QGroundControl.Palette
// import QGroundControl.Controls
// import QtQuick.Effects

// T.ComboBox {
//     id:             control
//     padding:        ScreenTools.comboBoxPadding
//     spacing:        ScreenTools.defaultFontPixelWidth
//     font.pointSize: ScreenTools.defaultFontPointSize
//     font.family:    ScreenTools.normalFontFamily
//     //尺寸计算
//     implicitWidth:  Math.max(background ? background.implicitWidth : 0,
//                              contentItem.implicitWidth + leftPadding + rightPadding + padding)
//     implicitHeight: Math.max(background ? background.implicitHeight : 0,
//                              Math.max(contentItem.implicitHeight, indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
//     baselineOffset: contentItem.y + text.baselineOffset
//     leftPadding:    padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
//     rightPadding:   padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width)

//     property bool   centeredLabel:  false  // 文本是否居中
//     property bool   sizeToContents: false // 是否根据内容调整宽度
//     property string alternateText:  ""   // 替代显示文本

//     property real   _popupWidth:    width  // 弹出菜单宽度
//     property bool   _onCompleted:   false   // 组件完成标志
//     property bool   _showBorder:    qgcPal.globalTheme === QGCPalette.Light // 是否显示边框

//     QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

//     TextMetrics {
//         id:                 textMetrics
//         font.family:        control.font.family
//         font.pointSize:     control.font.pointSize
//     }

//     ItemDelegate {
//         id:             itemDelegateMetrics
//         visible:        false
//         font.family:    control.font.family
//         font.pointSize: control.font.pointSize
//     }


//     //弹出菜单宽度计算
//     function _calcPopupWidth() {
//         if (_onCompleted && sizeToContents && model) {
//             var largestTextWidth = 0
//             for (var i = 0; i < model.length; i++){
//                 textMetrics.text = control.textRole ? model[i][control.textRole] : model[i]
//                 largestTextWidth = Math.max(textMetrics.width, largestTextWidth)
//             }
//             _popupWidth = largestTextWidth + itemDelegateMetrics.leftPadding + itemDelegateMetrics.rightPadding
//         }
//     }

//     onModelChanged: _calcPopupWidth()

//     Component.onCompleted: {
//         _onCompleted = true
//         _calcPopupWidth()
//     }

//     // The items in the popup
//     //代理项（Delegate）设计
//     delegate: ItemDelegate {
//         width:  _popupWidth
//         height: Math.round(popupItemMetrics.height/* * 1.75*/)

//         property string _text: control.textRole ?
//                                     (model.hasOwnProperty(control.textRole) ? model[control.textRole] : modelData[control.textRole]) :
//                                     modelData

//         TextMetrics {
//             id:             popupItemMetrics
//             font:           control.font
//             text:           _text
//         }

//         contentItem: Text {
//             text:                   _text
//             font:                   control.font
//             color:                 control.currentIndex === index ? "dodgerblue" : "white"// control.currentIndex === index ? qgcPal.buttonHighlightText : qgcPal.buttonText

//             verticalAlignment:      Text.AlignVCenter
//         }

//         // background: Rectangle {
//         //     color:            "transparent"  /* qgcPal.window// *///  control.currentIndex === index ? qgcPal.buttonHighlight : qgcPal.button
//         //  radius:         ScreenTools.buttonBorderRadius
//         // }
//         background: Rectangle {
//                     color:/* highlighted ? "#444" :*/ "transparent"
//                    // radius: index === 0 || index === control.count - 1 ? 8 : 0
//                 }
//         highlighted:                control.highlightedIndex === index
//     }

//     //指示器（Indicator），使用向下箭头图标作为下拉指示器
//     indicator: QGCColoredImage {
//         anchors.rightMargin:    control.padding
//         anchors.right:          parent.right
//         anchors.verticalCenter: parent.verticalCenter
//         height:                 ScreenTools.defaultFontPixelWidth
//         width:                  height
//         source:                 "/qmlimages/arrow-down.png"
//         color:                  qgcPal.buttonText
//     }

//     // The label of the button、
//     //内容显示
//     contentItem: QGCLabel {
//         id:                         text
//         anchors.verticalCenter:     parent.verticalCenter
//         anchors.horizontalCenter:   centeredLabel ? parent.horizontalCenter : undefined
//         text:                       control.alternateText === "" ? control.currentText : control.alternateText
//         font:                       control.font
//        // color:                    qgcPal.buttonText
//     }

//     background: Rectangle {
//         color:          "transparent"
//         border.color:   qgcPal.buttonBorder
//         border.width:   _showBorder ? 1 : 0
//         radius:         ScreenTools.buttonBorderRadius
//     }
//     // popup: T.Popup {
//     //     id: popup
//     //     x: -0.2
//     //     y: -0.2/*control.height*/
//     //     width: _popupWidth
//     //     modal: true

//     //     // 背景放在这里
//     //     Rectangle {
//     //         id: popupBackground
//     //         anchors.fill: parent
//     //         radius: ScreenTools.buttonBorderRadius
//     //         color: "#444444"
//     //        border.color:  qgcPal.buttonBorder
//     //         border.width: 1
//     //         z: -1  // 确保在 ListView 后面
//     //     }

//     //     contentItem: ListView {
//     //         id: listView
//     //         width: parent.width
//     //         height: 0
//     //         clip: true
//     //         anchors.top: parent.top
//     //         anchors.left: parent.left
//     //         anchors.right: parent.right
//     //         model: control.delegateModel
//     //         currentIndex: control.currentIndex

//     //         // delegate: ItemDelegate {
//     //         //     width: parent.width
//     //         //     //height: ScreenTools.defaultFontPixelWidth
//     //         //     contentItem: Text {
//     //         //         text: modelData
//     //         //         color: control.currentIndex === index ? "dodgerblue" : "white"
//     //         //         anchors.verticalCenter: parent.verticalCenter
//     //         //         anchors.left: parent.left
//     //         //          anchors.right: parent.right
//     //         //         anchors.leftMargin: ScreenTools.defaultFontPixelWidth
//     //         //     }
//     //         //     background: Rectangle {
//     //         //         anchors.fill: parent
//     //         //         color: control.currentIndex === index ? "#3333ff" : "transparent"
//     //         //     }
//     //         // }

//     //         Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
//     //     }

//     //     onOpened: { listView.height = Math.min(listView.contentHeight, 200) }
//     //     onClosed: { listView.height = 0 }
//     // }




//     // popup: T.Popup {
//     //     x:              0
//     //     y:              0//control.height
//     //     width:         _popupWidth
//     //     // 关键：给 popup 明确高度（由内容隐式高度推导）
//     //     height:         Math.min(contentItem.implicitHeight,
//     //                              control.Window.height - topMargin - bottomMargin)
//     //     topMargin:      6
//     //     bottomMargin:   6
//     //     focus:          true
//     //     modal:          false
//     //     closePolicy:    T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside

//     //     // 背景样式 OK，别放会截获事件的 MouseArea
//     //     // background: Rectangle {
//     //     //     id: popupBackground
//     //     //     radius:ScreenTools.buttonBorderRadius
//     //     //     color: "#2c2c2c"
//     //     //     border.color: "#555555"
//     //     //     border.width: 1

//     //     //     layer.enabled: true
//     //     //     layer.effect: MultiEffect {
//     //     //         shadowEnabled: true
//     //     //         shadowColor: "#00000088"
//     //     //         shadowBlur: 0.3
//     //     //         shadowHorizontalOffset: 0
//     //     //         shadowVerticalOffset: 2
//     //     //     }
//     //     // }
//     //     background: Rectangle {
//     //                 color: "#2c2c2c"
//     //                 radius: ScreenTools.buttonBorderRadius
//     //                 border.color: qgcPal.buttonBorder
//     //             }


//     //     contentItem: ListView {
//     //         clip:                   true
//     //         // 关键：ListView 需要这个，让 Popup 拿到隐式高度
//     //         implicitHeight:         contentHeight
//     //         model:                  control.delegateModel    // 用控件内置的 DelegateModel
//     //         currentIndex:           control.highlightedIndex
//     //         highlightMoveDuration:  0
//     //         spacing:                2

//     //         // 不要在这里再设置 delegate，保持用 control.delegate
//     //         // 想改外观就在顶层的 control.delegate 里改
//     //     }
//     // }



//     popup: T.Popup {
//         x:              control.width - _popupWidth
//         y:              control.height
//         width:          _popupWidth
//         height:         Math.min(contentItem.implicitHeight, control.Window.height - topMargin - bottomMargin)
//         topMargin:      6
//         bottomMargin:   6

//         contentItem: ListView {
//             clip:                   true
//             implicitHeight:         contentHeight
//             model:                  control.delegateModel
//             currentIndex:           control.highlightedIndex
//             highlightMoveDuration:  0

//             Rectangle {
//                 z:              10
//                 width:          parent.width
//                 height:         parent.height
//                 color:          "transparent"
//                 border.color:   qgcPal.text
//                 radius:         ScreenTools.buttonBorderRadius
//             }

//             T.ScrollIndicator.vertical: ScrollIndicator { }
//         }

//         background: Rectangle {
//             color:"transparent"

//         }
//     }
// }
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Templates as T
import QtQuick.Effects

import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.Controls

T.ComboBox {
    id: control

    // 基本样式设置
    padding: ScreenTools.comboBoxPadding
    spacing: ScreenTools.defaultFontPixelWidth
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family: ScreenTools.normalFontFamily

    // 尺寸计算
    implicitWidth: Math.max(
        background ? background.implicitWidth : 0,
        contentItem.implicitWidth + leftPadding + rightPadding + padding
    )
    implicitHeight: Math.max(
        background ? background.implicitHeight : 0,
        Math.max(contentItem.implicitHeight, indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding
    )

    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width)

    // 自定义属性
    property bool centeredLabel: false
    property bool sizeToContents: false
    property string alternateText: ""
    property real animationDuration: 200
    property real popupMaxHeight: 300

    property real _popupWidth: width
    property bool _onCompleted: false
    property bool _showBorder: qgcPal.globalTheme === QGCPalette.Light

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // 文本测量
    TextMetrics {
        id: textMetrics
        font.family: control.font.family
        font.pointSize: control.font.pointSize
    }

    ItemDelegate {
        id: itemDelegateMetrics
        visible: false
        font.family: control.font.family
        font.pointSize: control.font.pointSize
    }

    // 弹出菜单宽度计算
    function _calcPopupWidth() {
        if (_onCompleted && sizeToContents && model) {
            var largestTextWidth = 0
            for (var i = 0; i < model.length; i++) {
                textMetrics.text = control.textRole ? model[i][control.textRole] : model[i]
                largestTextWidth = Math.max(textMetrics.width, largestTextWidth)
            }
            _popupWidth = Math.max(control.width, largestTextWidth + itemDelegateMetrics.leftPadding + itemDelegateMetrics.rightPadding + 20)
        }
    }

    onModelChanged: _calcPopupWidth()
    Component.onCompleted: {
        _onCompleted = true
        _calcPopupWidth()
    }

    // 代理项设计 - 现代风格
    delegate: ItemDelegate {
        width: _popupWidth
        height: Math.max(ScreenTools.defaultFontPixelHeight * 2, popupItemMetrics.height + ScreenTools.defaultFontPixelHeight)

        property string _text: control.textRole ?
            (Array.isArray(model) ? modelData : (model.hasOwnProperty(control.textRole) ? model[control.textRole] : modelData[control.textRole])) :
            modelData

        TextMetrics {
            id: popupItemMetrics
            font: control.font
            text: _text
        }

        contentItem: Text {
            text: _text
            font: control.font
            color: qgcPal.buttonText
            verticalAlignment: Text.AlignVCenter
            leftPadding: ScreenTools.defaultFontPixelWidth
        }

        background: Rectangle {
            color: "transparent"
            radius: 4
        }

        highlighted: control.highlightedIndex === index
    }

    // 指示器 - 现代风格
    indicator: Item {
        anchors.right: parent.right
        anchors.rightMargin: control.padding
        anchors.verticalCenter: parent.verticalCenter
        width: ScreenTools.defaultFontPixelWidth * 1.5
        height: width

        QGCColoredImage {
            id: arrowIcon
            anchors.centerIn: parent
            width: parent.width * 0.6
            height: width
            source: "/qmlimages/arrow-down.png"
            color: qgcPal.buttonText
            rotation: control.popup.visible ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: control.animationDuration; easing.type: Easing.OutCubic }
            }
        }
    }

    // 内容显示
    contentItem: QGCLabel {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: centeredLabel ? parent.horizontalCenter : undefined
        text: control.alternateText === "" ? control.currentText : control.alternateText
        font: control.font
        color: qgcPal.buttonText
        leftPadding: ScreenTools.defaultFontPixelWidth
    }

    // 背景 - 现代风格
    background: Rectangle {
        color:  "transparent"
        border.color: _showBorder ? qgcPal.buttonBorder : "transparent"
        border.width: _showBorder ? 1 : 0
        radius: 6

        // 悬停效果
        states: State {
            name: "hovered"
            when: control.hovered
            PropertyChanges { target: background; color: Qt.lighter("dodgerblue", 1.1) }
        }

        transitions: Transition {
            ColorAnimation { duration: 150 }
        }
    }

    // 弹出菜单 - 现代风格
    popup: T.Popup {
        id: popup
        x: 0
        y: control.height + 4
        width: _popupWidth
        padding: 4
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property real targetHeight: 0   // 目标高度

        background: Rectangle {
            color: qgcPal.window
            radius: 8
            border.color: qgcPal.buttonBorder
            border.width: 1
            layer.enabled: true
            //阴影
            // layer.effect: MultiEffect {
            //     shadowEnabled: true
            //     shadowColor: "#40000000"
            //     shadowBlur: 12
            //     shadowHorizontalOffset: 0
            //     shadowVerticalOffset: 4
            //     shadowScale: 1.05
            // }
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            highlightFollowsCurrentItem: true
            boundsBehavior: Flickable.StopAtBounds

            // 高亮指示器
            highlight: Rectangle {
                color: "dodgerblue"
                radius: 4
                anchors.left: parent.left
                anchors.right: parent.right
                height: listView.currentItem ? listView.currentItem.height : 0
                y: listView.currentItem ? listView.currentItem.y : 0
            }
        }


        // 高度绑定在 targetHeight 上
        height: targetHeight

        // 动画
        Behavior on targetHeight {
            NumberAnimation {
                duration: control.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        onOpened: {
            targetHeight = Math.min(listView.contentHeight + padding * 2, control.popupMaxHeight)
        }
        onClosed: {
            targetHeight = 0
        }
    }


    // 状态变化时的动画
    states: [
        State {
            name: "popupOpen"
            when: control.popup.visible
            PropertyChanges { target: control.background; color: Qt.lighter("dodgerblue", 1.1) }
        }
    ]

    transitions: [
        Transition {
            to: "popupOpen"
            reversible: true
            ColorAnimation { duration: control.animationDuration }
        }
    ]
}
