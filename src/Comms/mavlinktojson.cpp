#include "MavlinkToJson.h"
#include "Mqttlink.h"
#include <QJsonArray>
#include <QJsonDocument>
#include <QDebug>
#include"px4_custom_mode.h"
#include "QGCApplication.h"
#include "MultiVehicleManager.h"
#include "ParameterManager.h"





MavlinkToJson::MavlinkToJson(QObject* parent) : QObject(parent),
                                                _timer(new QTimer(this))
{
    connect(_timer, &QTimer::timeout, this, &MavlinkToJson::publishStatusFlight);//发布
    connect(_timer, &QTimer::timeout, this, &MavlinkToJson::publishStatusPayload);

    //异步，防止初始化时候，保证MultiVehicleManager单例创建成功，Vehicle 对象也可能还没创建
    // QTimer::singleShot是一个静态函数，用于安排一个只执行一次的定时器，它会在指定的时间间隔过后，触发一个操作
    //0 毫秒并不意味着“立即执行”，而是意味着“尽可能快地在下一个可用的时间点执行”，但这个时间点是在当前代码执行完毕之后
    //将代码段推迟到当前函数执行完毕后、下一个事件循环中执行
    //这是上下文对象（Context Object），它的作用是：如果 this 对象被销毁了，那么这个定时器事件将会被自动取消，防止在对象已销毁后还去执行其成员函数，从而导致程序崩溃。
    //等MavlinkToJson 构造函数完成之后执行函数体
    QTimer::singleShot(0, this, [this](){
        MultiVehicleManager* mvm = MultiVehicleManager::instance();//拿到单例对象
        if (mvm) {
            connect(mvm, &MultiVehicleManager::activeVehicleChanged, this, [this](Vehicle* vehicle){
                if (vehicle) {
                   // connect(vehicle, &Vehicle::rcChannelsChanged, this, &MavlinkToJson::handleRcChannels);

                    initRcMapping(vehicle);
                }
                else//未连接vehicle
                {
                    //flight
                    _state.batteries.clear();
                    _state.hydrogens.clear();
                    _state.heartbeat = QJsonObject();
                    _state.position = QJsonObject();
                    _state.attitude = QJsonObject();
                    _state.velocity = QJsonObject();
                    _state.telemetry = QJsonObject();
                    _state.rc = QJsonObject();    // RcMapping();


                    //payload
                    _state.gimble = QJsonObject();
                }


            });
        }
        // 如果当前已有活跃 Vehicle，立即初始化
        if (mvm->activeVehicle()) {
            initRcMapping(mvm->activeVehicle());
        }
    });


    _timer->start(10000);  // 10s
}






//status的public
void MavlinkToJson::publishStatusFlight()
{
    QJsonObject json=makeHeader("flight");
    json["state"] = _state.heartbeat;
    json["position"]       = _state.position;
    // json["hydrogen"]  = _state.hydrogen;
    // json["battery"]   = _state.battery;
    QJsonArray batteryArray;
    for (auto it = _state.batteries.begin(); it != _state.batteries.end(); ++it) {
        batteryArray.append(it.value());
    }
    json["battery"] = batteryArray;

    QJsonArray hydrogenArray;
    for (auto it = _state.hydrogens.begin(); it != _state.hydrogens.end(); ++it) {
        hydrogenArray.append(it.value());
    }
    json["hydrogen"] = hydrogenArray;
    // ---- Battery ----
    // QJsonArray batteryArray;
    // for (auto it = _state.batteries.begin(); it != _state.batteries.end(); ) {
    //     if (it.value().isEmpty()) {
    //         // 遇到空的就顺手清掉
    //         it = _state.batteries.erase(it);
    //     } else {
    //         batteryArray.append(it.value());
    //         ++it;
    //     }
    // }
    // json["battery"] = batteryArray;

    //         // ---- Hydrogen ----
    // QJsonArray hydrogenArray;
    // for (auto it = _state.hydrogens.begin(); it != _state.hydrogens.end(); ) {
    //     if (it.value().isEmpty()) {
    //         it = _state.hydrogens.erase(it);
    //     } else {
    //         hydrogenArray.append(it.value());
    //         ++it;
    //     }
    // }
    // json["hydrogen"] = hydrogenArray;
    json["attitude"]  = _state.attitude;//海拔
     json["position"]  = _state.position;//海拔
    json["velocity"]  = _state.velocity; //坐标
    // ----  ----
    json["telemetry"] = _state.telemetry;  // 直接放入 QJsonObject
    //json["gimbal"]    = _state.gimble;
    json["rc"]    = _state.rc;

    QString topic = topicFor("status", "", "");  //飞控不传 group/droneId，则默认用 _group 和 _droneId
    qDebug()<<"topic的值:"<<topic;
    Mqttlink::instance()->publish(topic, json, 0, false);
}
//status的public
void MavlinkToJson::publishStatusPayload()
{
    QJsonObject json=makeHeader("Payload");

    json["gimbal"]    = _state.gimble;
    QString topic = topicFor("status", "", "");  //飞控不传 group/droneId，则默认用 _group 和 _droneId
    qDebug()<<"topic的值:"<<topic;
    Mqttlink::instance()->publish(topic, json, 0, false);
}

//暂时不用
void MavlinkToJson::setContext(const QString& group, const QString& droneId,
                               const QString& from, const QString& ver)
{
    _group = group;
    _droneId = droneId;
    _from = from;
    _ver = ver;
}

// void MavlinkToJson::handleRcChannels(Vehicle* vehicle)
// {
//     QJsonObject rcObj;

//     auto getChannelValue = [vehicle](int chan) -> int {
//         if (chan < 1) return -1;        // 无效映射
//         return vehicle->rcValue(chan-1); // QGC 内部是 0-based，飞控参数是 1-based
//     };

//     rcObj["roll"]     = getChannelValue(_rcMapping.roll);
//     rcObj["pitch"]    = getChannelValue(_rcMapping.pitch);
//     rcObj["yaw"]      = getChannelValue(_rcMapping.yaw);
//     rcObj["throttle"] = getChannelValue(_rcMapping.throttle);
//     rcObj["mode"]     = getChannelValue(_rcMapping.mode);
//     rcObj["gimbal"]   = getChannelValue(_rcMapping.gimbal);

//     _state.rc = rcObj;  // 存到你的状态结构体
// }


// QString MavlinkToJson::messageClassForMavlink(uint32_t msgid) {
//     switch (msgid) {
//         case MAVLINK_MSG_ID_HEARTBEAT:
//         case MAVLINK_MSG_ID_SYS_STATUS:
//         case MAVLINK_MSG_ID_BATTERY_STATUS:
//         case MAVLINK_MSG_ID_DATA32:
//             return "status";

//         case MAVLINK_MSG_ID_GIMBAL_DEVICE_ATTITUDE_STATUS:
//         case MAVLINK_MSG_ID_GIMBAL_MANAGER_STATUS:
//         case MAVLINK_MSG_ID_CAMERA_CAPTURE_STATUS:
//             return "payload";

//         case MAVLINK_MSG_ID_COMMAND_LONG:
//         case MAVLINK_MSG_ID_SET_MODE:
//             return "ctl";

//         case MAVLINK_MSG_ID_MISSION_ITEM:
//         case MAVLINK_MSG_ID_MISSION_ACK:
//             return "mission";

//         default:
//             return "status"; // 默认
//     }
// }

//消息转换
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

            QJsonObject json /*= makeHeader("status/heartbeat")*/;
            //topic_name
            json["sysid"] = msg.sysid;
            json["compid"] = msg.compid;
            //json["type"] = hb.type;
            //json["autopilot"] = hb.autopilot;
            // json["mode"] = hb.base_mode;

                    //json["seq2"] = msg.seq;//mavlink本身的全链路上seq
            json["mode"] = flightMode;
            //json["custom_mode"] = static_cast<qint64>(hb.custom_mode);;
            // json["system_status"] = hb.system_status;
            json["status"] = statusName(hb);
            json["armed"] = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
            json["flightTime"] = flightTime;

             _state.heartbeat = json;

            //Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;
        }


        //飞机位置信息
        //需结合两个mavlink信号
        //position
        case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
        case MAVLINK_MSG_ID_GPS_RAW_INT:
            publishGeoPositionJson(msg);
            {
                if (_geoCache.globalUpdated && _geoCache.gpsUpdated){
                    QJsonObject json /*= makeHeader("geo/position")*/;
                    json["lat"]    = _geoCache.lat;
                    json["lon"]    = _geoCache.lon;
                    json["alt"]    = _geoCache.alt;
                    json["relAlt"] = _geoCache.relAlt;
                    json["hdop"]   = _geoCache.hdop;
                    json["vdop"]   = _geoCache.vdop;
                    json["sat"]    = _geoCache.satellites;
                     _state.position = json;
                   // Mqttlink::instance()->publish(topicFor(), json, 0, false);
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
            QJsonObject json/*=makeHeader("power/hydrogen")*/;
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
            json["servo_voltage"]   = (int)u16le(d, 6);
            json["bat_refuel_current"] = (int)u16le(d, 8);//电池补能电流
            json["gas_tank_presure"]   = (int)u16le(d, 10);
            json["pipe_pressure"]      = (int)u16le(d, 12);

            json["pcb_temperature"]    = (int)d[14];
            json["stack_temperature"]  = (int)d[15];

            json["work_status"] = (int)d[16];
            json["falt_status"] = (int)d[17];
            json["self_check"]  = ((int)d[18] == 1) ? "已通过" : "未通过";

                    //json["pack_id"] = (int)d[19];
              _state.hydrogens[(int)d[19]] = json;
            //Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;/*"power/hydrogen"*/
        }

            //飞机横滚、俯仰、偏航altitude
        case MAVLINK_MSG_ID_ATTITUDE: {
            mavlink_attitude_t attitude;
            mavlink_msg_attitude_decode(&msg, &attitude);

                    // 弧度转角度
            float roll_deg  = attitude.roll  * 180.0 / M_PI;
            float pitch_deg = attitude.pitch * 180.0 / M_PI;
            float yaw_deg   = attitude.yaw   * 180.0 / M_PI;

                    // 构建 JSON
            QJsonObject json/*=makeHeader("geo/attitude")*/;
            json["roll"]  = roll_deg;
            json["pitch"] = pitch_deg;
            json["yaw"]   = yaw_deg;
             _state.attitude = json;
            //Mqttlink::instance()->publish(topicFor(), json, 0, false);

            break;
        }

        //发送无线电/遥控链路状态的标准消息
        case MAVLINK_MSG_ID_RADIO_STATUS: {
            mavlink_radio_status_t rs;
            mavlink_msg_radio_status_decode(&msg, &rs);

            QJsonObject json;
            json["signal"] = rs.remrssi;//信号强度
            json["rssi"]   = rs.rssi;//接收信号强度指示
            json["snr"]    = rs.noise;//信噪比
            json["txRate"] = rs.txbuf;//发送速率
            json["rxRate"] = rs.rxerrors;//接收速率
            _state.telemetry = json;
            break;
        }




        //坐标轴方向速度
        case MAVLINK_MSG_ID_LOCAL_POSITION_NED: {
            mavlink_local_position_ned_t pos;
            mavlink_msg_local_position_ned_decode(&msg, &pos);

            QJsonObject json/*=makeHeader("geo/velocity")*/;
            json["vx"] = pos.vx;//x 方向速度 (m/s)
            json["vy"] = pos.vy;//y 方向速度 (m/s)
            json["vz"] = pos.vz;//z 方向速度 (m/s，注意NED坐标系，向下是正)

            _state.velocity = json;
                      //Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;
        }
        //标准电池消息
        case MAVLINK_MSG_ID_BATTERY_STATUS: {
            mavlink_battery_status_t battery;
            mavlink_msg_battery_status_decode(&msg, &battery);

            QJsonObject json /*= makeHeader("status/battery")*/;
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

                    // 剩余电量百分比，多块电池取平均
            if (battery.battery_remaining != -1) {
                json["soc"] = battery.battery_remaining;//剩余电量
            }
            //todo:电池剩余容量
            json["remainingMah"]=0;

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

              _state.batteries[battery.id] = json;
            //Mqttlink::instance()->publish(topicFor(), json, 0, false);
            break;
        }

        //todo:遥控器通道映射
        case MAVLINK_MSG_ID_RC_CHANNELS: {
            mavlink_rc_channels_t rc;
            mavlink_msg_rc_channels_decode(&msg, &rc);
            qDebug() << "RC_CHANNELS 信号发送了";
            auto getChannel = [&](int mapIndex) -> int {
                if (mapIndex < 1 || mapIndex > 18) return -1;
                switch (mapIndex) {
                    case 1: return rc.chan1_raw;
                    case 2: return rc.chan2_raw;
                    case 3: return rc.chan3_raw;
                    case 4: return rc.chan4_raw;
                    case 5: return rc.chan5_raw;
                    case 6: return rc.chan6_raw;
                    case 7: return rc.chan7_raw;
                    case 8: return rc.chan8_raw;
                    case 9: return rc.chan9_raw;
                    case 10: return rc.chan10_raw;
                    case 11: return rc.chan11_raw;
                    case 12: return rc.chan12_raw;
                    case 13: return rc.chan13_raw;
                    case 14: return rc.chan14_raw;
                    case 15: return rc.chan15_raw;
                    case 16: return rc.chan16_raw;
                    case 17: return rc.chan17_raw;
                    case 18: return rc.chan18_raw;
                    default: return -1;
                }
            };

            QJsonObject json;
            json["roll"]     = getChannel(_rcMapping.roll);
            json["pitch"]    = getChannel(_rcMapping.pitch);
            json["yaw"]      = getChannel(_rcMapping.yaw);
            json["throttle"] = getChannel(_rcMapping.throttle);
            json["mode"]     = getChannel(_rcMapping.mode);
            json["gimbal"]   = getChannel(_rcMapping.gimbal);

            _state.rc = json;
            break;
        }


        //云台
        case MAVLINK_MSG_ID_GIMBAL_DEVICE_ATTITUDE_STATUS:
        case MAVLINK_MSG_ID_GIMBAL_MANAGER_STATUS:
        case MAVLINK_MSG_ID_CAMERA_CAPTURE_STATUS:
            updateGimbalStatus(msg);
            {
                QJsonObject json /*= makeHeader("gimbal/status")*/;
                json["roll"]      = _gimbalCache.roll;
                json["pitch"]     = _gimbalCache.pitch;
                json["yaw"]       = _gimbalCache.yaw;
                json["mode"]      = _gimbalCache.mode;
                json["recording"] = _gimbalCache.recording;
                _state.gimble = json;
               // Mqttlink::instance()->publish(topicFor(), json, 0, false);
            }
            break;
            default:
                break;
    }
}


//真实链路使用
void MavlinkToJson::initRcMapping(Vehicle* vehicle) {
    if (!vehicle) return;

    auto* params = vehicle->parameterManager();
    auto getParam = [params](const char* name, int defaultVal) -> int {
        if (!params) return defaultVal;
        auto fact = params->getParameter(-1, name);
        if (!fact) return defaultVal;
        return fact->rawValue().toInt();
    };

    //PX4 优先，PX4 的 映射是固定参数
    int roll     = getParam("RC_MAP_ROLL",     -1);
    int pitch    = getParam("RC_MAP_PITCH",    -1);
    int yaw      = getParam("RC_MAP_YAW",      -1);
    int throttle = getParam("RC_MAP_THROTTLE", -1);
    int mode     = getParam("RC_MAP_MODE_SW",  -1);
    int gimbal   = getParam("RC_MAP_AUX1",     -1);

    //如果 PX4 参数没取到，尝试 APM
    //如果某个 RCx_FUNCTION = 0，那就说明这个通道未映射
    if (roll == -1) {
        for (int i = 1; i <= 16; i++) {
            QString pname = QString("RC%1_FUNCTION").arg(i);
            int func = getParam(pname.toUtf8().constData(), -1);
            if (func == 1) roll = i;       // Roll
            if (func == 2) pitch = i;      // Pitch
            if (func == 3) throttle = i;   // Throttle
            if (func == 4) yaw = i;        // Yaw
        }
    }

    // 模式通道在 APM 里一般叫 FLTMODE_CH
    if (mode == -1) {
        mode = getParam("FLTMODE_CH", -1);
    }

            // 保存到成员
    _rcMapping.roll     = roll;
    _rcMapping.pitch    = pitch;
    _rcMapping.yaw      = yaw;
    _rcMapping.throttle = throttle;
    _rcMapping.mode     = mode;
    _rcMapping.gimbal   = gimbal;

    qDebug() << "[RC Mapping] roll=" << roll
             << " pitch=" << pitch
             << " yaw=" << yaw
             << " throttle=" << throttle
             << " mode=" << mode
             << " gimbal=" << gimbal;
}

//mock用
// void MavlinkToJson::initRcMapping(Vehicle* vehicle) {
//     if (!vehicle) return;

//     // 先固定前 4 个基础通道
//     _rcMapping.roll     = 1;
//     _rcMapping.pitch    = 2;
//     _rcMapping.throttle = 3;
//     _rcMapping.yaw      = 4;

//     // Mode/Gimbal 可选读取参数
//     auto* params = vehicle->parameterManager();
//     auto getParam = [params](const char* name, int defaultVal) -> int {
//         auto fact = params->getParameter(-1, name);
//         return fact ? fact->rawValue().toInt() : defaultVal;
//     };

//     _rcMapping.mode   = getParam("RC_MAP_MODE_SW", 5); // 默认 5 通道
//     _rcMapping.gimbal = getParam("RC_MAP_AUX1", 6);    // 默认 6 通道，可选
// }




// //消息转换
// void MavlinkToJson::handleMessage(LinkInterface* /*link*/, const mavlink_message_t& msg)
// {
//     switch (msg.msgid) {
//         //心跳包消息
//         case MAVLINK_MSG_ID_HEARTBEAT: {
//             mavlink_heartbeat_t hb;
//             mavlink_msg_heartbeat_decode(&msg, &hb);
//             //算起飞时间
//             static bool armedLast = false;          // 上一次 armed 状态
//             static qint64 flightStartMSecs = 0;     // 起飞时间戳
//             bool armed = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
//             // 状态切换：未解锁 -> 解锁
//             if (!armedLast && armed) {
//                 flightStartMSecs = QDateTime::currentMSecsSinceEpoch();
//             }
//             // 解锁 -> 上锁，清零
//             if (armedLast && !armed)
//             {
//                 flightStartMSecs = 0;
//             }
//             armedLast = armed;

//             int flightTime = 0;
//             if (armed && flightStartMSecs > 0)
//             {
//                 qint64 now = QDateTime::currentMSecsSinceEpoch();
//                 flightTime = int((now - flightStartMSecs) / 1000);
//             }

//             QString flightMode = decodeFlightMode(hb.autopilot, hb.type, hb.custom_mode);//飞行模式

//             QJsonObject json = makeHeader("status/heartbeat");
//             //topic_name
//             json["sysid"] = msg.sysid;
//             json["compid"] = msg.compid;
//             //json["type"] = hb.type;
//             //json["autopilot"] = hb.autopilot;
//             // json["mode"] = hb.base_mode;

//             //json["seq2"] = msg.seq;//mavlink本身的全链路上seq
//             json["mode"] = flightMode;
//             //json["custom_mode"] = static_cast<qint64>(hb.custom_mode);;
//             // json["system_status"] = hb.system_status;
//             json["status"] = statusName(hb);
//             json["armed"] = (hb.base_mode & MAV_MODE_FLAG_SAFETY_ARMED) != 0;
//             json["flightTime"] = flightTime;
//             Mqttlink::instance()->publish(topicFor(), json, 0, false);
//             break;
//         }


//         //飞机位置信息
//         //需结合两个mavlink信号
//         case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
//         case MAVLINK_MSG_ID_GPS_RAW_INT:
//             publishGeoPositionJson(msg);
//             {
//                 if (_geoCache.globalUpdated && _geoCache.gpsUpdated){
//                 QJsonObject json = makeHeader("geo/position");
//                 json["lat"]    = _geoCache.lat;
//                 json["lon"]    = _geoCache.lon;
//                 json["alt"]    = _geoCache.alt;
//                 json["relAlt"] = _geoCache.relAlt;
//                 json["hdop"]   = _geoCache.hdop;
//                 json["vdop"]   = _geoCache.vdop;
//                 json["sat"]    = _geoCache.satellites;

//                 Mqttlink::instance()->publish(topicFor(), json, 0, false);
//                  _geoCache.globalUpdated = _geoCache.gpsUpdated = false;
//                 }
//             }
//             break;
//         //氢能电池信息
//         case MAVLINK_MSG_ID_DATA32: {
//             mavlink_data32_t d32;
//             mavlink_msg_data32_decode(&msg, &d32);
//             const uint8_t* d = d32.data;

//                     // 按顺序插入 JSON
//             QJsonObject json=makeHeader("power/hydrogen");
//             // json["ts"] = static_cast<qint64>(QDateTime::currentDateTimeUtc().toMSecsSinceEpoch());
//             // json["seq"] = static_cast<qint64>(++_seq);;
//             // json["ver"] = _ver;
//             // json["from"] = _from;
//             // json["msg_name"] = "power/hydrogen";

//             json["type"] = d32.type;
//             json["len"] = d32.len;
//             json["hydrogen_id"] = (int)d[19];
//             json["compid"] = msg.compid;

//             json["servo_current"]      = (int)u16le(d, 2);
//             json["stack_voltage"]      = (int)u16le(d, 4);
//             json["servo_voltage_mv"]   = (int)u16le(d, 6);
//             json["bat_refuel_current"] = (int)u16le(d, 8);
//             json["gas_tank_presure"]   = (int)u16le(d, 10);
//             json["pipe_pressure"]      = (int)u16le(d, 12);

//             json["pcb_temperature"]    = (int)d[14];
//             json["stack_temperature"]  = (int)d[15];

//             json["work_status"] = (int)d[16];
//             json["falt_status"] = (int)d[17];
//             json["self_check"]  = ((int)d[18] == 1) ? "已通过" : "未通过";

//             //json["pack_id"] = (int)d[19];

//             Mqttlink::instance()->publish(topicFor(), json, 0, false);
//             break;/*"power/hydrogen"*/
//         }
//         //飞机横滚、俯仰、偏航
//         case MAVLINK_MSG_ID_ATTITUDE: {
//             mavlink_attitude_t attitude;
//             mavlink_msg_attitude_decode(&msg, &attitude);

//                     // 弧度转角度
//             float roll_deg  = attitude.roll  * 180.0 / M_PI;
//             float pitch_deg = attitude.pitch * 180.0 / M_PI;
//             float yaw_deg   = attitude.yaw   * 180.0 / M_PI;

//                     // 构建 JSON
//             QJsonObject json=makeHeader("geo/attitude");
//             json["roll"]  = roll_deg;
//             json["pitch"] = pitch_deg;
//             json["yaw"]   = yaw_deg;

//             Mqttlink::instance()->publish(topicFor(), json, 0, false);

//             break;
//         }

//             //方向速度
//         case MAVLINK_MSG_ID_LOCAL_POSITION_NED: {
//             mavlink_local_position_ned_t pos;
//             mavlink_msg_local_position_ned_decode(&msg, &pos);

//             QJsonObject json=makeHeader("geo/velocity");
//             json["vx"] = pos.vx;//x 方向速度 (m/s)
//             json["vy"] = pos.vy;//y 方向速度 (m/s)
//             json["vz"] = pos.vz;//z 方向速度 (m/s，注意NED坐标系，向下是正)

//             Mqttlink::instance()->publish(topicFor(), json, 0, false);
//             break;
//         }
//         //标准电池消息
//         case MAVLINK_MSG_ID_BATTERY_STATUS: {
//             mavlink_battery_status_t battery;
//             mavlink_msg_battery_status_decode(&msg, &battery);

//             QJsonObject json = makeHeader("status/battery");
//             json["sysid"] = msg.sysid;
//             json["compid"] = msg.compid;

//             // 基本信息
//             json["battery_id"] = battery.id;//电池id
//             json["battery_function"] = batteryFunctionName(battery.battery_function);//电池功能
//             json["battery_type"] = batteryTypeName(battery.type);//电池类型

//             // 电气参数‘
//             //battery.voltages 其实是一个 数组（uint16_t voltages[10]），而不是一个数值
//             //在 MAVLink 的 BATTERY_STATUS 里，没有单独的 "总电压" 字段，而是要自己把 voltages[] 相加
//             //json["voltage"] = battery.voltages[0] / 1000.0;     // 每一节电芯的电压

//             json["current"] = battery.current_battery / 100.0;  // 电流 (A)
//             json["current_consumed"] = battery.current_consumed; // 已消耗电流 (mAh)
//             json["energy_consumed"] = battery.energy_consumed;  // 已消耗能量 (hJ)
//             // 总电压


//             float totalVoltage = 0.0;
//             for (int i = 0; i < 10; i++) {
//                 if (battery.voltages[i] != UINT16_MAX) { // 过滤掉无效值
//                     totalVoltage += battery.voltages[i] / 1000.0; // 转成 V 再加
//                 }
//             }
//             json["voltage"] = totalVoltage;
//             QJsonArray cellsa;
//             for (int i = 0; i < 10; i++) {
//                 if (battery.voltages[i] != UINT16_MAX) { // 过滤掉无效值
//                     cellsa.append(battery.voltages[i] / 1000.0); // mV -> V
//                 }
//             }
//             json["cells"] = cellsa;

//             // double totalVoltage = 0.0;
//             // QJsonArray cellsArray;
//             // for (int i = 0; i < 10; i++) {
//             //     if (battery.voltages[i] != UINT16_MAX) { // 有效电压
//             //         double cellV = battery.voltages[i] / 1000.0;
//             //         totalVoltage += cellV;
//             //         cellsArray.append(cellV);
//             //     }
//             // }
//             // json["cells"]   = cellsArray;//单体电压，以数组形式出现
//             // json["voltage"] = totalVoltage;//总电压

//             // 状态信息
//             json["temperature"] = battery.temperature;          // 温度 (c°C)
//             json["charge_state"] = chargeStateName(battery.charge_state);//充电状态

//             // 剩余电量
//             if (battery.battery_remaining != -1) {
//                 json["soc"] = battery.battery_remaining;//剩余电量
//             }

//             // 各节电池电压，以json数组的形式
//             // QJsonArray cells;
//             // for (int i = 0; i < 10; i++) {
//             //     if (battery.voltages[i] != UINT16_MAX) {
//             //         QJsonObject cell;
//             //         cell["number"] = i + 1;
//             //         cell["voltage"] = battery.voltages[i] / 1000.0;
//             //         cells.append(cell);
//             //     }
//             // }
//             // json["cells"] = cells;

//             // 时间戳
//             json["timestamp"] = QDateTime::currentMSecsSinceEpoch();

//             Mqttlink::instance()->publish(topicFor(), json, 0, false);
//             break;
//         }

//         //云台
//         case MAVLINK_MSG_ID_GIMBAL_DEVICE_ATTITUDE_STATUS:
//         case MAVLINK_MSG_ID_GIMBAL_MANAGER_STATUS:
//         case MAVLINK_MSG_ID_CAMERA_CAPTURE_STATUS:
//             updateGimbalStatus(msg);
//             {
//                 QJsonObject json = makeHeader("gimbal/status");
//                 json["roll"]      = _gimbalCache.roll;
//                 json["pitch"]     = _gimbalCache.pitch;
//                 json["yaw"]       = _gimbalCache.yaw;
//                 json["mode"]      = _gimbalCache.mode;
//                 json["recording"] = _gimbalCache.recording;

//                 Mqttlink::instance()->publish(topicFor(), json, 0, false);
//             }
//             break;


//         default:
//             break;
//     }
// }


//如果飞控传了就是飞控的值，没传就是默认值
QString MavlinkToJson::topicFor(const QString& messageClass, const QString& group ,const QString& droneId ) const
{
    QString g = group.isEmpty() ? _group : group;
    QString d = droneId.isEmpty() ? _droneId : droneId;
    return QString("uav/%1/%2/%3").arg(g, d, messageClass);
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

// PX4 Custom Mode 解码
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

// ArduPilot Copter Mode 解码
//多旋翼/直升机
//垂直起降
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

// ArduPilot Plane Mode 解码
//固定翼飞机，需要跑道
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

//ArduPilot Rover Mode 解码
//地面车辆，无人车、机器人
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
//水下机器人
//水下航行器
QString MavlinkToJson::apmSubModeToString(uint32_t custom_mode) {
    switch(custom_mode) {
        case 0: return "STABILIZE";
        case 1: return "ACRO";
        case 2: return "ALT_HOLD";
        case 3: return "AUTO";
        case 4: return "GUIDED";
#if defined(_MSC_VER) //MSVC不支持范围 case
        case 5:
        case 6:
        case 8:
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
            return "RESERVED";
#else // GCC/Clang 支持
        case 5: case 6: case 8: case 10 ... 15:
            return "RESERVED";
#endif

        //case 5: case 6: case 8: case 10 ... 15: return "RESERVED";
        case 16: return "POSHOLD";
        case 19: return "MANUAL";
        case 20: return "MOTORDETECTION";
        case 21: return "SURFTRAK";
        default: return "UNKNOWN";
    }
}

//主解码函数
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

                    // 四元数转欧拉角
            double q0 = att.q[0], q1 = att.q[1], q2 = att.q[2], q3 = att.q[3];
            _gimbalCache.roll  = qRadiansToDegrees(qAtan2(2*(q0*q1 + q2*q3),
                                                         1 - 2*(q1*q1 + q2*q2)));
            _gimbalCache.pitch = qRadiansToDegrees(qAsin(2*(q0*q2 - q3*q1)));
            _gimbalCache.yaw   = qRadiansToDegrees(qAtan2(2*(q0*q3 + q1*q2),
                                                        1 - 2*(q2*q2 + q3*q3)));
            break;
        }

        case MAVLINK_MSG_ID_GIMBAL_MANAGER_STATUS: {
            mavlink_gimbal_manager_status_t mgr;
            mavlink_msg_gimbal_manager_status_decode(&msg, &mgr);

            QStringList flagsList;
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_RETRACT)              flagsList << "RETRACT";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_NEUTRAL)              flagsList << "NEUTRAL";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_ROLL_LOCK)            flagsList << "ROLL_LOCK";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_PITCH_LOCK)           flagsList << "PITCH_LOCK";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_YAW_LOCK)             flagsList << "YAW_LOCK";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_YAW_IN_VEHICLE_FRAME) flagsList << "YAW_IN_VEHICLE_FRAME";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_YAW_IN_EARTH_FRAME)   flagsList << "YAW_IN_EARTH_FRAME";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_ACCEPTS_YAW_IN_EARTH_FRAME)
                flagsList << "ACCEPTS_YAW_IN_EARTH_FRAME";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_RC_EXCLUSIVE)         flagsList << "RC_EXCLUSIVE";
            if (mgr.flags & GIMBAL_MANAGER_FLAGS_RC_MIXED)             flagsList << "RC_MIXED";

            _gimbalCache.mode = flagsList.isEmpty() ? "NONE" : flagsList.join("|");
            break;
        }

        //相机状态
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
