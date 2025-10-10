#ifndef MAVLINKTOJSON_H
#define MAVLINKTOJSON_H

#pragma once
#include <QObject>
#include <QJsonObject>
#include <QDateTime>
#include <QtMath>
#include<QTimer>
#include"Vehicle.h"

class Vehicle;  // 前向声明

class LinkInterface;
// extern "C" {
// #include <mavlink.h>
// }

class MavlinkToJson : public QObject {
    Q_OBJECT
   public:
    explicit MavlinkToJson(QObject* parent = nullptr);

    void setContext(const QString& group, const QString& droneId,
                    const QString& from, const QString& ver);

    //QString messageClassForMavlink(uint32_t msgid);//分发消息类型

   public slots:
    void handleMessage(LinkInterface* link, const mavlink_message_t& msg);
    void publishStatusFlight();//发送status/flight
    void publishStatusPayload();//发送status/Payload
   private:
    // 统一头
    QJsonObject makeHeader(const QString& msgName);

    void initRcMapping(Vehicle* vehicle);//rc映射
    //void handleRcChannels(Vehicle* vehicle);//处理通道

    // 主题：uav/<group>/<drone_id>/<msg_name>
    // QString topicFor(/*const QString& msgName*/) const
    // {
    //     if (_group.isEmpty())
    //         return QString("uav/%1").arg(_droneId/*, msgName*/);
    //     return QString("uav/%1/%2").arg(_group, _droneId/*, msgName*/);
    // }
    QString topicFor(const QString& messageClass,
                     const QString& group ,
                     const QString& droneId)const;


    //工具：读小端 u16
    static inline quint16 u16le(const uint8_t* d, int i)
    {
        return quint16(d[i]) | (quint16(d[i+1]) << 8);
    }
    void publishGeoPositionJson(const mavlink_message_t& msg);//方位等
    QString statusName(const mavlink_heartbeat_t& hb);//状态转换
    QString px4ModeToString(uint32_t custom_mode);//px4飞行模式
    QString apmCopterModeToString(uint32_t custom_mode);//apm
    QString apmPlaneModeToString(uint32_t custom_mode);
    QString apmRoverModeToString(uint32_t custom_mode);
    QString apmSubModeToString(uint32_t custom_mode);
    QString decodeFlightMode(uint8_t autopilot, uint8_t type, uint32_t custom_mode);

    void updateGimbalStatus(const mavlink_message_t& msg);//云台数据转换

    QString batteryFunctionName(uint8_t function);//标准电池功能
    QString batteryTypeName(uint8_t type);//标准电池类型
    QString chargeStateName(uint8_t state);//电池充电状态

   private:

    QTimer* _timer;


    //全球坐标位置
    struct GeoPositionCache {
        double lat = 0;
        double lon = 0;
        double alt = 0;
        double relAlt = 0;
        double hdop = 0;//水平精度因子，值越小越好，衡量GPS水平方向（经度和纬度）定位精度的衰减程度
        //通常情况下，VDOP值会比HDOP稍大，因为卫星主要分布在地平线上方，垂直方向的几何分布不如水平方向理想
        double vdop = 0;//垂直精度因子
        // 值越大越好（但质量比数量更重要）
        // 最少需要4颗卫星才能进行3D定位（经度、纬度、高度）
        // 通常6-8颗以上才能获得较好的定位精度
        // 卫星数量多且分布均匀时，HDOP/VDOP值通常会更好
        int satellites = 0;//卫星数量，参与解算定位的可见卫星数量

        bool gpsUpdated = false;//标志位，是否收到gps原始消息
        bool globalUpdated = false;//标志位，是否收到全球经纬度信号
    } _geoCache;



    //云台角度
    struct GimbalCache {
        double roll = 0;
        double pitch = 0;
        double yaw = 0;
        QString mode;
        bool recording;
    } _gimbalCache;



    //统一大json
    struct StateCache {
        QJsonObject heartbeat;//心跳包
        QJsonObject position;//gps位置信息
        // QJsonObject hydrogen;//氢电池信息
        // QJsonObject battery;//标准电池信息
        QMap<int, QJsonObject> batteries;   // battery_id -> 电池信息
        QMap<int, QJsonObject> hydrogens;   // hydrogen_id -> 氢电池信息
        QJsonObject attitude;//roll

        QJsonObject telemetry; // 信号、RSSI、SNR、TX/RX 速率

        QJsonObject velocity;//坐标

        QJsonObject rc;//遥控器
         QJsonObject gimble;//云台
    }_state;



    //rc映射
    struct RcMapping {
        int roll   ;
        int pitch ;
        int yaw  ;
        int throttle ;
        int mode    ;
        int gimbal  ;
    } _rcMapping;


    //信号
    struct TelemetryCache {
        bool signalUpdated = false;
        int signal = 0;
        int rssi = 0;
        float snr = 0;
        float txRate = 0;
        float rxRate = 0;
    }_telemetryCache;



    //处理数据
    struct FlightReport {
        struct State {
            QString mode;
            bool armed = false;
            QString status;
            int flightTime = 0;
        } state;

        struct Position {
            double lat = 0;
            double lon = 0;
            double alt = 0;
            double relAlt = 0;
            double hdop = 0;
            double vdop = 0;
            int sat = 0;
        } position;

        struct Attitude {
            double roll = 0;
            double pitch = 0;
            double yaw = 0;
        } attitude;

        struct Velocity {
            double vx = 0;
            double vy = 0;
            double vz = 0;
        } velocity;

        struct Telemetry {
            int signal = 0;
            int rssi = 0;
            double snr = 0;
            double txRate = 0;
            double rxRate = 0;
        } telemetry;

        struct RC {
            int roll = 0;
            int pitch = 0;
            int yaw = 0;
            int throttle = 0;
            int mode = 0;
            int gimbal = 0;
        } rc;

        struct Battery {
            double soc = 0;
            double voltage = 0;
            double current = 0;
            int remainingMah = 0;
            QVector<double> cells;
        } battery;

        struct Hydrogen {
            QString hydrogen_id;
            double battery_voltage = 0;
            double servo_current = 0;
            double stack_voltage = 0;
            double bat_refuel_current = 0;
            double gas_tank_presure = 0;
            double pipe_pressure = 0;
            double pcb_temperature = 0;
            double stack_temperature = 0;
            QString work_status;
            QString falt_status;
        } hydrogen;
    };


    QMap<QString, quint64> _seqMap; // 每种消息独立序列号
    // quint64 _seq = 0;
    QString _group = "h15-01";
    QString _droneId = "uav-1001";
    QString _from = "station";
    QString _ver  = "1.0.2";


};

#endif  // MAVLINKTOJSON_H
