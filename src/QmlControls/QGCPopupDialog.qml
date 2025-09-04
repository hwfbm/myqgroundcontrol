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
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools


// 解决方案：始终用布局容器包裹：

// qml
// QGCPopupDialog {
//     ColumnLayout { // ← 唯一被移动的子项
//         QGCLabel { text: "标签1" }
//         QGCLabel { text: "标签2" }
//     }
// }


// Provides the standard dialog mechanism for QGC. Works 99% like Qml Dialog.
//
// Example usage:
//      Component {
//          id: dialogComponent
//
//          QGCPopupDialog {
//              ...
//          }
//      }
//
//      onFoo: dialogComponent.createObject(mainWindow).open()
//
// Notes:
//  * QGCPopupDialog should be created from a component to limit the memory usage of the dialog
//      to only when it is displayed.
//  * Parent for createObject should always be mainWindow.
// Differences from standard Qml Dialog:
//  * The QGCPopupDialog object will automatically be destroyed when it closed. You can override this
//      behaviour by setting destroyOnClose to false if it was not created dynamically.
//  * Dialog will automatically close after accepted/rejected signal processing. You can prevent this by setting
//      preventClose = true prior to returning from your signal handlers.
Popup {
    id:                 root
    width:  mainWindow.width
    height: mainWindow.height
    parent:             Overlay.overlay
    modal:              true
    focus:              true
    margins:            0

    property string title
    property var    buttons:                Dialog.Ok //按钮组合 (使用 Qt 的 Dialog 标准按钮枚举)
    property alias  acceptButtonEnabled:    acceptButton.enabled //接受按钮启用状态
    property alias  rejectButtonEnabled:    rejectButton.enabled //拒绝按钮启用状态
    property var    dialogProperties // 自定义属性


    // QGCPopupDialog {
    //     dialogProperties: {
    //         "customItem": Qt.createComponent("MyItem.qml").createObject(dialogContentParent)
    //     }
    // }
    // 关键区别：createObject 时直接指定了 parent: dialogContentParent
    // 这种内容 不会先成为 QGCPopupDialog 的子项，而是直接插入目标父级
    // 因此不会出现在 contentChildren 中


    property bool   destroyOnClose:         true //关闭时自动销毁
    property bool   preventClose:           false //阻止自动关闭
    
    readonly property real headerMinWidth: titleLable.implicitWidth + rejectButton.width + acceptButton.width + titleRowLayout.spacing * 2

    signal accepted
    signal rejected

    property var    _qgcPal:            QGroundControl.globalPalette //使用 QGC 的全局调色板
    property real   _frameSize:         ScreenTools.defaultFontPixelWidth //边框大小
    property real   _contentMargin:     ScreenTools.defaultFontPixelHeight / 2 //内容边距
    property bool   _acceptAllowed:     acceptButton.visible //按钮可见性状态
    property bool   _rejectAllowed:     rejectButton.visible//内部计算，rejectButton 是否可见

    property int    _previousValidationErrorCount: 0

    //背景层
    background: QGCMouseArea {
        width:  mainWindow.width
        height: mainWindow.height
//全屏半透明背景，点击外部可关闭（如果 closePolicy 允许）
        onClicked: {
            if (closePolicy & Popup.CloseOnPressOutside) {
                _reject()
            }
        }
    }

    //动态内容插入，用户定义的 QML 内容会被自动插入到 dialogContentParent，确保正确的布局层级
    //当 QGCPopupDialog 完成实例化（所有子项已创建），在首次显示前（早于 onVisibleChanged）触发，只执行一次
    //在 QGCPopupDialog 源码中，Component.onCompleted 直接定义在根 Popup 下：
    //QML 引擎解析 QGCPopupDialog 的所有子项（标题、按钮、用户内容）
    //完成组件树构建后，触发 Component.onCompleted
    //执行移动逻辑
    Component.onCompleted: {
        // The last child item will be the true dialog content.
        // Re-Parent it to the right place in the ui hierarchy.
        // // 将最后一个子项（用户定义的内容）移动到 dialogContentParent

        //contentChildren 是 所有 QML 组件的默认属性（继承自 Item 基类）
        //它包含 当前组件的所有直接子项（不包括子项的子项）
        contentChildren[contentChildren.length - 1].parent = dialogContentParent
    }

    onAboutToShow: {
        _previousValidationErrorCount = globals.validationErrorCount
        setupDialogButtons(buttons)
    }


    //关闭时自动释放内存
    onClosed: {
        globals.validationErrorCount = _previousValidationErrorCount
        Qt.inputMethod.hide()
        if (destroyOnClose) {
            root.destroy()
        }
    }

    //处理接受/拒绝逻辑，触发 accepted/rejected 信号
    function _accept() {
        //（验证错误检查）
        if (_acceptAllowed && mainWindow.allowViewSwitch(_previousValidationErrorCount)) {
            accepted()//触发 accepted 信号
            if (preventClose) //如果 preventClose 为 false，关闭对话框
            {
                preventClose = false
            } else {
                close()
            }
        }
    }

    function _reject() {
        // Dialogs with cancel button are allowed to close with validation errors
        //检查 _rejectAllowed 或 Dialog.Cancel 是否允许关闭
        if (_rejectAllowed && ((buttons & Dialog.Cancel) || mainWindow.allowViewSwitch(_previousValidationErrorCount))) {
            rejected()//触发 rejected 信号
            if (preventClose)
            {
                preventClose = false//如果 preventClose 为 false，关闭对话框
            } else {
                close()
            }
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: parent.enabled }

    //按钮组合 (使用 Qt 的 Dialog 标准按钮枚举)
    //根据传入的 Dialog.StandardButton 配置按钮的显示和文本
    function setupDialogButtons(buttons) {
        acceptButton.visible = false
        rejectButton.visible = false
        // Accept role buttons
        if (buttons & Dialog.Ok) {
            acceptButton.text = qsTr("Ok")
            acceptButton.visible = true
        } else if (buttons & Dialog.Open) {
            acceptButton.text = qsTr("Open")
            acceptButton.visible = true
        } else if (buttons & Dialog.Save) {
            acceptButton.text = qsTr("Save")
            acceptButton.visible = true
        } else if (buttons & Dialog.Apply) {
            acceptButton.text = qsTr("Apply")
            acceptButton.visible = true
        } else if (buttons & Dialog.Open) {
            acceptButton.text = qsTr("Open")
            acceptButton.visible = true
        } else if (buttons & Dialog.SaveAll) {
            acceptButton.text = qsTr("Save All")
            acceptButton.visible = true
        } else if (buttons & Dialog.Yes) {
            acceptButton.text = qsTr("Yes")
            acceptButton.visible = true
        } else if (buttons & Dialog.YesToAll) {
            acceptButton.text = qsTr("Yes to All")
            acceptButton.visible = true
        } else if (buttons & Dialog.Retry) {
            acceptButton.text = qsTr("Retry")
            acceptButton.visible = true
        } else if (buttons & Dialog.Reset) {
            acceptButton.text = qsTr("Reset")
            acceptButton.visible = true
        } else if (buttons & Dialog.RestoreToDefaults) {
            acceptButton.text = qsTr("Restore to Defaults")
            acceptButton.visible = true
        } else if (buttons & Dialog.Ignore) {
            acceptButton.text = qsTr("Ignore")
            acceptButton.visible = true
        }

        // Reject role buttons
        if (buttons & Dialog.Cancel) {
            rejectButton.text = qsTr("Cancel")
            rejectButton.visible = true
        } else if (buttons & Dialog.Close) {
            rejectButton.text = qsTr("Close")
            rejectButton.visible = true
        } else if (buttons & Dialog.No) {
            rejectButton.text = qsTr("No")
            rejectButton.visible = true
        } else if (buttons & Dialog.NoToAll) {
            rejectButton.text = qsTr("No to All")
            rejectButton.visible = true
        } else if (buttons & Dialog.Abort) {
            rejectButton.text = qsTr("Abort")
            rejectButton.visible = true
        }
//如果包含 Dialog.Cancel，允许按 Escape 键关闭对话框
        closePolicy = Popup.NoAutoClose
        if (buttons & Dialog.Cancel) {
            closePolicy |= Popup.CloseOnEscape
        }
    }

    function disableAcceptButton() {
        acceptButton.enabled = false
    }

    Rectangle {
        x:              mainLayout.x - _contentMargin
        y:              mainLayout.y - _contentMargin
        width:          mainLayout.width + _contentMargin * 2
        height:         mainLayout.height + _contentMargin * 2
        color:          Qt.rgba(0, 0, 0, 0.65)//_qgcPal.windowShade
        radius:         root.padding / 2
        border.width:   1
        border.color:   _qgcPal.windowShadeLight
    }


    //主布局
    ColumnLayout {
        id:                 mainLayout
        anchors.centerIn:   parent
        x:          _contentMargin
        y:          _contentMargin
        spacing:    _contentMargin

        //// 标题行（包含标题和按钮）
        RowLayout {
            id:                     titleRowLayout
            Layout.fillWidth:       true
            spacing:                _contentMargin

            QGCLabel {
                id: titleLable
                Layout.fillWidth:   true
                text:               root.title
                font.pointSize:     ScreenTools.mediumFontPointSize
                verticalAlignment:	Text.AlignVCenter
            }
            //动态生成 acceptButton 和 rejectButton
            QGCButton {
                id:                     rejectButton
                onClicked:              _reject() //处理接受/拒绝逻辑，触发 accepted/rejected 信号。
                Layout.minimumWidth:    height * 1.5
            }

            QGCButton {
                id:                     acceptButton
                primary:                true
                onClicked:              _accept()
                Layout.minimumWidth:    height * 1.5
            }
        }

        //// 内容区域（可滚动）
        Rectangle {
            Layout.fillWidth:       true
            Layout.preferredWidth:  Math.min(maxAvailableWidth, totalContentWidth)
            Layout.preferredHeight: Math.min(maxAvailableHeight, totalContentHeight)
            color:                 Qt.rgba(0, 0, 0, 0.65) /* _qgcPal.window*/
            border.color:  "#888888"
            radius:         root.padding / 2

            //real 是一个数据类型，表示一个浮点数，property real 用于定义一个浮点数类型的属性
            property real maxAvailableWidth:    mainWindow.width - _contentMargin * 4
            property real maxAvailableHeight:   mainWindow.height - titleRowLayout.height - _contentMargin * 5

            //dialogContentParent.childrenRect 获取所有子项的联合边界矩形
           // 自动追踪内容变化（如动态添加/删除组件）
            property real totalContentWidth:    dialogContentParent.childrenRect.width + _contentMargin * 2  //确定内容区域的最小所需宽度
            property real totalContentHeight:   dialogContentParent.childrenRect.height + _contentMargin * 2//确定内容区域的最小所需高度

            //使用 QGCFlickable 支持滚动
            QGCFlickable {
                anchors.margins:    _contentMargin
                anchors.fill:       parent
                contentWidth:       dialogContentParent.childrenRect.width
                contentHeight:      dialogContentParent.childrenRect.height



                Item {
                    id:     dialogContentParent
                    focus:  true

                    //按 Escape 键触发 _reject()（如果允许）
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape && _rejectAllowed) {
                            _reject()
                            event.accepted = true
                        }
                    }
                }


            }
        }
    }
}
