#include "MavlinkToJson.h"
#include "Mqttlink.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QDebug>
#include"px4_custom_mode.h"

MavlinkToJson::MavlinkToJson(QObject* parent) : QObject(parent) {}

void MavlinkToJson::setContext(const QString& group, const QString& droneId,
                               const QString& from, const QString& ver)
{
    _group = group;
    _droneId = droneId;
    _from = from;
    _ver = ver;
}

void MavlinkToJson::handleMessage(LinkInterface* /*link*/, const mavlink_message_t& msg)
{
    switch (msg.msgid) {
        //心跳包消息
        case MAVLINK_MSG_ID_HEARTBEAT: {
            mavlink_heartbeat_t hb;
            mavlink_msg_heartbeat_decode(&msg, &hb);
            //算起飞时间
            static bool armedLast = false;          // 上一次 armed 状态
            static qint64 flightStartMSecs = 0;     // 起飞时间戳
            bool armed = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
            // 状态切换：未解锁 -> 解锁
            if (!armedLast && armed) {
                flightStartMSecs = QDateTime::currentMSecsSinceEpoch();
            }
            // 解锁 -> 上锁，清零
            if (armedLast && !armed)
            {
                flightStartMSecs = 0;
            }
            armedLast = armed;

            int flightTime = 0;
            if (armed && flightStartMSecs > 0)
            {
                qint64 now = QDateTime::currentMSecsSinceEpoch();
                flightTime = int((now - flightStartMSecs) / 1000);
            }

            QString flightMode = decodeFlightMode(hb.autopilot, hb.type, hb.custom_mode);//飞行模式

            QJsonObject json = makeHeader("status/heartbeat");
            json["sysid"] = msg.sysid;
            json["compid"] = msg.compid;
           // json["type"] = hb.type;
            //json["autopilot"] = hb.autopilot;
            // json["mode"] = hb.base_mode;

             //json["seq2"] = msg.seq;//mavlink本身的全链路上seq
            json["mode"] = flightMode;
            //json["custom_mode"] = static_cast<qint64>(hb.custom_mode);;
            // json["system_status"] = hb.system_status;
            json["status"] = statusName(hb);
            json["armed"] = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
            json["flightTime"] = flightTime;
            Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;
        }


        //飞机位置信息
            //需结合两个mavlink信号
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
        case MAVLINK_MSG_ID_GPS_RAW_INT:
            publishGeoPositionJson(msg);
            {
                if (_geoCache.globalUpdated && _geoCache.gpsUpdated){
                QJsonObject json = makeHeader("geo/position");
                json["lat"]    = _geoCache.lat;
                json["lon"]    = _geoCache.lon;
                json["alt"]    = _geoCache.alt;
                json["relAlt"] = _geoCache.relAlt;
                json["hdop"]   = _geoCache.hdop;
                json["vdop"]   = _geoCache.vdop;
                json["sat"]    = _geoCache.satellites;

                Mqttlink::instance()->publish(topicFor(), json, 0, false);
                 _geoCache.globalUpdated = _geoCache.gpsUpdated = false;
                }
            }
            break;
        //氢能电池信息
        case MAVLINK_MSG_ID_DATA32: {
            mavlink_data32_t d32;
            mavlink_msg_data32_decode(&msg, &d32);
            const uint8_t* d = d32.data;

                    // 按顺序插入 JSON
            QJsonObject json=makeHeader("power/hydrogen");
            // json["ts"] = static_cast<qint64>(QDateTime::currentDateTimeUtc().toMSecsSinceEpoch());
            // json["seq"] = static_cast<qint64>(++_seq);;
            // json["ver"] = _ver;
            // json["from"] = _from;
            // json["msg_name"] = "power/hydrogen";

            json["type"] = d32.type;
            json["len"] = d32.len;
            json["hydrogen_id"] = (int)d[19];
            json["compid"] = msg.compid;

            json["servo_current"]      = (int)u16le(d, 2);
            json["stack_voltage"]      = (int)u16le(d, 4);
            json["servo_voltage_mv"]   = (int)u16le(d, 6);
            json["bat_refuel_current"] = (int)u16le(d, 8);
            json["gas_tank_presure"]   = (int)u16le(d, 10);
            json["pipe_pressure"]      = (int)u16le(d, 12);

            json["pcb_temperature"]    = (int)d[14];
            json["stack_temperature"]  = (int)d[15];

            json["work_status"] = (int)d[16];
            json["falt_status"] = (int)d[17];
            json["self_check"]  = ((int)d[18] == 1) ? "已通过" : "未通过";

            //json["pack_id"] = (int)d[19];

            Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;/*"power/hydrogen"*/
        }
        //飞机横滚、俯仰、偏航
        case MAVLINK_MSG_ID_ATTITUDE: {
            mavlink_attitude_t attitude;
            mavlink_msg_attitude_decode(&msg, &attitude);

                    // 弧度转角度
            float roll_deg  = attitude.roll  * 180.0 / M_PI;
            float pitch_deg = attitude.pitch * 180.0 / M_PI;
            float yaw_deg   = attitude.yaw   * 180.0 / M_PI;

                    // 构建 JSON
            QJsonObject json=makeHeader("geo/attitude");
            json["roll"]  = roll_deg;
            json["pitch"] = pitch_deg;
            json["yaw"]   = yaw_deg;

            Mqttlink::instance()->publish(topicFor(), json, 0, false);

            break;
        }

            //方向速度
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED: {
            mavlink_local_position_ned_t pos;
            mavlink_msg_local_position_ned_decode(&msg, &pos);

            QJsonObject json=makeHeader("geo/velocity");
            json["vx"] = pos.vx;//x 方向速度 (m/s)
            json["vy"] = pos.vy;//y 方向速度 (m/s)
            json["vz"] = pos.vz;//z 方向速度 (m/s，注意NED坐标系，向下是正)

            Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;
        }
        //标准电池消息
        case MAVLINK_MSG_ID_BATTERY_STATUS: {
            mavlink_battery_status_t battery;
            mavlink_msg_battery_status_decode(&msg, &battery);

            QJsonObject json = makeHeader("status/battery");
            json["sysid"] = msg.sysid;
            json["compid"] = msg.compid;

            // 基本信息
            json["battery_id"] = battery.id;//电池id
            json["battery_function"] = batteryFunctionName(battery.battery_function);//电池功能
            json["battery_type"] = batteryTypeName(battery.type);//电池类型

            // 电气参数‘
            //battery.voltages 其实是一个 数组（uint16_t voltages[10]），而不是一个数值
            //在 MAVLink 的 BATTERY_STATUS 里，没有单独的 "总电压" 字段，而是要自己把 voltages[] 相加
            //json["voltage"] = battery.voltages[0] / 1000.0;     // 每一节电芯的电压

            json["current"] = battery.current_battery / 100.0;  // 电流 (A)
            json["current_consumed"] = battery.current_consumed; // 已消耗电流 (mAh)
            json["energy_consumed"] = battery.energy_consumed;  // 已消耗能量 (hJ)
            // 总电压


            float totalVoltage = 0.0;
            for (int i = 0; i < 10; i++) {
                if (battery.voltages[i] != UINT16_MAX) { // 过滤掉无效值
                    totalVoltage += battery.voltages[i] / 1000.0; // 转成 V 再加
                }
            }
            json["voltage"] = totalVoltage;
            QJsonArray cellsa;
            for (int i = 0; i < 10; i++) {
                if (battery.voltages[i] != UINT16_MAX) { // 过滤掉无效值
                    cellsa.append(battery.voltages[i] / 1000.0); // mV -> V
                }
            }
            json["cells"] = cellsa;

            // double totalVoltage = 0.0;
            // QJsonArray cellsArray;
            // for (int i = 0; i < 10; i++) {
            //     if (battery.voltages[i] != UINT16_MAX) { // 有效电压
            //         double cellV = battery.voltages[i] / 1000.0;
            //         totalVoltage += cellV;
            //         cellsArray.append(cellV);
            //     }
            // }
            // json["cells"]   = cellsArray;//单体电压，以数组形式出现
            // json["voltage"] = totalVoltage;//总电压

            // 状态信息
            json["temperature"] = battery.temperature;          // 温度 (c°C)
            json["charge_state"] = chargeStateName(battery.charge_state);//充电状态

            // 剩余电量
            if (battery.battery_remaining != -1) {
                json["soc"] = battery.battery_remaining;//剩余电量
            }

            // 各节电池电压，以json数组的形式
            // QJsonArray cells;
            // for (int i = 0; i < 10; i++) {
            //     if (battery.voltages[i] != UINT16_MAX) {
            //         QJsonObject cell;
            //         cell["number"] = i + 1;
            //         cell["voltage"] = battery.voltages[i] / 1000.0;
            //         cells.append(cell);
            //     }
            // }
            // json["cells"] = cells;

            // 时间戳
            json["timestamp"] = QDateTime::currentMSecsSinceEpoch();

            Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;
        }

        //云台
        case MAVLINK_MSG_ID_GIMBAL_DEVICE_ATTITUDE_STATUS:
        case MAVLINK_MSG_ID_GIMBAL_MANAGER_STATUS:
        case MAVLINK_MSG_ID_CAMERA_CAPTURE_STATUS:
            updateGimbalStatus(msg);
            {
                // 构建并发布 JSON
                QJsonObject json = makeHeader("gimbal/status");
                json["roll"]      = _gimbalCache.roll;
                json["pitch"]     = _gimbalCache.pitch;
                json["yaw"]       = _gimbalCache.yaw;
                json["mode"]      = _gimbalCache.mode;
                json["recording"] = _gimbalCache.recording;

                Mqttlink::instance()->publish(topicFor(), json, 0, false);
            }
            break;


        default:
            break;
    }
}
QJsonObject MavlinkToJson::makeHeader(const QString& msgName) {
    QJsonObject h;
    quint64 seq = ++_seqMap[msgName];
    h["seq"] = static_cast<qint64>(seq);

            // 每类消息独立时间戳
    h["ts"] = QDateTime::currentDateTimeUtc().toMSecsSinceEpoch();

    //Timestamp（时间戳）
    //h["ts"] = QDateTime::currentDateTimeUtc().toMSecsSinceEpoch();
    //Sequence（序列号）,单调递增，检测丢包
   //h["seq"] =static_cast<qint64>(++_seq);
    //Version（版本号）
    h["ver"] = _ver;
    //from:Sender（发送者标识）
    h["from"] = _from;
    //Message Name（消息名称）
    h["msg_name"] = msgName;
    return h;
}
QString MavlinkToJson::statusName(const mavlink_heartbeat_t& hb)
{
    switch (hb.system_status) {
        case MAV_STATE_UNINIT:            return "UNINIT";            // 未初始化
        case MAV_STATE_BOOT:              return "BOOT";              // 正在启动
        case MAV_STATE_CALIBRATING:       return "CALIBRATING";       // 正在校准
        case MAV_STATE_STANDBY:           return "STANDBY";           // 地面待命
        case MAV_STATE_ACTIVE:            return "ACTIVE";            // 飞行中（电机已接通）
        case MAV_STATE_CRITICAL:          return "CRITICAL";          // 故障保护，可导航
        case MAV_STATE_EMERGENCY:         return "EMERGENCY";         // 严重故障，失控坠落
        case MAV_STATE_POWEROFF:          return "POWEROFF";          // 正在关机
        case MAV_STATE_FLIGHT_TERMINATION:return "TERMINATION";       // 终止飞行（自毁/立即停止）
        default:
            return QString("UNKNOWN(%1)").arg(hb.system_status);
    }
}

// ----------------- PX4 Custom Mode 解码 -----------------
QString MavlinkToJson::px4ModeToString(uint32_t custom_mode) {
    // PX4 的 main_mode 位于 [16-23]，sub_mode 位于 [24-31]
    uint8_t main_mode = (custom_mode >> 16) & 0xFF;
    uint8_t sub_mode  = (custom_mode >> 24) & 0xFF;

    switch (main_mode) {
        case PX4_CUSTOM_MAIN_MODE_MANUAL: return "MANUAL";
        case PX4_CUSTOM_MAIN_MODE_STABILIZED: return "STABILIZED";
        case PX4_CUSTOM_MAIN_MODE_ACRO: return "ACRO";
        case PX4_CUSTOM_MAIN_MODE_RATTITUDE: return "RATTITUDE";
        case PX4_CUSTOM_MAIN_MODE_ALTCTL: return "ALTCTL";
        case PX4_CUSTOM_MAIN_MODE_OFFBOARD: return "OFFBOARD";
        case PX4_CUSTOM_MAIN_MODE_AUTO:
            switch(sub_mode) {
                case PX4_CUSTOM_SUB_MODE_AUTO_MISSION: return "AUTO_MISSION";
                case PX4_CUSTOM_SUB_MODE_AUTO_LOITER: return "AUTO_LOITER";
                case PX4_CUSTOM_SUB_MODE_AUTO_RTL: return "AUTO_RTL";
                case PX4_CUSTOM_SUB_MODE_AUTO_LAND: return "AUTO_LAND";
                case PX4_CUSTOM_SUB_MODE_AUTO_TAKEOFF: return "AUTO_TAKEOFF";
                case PX4_CUSTOM_SUB_MODE_AUTO_FOLLOW_TARGET: return "AUTO_FOLLOW_TARGET";
                case PX4_CUSTOM_SUB_MODE_AUTO_PRECLAND: return "AUTO_PRECLAND";
                case PX4_CUSTOM_SUB_MODE_AUTO_READY: return "AUTO_READY";
                case PX4_CUSTOM_SUB_MODE_AUTO_RTGS: return "AUTO_RTGS";
                default: return "AUTO_UNKNOWN";
            }
        default: return "UNKNOWN";
    }
}

// ----------------- ArduPilot Copter Mode 解码 -----------------
QString MavlinkToJson::apmCopterModeToString(uint32_t custom_mode) {
    switch(custom_mode) {
        case 0: return "STABILIZE";
        case 1: return "ACRO";
        case 2: return "ALT_HOLD";
        case 3: return "AUTO";
        case 4: return "GUIDED";
        case 5: return "LOITER";
        case 6: return "RTL";
        case 7: return "CIRCLE";
        case 9: return "LAND";
        case 13: return "SPORT";
        case 14: return "FLIP";
        case 15: return "AUTOTUNE";
        case 16: return "POS_HOLD";
        case 17: return "BRAKE";
        case 18: return "THROW";
        case 21: return "SMART_RTL";
        case 22: return "FLOWHOLD";
        case 23: return "FOLLOW";
        case 24: return "ZIGZAG";
        default: return "UNKNOWN";
    }
}

// ----------------- ArduPilot Plane Mode 解码 -----------------
QString MavlinkToJson::apmPlaneModeToString(uint32_t custom_mode) {
    switch(custom_mode) {
        case 0: return "MANUAL";
        case 1: return "CIRCLE";
        case 2: return "STABILIZE";
        case 3: return "TRAINING";
        case 4: return "ACRO";
        case 5: return "FLY_BY_WIRE_A";
        case 6: return "FLY_BY_WIRE_B";
        case 7: return "CRUISE";
        case 8: return "AUTOTUNE";
        case 10: return "AUTO";
        case 11: return "RTL";
        case 12: return "LOITER";
        case 13: return "TAKEOFF";
        case 14: return "AVOID_ADSB";
        case 15: return "GUIDED";
        default: return "UNKNOWN";
    }
}

// ----------------- ArduPilot Rover Mode 解码 -----------------
QString MavlinkToJson::apmRoverModeToString(uint32_t custom_mode) {
    switch(custom_mode) {
        case 0: return "MANUAL";
        case 1: return "ACRO";
        case 3: return "STEERING";
        case 4: return "HOLD";
        case 5: return "LOITER";
        case 6: return "FOLLOW";
        case 7: return "SIMPLE";
        case 8: return "DOCK";
        case 9: return "CIRCLE";
        case 10: return "AUTO";
        case 11: return "RTL";
        case 12: return "SMART_RTL";
        case 15: return "GUIDED";
        default: return "UNKNOWN";
    }
}
// ----------------- ArduPilot Sub Mode 解码 -----------------
QString MavlinkToJson::apmSubModeToString(uint32_t custom_mode) {
    switch(custom_mode) {
        case 0: return "STABILIZE";
        case 1: return "ACRO";
        case 2: return "ALT_HOLD";
        case 3: return "AUTO";
        case 4: return "GUIDED";
        case 5: case 6: case 8: case 10 ... 15: return "RESERVED";
        case 16: return "POSHOLD";
        case 19: return "MANUAL";
        case 20: return "MOTORDETECTION";
        case 21: return "SURFTRAK";
        default: return "UNKNOWN";
    }
}

// ----------------- 主解码函数 -----------------
QString MavlinkToJson::decodeFlightMode(uint8_t autopilot, uint8_t type, uint32_t custom_mode) {
    // ArduPilot 系列
    if (autopilot == 3 /* MAV_AUTOPILOT_ARDUPILOTMEGA */) {
        switch(type) {
            case 2: // MAV_TYPE_QUADROTOR
            case 3: // MAV_TYPE_COAXIAL
            case 4: // MAV_TYPE_HELICOPTER
            case 13: // MAV_TYPE_HEXAROTOR
            case 14: // MAV_TYPE_OCTOROTOR
            case 15: // MAV_TYPE_TRICOPTER
                return apmCopterModeToString(custom_mode);
            case 1: // MAV_TYPE_FIXED_WING
            case 19: case 20: case 21: case 22: case 23: case 24:
                return apmPlaneModeToString(custom_mode);
            case 10: // MAV_TYPE_GROUND_ROVER
                return apmRoverModeToString(custom_mode);
            case 12: // MAV_TYPE_SUBMARINE
                return apmSubModeToString(custom_mode);
            default:
                return "UNKNOWN";
        }
    }
    // PX4 系列
    else if (autopilot == 12 /* MAV_AUTOPILOT_PX4 */) {
        return px4ModeToString(custom_mode);
    }

    return "UNSUPPORTED_AUTOPILOT";
}


//全球位置信息转换
//将 MAVLink 消息转换成 geo/position
void MavlinkToJson::publishGeoPositionJson(const mavlink_message_t& msg)
{
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT: {
            mavlink_global_position_int_t pos;
            mavlink_msg_global_position_int_decode(&msg, &pos);
            if (pos.lat == 0 && pos.lon == 0) {
                _geoCache.relAlt = pos.relative_alt / 1000.0;
                _geoCache.alt    = pos.alt / 1000.0;
                return;
            }
            _geoCache.lat    = pos.lat / 1e7;//从 degE7 还原，原数据乘以10的7次方，还原/10的7次方
            _geoCache.lon    = pos.lon / 1e7;
            _geoCache.alt    = pos.alt / 1000.0;//毫米置换
            _geoCache.relAlt = pos.relative_alt / 1000.0;//毫米置换
             _geoCache.globalUpdated = true;//标志位收到
            break;
        }

        case MAVLINK_MSG_ID_GPS_RAW_INT: {
            mavlink_gps_raw_int_t gps;
            mavlink_msg_gps_raw_int_decode(&msg, &gps);
            _geoCache.hdop       = gps.eph / 100.0;
            _geoCache.vdop       = gps.epv / 100.0;
            _geoCache.satellites = gps.satellites_visible;
             _geoCache.gpsUpdated = true;//标志位收到
            break;
        }

        default:
            return;
    }


}

void MavlinkToJson::updateGimbalStatus(const mavlink_message_t& msg)
{
    switch (msg.msgid) {
        case MAVLINK_MSG_ID_GIMBAL_DEVICE_ATTITUDE_STATUS: {
            mavlink_gimbal_device_attitude_status_t att;
            mavlink_msg_gimbal_device_attitude_status_decode(&msg, &att);

            double q0 = att.q[0], q1 = att.q[1], q2 = att.q[2], q3 = att.q[3];
            _gimbalCache.roll  = qRadiansToDegrees(qAtan2(2*(q0*q1 + q2*q3), 1 - 2*(q1*q1 + q2*q2)));
            _gimbalCache.pitch = qRadiansToDegrees(qAsin(2*(q0*q2 - q3*q1)));
            _gimbalCache.yaw   = qRadiansToDegrees(qAtan2(2*(q0*q3 + q1*q2), 1 - 2*(q2*q2 + q3*q3)));
            break;
        }

        case MAVLINK_MSG_ID_GIMBAL_MANAGER_STATUS: {
            mavlink_gimbal_manager_status_t mgr;
            mavlink_msg_gimbal_manager_status_decode(&msg, &mgr);
            _gimbalCache.mode = (mgr.flags & GIMBAL_MANAGER_FLAGS_NEUTRAL) ? "NEUTRAL" : "LOCK";
            break;
        }

        case MAVLINK_MSG_ID_CAMERA_CAPTURE_STATUS: {
            mavlink_camera_capture_status_t cam;
            mavlink_msg_camera_capture_status_decode(&msg, &cam);
            _gimbalCache.recording = (cam.video_status == 1);
            break;
        }

        default:
            return; // 非 gimbal 消息，直接返回
    }
}

// 电池功能描述
QString MavlinkToJson::batteryFunctionName(uint8_t function) {
    switch (function) {
        case MAV_BATTERY_FUNCTION_UNKNOWN: return "unknown";//未知
        case MAV_BATTERY_FUNCTION_ALL: return "all";//主电池，整机供电
        case MAV_BATTERY_FUNCTION_PROPULSION: return "propulsion";//推进电池（专门给电机供电）
        case MAV_BATTERY_FUNCTION_AVIONICS: return "avionics";//航电电池（飞控/传感器/通信）
        case MAV_BATTERY_FUNCTION_PAYLOAD: return "payload";//载荷电池（比如云台、相机、任务载荷）
        default: return QString("unknown_%1").arg(function);
    }
}

// 电池类型描述
QString MavlinkToJson::batteryTypeName(uint8_t type) {
    switch (type) {
        case MAV_BATTERY_TYPE_UNKNOWN: return "unknown";
        case MAV_BATTERY_TYPE_LIPO: return "lipo";//锂聚合物
        case MAV_BATTERY_TYPE_LIFE: return "life";//磷酸铁锂
        case MAV_BATTERY_TYPE_LION: return "lion";//锂离子
        // case MAV_BATTERY_TYPE_NIMH: return "znimh";/镍氢

        default: return QString("unknown_%1").arg(type);
    }
}

// 充电状态描述
QString MavlinkToJson::chargeStateName(uint8_t state) {
    switch (state) {
        case MAV_BATTERY_CHARGE_STATE_UNDEFINED: return "undefined";
        case MAV_BATTERY_CHARGE_STATE_OK: return "ok";
        case MAV_BATTERY_CHARGE_STATE_LOW: return "low";
        case MAV_BATTERY_CHARGE_STATE_CRITICAL: return "critical";
        case MAV_BATTERY_CHARGE_STATE_EMERGENCY: return "emergency";
        case MAV_BATTERY_CHARGE_STATE_FAILED: return "failed";
        case MAV_BATTERY_CHARGE_STATE_UNHEALTHY: return "unhealthy";
        case MAV_BATTERY_CHARGE_STATE_CHARGING: return "charging";
        default: return QString("unknown_%1").arg(state);
    }
}
