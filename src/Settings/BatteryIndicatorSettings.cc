/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "BatteryIndicatorSettings.h"

#include <QSettings> //用于访问和存储设置
#include <QtQml/QQmlEngine> //用于 QML 引擎的集成


//声明设置组，并注册 BatteryIndicatorSettings 类到 QML 环境中。qmlRegisterUncreatableType 确保该类在 QML 中可以被引用，但不能被直接实例化
//声明一个名为 BatteryIndicator 的设置组（Settings Group），用于归类所有与电池指示器相关的配置项
// 宏展开后可能包含：
//     定义该组的唯一标识符（如 SETTING_GROUP_BatteryIndicator）。
//     提供访问该组配置的接口（如 BatteryIndicatorSettings 类）
//1. 核心功能
// 定义设置项的分组名称：
//     将相关的配置项归类到同一个逻辑组（例如 "AppSettings"、"CommSettings"），方便在代码或配置文件中组织和管理。
//     避免硬编码字符串：
//     通过宏生成一致的组名常量，减少手动输入错误的风险。
//在 C++ 中，宏可以通过代码块的形式来定义复杂的逻辑，这使得它看起来像是一个函数
// 代码块：
//     宏的主体是一个代码块，包含了一个调用 qmlRegisterUncreatableType 的语句。
//     这个代码块在宏展开时会被插入到宏调用的位置。

DECLARE_SETTINGGROUP(BatteryIndicator, "BatteryIndicator")
{
    qmlRegisterUncreatableType<BatteryIndicatorSettings>("QGroundControl.SettingsManager", 1, 0, "BatteryIndicatorSettings", "Reference only");
}


//DECLARE_SETTINGSFACT 和 DECLARE_SETTINGSFACT_NO_FUNC：宏，用于声明设置项
DECLARE_SETTINGSFACT(BatteryIndicatorSettings, valueDisplay)//valueDisplay：电池值的显示模式，threshold1 和 threshold2：电池阈值

DECLARE_SETTINGSFACT_NO_FUNC(BatteryIndicatorSettings, threshold1)
{
    if (!_threshold1Fact) {
        _threshold1Fact = _createSettingsFact(threshold1Name);//SettingsFact* SettingsGroup::_createSettingsFact(const QString& factName)：创建一个 SettingsFact 对象
        connect(_threshold1Fact, &SettingsFact::rawValueChanged, this, &BatteryIndicatorSettings::_threshold1Changed);
    }//连接 SettingsFact 的 rawValueChanged 信号到 _threshold1Changed 和 _threshold2Changed 槽函数，以便在值变化时触发验证
    return _threshold1Fact;
}

DECLARE_SETTINGSFACT_NO_FUNC(BatteryIndicatorSettings, threshold2)
{
    if (!_threshold2Fact) {
        _threshold2Fact = _createSettingsFact(threshold2Name);
        connect(_threshold2Fact, &SettingsFact::rawValueChanged, this, &BatteryIndicatorSettings::_threshold2Changed);
    }
    return _threshold2Fact;
}

// Change handlers for thresholds
void BatteryIndicatorSettings::_threshold1Changed() {
    validateThreshold1(); // Call validation when threshold1 value changes
}//_threshold1Changed 和 _threshold2Changed：槽函数，当阈值变化时调用验证函数

void BatteryIndicatorSettings::_threshold2Changed() {
    validateThreshold2(); // Call validation when threshold2 value changes
}

// Validate threshold1 value
//验证函数，确保阈值在有效范围内，并调用设置函数
void BatteryIndicatorSettings::validateThreshold1() {
    int value = threshold1()->rawValue().toInt();
    setThreshold1(value); // Call the setter with the current value
}

// Validate threshold2 value
void BatteryIndicatorSettings::validateThreshold2() {
    int value = threshold2()->rawValue().toInt();
    setThreshold2(value); // Call the setter with the current value
}

// Set threshold1 with validation
//最小值为 16，最大值为 99，确保 threshold1 大于 threshold2
void BatteryIndicatorSettings::setThreshold1(int value) {
    // Ensure value is at least 16 and less than 100
    if (value < 16) {
        threshold1()->setRawValue(17); // Adjust to minimum valid value
    } else if (value > 99) {
        threshold1()->setRawValue(99); // Cap at maximum valid value
    } else {
        // Check if value is greater than threshold2
        if (value > threshold2()->rawValue().toInt()) {
            threshold1()->setRawValue(value);
        } else {
            // Ensure threshold1 is greater than threshold2
            threshold1()->setRawValue(threshold2()->rawValue().toInt() + 1);
        }
    }
}

// Set threshold2 with validation
//最小值为 16
//确保 threshold2 小于 threshold1
void BatteryIndicatorSettings::setThreshold2(int value) {
    // Ensure value is greater than 15
    if (value <= 15) {
        threshold2()->setRawValue(16); // Adjust to the minimum valid value
        return;
    }

    // Check if value is less than threshold1
    if (value < threshold1()->rawValue().toInt()) {
        threshold2()->setRawValue(value);
    } else {
        // Ensure threshold2 is less than threshold1
        threshold2()->setRawValue(threshold1()->rawValue().toInt() - 1);
    }
}
