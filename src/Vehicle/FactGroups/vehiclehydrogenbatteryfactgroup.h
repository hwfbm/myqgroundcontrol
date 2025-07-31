#ifndef VEHICLEHYDROGENBATTERYFACTGROUP_H
#define VEHICLEHYDROGENBATTERYFACTGROUP_H
#pragma once      //用于防止头文件被多次包含（即防止重复包含）。它的作用是告诉编译器：“这个文件只编译一次”，从而避免重复定义、重复声明等问题。
#include "FactGroup.h"
#include "QGCMAVLink.h"
class Vehicle;
class VehicleHydrogenBatteryFactGroup : public FactGroup {
    Q_OBJECT

    Q_PROPERTY(Fact* batVoltage         READ batVoltage         CONSTANT)
    Q_PROPERTY(Fact* servoCurrent       READ servoCurrent       CONSTANT)
    Q_PROPERTY(Fact* stackVoltage       READ stackVoltage       CONSTANT)
    Q_PROPERTY(Fact* servoVoltage       READ servoVoltage       CONSTANT)
    Q_PROPERTY(Fact* batRefuelCurrent   READ batRefuelCurrent   CONSTANT)
    Q_PROPERTY(Fact* gasTankPressure    READ gasTankPressure    CONSTANT)
    Q_PROPERTY(Fact* pipePressure       READ pipePressure       CONSTANT)
    Q_PROPERTY(Fact* pcbTemp            READ pcbTemp            CONSTANT)
    Q_PROPERTY(Fact* stackTemp          READ stackTemp          CONSTANT)
    Q_PROPERTY(Fact* workStatus         READ workStatus         CONSTANT)
    Q_PROPERTY(Fact* faultStatus        READ faultStatus        CONSTANT)
    Q_PROPERTY(Fact* selfCheck          READ selfCheck          CONSTANT)
    Q_PROPERTY(Fact* hydroId            READ hydroId            CONSTANT)


public:
    uint8_t _id;
    Fact* batVoltage        () { return &_batVoltageFact; }
    Fact* servoCurrent      () { return &_servoCurrentFact; }
    Fact* stackVoltage      () { return &_stackVoltageFact; }
    Fact* servoVoltage      () { return &_servoVoltageFact; }
    Fact* batRefuelCurrent  () { return &_batRefuelCurrentFact; }
    Fact* gasTankPressure   () { return &_gasTankPressureFact; }
    Fact* pipePressure      () { return &_pipePressureFact; }
    Fact* pcbTemp           () { return &_pcbTempFact; }
    Fact* stackTemp         () { return &_stackTempFact; }
    Fact* workStatus        () { return &_workStatusFact; }
    Fact* faultStatus       () { return &_faultStatusFact; }
    Fact* selfCheck         () { return &_selfCheckFact; }
    Fact* hydroId           () { return &_idFact; } // 用于表示氢电池ID

    VehicleHydrogenBatteryFactGroup(uint8_t id,QObject* parent = nullptr);


    static void handleMessageForFactGroupCreation(Vehicle* vehicle, const mavlink_message_t& message);

    void handleMessage(Vehicle* vehicle, mavlink_message_t& message) override;
    void _handleHydrogenBattery(Vehicle* vehicle, const mavlink_message_t& message);
    static VehicleHydrogenBatteryFactGroup* _findOrAddGroupById(Vehicle* vehicle, uint8_t id);

    uint8_t id() const { return _id; }





private:
    //对应上述每个名称都有一个 Fact 成员变量，用于存储具体值



    //Fact 名称注册为 _nameToFactMap 的键名，便于自动注册与 UI 显示
    const QString _batVoltageFactName        = QStringLiteral("bat_voltage");
    const QString _servoCurrentFactName      = QStringLiteral("servo_current");
    const QString _stackVoltageFactName      = QStringLiteral("stack_voltage");
    const QString _servoVoltageFactName      = QStringLiteral("servo_voltage");
    const QString _batRefuelCurrentFactName  = QStringLiteral("bat_refuel_current");
    const QString _gasTankPressureFactName   = QStringLiteral("gas_tank_pressure");
    const QString _pipePressureFactName      = QStringLiteral("pipe_pressure");
    const QString _pcbTempFactName           = QStringLiteral("pcb_temp");
    const QString _stackTempFactName         = QStringLiteral("stack_temp");
    const QString _workStatusFactName        = QStringLiteral("work_status");
    const QString _faultStatusFactName       = QStringLiteral("fault_status");
    const QString _selfCheckFactName         = QStringLiteral("self_check");
    const QString _hydroIdFactName           = QStringLiteral("hydroId");


    Fact _batVoltageFact;
    Fact _servoCurrentFact;
    Fact _stackVoltageFact;
    Fact _servoVoltageFact;
    Fact _batRefuelCurrentFact;
    Fact _gasTankPressureFact;
    Fact _pipePressureFact;
    Fact _pcbTempFact;
    Fact _stackTempFact;
    Fact _workStatusFact;
    Fact _faultStatusFact;
    Fact _selfCheckFact;
    Fact _idFact;




};

#endif  // VEHICLEHYDROGENBATTERYFACTGROUP_H
