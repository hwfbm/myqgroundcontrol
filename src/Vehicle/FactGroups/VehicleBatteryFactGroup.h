/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "FactGroup.h"
#include "QGCMAVLink.h"

class Vehicle;

//用于管理和处理与车辆电池相关的各种数据。这个类主要用于 QGroundControl (QGC) 地面站软件中，处理来自 MAVLink 协议的电池信息
//继承自 FactGroup，这是一个基础类，用于管理一组相关的数据项(Facts)
// 管理电池相关的各种参数（电压、电流、温度等）
// 处理来自 MAVLink 协议的电池状态消息
// 提供电池信息的 QML 访问接口
//这个类在 QGroundControl 中扮演着电池信息管理的核心角色，将来自飞行器的电池状态信息处理后提供给用户界面显示

class VehicleBatteryFactGroup : public FactGroup
{
    Q_OBJECT

public:
    VehicleBatteryFactGroup(uint8_t batteryId, QObject* parent = nullptr); //初始化所有 Fact 成员并设置初始值，batteryId 表示电池ID，parent 为父QObject

    //这些声明使得 QML 可以访问 C++ 中的 Fact 成员。每个属性都是只读的(CONSTANT)，通过对应的访问函数获取
    Q_PROPERTY(Fact* id                 READ id                 CONSTANT)
    Q_PROPERTY(Fact* function           READ function           CONSTANT)
    Q_PROPERTY(Fact* type               READ type               CONSTANT)
    Q_PROPERTY(Fact* temperature        READ temperature        CONSTANT)
    Q_PROPERTY(Fact* voltage            READ voltage            CONSTANT)
    Q_PROPERTY(Fact* current            READ current            CONSTANT)
    Q_PROPERTY(Fact* mahConsumed        READ mahConsumed        CONSTANT)
    Q_PROPERTY(Fact* percentRemaining   READ percentRemaining   CONSTANT)
    Q_PROPERTY(Fact* timeRemaining      READ timeRemaining      CONSTANT)
    Q_PROPERTY(Fact* timeRemainingStr   READ timeRemainingStr   CONSTANT)
    Q_PROPERTY(Fact* chargeState        READ chargeState        CONSTANT)
    Q_PROPERTY(Fact* instantPower       READ instantPower       CONSTANT)


    //属性访问函数
    //这些函数提供了对各个 Fact 成员的访问接口
    Fact* id                        () { return &_batteryIdFact; }
    Fact* function                  () { return &_batteryFunctionFact; }
    Fact* type                      () { return &_batteryTypeFact; }
    Fact* voltage                   () { return &_voltageFact; }
    Fact* percentRemaining          () { return &_percentRemainingFact; }
    Fact* mahConsumed               () { return &_mahConsumedFact; }
    Fact* current                   () { return &_currentFact; }
    Fact* temperature               () { return &_temperatureFact; }
    Fact* instantPower              () { return &_instantPowerFact; }
    Fact* timeRemaining             () { return &_timeRemainingFact; }
    Fact* timeRemainingStr          () { return &_timeRemainingStrFact; }
    Fact* chargeState               () { return &_chargeStateFact; }




    /// Creates a new fact group for the battery id as needed and updates the Vehicle with it
    //参数：vehicle 为车辆对象，message 为 MAVLink 消息
    //功能：根据消息创建新的电池事实组或更新现有组
    static void handleMessageForFactGroupCreation(Vehicle* vehicle, mavlink_message_t& message); //静态消息处理函数

    // Overrides from FactGroup
    //消息处理函数，重写自 FactGroup
    //功能：处理传入的 MAVLink 消息并更新相应的电池数据
    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;

private slots:
    void _timeRemainingChanged(QVariant value);  //当剩余时间变化时更新剩余时间字符串表示

private:
    //私有静态消息处理函数
    //这些函数处理特定类型的 MAVLink 消息
    static void                     _handleHighLatency          (Vehicle* vehicle, mavlink_message_t& message); //处理高延迟链路消息
    static void                     _handleHighLatency2         (Vehicle* vehicle, mavlink_message_t& message); //处理高延迟链路2消息
    static void                     _handleBatteryStatus        (Vehicle* vehicle, mavlink_message_t& message); //处理电池状态消息

    static VehicleBatteryFactGroup* _findOrAddBatteryGroupById  (Vehicle* vehicle, uint8_t batteryId);//电池组查找/添加函数，根据电池ID查找或创建新的电池事实组

    static const char* _batteryFactGroupNamePrefix; //电池事实组名称前缀

    const QString _batteryIdFactName             = QStringLiteral("id");
    const QString _batteryFunctionFactName       = QStringLiteral("batteryFunction");
    const QString _batteryTypeFactName           = QStringLiteral("batteryType");
    const QString _voltageFactName               = QStringLiteral("voltage");
    const QString _percentRemainingFactName      = QStringLiteral("percentRemaining");
    const QString _mahConsumedFactName           = QStringLiteral("mahConsumed");
    const QString _currentFactName               = QStringLiteral("current");
    const QString _temperatureFactName           = QStringLiteral("temperature");
    const QString _instantPowerFactName          = QStringLiteral("instantPower");
    const QString _timeRemainingFactName         = QStringLiteral("timeRemaining");
    const QString _timeRemainingStrFactName      = QStringLiteral("timeRemainingStr");
    const QString _chargeStateFactName           = QStringLiteral("chargeState");

    //对应上述每个名称都有一个 Fact 成员变量，用于存储具体值
    Fact            _batteryIdFact;
    Fact            _batteryFunctionFact;
    Fact            _batteryTypeFact;
    Fact            _voltageFact;
    Fact            _currentFact;
    Fact            _mahConsumedFact;
    Fact            _temperatureFact;
    Fact            _percentRemainingFact;
    Fact            _timeRemainingFact;
    Fact            _timeRemainingStrFact;
    Fact            _chargeStateFact;
    Fact            _instantPowerFact;


};
