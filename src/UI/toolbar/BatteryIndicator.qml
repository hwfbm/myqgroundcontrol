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

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle//当前活动的无人机对象，返回当前激活的无人机（通过 multiVehicleManager 获取）
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
        //动态显示多个电池的状态（如双电池系统）
        //使用 Repeater 根据飞控报告的电池数量生成对应的可视化组件
        //object 是 Repeater 为每个迭代项自动提供的模型数据：若 model 是数组（如 _activeVehicle.batteries），object 是当前遍历的数组元素（电池对象）。若 model 是整数（如 model: 5），object 是 undefined（此时通常用 index）
        Repeater {
            model: control._activeVehicle ? control._activeVehicle.batteries : 0 //绑定到当前活动飞行器（_activeVehicle）的电池列表，若无则返回 0（不生成任何项），飞控报告的电池列表（如双电系统的电池1/电池2）

            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                sourceComponent:    batteryVisual   //动态加载每个电池的视觉组件

                property var battery: object //将 Repeater 迭代的电池对象（object）传递给子组件
            }
        }
    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            //点击电池区域时，调用主窗口的 showIndicatorDrawer 方法，弹出详情面板
            mainWindow.showIndicatorDrawer(batteryPopup, control) //弹出的电池详情面板（定义为 ToolIndicatorPage），showIndicatorDrawer主窗口的抽屉式面板显示方法
        }
    }

    Component {
        id: batteryPopup

        ToolIndicatorPage {
            showExpand:         expandedComponent ? true : false  // 根据是否存在扩展内容（expandedComponent）决定是否显示展开按钮，显示展开按钮
            waitForParameters:  control.waitForParameters //绑定到外部控制器的参数等待状态（可能用于加载动画）
            contentComponent:   batteryContentComponent   // 面板主内容（如电池概要信息）
            expandedComponent:  batteryExpandedComponent  // 展开后的详细内容（如电池历史曲线）
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

            //智能显示控制：ColumnLayout：一个布局容器，用于垂直排列子元素。
           ColumnLayout {
                id:                     batteryInfoColumn
                anchors.top:            parent.top
                anchors.bottom:         parent.bottom
                spacing:                0

                //通过 _showBoth、_showPercentage 和 _showVoltage 的值动态控制显示内容
                //显示电池百分比
                QGCLabel {
                    Layout.alignment:       Qt.AlignHCenter
                    verticalAlignment:      Text.AlignVCenter
                    color:                  qgcPal.text
                    text:                   getBatteryPercentageText()
                    font.pointSize:         _showBoth ? ScreenTools.defaultFontPointSize : ScreenTools.mediumFontPointSize// 根据用户设置显示/隐藏
                    visible:                _showBoth || _showPercentage
                }
               //显示电池电压
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
                //QtObject：轻量级非可视化对象，仅用于封装属性逻辑
                //集中管理电池数据的有效性状态，供其他组件（如 UI）查询
                //所有属性均绑定到 battery 对象的原始值（rawValue），当 battery 数据更新时，这些属性自动重新计算
                QtObject {
                    property bool functionAvailable:         battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN //判断电池功能是否已知
                    property bool showFunction:              functionAvailable && battery.function.rawValue != MAVLink.MAV_BATTERY_FUNCTION_ALL //判断是否显示电池功能
                    //isNaN()：JavaScript 函数，若值非数字返回 true
                    property bool temperatureAvailable:      !isNaN(battery.temperature.rawValue) //判断电池温度数据是否有效
                    property bool currentAvailable:          !isNaN(battery.current.rawValue) //判断电池电流数据是否有效
                    property bool mahConsumedAvailable:      !isNaN(battery.mahConsumed.rawValue)//判断电池剩余时间数据是否有效
                    property bool timeRemainingAvailable:    !isNaN(battery.timeRemaining.rawValue)//判断电池剩余时间数据是否有效
                    property bool percentRemainingAvailable: !isNaN(battery.percentRemaining.rawValue) //判断电池剩余百分比数据是否有效
                    property bool chargeStateAvailable:      battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED //判断电池充电状态是否已定义
                }
            }
      //Repeater据 model 中的数据数量，动态实例化其内部的 SettingsGroupLayout 模板。若 batteries 包含 2 个电池，则生成 2 个独立的 SettingsGroupLayout
    //当你使用 Repeater + model（比如是一个数组）时，每次迭代会自动提供当前项作为上下文变量 modelData
            //而在 QML 里，modelData 会自动作为每个迭代子项的默认 object 属性注入进去，如果你没有显示声明 object，它也会变成隐式属性，子项可以直接用
            Repeater {
                model: _activeVehicle ? _activeVehicle.batteries : 0//数据驱动源，这里绑定到当前活动飞行器的电池列表 _activeVehicle.batteries，空模型安全处理
                //每次 Repeater 迭代时，modelData 是当前的 battery 对象
                //如果无活动飞行器（_activeVehicle 为 null），则设置为 0 表示不生成任何项

                //在 Repeater 中，每次迭代会隐式注入 modelData 给子组件，并把它设为默认的 object 属性 —— 所以你在 SettingsGroupLayout 和 LabelledLabel 中使用 object.xxx 是成立的，它等于当前 battery
                
                
                SettingsGroupLayout {
                    heading:        qsTr("氢电池 %1").arg(_activeVehicle.batteries.length === 1 ? qsTr("Status") : object.id.rawValue)//单电池时显示 "Battery Status"，多电池时显示 "Battery 1"、"Battery 2"
                    headingDescription: "以下数据来自自定义 HYDROGEN_BATTERY 消息"
                    contentSpacing: 0 //保持简洁，紧凑布局
                    showDividers:   false

                    property var batteryValuesAvailable: batteryValuesAvailableLoader.item//结果存储在 batteryValuesAvailableLoader.item 中供后续使用
                    //通过 Loader 动态加载检测逻辑
                    Loader {// 加载检测组件
                        id: batteryValuesAvailableLoader
                        sourceComponent:    batteryValuesAvailableComponent
                        property var battery: object//// 传递当前电池对象
                    }
                    Component.onCompleted: {
                        console.log("当前 object 是：", object)  // 打印出电池对象
                    }

                    //Repeater 适用于静态/预处理好的数据模型，不适合用于绑定具体对象字段
                    GridLayout {
                            columns: 4
                            rowSpacing: 10
                            columnSpacing: 20
                            Layout.fillWidth: true

                            //对称布局，左侧标签 + 右侧数值

                            LabelledLabel {
                                label:  qsTr("电池电压")
                                labelText:  object.bat_voltage.valueString + " " + object.bat_voltage.units
                                visible:true
                                //visible:    batteryValuesAvailable.chargeStateAvailable//动态可见性，仅当数据有效时显示
                            }

                            LabelledLabel {
                                label:      qsTr("电机电流")
                                labelText:  object.servo_current.object.valueString + " " + object.servo_current.units
                                visible:    true
                            }

                            LabelledLabel {
                                label:      qsTr("电堆电压")
                                labelText:  object.stack_voltage.valueString + " " + object.stack_voltage.units//单位自动附加双引号，如 "24.3 V"
                                visible:    true
                            }

                            LabelledLabel {
                                label:      qsTr("电机电压")
                                labelText:  object.servo_voltage.valueString + " " + object.servo_voltage.units
                            }

                            LabelledLabel {
                                label:      qsTr("电池补能电流")
                                labelText:  object.bat_refuel_current.valueString + " " + object.bat_refuel_current.units
                                visible:    true
                            }

                            LabelledLabel {
                                label:      qsTr("气罐压力")
                                labelText:  object.gas_tank_pressure.valueString + " " + object.gas_tank_pressure.units
                                visible:    true
                            }

                            // LabelledLabel {
                            //     label:      qsTr("Function")
                            //     labelText:  object.function.enumStringValue
                            //     visible:    batteryValuesAvailable.showFunction
                            // }
                            LabelledLabel {
                                label:      qsTr("管道压力")
                                labelText:  object.pipe_pressure.valueString + " " + object.pipe_pressure.units
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("主板温度")
                                labelText:  object.pcb_temp.valueString + " " + object.pcb_temp.units
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("电堆温度")
                                labelText:  object.stack_temp.valueString + " " + object.stack_temp.units
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("设备状态")
                                labelText:  object.work_status.valueString
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("报警状态")
                                labelText:  object.falt_status.valueString
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("自检状态")
                                labelText: object.self_check.enumStringValue
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("id")
                                labelText:  object.hydroId.enumStringValue
                                visible:    true
                            }

                            LabelledLabel {
                                    label:      qsTr("自定义")
                                    labelText:  qsTr("这是我加的自定义文字")
                                    visible:    true
                                }
                            // Repeater {
                            //     model: [
                            //         { label: "氢堆温度1", value: "35°C" },
                            //         { label: "气罐压力", value: "12 MPa" },
                            //         { label: "输出电压", value: "48 V" },
                            //         { label: "设备状态", value: "正常" },
                            //         { label: "氢堆温度2", value: "34°C" },
                            //         { label: "板载温度", value: "38°C" },
                            //         { label: "锂电电压", value: "15 V" },
                            //         { label: "充电状态", value: "充电中" },
                            //         { label: "氢电电流", value: "5 A" },
                            //         { label: "锂电电流", value: "3 A" },
                            //         { label: "氢电电压", value: "49 V" },
                            //         { label: "放电状态", value: "正常" }
                            //     ]

                            //     //modelData 是 QML 中 Repeater、ListView、GridView 等组件中的一个固定属性，它用于在 delegate 中访问当前数据项的数据
                            //     // //delegate 是一个组件模板，它会被实例化多次，每次对应数据模型中的一个数据项


                            //     // delegate: Column {
                            //     //     spacing: 2
                            //     //     QGCLabel {
                            //     //         text: modelData.value
                            //     //         font.pixelSize: ScreenTools.defaultFontPixelHeight * 1.2
                            //     //         color: "white"
                            //     //         horizontalAlignment: Text.AlignHCenter
                            //     //         Layout.alignment: Qt.AlignHCenter
                            //     //     }
                            //     //     QGCLabel {
                            //     //         text: modelData.label
                            //     //         font.pixelSize: ScreenTools.defaultFontPixelHeight
                            //     //         color: "lightgray"
                            //     //         horizontalAlignment: Text.AlignHCenter
                            //     //         Layout.alignment: Qt.AlignHCenter
                            //     //     }
                            //     // }
                            //     delegate:LabelledLabel{
                            //         label: modelData.label
                            //         labelText: modelData.value
                            //         visible: modelData.visible
                            //     }
                            // }
                        }
                    }
            }
        }
    }

                        
    //Component定义了一个 QML 组件，可以被动态加载和使用，使用 Component 封装，是为了延迟加载（通常配合 Loader 使用）
     //电池设置扩展面板 的 QML 实现，主要用于配置电池显示参数和警告阈值
     // 显示模式配置：选择显示百分比、电压或两者
     // 阈值颜色管理：设置电量警告阈值（threshold1/threshold2）
     // 状态颜色预览：直观展示不同电量状态对应的颜色/图标
     // 高级电源配置：跳转到车辆电源管理界面（需高级权限）
    Component {
        id: batteryExpandedComponent
      //ColumnLayout：一个垂直布局容器，用于排列子元素
        ColumnLayout {
            //spacing 设置了控件之间的垂直间距，使用屏幕字体高度作为参考，确保在不同分辨率下自适应
            spacing: ScreenTools.defaultFontPixelHeight / 2


            //FactPanelController：一个控制器，可能用于管理与电池相关的事实（Fact
            //控制器类，用于管理 QGC 中的 Fact（参数绑定对象），帮助 UI 控件获取或修改设置项的值
            FactPanelController { id: controller }

            
            //SettingsGroupLayout：一个布局，用于分组显示设置
            SettingsGroupLayout {
                //设置组的标题为 "Battery Display"
                heading:            qsTr("Battery Display")
                Layout.fillWidth:   true
            //显示模式选择，LabelledFactComboBox：自定义的一个带标签的下拉选择框，用于选择电池的显示模式（如百分比、电压等）
             LabelledFactComboBox {
                    id:             editModeCheckBox
                    label:          qsTr("Value") //根据 Fact 的元数据生成下拉选项（0=百分比, 1=电压, 2=两者）。显示的标签文本为 "Value"
                    fact:           _fact  //直接关联到设置管理器的 valueDisplay 属性，fact,_fact用来缓存从 settingsManager 获取的设置

                    //绑定到 QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay，这可能是一个枚举值，用于选择显示模式（如百分比、电压或两者）
                    visible:        _fact.visible
                    property Fact _fact: QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay
                }

                ColumnLayout {
                    QGCLabel { text: qsTr("Coloring") }

                    RowLayout {
                        spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Reduced spacing between elements

                        // Battery 100%
                        //每个子 RowLayout 代表一个电池状态颜色和数值配置
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

                        // Threshold 1，图标是黄绿色，带一个 FactTextField 输入框
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

                        // Threshold 2，图标是黄色
                        RowLayout {
                            spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field根据屏幕 DPI 自动调整，确保在不同设备上显示一致，// 极小的元素间距
                            QGCColoredImage {
                                source: "/qmlimages/BatteryYellow.svg"
                                width: ScreenTools.defaultFontPixelWidth * 6
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorYellow
                            }
                            //设置阈值较低的报警条件
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
                        // Low state， Low 状态（橙色图标🟠，纯展示，无法设置）
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

                        // Critical state，🔴 Critical 状态（红色图标，纯展示，无法设置）
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


            //用于动态加载其他页面，避免一次加载所有界面，提升性能
            Loader {
                Layout.fillWidth: true//// 填充可用宽度
                sourceComponent: expandedPageComponent //延迟加载的 QML 组件（比如更详细的电池页面），通过 expandedPageComponent 提供（看起来好像还没提供实现）
            }

            SettingsGroupLayout {
                visible: _activeVehicle.autopilotPlugin.knownVehicleComponentAvailable(AutoPilotPlugin.KnownPowerVehicleComponent) &&
                            QGroundControl.corePlugin.showAdvancedUI//仅当同时满足时显示，普通用户无法访问高级电源配置

                
                // 高级功能入口
                //这个区域只有在两个条件满足时才显示
                     //当前载具的自动驾驶插件支持“电源配置”组件。
                     //启用了高级用户界面（非普通用户）。
                //按钮点击后会打开电源配置页面，同时关闭侧边栏抽屉
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

