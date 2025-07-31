#include "hydrogenbatteryhandler.h"


HydrogenBatteryHandler* HydrogenBatteryHandler::_instance = nullptr;

HydrogenBatteryHandler::HydrogenBatteryHandler(QObject *parent)
    : QObject{parent}

{
    qDebug()<<"调用了hydrogenbatteryhandler.h这个类哦";

}



HydrogenBatteryHandler* HydrogenBatteryHandler::instance()
{
    if (!_instance) {
        _instance = new HydrogenBatteryHandler();
    }
    return _instance;
}

// void HydrogenBatteryHandler::handleData32(const uint8_t* data, uint8_t len)
// {
//     if (len < 23) return; // 确保至少23字节有效负载

//     uint16_t batVoltage      = (data[0]  | (data[1] << 8));
//     uint16_t servoCurrent    = (data[2]  | (data[3] << 8));
//     uint16_t stackVoltage    = (data[4]  | (data[5] << 8));
//     uint16_t servoVoltage    = (data[6]  | (data[7] << 8));
//     uint16_t refuelCurrent   = (data[8]  | (data[9] << 8));
//     uint16_t tankPressure    = (data[10] | (data[11] << 8));
//     uint16_t pipePressure    = (data[12] | (data[13] << 8));
//     int16_t  pcbTemp         = (data[14] | (data[15] << 8));
//     int16_t  stackTemp       = (data[16] | (data[17] << 8));
//     uint8_t  workStatus      = data[18];
//     uint8_t  selfCheck       = data[19];
//     uint16_t faultStatus     = (data[20] | (data[21] << 8));
//     uint8_t  batteryId       = data[22];

//     emit dataUpdated(
//         batVoltage * 0.01f,
//         servoCurrent * 0.01f,
//         stackVoltage * 0.01f,
//         servoVoltage * 0.01f,
//         refuelCurrent * 0.01f,
//         tankPressure * 0.01f,
//         pipePressure * 0.01f,
//         pcbTemp * 0.01f,
//         stackTemp * 0.01f,
//         workStatus,
//         selfCheck,
//         faultStatus,
//         batteryId
//         );
//     qDebug() << "🔋 Hydrogen Battery Data Received:";
//     qDebug() << "电池电压 (V):"         << batVoltage * 0.01f;
//     qDebug() << "电机电流 (A):"         << servoCurrent * 0.01f;
//     qDebug() << "电堆电压 (V):"         << stackVoltage * 0.01f;
//     qDebug() << "电机电压 (V):"         << servoVoltage * 0.01f;
//     qDebug() << "补能电流 (A):"         << refuelCurrent * 0.01f;
//     qDebug() << "气罐压力 (MPa):"       << tankPressure * 0.01f;
//     qDebug() << "管道压力 (MPa):"       << pipePressure * 0.01f;
//     qDebug() << "主板温度 (°C):"        << pcbTemp * 0.01f;
//     qDebug() << "电堆温度 (°C):"        << stackTemp * 0.01f;
//     qDebug() << "设备状态:"             << QString("0x%1").arg(workStatus, 2, 16, QLatin1Char('0')).toUpper();
//     qDebug() << "开关机状态:" << ((workStatus & 0x80) ? "关机" : "开机");
//     qDebug() << "充电状态:"   << ((workStatus & 0x40) ? "未充电" : "充电中");
//     qDebug() << "放电状态:"   << ((workStatus & 0x20) ? "未放电" : "放电中");
//     qDebug() << "自检状态:"             << (selfCheck == 1 ? "通过" : "未通过");
//     qDebug() << "报警状态位:"           << QString("0x%1").arg(faultStatus, 4, 16, QLatin1Char('0')).toUpper();
//     qDebug() << "电池ID:"              << batteryId;

// }
void HydrogenBatteryHandler::handleData32(const uint8_t* data, uint8_t len) {
    if (len < 23) return;

    QVariantList list;
    list << QVariantMap{{"label", "电池电压"}, {"value", (data[0] | (data[1] << 8)) * 0.01f}, {"unit", "V"}}
         << QVariantMap{{"label", "电机电流"}, {"value", (data[2] | (data[3] << 8)) * 0.01f}, {"unit", "A"}}
         << QVariantMap{{"label", "电堆电压"}, {"value", (data[4] | (data[5] << 8)) * 0.01f}, {"unit", "V"}}
         << QVariantMap{{"label", "电机电压"}, {"value", (data[6] | (data[7] << 8)) * 0.01f}, {"unit", "V"}}
         << QVariantMap{{"label", "补能电流"}, {"value", (data[8] | (data[9] << 8)) * 0.01f}, {"unit", "A"}}
         << QVariantMap{{"label", "气罐压力"}, {"value", (data[10] | (data[11] << 8)) * 0.01f}, {"unit", "MPa"}}
         << QVariantMap{{"label", "管道压力"}, {"value", (data[12] | (data[13] << 8)) * 0.01f}, {"unit", "MPa"}}
         << QVariantMap{{"label", "主板温度"}, {"value", int16_t(data[14] | (data[15] << 8)) * 0.01f}, {"unit", "℃"}}
         << QVariantMap{{"label", "电堆温度"}, {"value", int16_t(data[16] | (data[17] << 8)) * 0.01f}, {"unit", "℃"}}
         << QVariantMap{{"label", "设备状态"}, {"value", data[18]}, {"unit", ""}}
         << QVariantMap{{"label", "自检状态"}, {"value", data[19]}, {"unit", ""}}
         << QVariantMap{{"label", "报警状态"}, {"value", QString("0x%1").arg((data[20] | (data[21] << 8)), 4, 16, QChar('0'))}, {"unit", ""}}
         << QVariantMap{{"label", "电池编号"}, {"value", data[22]}, {"unit", ""}};

    for (int i = 0; i < len; ++i) {
        qDebug() << QString("data[%1] = 0x%2").arg(i).arg(data[i], 2, 16, QChar('0'));
    }
    m_batteryInfoList = list;
    emit batteryInfoChanged();
}
