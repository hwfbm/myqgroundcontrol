/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "SettingsGroup.h"

//继承自 SettingsGroup。这个类用于管理电池指示器的设置，包括电池值的显示模式和电池阈值的配置
//BatteryIndicatorSettings 继承自 SettingsGroup，这可能是一个通用的设置管理类，提供了基本的设置管理功能
class BatteryIndicatorSettings : public SettingsGroup
{
    Q_OBJECT

public:
    BatteryIndicatorSettings(QObject* parent = nullptr);

    DEFINE_SETTING_NAME_GROUP() //这是一个宏，可能用于定义设置组的名称。这通常用于在设置管理器中注册和识别这个设置组


    //集成到 QGC 的设置系统中，支持 UI 自动生成、持久化存储和跨模块访问，自动处理设置值的数据类型转换（如 int/float/bool/string）
    //可以通过 QML 动态绑定。自动支持 UI 显示、校验、范围、单位、说明等
    //DEFINE_SETTINGFACT：这是一个宏，用于定义具体的设置项，将设置项的键（Key）、默认值、元数据等封装为可全局访问的 Fact 对象
    //最终会在写的类中生成类似这样的代码：Fact* valueDisplay(void) { return &_valueDisplayFact; }。并且 _valueDisplayFact 会被注册到 Settings 系统中：Fact _valueDisplayFact;
    //注册后 QML 中就能直接使用
    // Label {
    //     text: settingsManager.batterySettings.valueDisplay.valueString
    // }
    DEFINE_SETTINGFACT(valueDisplay)            //电池值的显示模式（例如，百分比、电压或两者） Battery value display mode
    DEFINE_SETTINGFACT(threshold1)              //第一个电池阈值 First threshold for battery level
    DEFINE_SETTINGFACT(threshold2)              // 第二个电池阈值Second threshold for battery level

    Q_INVOKABLE void setThreshold1(int value);  //设置第一个电池阈值，并进行验证 Set threshold1 with validation
    Q_INVOKABLE void setThreshold2(int value);  //设置第二个电池阈值，并进行验证 Set threshold2 with validation

private:
    void validateThreshold1();//验证第一个电池阈值的值是否有效
    void validateThreshold2(); //验证第二个电池阈值的值是否有效
    void _threshold1Changed(); //当第一个电池阈值发生变化时调用的槽函数
    void _threshold2Changed();//当第二个电池阈值发生变化时调用的槽函数
};
