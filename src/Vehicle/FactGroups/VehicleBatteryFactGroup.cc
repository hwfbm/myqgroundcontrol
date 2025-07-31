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
VehicleBatteryFactGroup::VehicleBatteryFactGroup(uint8_t batteryId, QObject* parent): FactGroup(1000, ":/json/Vehicle/BatteryFact.json", parent),
        _batVoltageFact(0, _batVoltageFactName, FactMetaData::valueTypeUint16),
        _servoCurrentFact(0, _servoCurrentFactName, FactMetaData::valueTypeUint16),
        _stackVoltageFact(0, _stackVoltageFactName, FactMetaData::valueTypeUint16),
        _servoVoltageFact(0, _servoVoltageFactName, FactMetaData::valueTypeUint16),
        _batRefuelCurrentFact(0, _batRefuelCurrentFactName, FactMetaData::valueTypeUint16),
        _gasTankPressureFact(0, _gasTankPressureFactName, FactMetaData::valueTypeUint16),
        _pipePressureFact(0, _pcbTempFactName, FactMetaData::valueTypeUint16),
        _pcbTempFact(0, _pcbTempFactName, FactMetaData::valueTypeInt8),
        _stackTempFact(0, _stackTempFactName, FactMetaData::valueTypeInt8),
        _workStatusFact(0, _workStatusFactName, FactMetaData::valueTypeUint8),
        _faultStatusFact(0, _faultStatusFactName, FactMetaData::valueTypeUint8),
        _selfCheckFact(0,_selfCheckFactName, FactMetaData::valueTypeUint8),
        _idFact(0, _hydroIdFactName, FactMetaData::valueTypeUint8)
        , _batteryIdFact        (0, _batteryIdFactName,                 FactMetaData::valueTypeUint8)
        , _batteryFunctionFact  (0, _batteryFunctionFactName,           FactMetaData::valueTypeUint8)
        , _batteryTypeFact      (0, _batteryTypeFactName,               FactMetaData::valueTypeUint8)
        , _voltageFact          (0, _voltageFactName,                   FactMetaData::valueTypeDouble)
        , _currentFact          (0, _currentFactName,                   FactMetaData::valueTypeDouble)
        , _mahConsumedFact      (0, _mahConsumedFactName,               FactMetaData::valueTypeDouble)
        , _temperatureFact      (0, _temperatureFactName,               FactMetaData::valueTypeDouble)
        , _percentRemainingFact (0, _percentRemainingFactName,          FactMetaData::valueTypeDouble)
        , _timeRemainingFact    (0, _timeRemainingFactName,             FactMetaData::valueTypeDouble)
        , _timeRemainingStrFact (0, _timeRemainingStrFactName,          FactMetaData::valueTypeString)
        , _chargeStateFact      (0, _chargeStateFactName,               FactMetaData::valueTypeUint8)
        , _instantPowerFact     (0, _instantPowerFactName,              FactMetaData::valueTypeDouble)
{
     // 添加所有Fact到组中

    _addFact(&_batVoltageFact,         "bat_voltage");
    _addFact(&_servoCurrentFact,       "servo_current");
    _addFact(&_stackVoltageFact,       "stack_voltage");
    _addFact(&_servoVoltageFact,       "servo_voltage");
    _addFact(&_batRefuelCurrentFact,   "bat_refuel_current");
    _addFact(&_gasTankPressureFact,    "gas_tank_pressure");
    _addFact(&_pipePressureFact,       "pipe_pressure");
    _addFact(&_pcbTempFact,            "pcb_temp");
    _addFact(&_stackTempFact,          "stack_temp");
    _addFact(&_workStatusFact,         "work_status");
    _addFact(&_faultStatusFact,        "fault_status");
    _addFact(&_selfCheckFact,          "self_check");
    _addFact(&_idFact,                 "hydroId"); //避免和 _batteryIdFact 冲突


    // 设置初始值
    //初始化各个电池字段的默认值（RawValue），保证启动时有值可用（哪怕是空值 NaN 或状态码）
    //在 QGC UI 中显示出这些字段的时候，如果没有收到飞控数据，也能看到占位默认值
    _batVoltageFact.setRawValue        (qQNaN());
    _servoCurrentFact.setRawValue      (0);
    _stackVoltageFact.setRawValue      (0);
    _servoVoltageFact.setRawValue      (0);
    _batRefuelCurrentFact.setRawValue  (0);
    _gasTankPressureFact.setRawValue   (0);
    _pipePressureFact.setRawValue      (0);
    _pcbTempFact.setRawValue           (0);
    _stackTempFact.setRawValue         (0);
    _workStatusFact.setRawValue        (0);
    _faultStatusFact.setRawValue       (0);
    _selfCheckFact.setRawValue         (0);
    _idFact.setRawValue                (batteryId);


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
   // qDebug() << "HYDROGEN_BATTERY ID AT COMPILE TIME = " << MAVLINK_MSG_ID_HYDROGEN_BATTERY;

    connect(&_timeRemainingFact, &Fact::rawValueChanged, this, &VehicleBatteryFactGroup::_timeRemainingChanged);
}



//消息处理入口
//根据 MAVLink 消息类型，判断是否需要处理电池数据，动态创建或查找电池组，确保每个电池 ID 有对应的数据存储结构
// 这个方法处理需要创建电池组的消息：
// 高延迟消息默认使用电池ID 0
// 电池状态消息使用消息中的电池ID
void VehicleBatteryFactGroup::handleMessageForFactGroupCreation(Vehicle* vehicle, mavlink_message_t& message)
{
    //mavlink_message_t& message：接收到的 MAVLink 消息
    //Vehicle* vehicle：指向当前载具（如无人机）的指针，用于管理电池组
    switch (message.msgid) {
        // 处理 HIGH_LATENCY 或 HIGH_LATENCY2 消息：高延迟遥测消息（用于低带宽链路，如卫星通信）
    case MAVLINK_MSG_ID_HIGH_LATENCY:
    case MAVLINK_MSG_ID_HIGH_LATENCY2:
        _findOrAddBatteryGroupById(vehicle, 0);//调用 _findOrAddBatteryGroupById，强制使用电池 ID 0：高延迟消息通常不携带多电池信息，默认处理单电池场景
        break;
        //标准电池状态消息（包含详细电池数据）
    case MAVLINK_MSG_ID_BATTERY_STATUS:
    {
        //mavlink_msg_battery_status_decode 解析消息内容到 batteryStatus 结构体
        mavlink_battery_status_t batteryStatus;
        mavlink_msg_battery_status_decode(&message, &batteryStatus);//从 batteryStatus.id 中提取电池标识符
        _findOrAddBatteryGroupById(vehicle, batteryStatus.id);//创建或查找电池组：调用 _findOrAddBatteryGroupById，传入载具和电池 ID
        qDebug() << "battery_status_decode id = " << batteryStatus.id;

        qDebug() << "handleMessageForFactGroupCreation中的原生电池 ID被识别为factgroup:" << message.msgid;
    }break;

    // case MAVLINK_MSG_ID_DATA32:
    // {
    //     //mavlink_msg_battery_status_decode 解析消息内容到 batteryStatus 结构体
    //     mavlink_data32_t data;
    //     mavlink_msg_data32_decode(&message, &data);//从 batteryStatus.id 中提取电池标识符
    //     _findOrAddBatteryGroupById(vehicle, data.id);//创建或查找电池组：调用 _findOrAddBatteryGroupById，传入载具和电池 ID
    //    // qDebug() << "battery_status_decode id = " << batteryStatus.id;

    //     qDebug() << "handleMessageForFactGroupCreation中的原生电池 ID被识别为factgroup:" << message.msgid;
    // }break;
    default:
        qDebug() << "未处理的消息 ID:" << message.msgid;
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
        qDebug() << "打印收到 msgid = " << message.msgid << " 类型 = " << typeid(message.msgid).name();
        break;
    // case MAVLINK_MSG_ID_HYDROGEN_BATTERY: // HYDROGEN_BATTERY
    //     qDebug() << "Hydrogen battery 在handleMessage被调用";

    //     _handleHydrogenBattery(vehicle, message);

    //     break;
    default:
        qDebug() << "message未处理的消息 ID:" << message.msgid;
        break;
    }

    //qDebug() << "handlemessage收到MAVLink消息，ID:" << message.msgid;
    // qDebug() << "原生Voltage:" << _voltageFact.rawValue();
    // qDebug() << "原生Percent remaining:" << _percentRemainingFact.rawValue();
    //    qDebug() << "自定义的voltage:" << _batVoltageFact.rawValue();
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
    int count=0;

    qDebug() << "电池状态消息到达！消息ID:" << message.msgid<<" "<<count++;
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
  //设置所有Fact值，设置了 VehicleBatteryFactGroup 对象的各种属性值，例如电池功能、类型、温度、电压、电流等
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


void VehicleBatteryFactGroup::_handleHydrogenBattery(Vehicle* vehicle, mavlink_message_t& message)
{
   //  int count=0;

   //  qDebug() << "氢协议电池状态消息到达！消息ID:" << message.msgid<<" "<<count++;
   //  mavlink_hydrogen_battery_t battery;
   //  mavlink_msg_hydrogen_battery_decode(&message, &battery);

   //  VehicleBatteryFactGroup* group = _findOrAddBatteryGroupById(vehicle, battery.id); // 可按需要更改 ID

   //  // 设置各项属性（单位转换正确）
   // // group->batVoltage()->setRawValue(static_cast<double>(battery.bat_voltage) / 1000.0);         // V
   //  group->batVoltage()->setRawValue(battery.bat_voltage);
   //   group->batVoltage()->setRawValue(battery.bat_voltage);

   //  // group->servoCurrent()->setRawValue(static_cast<double>(battery.servo_current) / 1000.0);     // A
   //  // group->stackVoltage()->setRawValue(static_cast<double>(battery.stack_voltage) / 1000.0);     // V
   //  // group->servoVoltage()->setRawValue(static_cast<double>(battery.servo_voltage) / 1000.0);     // V
   //  // group->batRefuelCurrent()->setRawValue(static_cast<double>(battery.bat_refuel_current) / 1000.0); // A
   //  group->servoCurrent()->setRawValue(battery.servo_current);     // A
   //  group->stackVoltage()->setRawValue(battery.stack_voltage);     // V
   //  group->servoVoltage()->setRawValue(battery.servo_voltage);     // V
   //  group->batRefuelCurrent()->setRawValue(battery.bat_refuel_current);


   //  group->gasTankPressure()->setRawValue(battery.gas_tank_pressure);                            // Pa
   //  group->pipePressure()->setRawValue(battery.pipe_pressure);                                   // Pa


   //  // group->pcbTemp()->setRawValue(static_cast<double>(battery.pcb_temp));                        // °C
   //  // group->stackTemp()->setRawValue(static_cast<double>(battery.stack_temp));                    // °C

   //  group->pcbTemp()->setRawValue(battery.pcb_temp);                        // °C
   //  group->stackTemp()->setRawValue(battery.stack_temp);                    // °C


   //  group->workStatus()->setRawValue(battery.work_status);                                       // 状态码
   //  group->faultStatus()->setRawValue(battery.fault_status);                                     // 故障码
   //  group->selfCheck()->setRawValue(battery.self_check);                                         // 0/1
   //  group->hydroId()->setRawValue(battery.id);
   //  // 可以根据需要添加更多字段，如氢燃料浓度、电堆电压等

   //  group->_setTelemetryAvailable(true);//标记遥测数据可用
   //  qDebug() << "Hydrogen battery data received，在_handleHydrogenBattery函数中";


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
        int listBatteryId = group->hydroId()->rawValue().toInt();
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
        qDebug()<<"运行到改的这里了";
    } else {
        int totalSeconds    = value.toInt();
        int hours           = totalSeconds / 3600;
        int minutes         = (totalSeconds % 3600) / 60;
        int seconds         = totalSeconds % 60;

        _timeRemainingStrFact.setRawValue(QString::asprintf("%02dH:%02dM:%02dS", hours, minutes, seconds));
    }
}
