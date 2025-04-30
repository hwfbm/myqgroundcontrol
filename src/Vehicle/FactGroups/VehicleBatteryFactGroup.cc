/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleBatteryFactGroup.h"
#include "QmlObjectListModel.h"
#include "Vehicle.h"

//实现文件提供了 VehicleBatteryFactGroup 类的具体功能实现，主要处理电池相关数据的收集、管理和展示

const char* VehicleBatteryFactGroup::_batteryFactGroupNamePrefix = "battery";

//其他Fact初始化
//初始化基类 FactGroup，设置更新频率和JSON配置文件路径
//初始化所有Fact成员，指定名称和数据类型
//将所有Fact添加到组中
//设置初始值（大部分为NaN表示无效值）
//连接剩余时间变化的信号到处理槽函数
VehicleBatteryFactGroup::VehicleBatteryFactGroup(uint8_t batteryId, QObject* parent): FactGroup             (1000, ":/json/Vehicle/BatteryFact.json", parent)
    , _batteryIdFact        (0, _batteryIdFactName,        FactMetaData::valueTypeUint8)
    , _batteryFunctionFact  (0, _batteryFunctionFactName,  FactMetaData::valueTypeUint8)
    , _batteryTypeFact      (0, _batteryTypeFactName,      FactMetaData::valueTypeUint8)
    , _voltageFact          (0, _voltageFactName,          FactMetaData::valueTypeDouble)
    , _currentFact          (0, _currentFactName,          FactMetaData::valueTypeDouble)
    , _mahConsumedFact      (0, _mahConsumedFactName,      FactMetaData::valueTypeDouble)
    , _temperatureFact      (0, _temperatureFactName,      FactMetaData::valueTypeDouble)
    , _percentRemainingFact (0, _percentRemainingFactName, FactMetaData::valueTypeDouble)
    , _timeRemainingFact    (0, _timeRemainingFactName,    FactMetaData::valueTypeDouble)
    , _timeRemainingStrFact (0, _timeRemainingStrFactName, FactMetaData::valueTypeString)
    , _chargeStateFact      (0, _chargeStateFactName,      FactMetaData::valueTypeUint8)
    , _instantPowerFact     (0, _instantPowerFactName,     FactMetaData::valueTypeDouble)
{

     // 添加所有Fact到组中

    _addFact(&_batteryIdFact,               _batteryIdFactName);
    _addFact(&_batteryFunctionFact,         _batteryFunctionFactName);
    _addFact(&_batteryTypeFact,             _batteryTypeFactName);
    _addFact(&_voltageFact,                 _voltageFactName);
    _addFact(&_currentFact,                 _currentFactName);
    _addFact(&_mahConsumedFact,             _mahConsumedFactName);
    _addFact(&_temperatureFact,             _temperatureFactName);
    _addFact(&_percentRemainingFact,        _percentRemainingFactName);
    _addFact(&_timeRemainingFact,           _timeRemainingFactName);
    _addFact(&_timeRemainingStrFact,        _timeRemainingStrFactName);
    _addFact(&_chargeStateFact,             _chargeStateFactName);
    _addFact(&_instantPowerFact,            _instantPowerFactName);


    // 设置初始值
    _batteryIdFact.setRawValue          (batteryId);
    _batteryFunctionFact.setRawValue    (MAV_BATTERY_FUNCTION_UNKNOWN);
    _batteryTypeFact.setRawValue        (MAV_BATTERY_TYPE_UNKNOWN);
    _voltageFact.setRawValue            (qQNaN());
    _currentFact.setRawValue            (qQNaN());
    _mahConsumedFact.setRawValue        (qQNaN());
    _temperatureFact.setRawValue        (qQNaN());
    _percentRemainingFact.setRawValue   (qQNaN());
    _timeRemainingFact.setRawValue      (qQNaN());
    _chargeStateFact.setRawValue        (MAV_BATTERY_CHARGE_STATE_UNDEFINED);
    _instantPowerFact.setRawValue       (qQNaN());
    // 连接信号槽
    connect(&_timeRemainingFact, &Fact::rawValueChanged, this, &VehicleBatteryFactGroup::_timeRemainingChanged);
}



//消息处理入口
// 这个方法处理需要创建电池组的消息：
// 高延迟消息默认使用电池ID 0
// 电池状态消息使用消息中的电池ID
void VehicleBatteryFactGroup::handleMessageForFactGroupCreation(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_HIGH_LATENCY:
    case MAVLINK_MSG_ID_HIGH_LATENCY2:
        _findOrAddBatteryGroupById(vehicle, 0);
        break;
    case MAVLINK_MSG_ID_BATTERY_STATUS:
    {
        mavlink_battery_status_t batteryStatus;
        mavlink_msg_battery_status_decode(&message, &batteryStatus);
        _findOrAddBatteryGroupById(vehicle, batteryStatus.id);
    }
        break;
    }
}


//消息分发处理
//根据消息类型分发到具体的处理方法
void VehicleBatteryFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_HIGH_LATENCY:
        _handleHighLatency(vehicle, message);
        break;
    case MAVLINK_MSG_ID_HIGH_LATENCY2:
        _handleHighLatency2(vehicle, message);
        break;
    case MAVLINK_MSG_ID_BATTERY_STATUS:
        _handleBatteryStatus(vehicle, message);
        break;
    }
}


//高延迟消息处理
//处理高延迟消息：
//   解码消息
//   获取或创建电池组（ID=0）
//   设置剩余电量百分比（处理无效值）
//   标记遥测数据可用
void VehicleBatteryFactGroup::_handleHighLatency(Vehicle* vehicle, mavlink_message_t& message)
{
    mavlink_high_latency_t highLatency;
    mavlink_msg_high_latency_decode(&message, &highLatency);

    VehicleBatteryFactGroup* group = _findOrAddBatteryGroupById(vehicle, 0);
    group->percentRemaining()->setRawValue(highLatency.battery_remaining == UINT8_MAX ? qQNaN() : highLatency.battery_remaining);
    group->_setTelemetryAvailable(true);
}




void VehicleBatteryFactGroup::_handleHighLatency2(Vehicle* vehicle, mavlink_message_t& message)
{
    mavlink_high_latency2_t highLatency2;
    mavlink_msg_high_latency2_decode(&message, &highLatency2);

    VehicleBatteryFactGroup* group = _findOrAddBatteryGroupById(vehicle, 0);
    group->percentRemaining()->setRawValue(highLatency2.battery == -1 ? qQNaN() : highLatency2.battery);
    group->_setTelemetryAvailable(true);
}


//电池状态消息处理
//这是最完整的电池数据处理方法：
//     解码电池状态消息
//     获取或创建对应ID的电池组
//     计算总电压（处理14个可能的电池单元）
//     设置所有电池参数（处理各种无效值情况）
//     计算并设置瞬时功率
//     标记遥测数据可用
void VehicleBatteryFactGroup::_handleBatteryStatus(Vehicle* vehicle, mavlink_message_t& message) //它接收一个指向 Vehicle 类的指针和一个 MAVLink 消息结构体的引用
{
    qDebug() << "电池状态消息到达！消息ID:" << message.msgid;
    mavlink_battery_status_t batteryStatus;
    mavlink_msg_battery_status_decode(&message, &batteryStatus);//使用 mavlink_msg_battery_status_decode() 函数解码传入的消息

    VehicleBatteryFactGroup* group = _findOrAddBatteryGroupById(vehicle, batteryStatus.id);//调用 _findOrAddBatteryGroupById 静态成员函数，根据电池 ID 查找或添加一个 VehicleBatteryFactGroup 对象
// 计算总电压（处理10+4个电池单元）
    double totalVoltage = qQNaN();
    for (int i=0; i<10; i++) {
        // 处理每个电池单元的电压
        double cellVoltage = batteryStatus.voltages[i] == UINT16_MAX ? qQNaN() : static_cast<double>(batteryStatus.voltages[i]) / 1000.0;
        if (qIsNaN(cellVoltage)) {
            break;
        }
        if (i == 0) {
            totalVoltage = cellVoltage;
        } else {
            totalVoltage += cellVoltage;
        }
    }
    for (int i=0; i<4; i++) {
        // 处理扩展电池单元的电压
        double cellVoltage = batteryStatus.voltages_ext[i] == 0 ? qQNaN() : static_cast<double>(batteryStatus.voltages_ext[i]) / 1000.0;
        if (qIsNaN(cellVoltage)) {
            break;
        }
        totalVoltage += cellVoltage;
    }
  // 设置所有Fact值，设置了 VehicleBatteryFactGroup 对象的各种属性值，例如电池功能、类型、温度、电压、电流等
    group->function()->setRawValue          (batteryStatus.battery_function);
    group->type()->setRawValue              (batteryStatus.type);
    group->temperature()->setRawValue       (batteryStatus.temperature == INT16_MAX ?   qQNaN() : static_cast<double>(batteryStatus.temperature) / 100.0);
    group->voltage()->setRawValue           (totalVoltage);
    group->current()->setRawValue           (batteryStatus.current_battery == -1 ?      qQNaN() : static_cast<double>(batteryStatus.current_battery) / 100.0);
    group->mahConsumed()->setRawValue       (batteryStatus.current_consumed == -1  ?    qQNaN() : batteryStatus.current_consumed);
    group->percentRemaining()->setRawValue  (batteryStatus.battery_remaining == -1 ?    qQNaN() : batteryStatus.battery_remaining);
    group->timeRemaining()->setRawValue     (batteryStatus.time_remaining == 0 ?        qQNaN() : batteryStatus.time_remaining);
    group->chargeState()->setRawValue       (batteryStatus.charge_state);
    // 计算瞬时功率 = 电压 * 电流
    group->instantPower()->setRawValue      (totalVoltage * group->current()->rawValue().toDouble());
    group->_setTelemetryAvailable(true); //标记遥测数据可用
}


//电池组查找/创建
// 这个方法确保：
//     电池组列表按ID排序
//     如果ID已存在，返回现有组
//     如果ID不存在，在正确位置插入新组
//     为车辆添加新的事实组
//函数接收两个参数：一个指向 Vehicle 类型的指针 vehicle 和一个 batteryId，表示要查找或添加的电池组的 ID
VehicleBatteryFactGroup* VehicleBatteryFactGroup::_findOrAddBatteryGroupById(Vehicle* vehicle, uint8_t batteryId) //是在 Vehicle 对象的电池列表中查找特定 ID 的电池组（VehicleBatteryFactGroup），如果找不到，则创建一个新的电池组并添加到列表中
{
    QmlObjectListModel* batteries = vehicle->batteries();//获取电池列表，这行代码获取 Vehicle 对象中管理电池组的 QmlObjectListModel

    // We maintain the list in order sorted by battery id so the ui shows them sorted.
    // 保持列表按电池ID排序，遍历电池列表，检查每个电池组的 ID
    for (int i=0; i<batteries->count(); i++) {
        //检查并处理现有电池组
        VehicleBatteryFactGroup* group = batteries->value<VehicleBatteryFactGroup*>(i);
        int listBatteryId = group->id()->rawValue().toInt();
        if (listBatteryId >  batteryId) {
            // 在正确位置插入新电池组
            //如果找到 ID 匹配的电池组，直接返回这个电池组。如果没有找到匹配的 ID，但找到了一个更大的 ID，就在该位置插入一个新的电池组
            VehicleBatteryFactGroup* newBatteryGroup = new VehicleBatteryFactGroup(batteryId, batteries);
            batteries->insert(i, newBatteryGroup);
            vehicle->_addFactGroup(newBatteryGroup, QStringLiteral("%1%2").arg(_batteryFactGroupNamePrefix).arg(batteryId));
            return newBatteryGroup;
        } else if (listBatteryId == batteryId) {
            return group;
        }
    }
    // 添加新电池组，如果没有找到匹配的 ID，也没有找到可以插入的位置，就在列表末尾添加一个新的电池组
    VehicleBatteryFactGroup* newBatteryGroup = new VehicleBatteryFactGroup(batteryId, batteries);
    batteries->append(newBatteryGroup);
    vehicle->_addFactGroup(newBatteryGroup, QStringLiteral("%1%2").arg(_batteryFactGroupNamePrefix).arg(batteryId));

    return newBatteryGroup; //如果创建了新的电池组，返回新创建的电池组
}



//剩余时间格式化
//将秒数格式化为"HH:MM:SS"字符串，无效值显示为"--:--:--"
void VehicleBatteryFactGroup::_timeRemainingChanged(QVariant value)
{
    if (qIsNaN(value.toDouble())) {
        _timeRemainingStrFact.setRawValue("--:--:--");
    } else {
        int totalSeconds    = value.toInt();
        int hours           = totalSeconds / 3600;
        int minutes         = (totalSeconds % 3600) / 60;
        int seconds         = totalSeconds % 60;

        _timeRemainingStrFact.setRawValue(QString::asprintf("%02dH:%02dM:%02dS", hours, minutes, seconds));
    }
}
