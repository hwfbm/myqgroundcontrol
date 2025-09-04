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

import QGroundControl.ScreenTools
import QGroundControl.Palette

//定义了一个用于 QGroundControl 的工具条按钮组件，它是一个高度自定义的 Button 控件
// 这是一个圆形工具按钮，主要特点包括：
// 圆形设计（通过 radius 控制）
// 支持图标和文本组合显示
// 支持多种状态（正常、悬停、按下、选中）
// 支持下拉面板功能
// 支持多彩图标和双色图标
// 自适应不同屏幕尺寸
Button {
    id:             control
    width:          contentLayoutItem.contentWidth + (contentMargins * 2)
    height:         width //// 保持正方形
    hoverEnabled:   !ScreenTools.isMobile// 移动设备禁用悬停
    enabled:        toolStripAction.enabled //按钮是否响应交互
    visible:        toolStripAction.visible //按钮是否显示

    //根据showAlternateIcon显示主图标或备用图标
    imageSource:    toolStripAction.showAlternateIcon ? modelData.alternateIconSource : modelData.iconSource
    text:           toolStripAction.text //按钮显示文本
    checked:        toolStripAction.checked //选中状态
    //有下拉面板或标记为可检查时=true
    checkable:      toolStripAction.dropPanelComponent || modelData.checkable

    property var    toolStripAction:    undefined// 绑定的动作对象，它封装了工具条按钮的所有行为和状态
    property var    dropPanel:          undefined // 下拉面板引用
    property alias  radius:             buttonBkRect.radius// 背景圆角半径
    property alias  fontPointSize:      innerText.font.pointSize// 文本大小
    property alias  imageSource:        innerImage.source // 图标源
    property alias  contentWidth:       innerText.contentWidth// 文本内容宽度


    //当按钮只有图标没有文字时(text == "")，可以设置forceImageScale11让图标更大(0.8)
    //默认情况图标较小(0.6)，为文字留出空间
    property bool forceImageScale11: false //强制使用大比例缩放
    property real imageScale:        forceImageScale11 && (text == "") ? 0.8 : 0.6
    property real contentMargins:    innerText.height * 0.1 //内容边距，始终=文本高度的10%

    //定义了两个动态颜色属性（正常时候和按下或选择时候）
    // property color _currentContentColor:  (checked || pressed) ? qgcPal.buttonHighlightText : qgcPal.buttonText
    // property color _currentContentColorSecondary:  (checked || pressed) ? qgcPal.buttonText : qgcPal.buttonHighlight
                                     // 正常状态用默认颜色，按下时为橘色
                                     property color _currentContentColor: pressed ? "#ADFF2F" :
                                                                           (checked ? qgcPal.buttonHighlightText : qgcPal.buttonText)

                                     // 第二颜色逻辑，你可以根据需求调换
                                     property color _currentContentColorSecondary: pressed ? qgcPal.buttonText :
                                                                                 (checked ? qgcPal.buttonText : qgcPal.buttonHighlight)

    // 典型用途：
    // 记录最后使用的工具（如选择的是第几个工具）
    // 联动其他界面元素（如高亮对应功能区域）
    // 统计分析（记录用户最常使用的功能）
    signal dropped(int index)//定义一个信号可传递参数。当下拉面板显示时触发，index是按钮在工具条中的位置索引

    onCheckedChanged: toolStripAction.checked = checked

    //点击处理


    onClicked: {
        //// 1. 首先检查是否允许视图切换
        if (mainWindow.allowViewSwitch()) {
            dropPanel.hide()// 2. 先隐藏可能存在的下拉面板
            if (!toolStripAction.dropPanelComponent) // 3. 判断动作类型
            {  // 3a. 如果没有下拉面板组件，直接触发动作
                toolStripAction.triggered(this)
            }
            else if (checked)  //3b. 如果有下拉组件且当前是选中状态，显示面板
            {
                var panelEdgeTopPoint = mapToItem(_root, width, 0)
                dropPanel.show(panelEdgeTopPoint, toolStripAction.dropPanelComponent, this)
                checked = true
                control.dropped(index)// 发出信号
            }
        } else if (checkable) // 4. 如果不允许视图切换但按钮是可选的，切换选中状态
        {
            checked = !checked
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: control.enabled }

    contentItem: Item {
        id:                 contentLayoutItem
        anchors.fill:       parent
        anchors.margins:    contentMargins

        //使用 Column 布局垂直排列图标和文本：
        Column {
            anchors.centerIn:   parent
            spacing:        contentMargins * 2

            //// 多彩图标（全彩色）
            Image {
                id:                         innerImageColorful
                height:                     contentLayoutItem.height * imageScale
                width:                      contentLayoutItem.width  * imageScale
                smooth:                     true
                mipmap:                     true
                fillMode:                   Image.PreserveAspectFit
                antialiasing:               true
                sourceSize.height:          height
                sourceSize.width:           width
                anchors.horizontalCenter:   parent.horizontalCenter
                source:                     control.imageSource
                visible:                    source != "" && modelData.fullColorIcon
            }

            // // 单色/双色图标
            QGCColoredImage {
                id:                         innerImage
                height:                     contentLayoutItem.height * imageScale
                width:                      contentLayoutItem.width  * imageScale
                smooth:                     true
                mipmap:                     true
                color:                      _currentContentColor
                fillMode:                   Image.PreserveAspectFit
                antialiasing:               true
                sourceSize.height:          height
                sourceSize.width:           width
                anchors.horizontalCenter:   parent.horizontalCenter
                visible:                    source != "" && !modelData.fullColorIcon
                // 双色图标的第二部分
                QGCColoredImage {
                    id:                         innerImageSecondColor
                    source:                     modelData.alternateIconSource
                    height:                     contentLayoutItem.height * imageScale
                    width:                      contentLayoutItem.width  * imageScale
                    smooth:                     true
                    mipmap:                     true
                    color:                      _currentContentColorSecondary
                    fillMode:                   Image.PreserveAspectFit
                    antialiasing:               true
                    sourceSize.height:          height
                    sourceSize.width:           width
                    anchors.horizontalCenter:   parent.horizontalCenter
                    visible:                    source != "" && modelData.biColorIcon
                }
            }

            // 文本标签
            QGCLabel {
                id:                         innerText
                text:                       control.text
                color:                      _currentContentColor
                anchors.horizontalCenter:   parent.horizontalCenter
                font.bold:                  !innerImage.visible && !innerImageColorful.visible
                opacity:                    !innerImage.visible ? 0.8 : 1.0
            }
        }
    }

    //背景设计 (background)
    // 背景颜色根据状态变化：
    // 选中/按下状态：高亮色
    // 悬停状态：悬停色
    // 默认状态：工具条背景色
    background: Rectangle {
        id:             buttonBkRect
        color:"transparent"
        /* (control.checked || control.pressed) ?
                            qgcPal.buttonHighlight :
                            (control.hovered ? qgcPal.toolStripHoverColor : qgcPal.toolbarBackground)*/
        anchors.fill:   parent
    }
}
