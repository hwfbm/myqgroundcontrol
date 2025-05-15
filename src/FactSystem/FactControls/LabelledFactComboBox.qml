/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

//结合了 QGCLabel 和 FactComboBox，用于显示一个标签和一个下拉选择框
import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FactSystem
import QGroundControl.FactControls

RowLayout {
    property alias label:                   label.text //提供了一个别名，用于设置 QGCLabel 的文本
    property alias fact:                    _comboBox.fact//提供了一个别名，用于设置 FactComboBox 的 fact 属性
    property alias indexModel:              _comboBox.indexModel//提供了一个别名，用于设置 FactComboBox 的 indexModel 属性。
    property var   comboBox:                _comboBox//提供了一个别名，用于访问 FactComboBox 的实例
    property real  comboBoxPreferredWidth:  -1 //提供了一个属性，用于设置 FactComboBox 的首选宽度

    spacing: ScreenTools.defaultFontPixelWidth * 2 // 计算默认字体像素宽度

    signal activated(int index) //定义了一个信号，当用户选择下拉框中的某个选项时发出

    QGCLabel {
        id:                 label
        Layout.fillWidth:   true //确保标签填充整个可用宽度
    }

    FactComboBox {
        id:                     _comboBox
        Layout.preferredWidth:  comboBoxPreferredWidth //设置下拉选择框的首选宽度，使用 comboBoxPreferredWidth 属性
        sizeToContents:         true   //确保下拉选择框的大小根据内容自动调整

        onActivated: (index) => { parent.activated(index) } //当用户选择某个选项时，发出 activated 信号，并传递选中的索引
    }
}

