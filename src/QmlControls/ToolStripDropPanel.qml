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
import QGroundControl.ScreenTools
import QGroundControl.Palette

//带箭头的弹出式面板
Item {
    id:         _root
    visible:    false

    signal          clicked()
    property real   radius:             ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 1.75 : ScreenTools.defaultFontPixelHeight * 1.25
    property real   viewportMargins:    0
    property var    toolStrip

    // Should be an enum but that get's into the whole problem of creating a singleton which isn't worth the effort
    //方向枚举
    readonly property int dropLeft:     1
    readonly property int dropRight:    2
    readonly property int dropUp:       3
    readonly property int dropDown:     4

    readonly property real _arrowBaseHeight:    radius             // Height of vertical side of arrow
    readonly property real _arrowPointWidth:    radius * 0.666     // Distance from vertical side to point
    readonly property real _dropMargin:         ScreenTools.defaultFontPixelWidth

    property var    _dropEdgeTopPoint
    property alias  _dropDownComponent: panelLoader.sourceComponent
    property real   _viewportMaxTop:    0
    property real   _viewportMaxBottom: parent.parent.height - parent.y
    property real   _viewportMaxHeight: _viewportMaxBottom - _viewportMaxTop
    property var    _dropPanelCancel
    property var    _parentButton

    //显示面板
    function show(panelEdgeTopPoint, panelComponent, parentButton) {
        _parentButton = parentButton// 保存触发按钮
        _dropEdgeTopPoint = panelEdgeTopPoint// 箭头指向点
        _dropDownComponent = panelComponent// 要加载的面板组件
        _calcPositions() // 计算位置
        visible = true // 显示面板
        _dropPanelCancel = dropPanelCancelComponent.createObject(toolStrip.parent)// 创建取消区域
    }

    function hide() {
        if (_dropPanelCancel) {
            _dropPanelCancel.destroy()// 销毁取消区域
            _parentButton.checked = false// 取消按钮选中状态
            visible = false // 隐藏面板
            _dropDownComponent = undefined// 清除组件引用
        }
    }

    //计算位置和大小
// 负责：
//     计算面板大小（包含箭头）
//     定位面板位置
//     确保面板在视窗边界内
//     计算箭头点的坐标
    function _calcPositions() {
        var panelComponentWidth  = panelLoader.item.width
        var panelComponentHeight = panelLoader.item.height

        dropDownItem.width  = panelComponentWidth  + (_dropMargin * 2) + _arrowPointWidth
        dropDownItem.height = panelComponentHeight + (_dropMargin * 2)

        dropDownItem.x = _dropEdgeTopPoint.x + _dropMargin
        dropDownItem.y = _dropEdgeTopPoint.y -(dropDownItem.height / 2) + radius

        // Validate that dropdown is within viewport
      // 确保面板在视窗内
        dropDownItem.y = Math.min(dropDownItem.y + dropDownItem.height, _viewportMaxBottom) - dropDownItem.height
        dropDownItem.y = Math.max(dropDownItem.y, _viewportMaxTop)

        // Adjust height to not exceed viewport bounds
        // 调整高度不超出视窗边界
        dropDownItem.height = Math.min(dropDownItem.height, _viewportMaxHeight - dropDownItem.y)

        // Arrow points
        arrowCanvas.arrowPoint.y = (_dropEdgeTopPoint.y + radius) - dropDownItem.y
        arrowCanvas.arrowPoint.x = 0
        arrowCanvas.arrowBase1.x = _arrowPointWidth
        arrowCanvas.arrowBase1.y = arrowCanvas.arrowPoint.y - (_arrowBaseHeight / 2)
        arrowCanvas.arrowBase2.x = arrowCanvas.arrowBase1.x
        arrowCanvas.arrowBase2.y = arrowCanvas.arrowBase1.y + _arrowBaseHeight
        arrowCanvas.requestPaint()
    } // function - _calcPositions

    QGCPalette { id: qgcPal }

    //取消点击区域
    Component {
        // Overlay which is used to cancel the panel when the user clicks away
        id: dropPanelCancelComponent

         // 在工具条下层
        MouseArea {
            anchors.fill:   parent
            z:              toolStrip.z - 1
            onClicked:      dropPanel.hide() // 点击外部关闭面板
        }
    }

    // This item is sized to hold the entirety of the drop panel including the arrow point
    Item {
        id: dropDownItem

        // 阻止鼠标事件穿透
        DeadMouseArea {
            anchors.fill: parent
        }

        Canvas {
            id:             arrowCanvas
            anchors.fill:   parent

            property point arrowPoint: Qt.point(0, 0)
            property point arrowBase1: Qt.point(0, 0)
            property point arrowBase2: Qt.point(0, 0)

            // 绘制带箭头的面板背景
            // 使用调色板颜色
            onPaint: {
                var panelX = _arrowPointWidth
                var panelY = 0
                var panelWidth = parent.width - _arrowPointWidth
                var panelHeight = parent.height

                var context = getContext("2d")
                context.reset()
                context.beginPath()

                context.moveTo(panelX, panelY)                              // top left
                context.lineTo(panelX + panelWidth, panelY)                 // top right
                context.lineTo(panelX + panelWidth, panelX + panelHeight)   // bottom right
                context.lineTo(panelX, panelY + panelHeight)                // bottom left
                context.lineTo(arrowBase2.x, arrowBase2.y)
                context.lineTo(arrowPoint.x, arrowPoint.y)
                context.lineTo(arrowBase1.x, arrowBase1.y)
                context.lineTo(panelX, panelY)                              // top left

                context.closePath()
                context.fillStyle ="Qt.rgba(0, 0, 0, 0.6)"/* qgcPal.windowShade*/
                context.fill()
            }
        } // Canvas - arrowCanvas

        //可滚动内容区域
        QGCFlickable {
            id:                 panelItemFlickable
            anchors.margins:    _dropMargin
            anchors.leftMargin: _dropMargin + _arrowPointWidth
            anchors.fill:       parent
            flickableDirection: Flickable.VerticalFlick
            contentWidth:       panelLoader.width
            contentHeight:      panelLoader.height

            //// 动态加载实际内容
            Loader {
                id: panelLoader

                onHeightChanged:    _calcPositions()
                onWidthChanged:     _calcPositions()

                property var dropPanel: _root// 向子组件暴露面板引用
            }
        }
    } // Item - dropDownItem
}
