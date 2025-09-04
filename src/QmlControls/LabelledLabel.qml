/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.ScreenTools //

//这个 RowLayout 组件是一个简单的双标签布局控件，主要用于在 QML 界面中显示键值对形式的内容（如设置项的标签和值）
//左侧显示字段名称（label），右侧显示字段值（labelText
RowLayout {
    property alias label:                   _labelLabel.text//左侧标签文本（绑定到 _labelLabel.text）
    property alias labelText:              _label.text //右侧值文本（绑定到 _label.text）
    property real  labelPreferredWidth:    -1 //右侧标签的预设宽度，-1：自动扩展（在布局容器中-1相当于没有设置固定值，qt默认会根据内容长度拓展），>0：固定宽度


    spacing: ScreenTools.defaultFontPixelWidth * 2 //使用 ScreenTools 实现跨设备的间距适配

    //左侧标签
    QGCLabel { 
        id:                 _labelLabel
        Layout.fillWidth:   true  //使其尽可能扩展，挤压右侧标签空间
    }


    // implicitWidth 是 Qt 中每个可视项都有的内置属性，它表示：
    // 这个控件在“自然状态下”所需的宽度 —— 通常是根据控件的内容、字体大小等自动计算出来的。
    // 比如一个 Label 显示 "Hello"，它的 implicitWidth 可能是 50，但如果显示 "Hello World!"，它可能变成 100


    //右侧标签
    //当 labelPreferredWidth = -1 时：宽度由文本内容决定，当 labelPreferredWidth > 0 时：强制固定宽度（可能截断文本）
    QGCLabel {
        id:                     _label
        color: "white"
        Layout.preferredWidth:  labelPreferredWidth
    }
}
//其实就是先让一个标签填满，右侧标签覆盖，根据字体自动扩展
