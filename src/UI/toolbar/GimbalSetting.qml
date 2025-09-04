// import QtQuick
// import QtQuick.Layouts
// import QGroundControl
// import QGroundControl.Controls
// import QGroundControl.FactSystem
// import QGroundControl.FactControls
// import QGroundControl.ScreenTools
// import QGroundControl.Palette

// GridLayout {
//     id: settingsPanel
//     columns:        2
//     rowSpacing:     ScreenTools.defaultFontPixelWidth
//     Layout.fillWidth: true

//     // 外部可传入控制参数
//     property bool joystickButtonsAvailable: false
//     property bool visiblePanel: true

//     visible: visiblePanel

//     // 屏幕上的云台控制开关
//     FactCheckBox {
//         id:                 enableOnScreenControlCheckbox
//         text:               "  " + QGroundControl.settingsManager.gimbalControllerSettings.EnableOnScreenControl.shortDescription
//         fact:               QGroundControl.settingsManager.gimbalControllerSettings.EnableOnScreenControl
//         checkedValue:       1
//         uncheckedValue:     0
//         Layout.columnSpan:  2
//     }

//     // 控制方式
//     QGCLabel {
//         text: qsTr("控制方式: ")
//         visible: enableOnScreenControlCheckbox.checked
//     }
//     FactComboBox {
//         fact:    QGroundControl.settingsManager.gimbalControllerSettings.ControlType
//         visible: enableOnScreenControlCheckbox.checked
//     }

//     // 水平FOV
//     QGCLabel {
//         text: qsTr("水平视场角")
//         visible: enableOnScreenControlCheckbox.checked
//                  && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
//     }
//     FactTextField {
//         fact:    QGroundControl.settingsManager.gimbalControllerSettings.CameraHFov
//         visible: enableOnScreenControlCheckbox.checked
//                  && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
//     }

//     // 垂直FOV
//     QGCLabel {
//         text: qsTr("垂直视场角")
//         visible: enableOnScreenControlCheckbox.checked
//                  && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
//     }
//     FactTextField {
//         fact:    QGroundControl.settingsManager.gimbalControllerSettings.CameraVFov
//         visible: enableOnScreenControlCheckbox.checked
//                  && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
//     }

//     // 速度模式
//     QGCLabel {
//         text: qsTr("最大速度:")
//         visible: enableOnScreenControlCheckbox.checked
//                  && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 1
//     }
//     FactTextField {
//         fact:    QGroundControl.settingsManager.gimbalControllerSettings.CameraSlideSpeed
//         visible: enableOnScreenControlCheckbox.checked
//                  && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 1
//     }

//     // 分割线
//     Rectangle {
//         Layout.columnSpan:       2
//         Layout.preferredHeight:  2
//         Layout.preferredWidth:   parent.width
//         Layout.margins:          ScreenTools.defaultFontPixelWidth
//         color:                   qgcPal.windowShade
//     }

//     // Joystick speed
//     QGCLabel {
//         text: qsTr("纵杆按钮速度:")
//         visible: joystickButtonsAvailable && QGroundControl.settingsManager.gimbalControllerSettings.visible
//     }
//     FactTextField {
//         fact:    QGroundControl.settingsManager.gimbalControllerSettings.joystickButtonsSpeed
//         visible: joystickButtonsAvailable && QGroundControl.settingsManager.gimbalControllerSettings.visible
//         showHelp: true
//     }

//     // 分割线
//     Rectangle {
//         Layout.columnSpan:       2
//         Layout.preferredHeight:  2
//         Layout.preferredWidth:   parent.width
//         Layout.margins:          ScreenTools.defaultFontPixelWidth
//         color:                   qgcPal.windowShade
//         visible: joystickButtonsAvailable && QGroundControl.settingsManager.gimbalControllerSettings.visible
//     }

//     FactCheckBox {
//         text: "  " + qsTr("在地图中显示云台方位角指示器")
//         fact: QGroundControl.settingsManager.gimbalControllerSettings.showAzimuthIndicatorOnMap
//         Layout.columnSpan:  2
//         checkedValue: 1
//         uncheckedValue: 0
//     }

//     FactCheckBox {
//         text: "  " + qsTr("在顶部工具栏指示器上使用方位角而不是局部偏航")
//         fact: QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAzimuth
//         Layout.columnSpan:  2
//         checkedValue: 1
//         uncheckedValue: 0
//     }

//     FactCheckBox {
//         text: "  " + qsTr("显示 采集/释放 控制按钮")
//         fact: QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAcquireReleaseControl
//         Layout.columnSpan:  2
//         checkedValue: 1
//         uncheckedValue: 0
//     }
// }
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15  // ← 必须导入 Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.Palette

QGCCard {
    id: gimbalSettingsCard
    property bool joystickButtonsAvailable: false

    content: /*ColumnLayout {
        anchors.fill: parent
        spacing: 8*/
        Item {
                       width: parent.width
        GridLayout {
            id: settingsPanel
            columns: 2
            rowSpacing: ScreenTools.defaultFontPixelWidth
            Layout.fillWidth: true

            // 固定显示的开关
            FactCheckBox {
                id: enableOnScreenControlCheckbox
                text: "  " + QGroundControl.settingsManager.gimbalControllerSettings.EnableOnScreenControl.shortDescription
                fact: QGroundControl.settingsManager.gimbalControllerSettings.EnableOnScreenControl
                checkedValue: 1
                uncheckedValue: 0
                Layout.columnSpan: 2
            }

            // 控制方式
            QGCLabel {
                text: qsTr("控制方式:")
            }
            FactComboBox {
                fact: QGroundControl.settingsManager.gimbalControllerSettings.ControlType
            }

            // 用 Item 包裹可动态显示的控件
           // Item {
               // Layout.columnSpan: 2
              //  visible: enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 0
               // RowLayout {
                 //   spacing: 4
                    QGCLabel { text: qsTr("水平视场角") }
                    FactTextField { fact: QGroundControl.settingsManager.gimbalControllerSettings.CameraHFov }
                    QGCLabel { text: qsTr("垂直视场角") }
                    FactTextField { fact: QGroundControl.settingsManager.gimbalControllerSettings.CameraVFov }
          //      }
            //}

            //Item {
              //  Layout.columnSpan: 2
               // visible: true//enableOnScreenControlCheckbox.checked && QGroundControl.settingsManager.gimbalControllerSettings.ControlType.rawValue === 1
                //ColumnLayout {
                    //spacing: 4
                    QGCLabel { text:   qsTr("最大速度:") }
                    FactTextField { fact: QGroundControl.settingsManager.gimbalControllerSettings.CameraSlideSpeed }
                //}
            //}

            // 分割线
            // Rectangle {
            //     Layout.columnSpan: 2
            //     Layout.preferredHeight: 2
            //     color: qgcPal.windowShade
            // }

            // Joystick speed
            //Item {
              //  Layout.columnSpan: 2
               // visible: true//gimbalSettingsCard.joystickButtonsAvailable
              //  ColumnLayout {
              //      spacing: 4
                    QGCLabel { text: qsTr("纵杆按钮速度:") }
                    FactTextField {
                        fact: QGroundControl.settingsManager.gimbalControllerSettings.joystickButtonsSpeed
                        showHelp: true
                    }
               // }
           // }

            // 分割线
            // Rectangle {
            //     Layout.columnSpan: 2
            //     Layout.preferredHeight: 2
            //     color: qgcPal.windowShade
            //     visible: gimbalSettingsCard.joystickButtonsAvailable
            // }

            // 其他固定显示的控件
            FactCheckBox {
                text: "  " + qsTr("在地图中显示云台方位角指示器")
                fact: QGroundControl.settingsManager.gimbalControllerSettings.showAzimuthIndicatorOnMap
                Layout.columnSpan: 2
            }
            FactCheckBox {
                text: "  " + qsTr("在顶部工具栏指示器上使用方位角而不是局部偏航")
                fact: QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAzimuth
                Layout.columnSpan: 2
            }
            FactCheckBox {
                text: "  " + qsTr("显示 采集/释放 控制按钮")
                fact: QGroundControl.settingsManager.gimbalControllerSettings.toolbarIndicatorShowAcquireReleaseControl
                Layout.columnSpan: 2
            }
        }
}
   // }
}
