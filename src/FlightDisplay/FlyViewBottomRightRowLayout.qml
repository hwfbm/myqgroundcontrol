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

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

//底部展示遥测数据条（TelemetryValuesBar）和仪表面板（FlyViewInstrumentPanel）
//数据条内容可自定义
RowLayout {
    // TelemetryValuesBar {
    //     Layout.alignment:   Qt.AlignBottom
    //     extraWidth:         instrumentPanel.extraValuesWidth
    // }
//仪表面板
    FlyViewInstrumentPanel {
        id:         instrumentPanel
        visible:    QGroundControl.corePlugin.options.flyView.showInstrumentPanel && _showSingleVehicleUI
    }
}
