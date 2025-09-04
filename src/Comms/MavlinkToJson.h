#ifndef MAVLINKTOJSON_H
#define MAVLINKTOJSON_H

#pragma once
#include <QObject>
#include <QJsonObject>
#include <QDateTime>
#include <QtMath>



class LinkInterface;
extern "C" {
#include <mavlink.h>
}

class MavlinkToJson : public QObject {
    Q_OBJECT
   public:
    explicit MavlinkToJson(QObject* parent = nullptr);

    void setContext(const QString& group, const QString& droneId,
                    const QString& from, const QString& ver);

   public slots:
    void handleMessage(LinkInterface* link, const mavlink_message_t& msg);

   private:
    // 统一头
    QJsonObject makeHeader(const QString& msgName);

            // 主题：uav/<group>/<drone_id>/<msg_name>
    QString topicFor(/*const QString& msgName*/) const
    {
        if (_group.isEmpty())
            return QString("uav/%1").arg(_droneId/*, msgName*/);
        return QString("uav/%1/%2").arg(_group, _droneId/*, msgName*/);
    }

            // 工具：读小端 u16
    static inline quint16 u16le(const uint8_t* d, int i) {
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
        QString mode = "LOCK";
        bool recording = false;
    } _gimbalCache;

    QMap<QString, quint64> _seqMap; // 每种消息独立序列号
    // quint64 _seq = 0;
    QString _group = "factory-01";
    QString _droneId = "uav-1001";
    QString _from = "station";
    QString _ver  = "1.0.1";


};

#endif  // MAVLINKTOJSON_H
