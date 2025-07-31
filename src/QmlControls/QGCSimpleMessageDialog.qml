/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl.Controls
import QGroundControl.ScreenTools


//段代码定义了一个基于 QGCPopupDialog 的可复用消息对话框
QGCPopupDialog {
    property alias  text:           label.text
    property var    acceptFunction: null        // Mainly used by MainRootWindow.showMessage to specify accept function in call
    property var    closeFunction:  null

    onAccepted: {

        //可选接受回调 (acceptFunction)
        if (acceptFunction) {
            acceptFunction()//// 执行接受回调
        }
    }

    onClosed: {

        //可选关闭回调 (closeFunction)
        if (closeFunction) {
            closeFunction()   // 执行关闭回调
        }
    }

    //显示文本消息（支持自动换行
    ColumnLayout {
        QGCLabel {
            id:                     label
            Layout.preferredWidth:  Math.max(mainWindow.width / (ScreenTools.isMobile ? 2 : 3), headerMinWidth)//桌面端：窗口宽度的 1/3，移动端：窗口宽度的 1/2
            wrapMode:               Text.WordWrap
        }
    }
}
