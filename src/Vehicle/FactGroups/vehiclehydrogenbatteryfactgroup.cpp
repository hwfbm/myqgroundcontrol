#include "vehiclehydrogenbatteryfactgroup.h"
#include "QmlObjectListModel.h"
#include "Vehicle.h"

VehicleHydrogenBatteryFactGroup::VehicleHydrogenBatteryFactGroup(uint8_t id, QObject* parent)
: FactGroup(1000, ":/json/Vehicle/VehicleHydrogenBatteryFact.json", parent), _id(id),
      _batVoltageFact(0, _batVoltageFactName, FactMetaData::valueTypeUint16),
      _servoCurrentFact(0, _servoCurrentFactName, FactMetaData::valueTypeUint16),
      _stackVoltageFact(0, _stackVoltageFactName, FactMetaData::valueTypeUint16),
      _servoVoltageFact(0, _servoVoltageFactName, FactMetaData::valueTypeUint16),
      _batRefuelCurrentFact(0, _batRefuelCurrentFactName, FactMetaData::valueTypeUint16),
      _gasTankPressureFact(0, _gasTankPressureFactName, FactMetaData::valueTypeUint16),
      _pipePressureFact(0, _pipePressureFactName, FactMetaData::valueTypeUint16),
      _pcbTempFact(0, _pcbTempFactName, FactMetaData::valueTypeInt8),
      _stackTempFact(0, _stackTempFactName, FactMetaData::valueTypeInt8),
      _workStatusFact(0, _workStatusFactName, FactMetaData::valueTypeUint8),
      _faultStatusFact(0, _faultStatusFactName, FactMetaData::valueTypeUint8),
      _selfCheckFact(0,_selfCheckFactName, FactMetaData::valueTypeUint8),
      _idFact(0, _hydroIdFactName, FactMetaData::valueTypeUint8)
{
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           // 添加所有Fact到组中

    // _addFact(&_batVoltageFact,         "bat_voltage");
    // _addFact(&_servoCurrentFact,       "servo_current");
    // _addFact(&_stackVoltageFact,       "stack_voltage");
    // _addFact(&_servoVoltageFact,       "servo_voltage");
    // _addFact(&_batRefuelCurrentFact,   "bat_refuel_current");
    // _addFact(&_gasTankPressureFact,    "gas_tank_pressure");
    // _addFact(&_pipePressureFact,       "pipe_pressure");
    // _addFact(&_pcbTempFact,            "pcb_temp");
    // _addFact(&_stackTempFact,          "stack_temp");
    // _addFact(&_workStatusFact,         "work_status");
    // _addFact(&_faultStatusFact,        "fault_status");
    // _addFact(&_selfCheckFact,          "self_check");
    // _addFact(&_idFact,                 "hydroId");
          _addFact(&_batVoltageFact,       _batVoltageFactName);
         _addFact(&_servoCurrentFact,     _servoCurrentFactName);
_addFact(&_stackVoltageFact,     _stackVoltageFactName);
_addFact(&_servoVoltageFact,     _servoVoltageFactName);
_addFact(&_batRefuelCurrentFact, _batRefuelCurrentFactName);
_addFact(&_gasTankPressureFact,  _gasTankPressureFactName);
_addFact(&_pipePressureFact,     _pipePressureFactName);
_addFact(&_pcbTempFact,          _pcbTempFactName);
_addFact(&_stackTempFact,        _stackTempFactName);
_addFact(&_workStatusFact,       _workStatusFactName);
_addFact(&_faultStatusFact,      _faultStatusFactName);
_addFact(&_selfCheckFact,        _selfCheckFactName);
_addFact(&_idFact,               _hydroIdFactName);                                                    // 设置初始值
for (const QString& name : _nameToFactMap.keys()) {
    qDebug() << "[H2] 已注册 Fact:" << name;
}

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
    _idFact.setRawValue                (id);



}

// 静态入口函数：识别新 ID，创建对应 fact group
// 仅负责发现电池 ID、创建或注册 FactGroup，不解析数据。
void VehicleHydrogenBatteryFactGroup::handleMessageForFactGroupCreation(Vehicle* vehicle, const mavlink_message_t& message)
{
    if (message.msgid != MAVLINK_MSG_ID_DATA32)
        return;

    mavlink_data32_t payload;
    mavlink_msg_data32_decode(&message, &payload);

            // 你的约定：电池 ID 存在 data[22]
    uint8_t batteryId = payload.data[19];

    _findOrAddGroupById(vehicle, batteryId); // 动态创建/查找对应的电池组

   // qDebug() << "handleMessageForFactGroupCreation：氢电池ID = " << batteryId;

}


//已经注册的 FactGroup 接收消息，只处理数据解析与赋值
void VehicleHydrogenBatteryFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
        case MAVLINK_MSG_ID_DATA32:
            _handleHydrogenBattery(vehicle, message);
            break;
        default:
            //qDebug() << "HydrogenBatteryFactGroup 未处理的消息 ID:" << message.msgid;
            break;
    }
}




//被 handleMessage 调用，专门处理 MAVLINK_MSG_ID_DATA32 消息的解析
void VehicleHydrogenBatteryFactGroup::_handleHydrogenBattery(Vehicle* vehicle, const mavlink_message_t& message)
{

    mavlink_data32_t data;
    mavlink_msg_data32_decode(&message, &data);

    if (data.type == 100 && data.len >= 20) {
        uint16_t bat_voltage         = data.data[0] | (data.data[1] << 8);
        uint16_t servo_current       = data.data[2] | (data.data[3] << 8);
        uint16_t stack_voltage       = data.data[4] | (data.data[5] << 8);
        uint16_t servo_voltage       = data.data[6] | (data.data[7] << 8);
        uint16_t bat_refuel_current  = data.data[8] | (data.data[9] << 8);
        uint16_t gas_tank_pressure   = data.data[10] | (data.data[11] << 8);
        uint16_t pipe_pressure       = data.data[12] | (data.data[13] << 8);
        int8_t   pcb_temp            = static_cast<int8_t>(data.data[14]);
        int8_t   stack_temp          = static_cast<int8_t>(data.data[15]);
        uint8_t  work_status         = data.data[16];
        uint8_t  fault_status        = data.data[17];
        uint8_t  self_check          = data.data[18];
        uint8_t  id                  = data.data[19];

        VehicleHydrogenBatteryFactGroup* group = _findOrAddGroupById(vehicle, id);
            group->_batVoltageFact.setRawValue(bat_voltage / 1000.0);
            group->_servoCurrentFact.setRawValue(servo_current / 1000.0);
            group->_stackVoltageFact.setRawValue(stack_voltage / 1000.0);
            group->_servoVoltageFact.setRawValue(servo_voltage / 1000.0);
            group->_batRefuelCurrentFact.setRawValue(bat_refuel_current);
            group->_gasTankPressureFact.setRawValue(gas_tank_pressure);
            group->_pipePressureFact.setRawValue(pipe_pressure);
            group->_workStatusFact.setRawValue(work_status);
            group->_faultStatusFact.setRawValue(fault_status);
            group->_selfCheckFact.setRawValue(self_check);
            group->_stackTempFact.setRawValue(stack_temp);
            group->_pcbTempFact.setRawValue(pcb_temp);
            group->_idFact.setRawValue(id);

        group->_setTelemetryAvailable(true);

        //qDebug() << "[HydrogenBattery] 更新完毕 ID = " << id;

    }
}



//静态函数，根据电池 ID 自动管理 QmlObjectListModel
VehicleHydrogenBatteryFactGroup* VehicleHydrogenBatteryFactGroup::_findOrAddGroupById(Vehicle* vehicle, uint8_t id)
{
    if (!vehicle) {
        qWarning() << "vehicle 为空";
        return nullptr;
    }

    QmlObjectListModel* batteries = vehicle->hydrogenBatteries();
    qDebug() << "batteries:" << batteries;
    if (!batteries) {
        qWarning() << "hydrogenBatteries() 返回 nullptr";
        return nullptr;
    }

    for (int i = 0; i < batteries->count(); i++) {
        VehicleHydrogenBatteryFactGroup* group = batteries->value<VehicleHydrogenBatteryFactGroup*>(i);
        if (!group) {
            qWarning() << "batteries->value 返回 nullptr，index=" << i;
            continue;
        }

        auto hydroIdFact = group->hydroId();
        if (!hydroIdFact) {
            qWarning() << "group->hydroId() 返回 nullptr，index=" << i;
            continue;
        }

        int groupId = hydroIdFact->rawValue().toInt();
       // qDebug() << "group id =" << groupId;

        if (groupId == id) {
            qDebug() << "[H2] 已存在电池组 ID=" << id << ", batteries model size=" << batteries->count();
            return group;
        } else if (groupId > id) {
            VehicleHydrogenBatteryFactGroup* newGroup = new VehicleHydrogenBatteryFactGroup(id, batteries);
            qDebug() << "[H2] 插入 HydrogenBatteryGroup id=" << id << " 对象地址=" << newGroup;
            batteries->insert(i, newGroup);
            vehicle->_addFactGroup(newGroup, QString("hydrogen_battery_%1").arg(id));
            emit vehicle->hydrogenBatteriesChanged();  //插入时也要 emit
            //qDebug() << "emit vehicle->hydrogenBatteriesChanged() "<<"count="<<batteries->count ();
            return newGroup;
        }
    }

    VehicleHydrogenBatteryFactGroup* newGroup = new VehicleHydrogenBatteryFactGroup(id, batteries);
    //qDebug() << "[H2] 追加 HydrogenBatteryGroup id=" << id << " 对象地址=" << newGroup;
    batteries->append(newGroup);
    vehicle->_addFactGroup(newGroup, QString("hydrogen_battery_%1").arg(id));
    emit vehicle->hydrogenBatteriesChanged();  //末尾追加时也 emit
               //qDebug() << "emit vehicle->hydrogenBatteriesChanged() "<<"count="<<batteries->count ();
    return newGroup;
}




