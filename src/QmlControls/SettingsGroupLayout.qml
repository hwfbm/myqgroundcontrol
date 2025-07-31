import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Palette


//结合了 ColumnLayout、QGCLabel 和 Rectangle，用于创建一个带有标题、描述和分隔线的布局
ColumnLayout {
    id:                 control    
    spacing:            _margins / 2
    implicitWidth:      _contentLayout.implicitWidth + (_margins * 2)
    implicitHeight:     _contentLayout.implicitHeight + (_margins * 2)

    //default property 表示未明确指定属性的子元素会绑定到 contentItem，只要你把内容包在这个 SettingsGroupLayout {} 中，它内部定义的 default property alias contentItem: _contentLayout.data 就会将你写的“子项”自动放入 _contentLayout 中，由 ColumnLayout 来自动排列它们
    //允许外部直接向 SettingsGroupLayout 添加子项，这些子项会自动注入到 _contentLayout 中
    //在 QML 中，每个 Item 类型都隐式地有一个 data 属性，它是一个包含所有“未绑定到特定属性的对象”的列表
    default property alias contentItem: _contentLayout.data //创建了一个别名 contentItem，它指向 _contentLayout 的 data 属性，用于设置或获取布局中的内容

    property alias contentSpacing: _contentLayout.spacing //创建了一个别名 contentSpacing，它指向 _contentLayout 的 spacing 属性，用于设置或获取布局中的间距

    //property string defaultBorderColor  : QGroundControl.globalPalette.groupBorder //定义了默认的边框颜色
    property string defaultBorderColor  :  "yellow" //定义了默认的边框颜色
    property string outerBorderColor    : defaultBorderColor //定义了外部边框的颜色，默认值为 defaultBorderColor

    property string heading //定义了标题文本
    property string headingDescription //定义了标题描述文本
    property bool   showDividers:       true //定义了是否显示分隔线，默认值为 true
    property bool   showBorder:         true //定义了是否显示边框，默认值为 true

    property real _margins: ScreenTools.defaultFontPixelHeight / 2 //定义了内部边距，默认值为 ScreenTools.defaultFontPixelHeight / 2


    //这个内部的 ColumnLayout 用于显示标题和描述
    ColumnLayout {
        Layout.leftMargin:  _margins
        Layout.fillWidth:   true
        spacing:            0
        visible:            heading !== ""

        //QGCLabel 用于显示标题和描述文本
        QGCLabel { 
            text:           heading
            font.pointSize: ScreenTools.defaultFontPointSize + 1
            font.bold:      true
        }

        QGCLabel { 
            Layout.fillWidth:   true
            text:               headingDescription
            wrapMode:           Text.WordWrap
            font.pointSize:     ScreenTools.smallFontPointSize
            visible:            headingDescription !== ""
        }
    }
    // "#9fa0e2"
//绘制外部边框
    Rectangle {
        id:                 outerRect
        Layout.fillWidth:   true
        implicitWidth:      _contentLayout.implicitWidth + (showBorder ? _margins * 2 : 0)
        implicitHeight:     _contentLayout.implicitHeight + (showBorder ? _margins * 2: 0)
        color:             "transparent"
        border.color:       outerBorderColor
        border.width:       showBorder ? 1 : 0
        radius:             ScreenTools.defaultFontPixelHeight / 2


        //Repeater 用于重复生成分隔线，是 Qt Quick 中的一个组件，用于基于模型（model）动态生成子项，Repeater 自动为每个生成的实例分配 index
        //它会根据 model 的值创建多个实例（此处是分隔线 Rectangle）。每个实例可以通过 index 访问其在模型中的位置
        Repeater {
            //_contentLayout.children.length（即子项数量）。length 是 JavaScript 数组的固有属性，表示元素个数
            //contentLayout 是一个布局组件（如 Column 或 Row），children 是其直接子项的列表，length 表示子项的数量，因此 Repeater 会为每个子项生成一个分隔线（但后续通过 visible 条件过滤）
            model: showDividers? _contentLayout.children.length : 0
          //每个分隔线是一个 Rectangle，其 y 坐标基于 _contentLayout 中子项的位置
            Rectangle {
                x:                  showBorder ? _margins : 0//// 是否有边框？有则缩进，否则贴左
                y:                  _contentItem.y + _contentItem.height + _margins + (showBorder ? _margins : 0)
                width:              parent.width - (showBorder ? _margins * 2 : 0)
                height:             1
                color:              QGroundControl.globalPalette.groupBorder
                visible:            _contentItem.visible && 
                                        _contentItem.width !== 0 && _contentItem.height !== 0 &&
                                        index < _contentLayout.children.length - 1//对应的子项 _contentItem 必须可见且尺寸非零，仅对非最后一个子项生成分隔线（index < length - 1）

                //在 QML 中，任何 可视化项（Item） 的 children 属性是一个 默认的数组，存储其直接子元素，动态添加/删除子项时，children 自动更新。
                property var _contentItem: _contentLayout.children[index] //将当前分隔线关联到 _contentLayout 的第 index 个子项，以便动态获取其位置和尺寸
            }
        }
 
        ColumnLayout {
            id:                 _contentLayout
            x:                  showBorder ? _margins : 0
            y:                  showBorder ? _margins : 0
            width:              parent.width - (showBorder ? _margins * 2 : 0)
            spacing:            _margins * 2
        }
    }
}
