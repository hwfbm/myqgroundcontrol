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
//import "."
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
    width:        parent.width

    readonly property real _horizontalMargin:   _defaultTextWidth / 2
    readonly property real _verticalMargin:     _defaultTextHeight / 2
    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    property bool       showIndicator:      true//是否显示电池指示器（可通过配置关闭）
    property bool       waitForParameters:  false   // 是否等待飞控参数加载完成后再显示 UI
    property Component  expandedPageComponent //Component 是 QML 的一个 可重用 UI 模板，类似于一个“未实例化的 QML 对象定义”，可以在运行时动态创建（类似 new 一个对象）
    //动态加载不同的 QML 页面（如弹窗、配置页）
    // 延迟实例化（优化性能，避免初始化时加载所有 UI）
    // 结合 Loader 动态切换界面

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle//当前活动的无人机对象，返回当前激活的无人机（通过 multiVehicleManager 获取），vehicle类
    property var    _batterySettings:   QGroundControl.settingsManager.batteryIndicatorSettings//电池显示相关的用户设置（如显示模式、警告阈值）
    property Fact   _indicatorDisplay:  _batterySettings.valueDisplay//_indicatorDisplay 决定显示内容
    property bool   _showPercentage:    _indicatorDisplay.rawValue === 0  //是否显示百分比（根据 valueDisplay 设置）
    property bool   _showVoltage:       _indicatorDisplay.rawValue === 1 // 1=电压
    property bool   _showBoth:          _indicatorDisplay.rawValue === 2  // 2=电压+百分比

    // Properties to hold the thresholds用户配置的电量警告阈值（用于触发颜色变化）
    //当电池电量低于 threshold2 时显示红色警告，低于 threshold1 显示黄色警告。
    property int threshold1: _batterySettings.threshold1.rawValue
    property int threshold2: _batterySettings.threshold2.rawValue
    Component.onCompleted: {
       // console.log("🚀 hydrogenBatteries:", control._activeVehicle.hydrogenBatteries);
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



    // 电池详细信息面板 的 QML 实现，用于展示单个或多个电池的全面状态数据
    //根据数据可用性自动隐藏无效项
    //分组显示电压、温度、消耗量等关键参数
    //所有文本使用 qsTr() 封装以便翻译
    //数据驱动的动态UI生成
    // Component {
    //     id: batteryContentComponent
    QGCFlickable {
        id:                 batteryList
        width:              parent.width
        anchors.topMargin:  _verticalMargin
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.leftMargin: _horizontalMargin
        anchors.left:       parent.left
        anchors.right:       parent.right
        contentHeight:      batteryshow.implicitHeight + _verticalMargin
        flickableDirection: Flickable.VerticalFlick
        clip:               true

        ColumnLayout {
            id:batteryshow
            spacing: ScreenTools.defaultFontPixelHeight / 2
            width: parent.width
            //anchors.fill: parent




            //Repeater据 model 中的数据数量，动态实例化其内部的 SettingsGroupLayout 模板。若 batteries 包含 2 个电池，则生成 2 个独立的 SettingsGroupLayout
    //当你使用 Repeater + model（比如是一个数组）时，每次迭代会自动提供当前项作为上下文变量 modelData
            //而在 QML 里，modelData 会自动作为每个迭代子项的默认 object 属性注入进去，如果你没有显示声明 object，它也会变成隐式属性，子项可以直接用
            Repeater {
                model: _activeVehicle ? _activeVehicle.hydrogenBatteries : 0//数据驱动源，这里绑定到当前活动飞行器的电池列表 _activeVehicle.batteries，空模型安全处理
                //每次 Repeater 迭代时，modelData 是当前的 battery 对象
                //如果无活动飞行器（_activeVehicle 为 null），则设置为 0 表示不生成任何项

                //在 Repeater 中，每次迭代会隐式注入 modelData 给子组件，并把它设为默认的 object 属性 —— 所以你在 SettingsGroupLayout 和 LabelledLabel 中使用 object.xxx 是成立的，它等于当前 battery


              SettingsGroupLayout {
                    // property var object: modelData   // ✅ 绑定当前迭代项
                    heading:        qsTr("氢电池 %1").arg(_activeVehicle.hydrogenBatteries.length === 1 ? qsTr("Status") : object.hydroId.rawValue+1)//单电池时显示 "Battery Status"，多电池时显示 "Battery 1"、"Battery 2"
                    headingDescription: "以下数据来自自定义消息"
                    contentSpacing: 0 //保持简洁，紧凑布局
                    showDividers:   false

                    property var batteryValuesAvailable: batteryValuesAvailableLoader.item//结果存储在 batteryValuesAvailableLoader.item 中供后续使用
                    //通过 Loader 动态加载检测逻辑


                    // Loader {// 加载检测组件
                    //     id: batteryValuesAvailableLoader
                    //     sourceComponent:    batteryValuesAvailableComponent
                    //     property var battery: object//// 传递当前电池对象
                    // }


                    Component.onCompleted: {
                        console.log("当前 object 是：", object)  // 打印出电池对象
                    }

                    //Repeater 适用于静态/预处理好的数据模型，不适合用于绑定具体对象字段
                    GridLayout {
                            columns: 3
                            rowSpacing: ScreenTools.defaultFontPixelWidth
                            columnSpacing: ScreenTools.defaultFontPixelWidth
                            Layout.fillWidth: true

                                Layout.preferredWidth: parent.width   // 限制宽度，超出时内容会被压缩

                            //对称布局，左侧标签 + 右侧数值

                            LabelledLabel {
                                label:  qsTr("电池电压")
                                labelText:  object.batVoltage.valueString + " " + object.batVoltage.units
                                visible:true
                                //visible:    batteryValuesAvailable.chargeStateAvailable//动态可见性，仅当数据有效时显示
                            }

                            LabelledLabel {
                                label:      qsTr("电机电流")
                                labelText:  object.servoCurrent.valueString + " " + object.servoCurrent.units
                                visible:    true
                            }

                            LabelledLabel {
                                label:      qsTr("电堆电压")
                                labelText:  object.stackVoltage.valueString + " " + object.stackVoltage.units//单位自动附加双引号，如 "24.3 V"
                                visible:    true
                            }

                            LabelledLabel {
                                label:      qsTr("电机电压")
                                labelText:  object.servoVoltage.valueString + " " + object.servoVoltage.units
                            }

                            LabelledLabel {
                                label:      qsTr("补能电流")
                                labelText:  object.batRefuelCurrent.valueString + " " + object.batRefuelCurrent.units
                                visible:    true
                            }

                            LabelledLabel {
                                label:      qsTr("气罐压力")
                                labelText:  object.gasTankPressure.valueString + " " + object.gasTankPressure.units
                                visible:    true
                            }

                            // LabelledLabel {
                            //     label:      qsTr("Function")
                            //     labelText:  object.function.enumStringValue
                            //     visible:    batteryValuesAvailable.showFunction
                            // }
                            LabelledLabel {
                                label:      qsTr("管道压力")
                                labelText:  object.pipePressure.valueString + " " + object.pipePressure.units
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("主板温度")
                                labelText:  object.pcbTemp.valueString + " " + object.pcbTemp.units
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("电堆温度")
                                labelText:  object.stackTemp.valueString + " " + object.stackTemp.units
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("设备状态")
                                labelText:  object.workStatus.valueString
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("报警状态")
                                labelText:  object.faultStatus.valueString
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("自检状态")
                                labelText: object.selfCheck.enumStringValue
                                visible:    true
                            }
                            LabelledLabel {
                                label:      qsTr("id")
                                labelText:  object.hydroId.enumStringValue
                                visible:    true
                            }
                            // HyBattery {
                                //     //anchors.fill: parent
                                // }

                        }
                    }
            }
        }
    }
    //}


    //Component定义了一个 QML 组件，可以被动态加载和使用，使用 Component 封装，是为了延迟加载（通常配合 Loader 使用）
     //电池设置扩展面板 的 QML 实现，主要用于配置电池显示参数和警告阈值
     // 显示模式配置：选择显示百分比、电压或两者
     // 阈值颜色管理：设置电量警告阈值（threshold1/threshold2）
     // 状态颜色预览：直观展示不同电量状态对应的颜色/图标
     // 高级电源配置：跳转到车辆电源管理界面（需高级权限）
    // Component {
    //     id: batteryExpandedComponent
    //   //ColumnLayout：一个垂直布局容器，用于排列子元素
    //     ColumnLayout {
    //         //spacing 设置了控件之间的垂直间距，使用屏幕字体高度作为参考，确保在不同分辨率下自适应
    //         spacing: ScreenTools.defaultFontPixelHeight / 2


    //         //FactPanelController：一个控制器，可能用于管理与电池相关的事实（Fact
    //         //控制器类，用于管理 QGC 中的 Fact（参数绑定对象），帮助 UI 控件获取或修改设置项的值
    //         FactPanelController { id: controller }


    //         //SettingsGroupLayout：一个布局，用于分组显示设置
    //         SettingsGroupLayout {
    //             //设置组的标题为 "Battery Display"
    //             heading:            qsTr("Battery Display")
    //             Layout.fillWidth:   true
    //         //显示模式选择，LabelledFactComboBox：自定义的一个带标签的下拉选择框，用于选择电池的显示模式（如百分比、电压等）
    //          LabelledFactComboBox {
    //                 id:             editModeCheckBox
    //                 label:          qsTr("Value") //根据 Fact 的元数据生成下拉选项（0=百分比, 1=电压, 2=两者）。显示的标签文本为 "Value"
    //                 fact:           _fact  //直接关联到设置管理器的 valueDisplay 属性，fact,_fact用来缓存从 settingsManager 获取的设置

    //                 //绑定到 QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay，这可能是一个枚举值，用于选择显示模式（如百分比、电压或两者）
    //                 visible:        _fact.visible
    //                 property Fact _fact: QGroundControl.settingsManager.batteryIndicatorSettings.valueDisplay
    //             }

    //             ColumnLayout {
    //                 QGCLabel { text: qsTr("Coloring") }

    //                 RowLayout {
    //                     spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Reduced spacing between elements

    //                     // Battery 100%
    //                     //每个子 RowLayout 代表一个电池状态颜色和数值配置
    //                     RowLayout {
    //                         spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
    //                         QGCColoredImage {
    //                             source: "/qmlimages/BatteryGreen.svg"
    //                             width: ScreenTools.defaultFontPixelWidth * 6
    //                             height: width
    //                             fillMode: Image.PreserveAspectFit
    //                             color: qgcPal.colorGreen
    //                         }
    //                         QGCLabel { text: qsTr("100%") }
    //                     }

    //                     // Threshold 1，图标是黄绿色，带一个 FactTextField 输入框
    //                     RowLayout {
    //                         spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field
    //                         QGCColoredImage {
    //                             source: "/qmlimages/BatteryYellowGreen.svg"
    //                             width: ScreenTools.defaultFontPixelWidth * 6
    //                             height: width
    //                             fillMode: Image.PreserveAspectFit
    //                             color: qgcPal.colorYellowGreen
    //                         }
    //                         //阈值配置
    //                         FactTextField {
    //                             id: threshold1Field
    //                             fact: _batterySettings.threshold1//输入验证：自动限制为整数输入
    //                             implicitWidth: ScreenTools.defaultFontPixelWidth * 6 // 输入框固定宽度
    //                             height: ScreenTools.defaultFontPixelHeight * 1.5
    //                             enabled: fact.visible
    //                             onEditingFinished: {
    //                                 // Validate and set the new threshold value
    //                                 _batterySettings.setThreshold1(parseInt(text));//即时生效：编辑完成后立即更新设置
    //                             }
    //                         }
    //                     }

    //                     // Threshold 2，图标是黄色
    //                     RowLayout {
    //                         spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and field根据屏幕 DPI 自动调整，确保在不同设备上显示一致，// 极小的元素间距
    //                         QGCColoredImage {
    //                             source: "/qmlimages/BatteryYellow.svg"
    //                             width: ScreenTools.defaultFontPixelWidth * 6
    //                             height: width
    //                             fillMode: Image.PreserveAspectFit
    //                             color: qgcPal.colorYellow
    //                         }
    //                         //设置阈值较低的报警条件
    //                         FactTextField {
    //                             fact: _batterySettings.threshold2
    //                             implicitWidth: ScreenTools.defaultFontPixelWidth * 6
    //                             height: ScreenTools.defaultFontPixelHeight * 1.5
    //                             enabled: fact.visible
    //                             onEditingFinished: {
    //                                 // Validate and set the new threshold value
    //                                 _batterySettings.setThreshold2(parseInt(text));
    //                             }
    //                         }
    //                     }
    //                     //使用标准化的 SVG 电池图标，
    //                     //所有尺寸基于 ScreenTools 计算
    //                     // Low state， Low 状态（橙色图标🟠，纯展示，无法设置）
    //                     RowLayout {
    //                         spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
    //                         QGCColoredImage {
    //                             source: "/qmlimages/BatteryOrange.svg"
    //                             width: ScreenTools.defaultFontPixelWidth * 6
    //                             height: width
    //                             fillMode: Image.PreserveAspectFit
    //                             color: qgcPal.colorOrange //从 qgcPalette 获取一致的主题色
    //                         }
    //                         QGCLabel { text: qsTr("Low") }
    //                     }

    //                     // Critical state，🔴 Critical 状态（红色图标，纯展示，无法设置）
    //                     RowLayout {
    //                         spacing: ScreenTools.defaultFontPixelWidth * 0.05  // Tighter spacing for icon and label
    //                         QGCColoredImage {
    //                             source: "/qmlimages/BatteryCritical.svg"
    //                             width: ScreenTools.defaultFontPixelWidth * 6
    //                             height: width
    //                             fillMode: Image.PreserveAspectFit
    //                             color: qgcPal.colorRed
    //                         }
    //                         QGCLabel { text: qsTr("Critical") }
    //                     }
    //                 }
    //             }
    //         }


    //         //用于动态加载其他页面，避免一次加载所有界面，提升性能
    //         Loader {
    //             Layout.fillWidth: true//// 填充可用宽度
    //             sourceComponent: expandedPageComponent //延迟加载的 QML 组件（比如更详细的电池页面），通过 expandedPageComponent 提供（看起来好像还没提供实现）
    //         }

    //         SettingsGroupLayout {
    //             visible: _activeVehicle.autopilotPlugin.knownVehicleComponentAvailable(AutoPilotPlugin.KnownPowerVehicleComponent) &&
    //                         QGroundControl.corePlugin.showAdvancedUI//仅当同时满足时显示，普通用户无法访问高级电源配置


    //             // 高级功能入口
    //             //这个区域只有在两个条件满足时才显示
    //                  //当前载具的自动驾驶插件支持“电源配置”组件。
    //                  //启用了高级用户界面（非普通用户）。
    //             //按钮点击后会打开电源配置页面，同时关闭侧边栏抽屉
    //             LabelledButton {
    //                 label:      qsTr("Vehicle Power")
    //                 buttonText: qsTr("Configure")

    //                 onClicked: {
    //                     mainWindow.showKnownVehicleComponentConfigPage(AutoPilotPlugin.KnownPowerVehicleComponent)
    //                     mainWindow.closeIndicatorDrawer()
    //                 }
    //             }
    //         }
    //     }
    // }
}

