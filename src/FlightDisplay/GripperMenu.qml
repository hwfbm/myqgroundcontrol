
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtLocation
import QtPositioning
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.FlightMap

// 弹出对话框（Popup Dialog），用于控制机械臂或抓取器（Gripper）的抓取/释放动作
QGCPopupDialog {
    title: "选择一个动作"
    property var  acceptFunction:     null
    buttons:  Dialog.Cancel

    onRejected:{
        _guidedController._gripperFunction = Vehicle.Invalid_option
        _guidedController.closeAll()
        close()
    }

    onAccepted: {
        if (acceptFunction) {
            _guidedController._gripperFunction = Vehicle.Invalid_option
            close()
        }
    }

    RowLayout {
        QGCColumnButton {
            id: grabButton
            text:                   "抓取"
            iconSource:             "/res/GripperGrab.svg"
            font.pointSize:         ScreenTools.defaultFontPointSize //* 3.5
            backRadius:             width / 40
            heightFactor:           0.75
            Layout.preferredHeight: releaseButton.height
            Layout.preferredWidth:  releaseButton.width

            onClicked: {
                _guidedController._gripperFunction = Vehicle.Gripper_grab
                close()
            }
        }

        QGCColumnButton {
            id: releaseButton
            text:                   "松开"
            iconSource:             "/res/GripperRelease.svg"
            font.pointSize:         ScreenTools.defaultFontPointSize //* 3.5
            backRadius:             width / 40
            heightFactor:           0.75
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 10
            Layout.preferredHeight: Layout.preferredWidth / 1.20

            onClicked: {
                _guidedController._gripperFunction = Vehicle.Gripper_release
                close()
            }
        }
    }
}
