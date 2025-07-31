import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools



//ScreenTools.qml 是 QGroundControl 提供的 QML 单例
//用于标准化字体、像素密度、屏幕大小、平台判断和控件尺寸等，使得 UI 设计在所有平台、设备上都一致美观、可读
Text {
    font.pointSize: ScreenTools.defaultFontPointSize
    font.family:    ScreenTools.normalFontFamily
    color:          qgcPal.text
    antialiasing:   true

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
}
