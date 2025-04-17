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
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.AutoPilotPlugin
import MAVLink

//-------------------------------------------------------------------------
//-- Battery Indicator
// 实时显示电池状态：电压、百分比或两者同时显示
// 支持多电池：通过 Repeater 动态生成每个电池的视觉指示
// 交互功能：点击弹出详细电池信息面板
// 阈值警告：根据用户设置的阈值（threshold1/threshold2）改变颜色提示
Item {
    id:             control
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          batteryIndicatorRow.width

    property bool       showIndicator:      true//是否显示电池指示器（可通过配置关闭）
    property bool       waitForParameters:  false   // 是否等待飞控参数加载完成后再显示 UI
    property Component  expandedPageComponent

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle//当前活动的无人机对象（通过 multiVehicleManager 获取）
    property var    _batterySettings:   QGroundControl.settingsManager.batteryIndicatorSettings//电池显示相关的用户设置（如显示模式、警告阈值）
    property Fact   _indicatorDisplay:  _batterySettings.valueDisplay//_indicatorDisplay 决定显示内容
    property bool   _showPercentage:    _indicatorDisplay.rawValue === 0  //是否显示百分比（根据 valueDisplay 设置）
    property bool   _showVoltage:       _indicatorDisplay.rawValue === 1 // 1=电压
    property bool   _showBoth:          _indicatorDisplay.rawValue === 2  // 2=电压+百分比

    // Properties to hold the thresholds用户配置的电量警告阈值（用于触发颜色变化）
    //当电池电量低于 threshold2 时显示红色警告，低于 threshold1 显示黄色警告。
    property int threshold1: _batterySettings.threshold1.rawValue
    property int threshold2: _batterySettings.threshold2.rawValue   

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Repeater {
            model: control._activeVehicle ? control._activeVehicle.batteries : 0 //飞控报告的电池列表（如双电系统的电池1/电池2）

            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                sourceComponent:    batteryVisual   //每个电池的视觉组件

                property var battery: object
            }
        }
    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorDrawer(batteryPopup, control) //弹出的电池详情面板（定义为 ToolIndicatorPage），showIndicatorDrawer主窗口的抽屉式面板显示方法
        }
    }

    Component {
        id: batteryPopup

        ToolIndicatorPage {
            showExpand:         expandedComponent ? true : false  // 显示展开按钮
            waitForParameters:  control.waitForParameters
            contentComponent:   batteryContentComponent   // 主要内容
            expandedComponent:  batteryExpandedComponent  // 展开后的内容
        }
    }

    
    //通过颜色、图标和文本动态反映电池的健康状态
    Component {
        id: batteryVisual

        Row {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            //明确区分五种电池状态
            
            //动态颜色逻辑
            function getBatteryColor() {
                switch (battery.chargeState.rawValue) {
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                        if (!isNaN(battery.percentRemaining.rawValue)) {
                            if (battery.percentRemaining.rawValue > threshold1) {
                                return qgcPal.colorGreen // >阈值1：绿色
                            } else if (battery.percentRemaining.rawValue > threshold2) {
                                return qgcPal.colorYellowGreen // 阈值1~2：黄绿
                            } else {
                                return qgcPal.colorYellow // <阈值2：黄色
                            }
                        } else {
                            return qgcPal.text
                        }
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                        return qgcPal.colorOrange // 低电量：橙色
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                        return qgcPal.colorRed  // 紧急状态：红色
                    default:
                        return qgcPal.text  // 默认文本色
                }
            }    

            //动态图标选择
            // 每种状态有专属 SVG 图标（如紧急状态显示感叹号）
            // 图标颜色与 getBatteryColor() 同步变化
            function getBatterySvgSource() {
                switch (battery.chargeState.rawValue) {
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                        if (!isNaN(battery.percentRemaining.rawValue)) {
                            if (battery.percentRemaining.rawValue > threshold1) {
                                return "/qmlimages/BatteryGreen.svg"
                            } else if (battery.percentRemaining.rawValue > threshold2) {
                                return "/qmlimages/BatteryYellowGreen.svg"
                            } else {
                                return "/qmlimages/BatteryYellow.svg"    
                            } 
                        }
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                        return "/qmlimages/BatteryOrange.svg" // Low with orange svg
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                        return "/qmlimages/BatteryCritical.svg" // Critical with red svg
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                    case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                        return "/qmlimages/BatteryEMERGENCY.svg" // Exclamation mark
                    default:
                        return "/qmlimages/Battery.svg" // Fallback if percentage is unavailable
                }
            }

            // 文本生成函数
            function getBatteryPercentageText() {
                if (!isNaN(battery.percentRemaining.rawValue)) {
                    if (battery.percentRemaining.rawValue > 98.9)//电量 >98.9% 显示 "100%"（避免 99.99% 等不直观数值）
                    {
                        return qsTr("100%")
                    } else {
                        return battery.percentRemaining.valueString + battery.percentRemaining.units //无百分比数据时回退到电压或状态文本
                    }
                } else if (!isNaN(battery.voltage.rawValue)) {
                    return battery.voltage.valueString + battery.voltage.units
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return qsTr("n/a")
            }
            //电压值带单位（如 "24.3V"
            function getBatteryVoltageText() {
                if (!isNaN(battery.voltage.rawValue)) {
                    return battery.voltage.valueString + battery.voltage.units
                } else if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return qsTr("n/a") //无数据时显示状态或 "n/a"
            }
           //QGCColoredImage 组件
            QGCColoredImage {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              height
                sourceSize.width:   width  // 按需缩放
                source:             getBatterySvgSource()  //// 绑定图标路径  
                fillMode:           Image.PreserveAspectFit // // 保持图标比例
                color:              getBatteryColor() // 绑定颜色
            }

            //智能显示控制：
           ColumnLayout {
                id:                     batteryInfoColumn
                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                spacing:                0

                QGCLabel {
                    Layout.alignment:       Qt.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                    color:                  qgcPal.text
                    text:                   getBatteryPercentageText()
                    font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize// 根据用户设置显示/隐藏
                    visible:                _showBoth || _showPercentage
                }

                QGCLabel {
                    Layout.alignment:       Qt.AlignHCenter
                    font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize
                    color:                  qgcPal.text
                    text:                   getBatteryVoltageText()
                    visible:                _showBoth || _showVoltage
                }
            }
        }
    }
    // 电池详细信息面板 的 QML 实现，用于展示单个或多个电池的全面状态数据
    //根据数据可用性自动隐藏无效项
    //分组显示电压、温度、消耗量等关键参数
    //所有文本使用 qsTr() 封装以便翻译
    //数据驱动的动态UI生成
    Component {
        id: batteryContentComponent

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            //// 检测组件定义
            Component {
                id: batteryValuesAvailableComponent

                //使用 !isNaN() 判断数值是否有效
                //对枚举类型检查是否等于 UNDEFINED 值
                QtObject {
                    property bool functionAvailable:         battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
                    property bool showFunction:              functionAvailable && battery.function.rawValue != MAVLink.MAV_BATTERY_FUNCTION_ALL
                    property bool temperatureAvailable:      !isNaN(battery.temperature.rawValue)
                    property bool currentAvailable:          !isNaN(battery.current.rawValue)
                    property bool mahConsumedAvailable:      !isNaN(battery.mahConsumed.rawValue)
                    property bool timeRemainingAvailable:    !isNaN(battery.timeRemaining.rawValue)
                    property bool percentRemainingAvailable: !isNaN(battery.percentRemaining.rawValue)
                    property bool chargeStateAvailable:      battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
                }
            }
      //Repeater据 model 中的数据数量，动态实例化其内部的 SettingsGroupLayout 模板。若 batteries 包含 2 个电池，则生成 2 个独立的 SettingsGroupLayout
            Repeater {
                model: _activeVehicle ? _activeVehicle.batteries : 0//数据驱动源，这里绑定到当前活动飞行器的电池列表 _activeVehicle.batteries，空模型安全处理
                //如果无活动飞行器（_activeVehicle 为 null），则设置为 0 表示不生成任何项

                
                
                SettingsGroupLayout {
                    heading:        qsTr("Battery %1").arg(_activeVehicle.batteries.length === 1 ? qsTr("Status") : object.id.rawValue)//单电池时显示 "Battery Status"，多电池时显示 "Battery 1"、"Battery 2"
                    contentSpacing: 0 //保持简洁，紧凑布局
                    showDividers:   false

                    property var batteryValuesAvailable: batteryValuesAvailableLoader.item//结果存储在 batteryValuesAvailableLoader.item 中供后续使用
                    //通过 Loader 动态加载检测逻辑
                    Loader {// 加载检测组件
                        id: batteryValuesAvailableLoader
                        sourceComponent:    batteryValuesAvailableComponent
                        property var battery: object//// 传递当前电池对象
                    }
                    
                    //对称布局，左侧标签 + 右侧数值
                    
                    LabelledLabel {
                        label:  qsTr("Charge State")
                        labelText:  object.chargeState.enumStringValue
                        visible:    batteryValuesAvailable.chargeStateAvailable//动态可见性，仅当数据有效时显示
                    }
                    
                    LabelledLabel {
                        label:      qsTr("Remaining") //剩余电量
                        labelText:  object.timeRemainingStr.value
                        visible:    batteryValuesAvailable.timeRemainingAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Remaining")
                        labelText:  object.percentRemaining.valueString + " " + object.percentRemaining.units//单位自动附加双引号，如 "24.3 V"   
                        visible:    batteryValuesAvailable.percentRemainingAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Voltage")//电压
                        labelText:  object.voltage.valueString + " " + object.voltage.units
                    }

                    LabelledLabel {
                        label:      qsTr("Consumed") //消耗
                        labelText:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                        visible:    batteryValuesAvailable.mahConsumedAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Temperature")//温度
                        labelText:  object.temperature.valueString + " " + object.temperature.units
                        visible:    batteryValuesAvailable.temperatureAvailable
                    }

                    LabelledLabel {
                        label:      qsTr("Function")
                        labelText:  object.function.enumStringValue
                        visible:    batteryValuesAvailable.showFunction
                    }
                }
            }
        }
    }

                        
     //电池设置扩展面板 的 QML 实现，主要用于配置电池显示参数和警告阈值
     // 显示模式配置：选择显示百分比、电压或两者
     // 阈值颜色管理：设置电量警告阈值（threshold1/threshold2）
     // 状态颜色预览：直观展示不同电量状态对应的颜色/图标
     // 高级电源配置：跳转到车辆电源管理界面（需高级权限）
    Component {
        id: batteryExpandedComponent

        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight / 2

            FactPanelController { id: controller }

            
            SettingsGroupLayout {
                heading:            qsTr("Battery Display")
                Layout.fillWidth:   true
            //显示模式选择
             LabelledFactComboBox {
                    id:             editModeCheckBox
                    label:          qsTr("Value") //根据 Fact 的元数据生成下拉选项（0=百分比, 1=电压, 2=两者）
                    fact:           _fact  //直接关联到设置管理器的 valueDisplay 属性，fact
                    visible:        _fact,visible

                    property Fact _fact: QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay
                }

                ColumnLayout {
                    QGCLabel { text: qsTr("Coloring") }

                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Reduced spacing between elements

                        // Battery 100%
                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                            QGCColoredImage {
                                source: "/qmlimages/BatteryGreen.svg"
                                width: ScreenTools.defaultFontPixelWidth * 6
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorGreen
                            }
                            QGCLabel { text: qsTr("100%") }
                        }

                        // Threshold 1
                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field
                            QGCColoredImage {
                                source: "/qmlimages/BatteryYellowGreen.svg"
                                width: ScreenTools.defaultFontPixelWidth * 6
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorYellowGreen
                            }
                            
                            //阈值配置 
                            
                            FactTextField {
                                id: threshold1Field
                                fact: _batterySettings.threshold1//输入验证：自动限制为整数输入
                                implicitWidth: ScreenTools.defaultFontPixelWidth * 6 // 输入框固定宽度
                                height: ScreenTools.defaultFontPixelHeight * 1.5
                                enabled: fact.visible
                                onEditingFinished: {
                                    // Validate and set the new threshold value
                                    _batterySettings.setThreshold1(parseInt(text));//即时生效：编辑完成后立即更新设置
                                }
                            }
                        }

                        // Threshold 2
                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field根据屏幕 DPI 自动调整，确保在不同设备上显示一致，// 极小的元素间距
                            QGCColoredImage {
                                source: "/qmlimages/BatteryYellow.svg"
                                width: ScreenTools.defaultFontPixelWidth * 6
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorYellow
                            }
                            FactTextField {
                                fact: _batterySettings.threshold2
                                implicitWidth: ScreenTools.defaultFontPixelWidth * 6
                                height: ScreenTools.defaultFontPixelHeight * 1.5
                                enabled: fact.visible
                                onEditingFinished: {
                                    // Validate and set the new threshold value
                                    _batterySettings.setThreshold2(parseInt(text));                                
                                }
                            }
                        }
                        //使用标准化的 SVG 电池图标，
                        //所有尺寸基于 ScreenTools 计算
                        // Low state
                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                            QGCColoredImage {
                                source: "/qmlimages/BatteryOrange.svg"
                                width: ScreenTools.defaultFontPixelWidth * 6
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorOrange //从 qgcPalette 获取一致的主题色
                            }
                            QGCLabel { text: qsTr("Low") }
                        }

                        // Critical state明确的状态描述
                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
                            QGCColoredImage {
                                source: "/qmlimages/BatteryCritical.svg"
                                width: ScreenTools.defaultFontPixelWidth * 6
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorRed
                            }
                            QGCLabel { text: qsTr("Critical") }
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true//// 填充可用宽度
                sourceComponent: expandedPageComponent
            }

            SettingsGroupLayout {
                visible: _activeVehicle.autopilotPlugin.knownVehicleComponentAvailable(AutoPilotPlugin.KnownPowerVehicleComponent) &&
                            QGroundControl.corePlugin.showAdvancedUI//仅当同时满足时显示，普通用户无法访问高级电源配置

                
                // 高级功能入口
                LabelledButton {
                    label:      qsTr("Vehicle Power")
                    buttonText: qsTr("Configure")

                    onClicked: {
                        mainWindow.showKnownVehicleComponentConfigPage(AutoPilotPlugin.KnownPowerVehicleComponent)
                        mainWindow.closeIndicatorDrawer()
                    }
                }                
            }
        }
    }
}
