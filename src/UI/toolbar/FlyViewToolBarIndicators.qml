// /****************************************************************************
//  *
//  * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
//  *
//  * QGroundControl is licensed according to the terms in the file
//  * COPYING.md in the root of the source code directory.
//  *
//  ****************************************************************************/

import QtQuick

import QGroundControl
import QGroundControl.ScreenTools
import QtQuick.Layouts

//-------------------------------------------------------------------------
//-- Toolbar Indicators

// QGroundControl 中工具栏指示器（Toolbar Indicators）的实现，用于显示飞行器状态和系统信息。我来详细解析它的结构和功能

Row {
    id:                 indicatorRow
    anchors.top:        parent.top
    anchors.bottom:     parent.bottom
    anchors.margins:    _toolIndicatorMargins
    spacing:            ScreenTools.defaultFontPixelWidth * 1.75
     //layoutDirection: Qt.RightToLeft

    property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle //自动更新：当切换活动飞行器时，所有指示器自动刷新
    property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.66

    //响应式更新：如果 C++ 端的列表内容变化（如插件热加载），Repeater 会自动增删子项
    //只有当前需要显示的指示器才会被实际加载（通过 Loader 的延迟加载机制）。
    Repeater {
        //提供 core UI，比如 RTK
        id:     appRepeater
        model:  QGroundControl.corePlugin.toolBarIndicators //核心插件指示器
        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             modelData
            visible:            item.showIndicator//指示器状态，加载的指示器qml必须有这个属性
        }
    }

    Repeater {
        //提供与固件有关的状态指示器，例如 Battery、RC RSSI、Telemetry、GPS 等
        id:     toolIndicatorsRepeater
        model:  _activeVehicle ? _activeVehicle.toolIndicators : [] //飞行器工具指示器

        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             modelData
            visible:            item.showIndicator
        }
    }

    Repeater {
        //安全处理：通过 _activeVehicle ? ... : [] 避免空指针
        model: _activeVehicle ? _activeVehicle.modeIndicators : [] //飞行模式指示器
        Loader {
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            source:             modelData
            visible:            item.showIndicator
        }
    }
}
/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

// import QtQuick

// import QGroundControl
// import QGroundControl.ScreenTools

//-------------------------------------------------------------------------
//-- Toolbar Indicators
// Row {
//     id:                 indicatorRow
//     anchors.top:        parent.top
//     anchors.bottom:     parent.bottom
//     anchors.margins:    _toolIndicatorMargins
//     spacing:            ScreenTools.defaultFontPixelWidth * 1.75

//     property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
//     property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.66

//     Repeater {
//         id:     appRepeater
//         model:  QGroundControl.corePlugin.toolBarIndicators
//         Loader {
//             anchors.top:        parent.top
//             anchors.bottom:     parent.bottom
//             source:             modelData
//             visible:            item.showIndicator
//         }
//     }

//     Repeater {
//         id:     toolIndicatorsRepeater
//         model:  _activeVehicle ? _activeVehicle.toolIndicators : []

//         Loader {
//             anchors.top:        parent.top
//             anchors.bottom:     parent.bottom
//             source:             modelData
//             visible:            item.showIndicator
//         }
//     }

//     Repeater {
//         model: _activeVehicle ? _activeVehicle.modeIndicators : []
//         Loader {
//             anchors.top:        parent.top
//             anchors.bottom:     parent.bottom
//             source:             modelData
//             visible:            item.showIndicator
//         }
//     }
// }


// RowLayout {
//     id:                 indicatorRow
//     anchors.top:        parent.top
//     anchors.bottom:     parent.bottom
//     anchors.margins:    _toolIndicatorMargins
//     spacing:            ScreenTools.defaultFontPixelWidth * 1.75
//     layoutDirection:    Qt.RightToLeft

//     property var  _activeVehicle:           QGroundControl.multiVehicleManager.activeVehicle
//     property real _toolIndicatorMargins:    ScreenTools.defaultFontPixelHeight * 0.66

//     Repeater {
//         id:     appRepeater
//         model:  QGroundControl.corePlugin.toolBarIndicators
//         Loader {
//             Layout.alignment: Qt.AlignVCenter
//             source:             modelData
//             visible:            item.showIndicator
//         }
//     }

//     Repeater {
//         id:     toolIndicatorsRepeater
//         model:  _activeVehicle ? _activeVehicle.toolIndicators : []

//         Loader {
//             Layout.alignment: Qt.AlignVCenter
//             source:             modelData
//             visible:            item.showIndicator
//         }
//     }

//     Repeater {
//         model: _activeVehicle ? _activeVehicle.modeIndicators : []
//         Loader {
//             Layout.alignment: Qt.AlignVCenter
//             source:             modelData
//             visible:            item.showIndicator
//         }
//     }
// }
