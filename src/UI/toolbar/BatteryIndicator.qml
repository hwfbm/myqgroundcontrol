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

Item {
    id: control
    height: parent.height   // 只跟 Toolbar 高度对齐，不拉伸上下
    anchors.verticalCenter: parent.verticalCenter
    width:batteryRow.width
    property bool       showIndicator:      true//是否显示电池指示器（可通过配置关闭）
    property bool       waitForParameters:  false   // 是否等待飞控参数加载完成后再显示 UI
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle//当前活动的无人机对象，返回当前激活的无人机（通过 multiVehicleManager 获取），vehicle类

    //电池设置参数
    //property Fact   _indicatorDisplay:  _batterySettings.valueDisplay//_indicatorDisplay 决定显示内容
    property var _batterySettings: QGroundControl.settingsManager.batteryIndicatorSettings
    property int threshold1: _batterySettings.threshold1.rawValue
    property int threshold2: _batterySettings.threshold2.rawValue

    property Component  expandedPageComponent //展开面板，放设置
    QtObject {
        id: batteryUtils

        // 计算总电压，单位 V
        function totalVoltage(vehicle) {
            if (!vehicle) return 0;
            let total = 0;

            // 遍历锂电池
            if (vehicle.batteries) {
                for (let i = 0; i < vehicle.batteries.count; i++) {
                    let b = vehicle.batteries.get(i)
                    if (b && b.voltage && !isNaN(b.voltage.rawValue)) {
                        total += b.voltage.rawValue / 1000;
                    }
                }
            }

            // 遍历氢电池
            if (vehicle.hydrogenBatteries) {
                for (let i = 0; i < vehicle.hydrogenBatteries.count; i++) {
                    let b = vehicle.hydrogenBatteries.get(i)
                    if (b && b.voltage && !isNaN(b.voltage.rawValue)) {
                        total += b.voltage.rawValue / 1000;
                    }
                }
            }

            return total;
        }

        // 计算平均 SOC
        function averageSOC(vehicle) {
            if (!vehicle) return "0";//如果车辆对象不存在，直接返回字符串"0"
            let socTotal = 0;//用于累加所有电池的SOC值
            let count = 0;//统计有效电池的数量

            if (vehicle.batteries) {
                for (let i = 0; i < vehicle.batteries.count; i++) //遍历所有电池（通过vehicle.batteries.count获取数量）
                {
                    let b = vehicle.batteries.get(i)//vehicle.batteries.get(i)获取单个电池对象
                    //若电池对象存在 (b)，有percentRemaining属性且percentRemaining.rawValue是有效数字 (!isNaN)
                    if (b && b.percentRemaining && !isNaN(b.percentRemaining.rawValue))
                    {
                        socTotal += b.percentRemaining.rawValue;//如果有效，多个电池对象累加SOC值并计数
                        count++;
                    }
                }
            }

            if (vehicle.hydrogenBatteries) {
                for (let i = 0; i < vehicle.hydrogenBatteries.count; i++) {
                    let b = vehicle.hydrogenBatteries.get(i)
                    if (b && b.percentRemaining && !isNaN(b.percentRemaining.rawValue)) {
                        socTotal += b.percentRemaining.rawValue;
                        count++;
                    }
                }
            }


            //三元条件运算：条件：count > 0（是否有有效电池）
            //真值：计算平均值并取整 (socTotal / count).toFixed(0)
            //假值：返回"n/a"（Not Available）
            return count > 0 ? (socTotal / count).toFixed(0) : "n/a";
        }
    }


    Row {
        id: batteryRow
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter


       // Repeater {
            //合并锂电 + 氢电
            //如果没有 _activeVehicle，model 就是空数组，如果 batteries 是 null/undefined，就用 []
            //.concat(_activeVehicle.hydrogenBatteries || []) → 拼接氢电池数组
            //只要有 vehicle，就会把「锂电数组 + 氢电数组」合并，交给 Repeater
            // model: (_activeVehicle ? (_activeVehicle.batteries || []).concat(_activeVehicle.hydrogenBatteries || []) : [])

            // Loader {
            //     sourceComponent: batteryIcon
            //     property var batteryItem: object
            // }
        //}



        // Repeater {
        //         model: _activeVehicle ? _activeVehicle.batteries : 0
                Loader {
                    sourceComponent: batteryVisual
                   // property var batteryLithium: modelData  // QML Object
                    //onLoaded: console.log("Lithium:", batteryLithium.voltage.rawValue)
                }
            //}

            // Repeater {
            //     model: _activeVehicle ? _activeVehicle.hydrogenBatteries : 0
            //     Loader {
            //         sourceComponent: batteryVisual
            //         property var batteryHydro+gen: modelData // QML Object
            //         onLoaded: console.log("Hydrogen:", batteryHydrogen.voltage.rawValue)
            //     }
            // }


        // 总览显示总电压/平均电量

    }

    MouseArea {
        anchors.fill: parent
        onClicked: mainWindow.showIndicatorDrawer(batteryPopup, control)
    }

    // 单块电池图标组件
    Component {
        id: batteryVisual
        Row {
            spacing:  ScreenTools.defaultFontPixelWidth*0.5
           // anchors.right: divider2.left
            anchors.verticalCenter: parent.verticalCenter   // 垂直居中
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth*2

            //总电压
            // Text {
            //     text: qsTr("Total V: %1").arg(batteryUtils.totalVoltage(control._activeVehicle).toFixed(2))
            // color:"white"
            // font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.8
            // verticalAlignment: Label.AlignVCenter
            // }


            //电池动画与展示
            property real displayedPercent: 0

            // 平滑动画
            Behavior on displayedPercent {
                NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
            }

            Item {
                id: batteryicon

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: height * 0.8  // 竖版电池的宽高比

                // 电池主体
                Rectangle {
                    id: batteryBody
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }
                    width: parent.width * 0.9    // 主体宽度为外框的80%
                    height: parent.height * 0.8  // 主体高度为外框的90%
                    color: "transparent"
                    border {
                        color: "white"
                        width: Math.max(1, parent.width * 0.05)  // 根据尺寸动态调整边框粗细
                    }
                    radius: width * 0.15  // 圆角随尺寸比例变化

                    // 电量填充（从底部向上增长）
                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: parent.border.width + 1  // 内边距略大于边框
                        }
                        height: (parent.height - (anchors.margins * 2)) * (displayedPercent / 100)
                        color: {
                            if (displayedPercent > 70) return "#ADFF2F";
                            if (displayedPercent > 30) return "#FFCC00";
                            return "#FF6B6B";
                        }
                        opacity: 0.8
                        radius: parent.radius * 0.5  // 内圆角为外圆角的一半
                    }
                }

                // 电池正极（在顶部，尺寸随外框比例调整）
                Rectangle {
                    anchors {
                        bottom: batteryBody.top
                        horizontalCenter: batteryBody.horizontalCenter
                       // verticalCenter: parent.verticalCenter

                    }
                    width: batteryBody.width * 0.3  // 正极宽度为主体宽度的40%
                    height: parent.height * 0.1    // 正极高度为外框高度的5%
                    color: batteryBody.border.color
                    radius: height * 0.2  // 半圆形正极
                }

                // 电量百分比文本（自适应字体大小z）
                // Text {
                //     // anchors.centerIn: batteryBody
                //        anchors.verticalCenter: batteryBody.verticalCenter
                //       anchors.horizontalCenter: batteryBody.horizontalCenter
                //     text: Math.round(displayedPercent)// + "%"//四舍五入
                //     color: displayedPercent > 70 ? "black" :"white"
                //     font.pixelSize:ScreenTools.defaultFontPixelHeight * 0.45	 // 字体大小随电池尺寸变化
                //     font.bold: true
                // }
            }
            //剩余电量
        QGCLabel {
            id:remainBattery

               text: {
                        if (!_activeVehicle)
                            return "n/a";

                        let totalPercent = 0;
                        let cellCount = 0;

                        if (_activeVehicle.batteries) {
                            for (let i=0; i<_activeVehicle.batteries.count; i++) {
                                let b = _activeVehicle.batteries.get(i);
                                if (b && b.percentRemaining && !isNaN(b.percentRemaining.rawValue)) {
                                    totalPercent += b.percentRemaining.rawValue;
                                    cellCount++;
                                }
                            }
                        }

                        // if (_activeVehicle.hydrogenBatteries) {
                        //     for (let i=0; i<_activeVehicle.hydrogenBatteries.count; i++) {
                        //         let b = _activeVehicle.hydrogenBatteries.get(i);
                        //         if (b && b.percentRemaining && !isNaN(b.percentRemaining.rawValue)) {
                        //             totalPercent += b.percentRemaining.rawValue;
                        //             cellCount++;
                        //         }
                        //     }
                        // }
                           displayedPercent = Math.min(totalPercent, 100)  // 避免超过 100%

                        return qsTr("(%1块)").arg(cellCount);
                        //return qsTr("%1% (%2块)").arg(totalPercent.toFixed(0)).arg(cellCount);
                    }/* qsTr("%1%").arg(batteryUtils.averageSOC(control._activeVehicle))*/
             color:"white"
             font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.8
             //verticalAlignment: Label.AlignVCenter


              }
        }
    }

    // 详细面板
    Component {
        id: batteryPopup
        ToolIndicatorPage {
            showExpand: true
            //expanded: false
            waitForParameters:  control.waitForParameters //绑定到外部控制器的参数等待状态（可能用于加载动画）
            contentComponent: batteryContentComponent
            expandedComponent:  batteryExpandedComponent//展开设置面板
        }
    }

    Component {
        id: batteryContentComponent
        ColumnLayout {
            spacing: 2
            width: ScreenTools.defaultFontPixelWidth * 20  // 增加宽度以显示更多内容
            height: width
            Layout.minimumWidth: ScreenTools.defaultFontPixelWidth * 15


            Repeater {
                model: _activeVehicle && _activeVehicle.batteries ? _activeVehicle.batteries : 0
               //因为model是QmlObjectListModel类型，可迭代对象容器，object指代其中一个对象
                delegate: SettingsGroupLayout {
                    id: batteryGroup
                    property var battery: object   // 当前电池对象

                    heading: qsTr("锂电池 %1").arg(battery.id ? battery.id.valueString : "N/A")
                    contentSpacing: 2
                    showDividers: true

                    GridLayout {
                        columns: 2
                        columnSpacing: 2
                        rowSpacing: 3

                        // 电压
                        LabelledLabel {
                            label: qsTr("电压:")
                            labelText: battery.voltage ? battery.voltage.valueString + " " + battery.voltage.units : "N/A"
                        }

                        // 电量
                        LabelledLabel {
                            label: qsTr("电量:")
                            labelText: battery.percentRemaining ? battery.percentRemaining.valueString + " " + battery.percentRemaining.units : "N/A"
                        }
                        // 电流
                        LabelledLabel {
                            label: qsTr("电流:")
                            labelText: battery.current ? battery.current.valueString + " " + battery.current.units : "N/A"
                        }
                        // 温度
                        LabelledLabel {
                            label: qsTr("温度:")
                            labelText: battery.temperature ? battery.temperature.valueString + " " + battery.temperature.units : "N/A"
                        }
                    }
                }
            }


            // 如果没有电池数据时的提示
            QGCLabel {
                text: qsTr("No battery data available")
                visible: !_activeVehicle || (_activeVehicle.batteries === 0 && _activeVehicle.hydrogenBatteries === 0)

                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
    }



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
             //设置显示什么数值在logo
            // LabelledFactComboBox {
             //        id:             editModeCheckBox
             //        label:          qsTr("Value") //根据 Fact 的元数据生成下拉选项（0=百分比, 1=电压, 2=两者）。显示的标签文本为 "Value"
             //        fact:           _fact  //直接关联到设置管理器的 valueDisplay 属性，fact,_fact用来缓存从 settingsManager 获取的设置

             //        //绑定到 QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay，这可能是一个枚举值，用于选择显示模式（如百分比、电压或两者）
             //        visible:        _fact.visible
             //        property Fact _fact: QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay
             //    }

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
                                width: ScreenTools.defaultFontPixelWidth * 3
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
                                width: ScreenTools.defaultFontPixelWidth *3
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorYellowGreen
                            }
                            //阈值配置
                            FactTextField {
                                id: threshold1Field
                                fact: _batterySettings.threshold1//输入验证：自动限制为整数输入
                                implicitWidth: ScreenTools.defaultFontPixelWidth *5 // 输入框固定宽度
                                height: ScreenTools.defaultFontPixelHeight //* 1.5
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
                                width: ScreenTools.defaultFontPixelWidth * 3
                                height: width
                                fillMode: Image.PreserveAspectFit
                                color: qgcPal.colorYellow
                            }
                            //设置阈值较低的报警条件
                            FactTextField {
                                fact: _batterySettings.threshold2
                                implicitWidth: ScreenTools.defaultFontPixelWidth * 5
                                height: ScreenTools.defaultFontPixelHeight /** 1.5*/
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
                                width: ScreenTools.defaultFontPixelWidth *3
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
                                width: ScreenTools.defaultFontPixelWidth * 3
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
