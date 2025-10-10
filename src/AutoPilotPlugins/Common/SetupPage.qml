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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Controllers

/// Base view control for all Setup pages
//这是一个设置页面基础框架，所有具体的设置页面（如电池设置、GPS设置等）都基于这个框架构建
Item {
    id:             setupView
    enabled:        !_disableDueToArmed && !_disableDueToFlying//启用/禁用逻辑，车辆已上电(armed)时禁用某些设置页面，防止在危险状态下修改关键设置

    property alias  pageComponent:          pageLoader.sourceComponent  // 实际的内容组件
    property string pageName:               vehicleComponent ? vehicleComponent.name : ""// 页面名称
    property string pageDescription:        vehicleComponent ? vehicleComponent.description : "" // 页面描述
    property real   availableWidth:         width - pageLoader.x// 可用宽度
    property real   availableHeight:        height - pageLoader.y// 可用高度
    property bool   showAdvanced:           false
    property alias  advanced:               advancedCheckBox.checked

    property bool   _vehicleIsRover:        globals.activeVehicle ? globals.activeVehicle.rover : false
    property bool   _vehicleArmed:          globals.activeVehicle ? globals.activeVehicle.armed : false
    property bool   _vehicleFlying:         globals.activeVehicle ? globals.activeVehicle.flying : false
    property bool   _disableDueToArmed:     vehicleComponent ? (!vehicleComponent.allowSetupWhileArmed && _vehicleArmed) : false
    // FIXME: The _vehicleIsRover checkl is a hack to work around https://github.com/PX4/Firmware/issues/10969
    property bool   _disableDueToFlying:    vehicleComponent ? (!_vehicleIsRover && !vehicleComponent.allowSetupWhileFlying && _vehicleFlying) : false
    property string _disableReason:         _disableDueToArmed ? qsTr("armed") : qsTr("flying")
    property real   _margins:               ScreenTools.defaultFontPixelHeight * 0.5
    property string _pageTitle:             qsTr("%1 Config").arg(pageName)

    //完成回调
    //页面加载完成后调用子组件的初始化方法
    Component.onCompleted: {
        if(pageLoader.item && pageLoader.item.setupPageCompleted) {
            pageLoader.item.setupPageCompleted()
        }
    }

    QGCFlickable {
        anchors.fill:   parent
        contentWidth:   Math.max(availableWidth, pageLoader.x + pageLoader.item.width)
        contentHeight:  Math.max(availableHeight, pageLoader.y + pageLoader.item.height)
        clip:           true

        //标题区域
        RowLayout {
            id:                 headingRow
            width:              availableWidth
            spacing:            _margins
            layoutDirection:    Qt.RightToLeft
            visible:            showAdvanced || (pageDescription !== "" && !ScreenTools.isShortScreen)

            //高级模式切换，显示/隐藏高级设置选项
            //通过showAdvanced属性控制是否显示复选框
            QGCCheckBox {
                id:         advancedCheckBox
                text:       qsTr("Advanced")
                visible:    showAdvanced
            }

            ColumnLayout {
                spacing:            _margins
                Layout.fillWidth:   true

                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.largeFontPointSize
                    text:               !setupView.enabled ? _pageTitle + "<font color=\"red\">" + qsTr(" (Disabled while the vehicle is %1)").arg(_disableReason) + "</font>" : _pageTitle
                    visible:            !ScreenTools.isShortScreen
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    wrapMode:           Text.WordWrap
                    text:               pageDescription
                    visible:            pageDescription !== "" && !ScreenTools.isShortScreen
                }
            }
        }

        //内容加载器
        //动态加载具体的设置页面内容
        //通过pageComponent属性设置要加载的组件
        Loader {
            id:                 pageLoader
            // height:parent.height
            width:parent.width
            anchors.topMargin:  _margins
            anchors.top:        headingRow.bottom
        }

        // Overlay to display when vehicle is armed and this setup page needs
        // to be disabled
        //禁用覆盖层
        //当页面被禁用时显示半透明黑色覆盖层，视觉上提示用户当前不可操作
        Rectangle {
            visible:            !setupView.enabled
            anchors.fill:       parent
            color:              "black"
            opacity:            0.5
        }
    }
}
