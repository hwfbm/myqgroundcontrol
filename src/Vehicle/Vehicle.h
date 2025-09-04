/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QElapsedTimer>
#include <QtCore/QObject>
#include <QtCore/QSharedPointer>
#include <QtCore/QTime>
#include <QtCore/QTimer>
#include <QtCore/QVariantList>
#include <QtPositioning/QGeoCoordinate>
#include <QtCore/QFile>
#include <QString>

#include "HealthAndArmingCheckReport.h"
#include "MAVLinkStreamConfig.h"
#include "QGCMapCircle.h"
#include "QGCMAVLink.h"
#include "QmlObjectListModel.h"
#include "SysStatusSensorInfo.h"
#include "VehicleLinkManager.h"

//#include "mavlink_custom.h"

#include "TerrainFactGroup.h"
#include "VehicleFactGroup.h"
#include "VehicleClockFactGroup.h"
#include "VehicleDistanceSensorFactGroup.h"
#include "VehicleEFIFactGroup.h"
#include "VehicleEscStatusFactGroup.h"
#include "VehicleEstimatorStatusFactGroup.h"
#include "VehicleGeneratorFactGroup.h"
#include "VehicleGPS2FactGroup.h"
#include "VehicleGPSFactGroup.h"
#include "VehicleHygrometerFactGroup.h"
#include "VehicleLocalPositionFactGroup.h"
#include "VehicleLocalPositionSetpointFactGroup.h"
#include "VehicleRPMFactGroup.h"
#include "VehicleSetpointFactGroup.h"
#include "VehicleTemperatureFactGroup.h"
#include "VehicleVibrationFactGroup.h"
#include "VehicleWindFactGroup.h"
#include "GimbalController.h"



class Actuators;
class AutoPilotPlugin;
class Autotune;
class ComponentInformationManager;
class EventHandler;
class FirmwarePlugin;
class FTPManager;
class GeoFenceManager;
class ImageProtocolManager;
class StatusTextHandler;
class InitialConnectStateMachine;
class Joystick;
class LinkInterface;
class MAVLinkLogManager;
class MissionManager;
class ParameterManager;
class QGCCameraManager;
class RallyPointManager;
class RemoteIDManager;
class RequestMessageTest;
class SendMavCommandWithHandlerTest;
class SendMavCommandWithSignallingTest;
class StandardModes;
class TerrainAtCoordinateQuery;
class TerrainProtocolHandler;
class TrajectoryPoints;
class VehicleBatteryFactGroup;
class VehicleObjectAvoidance;
class GimbalController;

#ifdef QGC_UTM_ADAPTER
class UTMSPVehicle;
#endif
//这是一个命名空间，其中包含了 ParsedEvent 类，可能用于解析事件
namespace events {
namespace parser {
class ParsedEvent;
}
}
//Q_DECLARE_LOGGING_CATEGORY 宏用于声明一个新的日志类别，用于日志记录
//这使得可以在代码中使用 qCDebug()、qWarning()、qCritical() 等函数输出日志信息，并且可以按类别过滤这些日志信息
//qCDebug(VehicleLog) << "This is a debug message";
Q_DECLARE_LOGGING_CATEGORY(VehicleLog) //声明了一个日志分类 VehicleLog，用于记录与 Vehicle 类相关的日志信息
//继承自 VehicleFactGroup 类
class Vehicle : public VehicleFactGroup
{
    Q_OBJECT

    //Q_MOC_INCLUDE 宏用于在 QML 文件中包含 C++ 头文件。这允许你在 QML 文件中访问 C++ 代码，实现 QML 和 C++ 代码的混合编程
    Q_MOC_INCLUDE("AutoPilotPlugin.h")
    Q_MOC_INCLUDE("TrajectoryPoints.h")
    Q_MOC_INCLUDE("ParameterManager.h")
    Q_MOC_INCLUDE("VehicleObjectAvoidance.h")
    Q_MOC_INCLUDE("Autotune.h")
    Q_MOC_INCLUDE("RemoteIDManager.h")
    Q_MOC_INCLUDE("QGCCameraManager.h")
    Q_MOC_INCLUDE("Actuators.h")

    //友元声明（friend classes）允许这些类访问 Vehicle 的私有（private）和保护（protected）成员
    friend class InitialConnectStateMachine;
    friend class VehicleLinkManager;
    friend class VehicleHydrogenBatteryFactGroup;
    friend class VehicleBatteryFactGroup;           // Allow VehicleBatteryFactGroup to call _addFactGroup
    friend class SendMavCommandWithSignallingTest;  // Unit test
    friend class SendMavCommandWithHandlerTest;     // Unit test
    friend class RequestMessageTest;                // Unit test
    friend class GimbalController;                  // Allow GimbalController to call _addFactGroup

public:
    //指向 LinkInterface 类型的指针，用于管理与无人机的连接
    //int vehicleId：无人机的 ID
    //nt defaultComponentId：默认组件的 ID
    //MAV_AUTOPILOT firmwareType：固件类型，使用 MAVLink 协议中的枚举类型 MAV_AUTOPILOT
    //MAV_TYPE vehicleType：无人机的类型，使用 MAVLink 协议中的枚举类型 MAV_TYPE
    //QObject* parent：父对象，通常用于 Qt 的对象树管理
    Vehicle(LinkInterface*          link,
            int                     vehicleId,
            int                     defaultComponentId,
            MAV_AUTOPILOT           firmwareType,
            MAV_TYPE                vehicleType,
            QObject*                parent = nullptr);

    // Pass these into the offline constructor to create an offline vehicle which tracks the offline vehicle settings
    //静态构造函数，用于创建离线无人机对象，它们跟踪离线无人机设置
    static const MAV_AUTOPILOT    MAV_AUTOPILOT_TRACK = static_cast<MAV_AUTOPILOT>(-1);
    static const MAV_TYPE         MAV_TYPE_TRACK = static_cast<MAV_TYPE>(-1);

    // The following is used to create a disconnected Vehicle for use while offline editing.
    //离线构造函数，创建一个离线 Vehicle 对象，用于离线编辑无人机设置
    Vehicle(MAV_AUTOPILOT           firmwareType,
            MAV_TYPE                vehicleType,
            QObject*                parent = nullptr);

    ~Vehicle();
//CheckList 枚举定义了三个值，用于表示检查列表的状态
    enum CheckList {
        CheckListNotSetup = 0,//检查列表未设置
        CheckListPassed, //检查列表通过
        CheckListFailed, //检查列表失败
    };
    Q_ENUM(CheckList) //Q_ENUM 宏用于使枚举类型 CheckList 可以被 Qt 的元对象系统识别，从而可以在 QML 中使用


    //对于使用 CONSTANT 标记的属性，它们通常不需要在构造函数中初始化，因为它们的值在编译时就已经确定，且不会改变，如果是指针，表示：属性指针本身（即 _batteryFactGroupListModel 的地址）在对象生命周期内不变
    Q_PROPERTY(int                  id                          READ id                                                             CONSTANT) //车辆的唯一标识符
    Q_PROPERTY(AutoPilotPlugin*     autopilotPlugin             MEMBER _autopilotPlugin                                             CONSTANT) //自动飞行插件对象。
    Q_PROPERTY(QGeoCoordinate       coordinate                  READ coordinate                                                     NOTIFY coordinateChanged)//地理位置坐标
    Q_PROPERTY(QGeoCoordinate       homePosition                READ homePosition                                                   NOTIFY homePositionChanged)
    Q_PROPERTY(QGeoCoordinate       armedPosition               READ armedPosition                                                  NOTIFY armedPositionChanged)
    Q_PROPERTY(bool                 armed                       READ armed                      WRITE setArmedShowError             NOTIFY armedChanged)//是否已解锁（准备飞行）
    Q_PROPERTY(bool                 autoDisarm                  READ autoDisarm                                                     NOTIFY autoDisarmChanged)
    Q_PROPERTY(bool                 flightModeSetAvailable      READ flightModeSetAvailable                                         CONSTANT) //飞行模式是否可用
    Q_PROPERTY(QStringList          flightModes                 READ flightModes                                                    NOTIFY flightModesChanged)//可用的飞行模式列表
    Q_PROPERTY(QString              flightMode                  READ flightMode                 WRITE setFlightMode                 NOTIFY flightModeChanged)//当前飞行模式
    Q_PROPERTY(TrajectoryPoints*    trajectoryPoints            MEMBER _trajectoryPoints                                            CONSTANT)//轨迹点
    Q_PROPERTY(QmlObjectListModel*  cameraTriggerPoints         READ cameraTriggerPoints                                            CONSTANT)
    Q_PROPERTY(float                latitude                    READ latitude                                                       NOTIFY coordinateChanged)
    Q_PROPERTY(float                longitude                   READ longitude                                                      NOTIFY coordinateChanged)
    Q_PROPERTY(bool                 joystickEnabled             READ joystickEnabled            WRITE setJoystickEnabled            NOTIFY joystickEnabledChanged)//是否启用了操纵杆
    Q_PROPERTY(int                  rcRSSI                      READ rcRSSI                                                         NOTIFY rcRSSIChanged) //接收信号强度指示器
    Q_PROPERTY(bool                 px4Firmware                 READ px4Firmware                                                    NOTIFY firmwareTypeChanged) //固件类型
    Q_PROPERTY(bool                 apmFirmware                 READ apmFirmware                                                    NOTIFY firmwareTypeChanged)
    Q_PROPERTY(bool                 soloFirmware                READ soloFirmware               WRITE setSoloFirmware               NOTIFY soloFirmwareChanged)
    Q_PROPERTY(bool                 genericFirmware             READ genericFirmware                                                CONSTANT)
    Q_PROPERTY(uint                 messagesReceived            READ messagesReceived                                               NOTIFY messagesReceivedChanged) //通信统计信息
    Q_PROPERTY(uint                 messagesSent                READ messagesSent                                                   NOTIFY messagesSentChanged)
    Q_PROPERTY(uint                 messagesLost                READ messagesLost                                                   NOTIFY messagesLostChanged)
    Q_PROPERTY(bool                 airship                     READ airship                                                        NOTIFY vehicleTypeChanged)//飞行器类型
    Q_PROPERTY(bool                 fixedWing                   READ fixedWing                                                      NOTIFY vehicleTypeChanged)//示飞行器是否为固定翼类型
    Q_PROPERTY(bool                 multiRotor                  READ multiRotor                                                     NOTIFY vehicleTypeChanged) //表示飞行器是否为多旋翼类型
    Q_PROPERTY(bool                 vtol                        READ vtol                                                           NOTIFY vehicleTypeChanged) //表示飞行器是否为垂直起降类型（VTOL
    Q_PROPERTY(bool                 rover                       READ rover                                                          NOTIFY vehicleTypeChanged)//表示飞行器是否为地面车辆（rover）
    Q_PROPERTY(bool                 sub                         READ sub                                                            NOTIFY vehicleTypeChanged)//表示飞行器是否为潜艇（sub）
    Q_PROPERTY(bool        supportsThrottleModeCenterZero       READ supportsThrottleModeCenterZero                                 CONSTANT) //表示是否支持油门中位零
    Q_PROPERTY(bool                supportsNegativeThrust       READ supportsNegativeThrust                                         CONSTANT) //表示是否支持负推力
    Q_PROPERTY(bool                 supportsJSButton            READ supportsJSButton                                               CONSTANT)//表示是否支持JS按钮
    Q_PROPERTY(bool                 supportsRadio               READ supportsRadio                                                  CONSTANT)//表示是否支持无线电控制
    Q_PROPERTY(bool               supportsMotorInterference     READ supportsMotorInterference                                      CONSTANT)//表示是否支持电机干扰检测
    Q_PROPERTY(QString              prearmError                 READ prearmError                WRITE setPrearmError                NOTIFY prearmErrorChanged) //表示预飞行错误信息
    Q_PROPERTY(int                  motorCount                  READ motorCount                                                     CONSTANT)//表示电机数量
    Q_PROPERTY(bool                 coaxialMotors               READ coaxialMotors                                                  CONSTANT) //表示是否为同轴电机
    Q_PROPERTY(bool                 xConfigMotors               READ xConfigMotors                                                  CONSTANT) //表示是否为X配置电机
    Q_PROPERTY(bool                 isOfflineEditingVehicle     READ isOfflineEditingVehicle                                        CONSTANT) //表示是否为离线编辑飞行器
    Q_PROPERTY(QString              brandImageIndoor            READ brandImageIndoor                                               NOTIFY firmwareTypeChanged)//表示室内和室外的品牌图像路径
    Q_PROPERTY(QString              brandImageOutdoor           READ brandImageOutdoor                                              NOTIFY firmwareTypeChanged)
    Q_PROPERTY(int                  sensorsPresentBits          READ sensorsPresentBits                                             NOTIFY sensorsPresentBitsChanged)//表示传感器的状态位掩码
    Q_PROPERTY(int                  sensorsEnabledBits          READ sensorsEnabledBits                                             NOTIFY sensorsEnabledBitsChanged)//启用的传感器位掩码
    Q_PROPERTY(int                  sensorsHealthBits           READ sensorsHealthBits                                              NOTIFY sensorsHealthBitsChanged)//传感器的健康状态位掩码
    Q_PROPERTY(int                  sensorsUnhealthyBits        READ sensorsUnhealthyBits                                           NOTIFY sensorsUnhealthyBitsChanged)//表示不健康的传感器位掩码 ///< Combination of enabled and health
    Q_PROPERTY(QString              missionFlightMode           READ missionFlightMode                                              CONSTANT) //表示当前的飞行任务模式
    Q_PROPERTY(QString              pauseFlightMode             READ pauseFlightMode                                                CONSTANT) //表示当前的暂停飞行模式
    Q_PROPERTY(QString              rtlFlightMode               READ rtlFlightMode                                                  CONSTANT) //表示当前的返回起飞点
    Q_PROPERTY(QString              smartRTLFlightMode          READ smartRTLFlightMode                                             CONSTANT) //表示当前的智能返回起飞点模式
    Q_PROPERTY(bool                 supportsSmartRTL            READ supportsSmartRTL                                               CONSTANT)//是否支持智能返回
    Q_PROPERTY(QString              landFlightMode              READ landFlightMode                                                 CONSTANT)//表示当前的着陆模式
    Q_PROPERTY(QString              takeControlFlightMode       READ takeControlFlightMode                                          CONSTANT) //表示当前的接管飞行模式
    Q_PROPERTY(QString              followFlightMode            READ followFlightMode                                               CONSTANT) //表示当前的跟随模式
    Q_PROPERTY(QString              motorDetectionFlightMode    READ motorDetectionFlightMode                                       CONSTANT) //表示当前的电机检测模式
    Q_PROPERTY(QString              stabilizedFlightMode        READ stabilizedFlightMode                                           CONSTANT)//表示当前的稳定飞行模式
    Q_PROPERTY(QString              firmwareTypeString          READ firmwareTypeString                                             NOTIFY firmwareTypeChanged)//固件类型，当固件类型发生变化时，会发出 firmwareTypeChanged 信号
    Q_PROPERTY(QString              vehicleTypeString           READ vehicleTypeString                                              NOTIFY vehicleTypeChanged)//表示车辆类型
    Q_PROPERTY(QString              vehicleImageOpaque          READ vehicleImageOpaque                                             CONSTANT) //表示车辆的不透明图像
    Q_PROPERTY(QString              vehicleImageOutline         READ vehicleImageOutline                                            CONSTANT) //表示车辆的轮廓图像
    Q_PROPERTY(int                  telemetryRRSSI              READ telemetryRRSSI                                                 NOTIFY telemetryRRSSIChanged)//表示遥测信号的接收信号强度指示
    Q_PROPERTY(int                  telemetryLRSSI              READ telemetryLRSSI                                                 NOTIFY telemetryLRSSIChanged)//表示遥测信号的接收质量指示
    Q_PROPERTY(unsigned int         telemetryRXErrors           READ telemetryRXErrors                                              NOTIFY telemetryRXErrorsChanged)//表示遥测接收过程中的错误计数
    Q_PROPERTY(unsigned int         telemetryFixed              READ telemetryFixed                                                 NOTIFY telemetryFixedChanged)//表示遥测信号的固定计数，可能用于表示信号丢失或重传的包数
    Q_PROPERTY(unsigned int         telemetryTXBuffer           READ telemetryTXBuffer                                              NOTIFY telemetryTXBufferChanged)//表示遥测传输缓冲区的大小或状态
    Q_PROPERTY(int                  telemetryLNoise             READ telemetryLNoise                                                NOTIFY telemetryLNoiseChanged) //表示遥测信号的噪声水平
    Q_PROPERTY(int                  telemetryRNoise             READ telemetryRNoise                                                NOTIFY telemetryRNoiseChanged) //表示遥测信号的接收噪声水平
    Q_PROPERTY(QVariant          mainStatusIndicatorContentItem READ mainStatusIndicatorContentItem                                 CONSTANT)//主状态指示器内容
    Q_PROPERTY(QVariantList         toolIndicators              READ toolIndicators                                                 NOTIFY toolIndicatorsChanged) //工具指示器列表
    Q_PROPERTY(QVariantList         modeIndicators              READ modeIndicators                                                 NOTIFY modeIndicatorsChanged)//模式指示器列表
    Q_PROPERTY(bool              initialPlanRequestComplete     READ initialPlanRequestComplete                                     NOTIFY initialPlanRequestCompleteChanged)//初始计划请求完成状态
    Q_PROPERTY(QVariantList         staticCameraList            READ staticCameraList                                               CONSTANT)//包含静态相机列表
    Q_PROPERTY(QGCCameraManager*    cameraManager               READ cameraManager                                                  NOTIFY cameraManagerChanged)//表示相机管理器
    Q_PROPERTY(QString              hobbsMeter                  READ hobbsMeter                                                     NOTIFY hobbsMeterChanged) //表示水平基准计
    Q_PROPERTY(bool                 vtolInFwdFlight             READ vtolInFwdFlight            WRITE setVtolInFwdFlight            NOTIFY vtolInFwdFlightChanged)//表示在飞行中是否启用了垂直总能量损失
    Q_PROPERTY(bool                 supportsTerrainFrame        READ supportsTerrainFrame                                           NOTIFY firmwareTypeChanged) //是否支持地形框架。当固件类型改变时会发出 firmwareTypeChanged 信号
    Q_PROPERTY(quint64              mavlinkSentCount            READ mavlinkSentCount                                               NOTIFY mavlinkStatusChanged) //跟踪 MAVLink 协议的发送、接收和丢包统计信息
    Q_PROPERTY(quint64              mavlinkReceivedCount        READ mavlinkReceivedCount                                           NOTIFY mavlinkStatusChanged)//表示通过 MAVLink 协议接收到的总消息数
    Q_PROPERTY(quint64              mavlinkLossCount            READ mavlinkLossCount                                               NOTIFY mavlinkStatusChanged) //表示通过 MAVLink 协议丢失的消息数
    Q_PROPERTY(float                mavlinkLossPercent          READ mavlinkLossPercent                                             NOTIFY mavlinkStatusChanged)//表示通过 MAVLink 协议丢失的消息百分比
    Q_PROPERTY(GimbalController*    gimbalController            READ gimbalController                                               CONSTANT) //表示云台控制器
    Q_PROPERTY(bool                 hasGripper                  READ hasGripper                                                     CONSTANT) //是否有机械臂（gripper）
    Q_PROPERTY(bool                 isROIEnabled                READ isROIEnabled                                                   NOTIFY isROIEnabledChanged) //是否启用了感兴趣区域（ROI）
    Q_PROPERTY(CheckList            checkListState              READ checkListState             WRITE setCheckListState             NOTIFY checkListStateChanged) //检查列表的状态
    Q_PROPERTY(bool                 readyToFlyAvailable         READ readyToFlyAvailable                                            NOTIFY readyToFlyAvailableChanged) //表示无人机是否准备好起飞 ///< true: readyToFly signalling is available on this vehicle
    Q_PROPERTY(bool                 readyToFly                  READ readyToFly                                                     NOTIFY readyToFlyChanged)
    Q_PROPERTY(QObject*             sysStatusSensorInfo         READ sysStatusSensorInfo                                            CONSTANT)//表示系统传感器信息
    Q_PROPERTY(bool                 allSensorsHealthy           READ allSensorsHealthy                                              NOTIFY allSensorsHealthyChanged)    //< true: all sensors in SYS_STATUS reported as healthy表示所有传感器是否健康
    Q_PROPERTY(bool                 requiresGpsFix              READ requiresGpsFix                                                 NOTIFY requiresGpsFixChanged) //是否需要 GPS 固定
    Q_PROPERTY(double               loadProgress                READ loadProgress                                                   NOTIFY loadProgressChanged)  //表示加载进度
    Q_PROPERTY(bool                 initialConnectComplete      READ isInitialConnectComplete                                       NOTIFY initialConnectComplete)//初始连接是否完成

    // The following properties relate to Orbit status
    Q_PROPERTY(bool             orbitActive     READ orbitActive        NOTIFY orbitActiveChanged) //表示轨道模式是否激活
    Q_PROPERTY(QGCMapCircle*    orbitMapCircle  READ orbitMapCircle     CONSTANT) //表示轨道的圆形路径

    // Vehicle state used for guided control
    Q_PROPERTY(bool     flying                  READ flying                                         NOTIFY flyingChanged)       //表示飞行器是否正在飞行///< Vehicle is flying
    Q_PROPERTY(bool     landing                 READ landing                                        NOTIFY landingChanged)      //表示飞行器是否正在降落///< Vehicle is in landing pattern (DO_LAND_START)
    Q_PROPERTY(bool     guidedMode              READ guidedMode                 WRITE setGuidedMode NOTIFY guidedModeChanged)   //飞行器是否处于引导模式，并且可以响应引导命///< Vehicle is in Guided mode and can respond to guided commands
    Q_PROPERTY(bool     guidedModeSupported     READ guidedModeSupported                            CONSTANT)                   //飞行器是否支持引导模式命令///< Guided mode commands are supported by this vehicle
    Q_PROPERTY(bool     pauseVehicleSupported   READ pauseVehicleSupported                          CONSTANT)                   //表示飞行器是否支持暂停命令///< Pause vehicle command is supported
    Q_PROPERTY(bool     orbitModeSupported      READ orbitModeSupported                             CONSTANT)                   //表示飞行器是否支持轨道模式///< Orbit mode is supported by this vehicle
    Q_PROPERTY(bool     roiModeSupported        READ roiModeSupported                               CONSTANT)                   //表示飞行器是否支持感兴趣区域（ROI）模式///< Orbit mode is supported by this vehicle
    Q_PROPERTY(bool     takeoffVehicleSupported READ takeoffVehicleSupported                        CONSTANT)                   //表示是否支持引导起飞///< Guided takeoff supported
    Q_PROPERTY(bool     changeHeadingSupported  READ changeHeadingSupported                         CONSTANT)                   //表示是否支持改变航向///< Change Heading supported
    Q_PROPERTY(QString  gotoFlightMode          READ gotoFlightMode                                 CONSTANT)                   //表示飞行器在执行“goto”操作时的飞行模式///< Flight mode vehicle is in while performing goto
    Q_PROPERTY(bool     haveMRSpeedLimits       READ haveMRSpeedLimits                              NOTIFY haveMRSpeedLimChanged)//表示是否有最大转速限制
    Q_PROPERTY(bool     haveFWSpeedLimits       READ haveFWSpeedLimits                              NOTIFY haveFWSpeedLimChanged)//表示是否有最大前向速度限制

    Q_PROPERTY(ParameterManager*        parameterManager    READ parameterManager   CONSTANT) // 指针类型的属性，用于管理参数
    Q_PROPERTY(VehicleLinkManager*      vehicleLinkManager  READ vehicleLinkManager CONSTANT) //用于管理飞行器的连接
    Q_PROPERTY(VehicleObjectAvoidance*  objectAvoidance     READ objectAvoidance    CONSTANT)//用于管理避障对象
    Q_PROPERTY(Autotune*                autotune            READ autotune           CONSTANT)//用于自动调参
    Q_PROPERTY(RemoteIDManager*         remoteIDManager     READ remoteIDManager    CONSTANT) //用于管理远程 ID

    // FactGroup object model properties
//这些属性用于访问不同类型的 FactGroup 对象
    Q_PROPERTY(FactGroup*           vehicle         READ vehicleFactGroup           CONSTANT)//指向 FactGroup 对象，包含与无人机相关的各种事实（Fact）
    Q_PROPERTY(FactGroup*           gps             READ gpsFactGroup               CONSTANT) //指向管理 GPS 相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           gps2            READ gps2FactGroup              CONSTANT) //指向管理第二组 GPS 相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           wind            READ windFactGroup              CONSTANT) //指向管理风速和风向相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           vibration       READ vibrationFactGroup         CONSTANT) //指向管理振动相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           temperature     READ temperatureFactGroup       CONSTANT)//指向管理温度相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           clock           READ clockFactGroup             CONSTANT) //指向管理时钟相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           setpoint        READ setpointFactGroup          CONSTANT) //指向管理设定点（如航点）相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           escStatus       READ escStatusFactGroup         CONSTANT) //指向管理紧急停止（ESC）状态相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           estimatorStatus READ estimatorStatusFactGroup   CONSTANT) //指向管理估计器状态相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           terrain         READ terrainFactGroup           CONSTANT) //指向管理地形相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           distanceSensors READ distanceSensorFactGroup    CONSTANT) //指向管理距离传感器相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           localPosition   READ localPositionFactGroup     CONSTANT) //指向管理本地位置（如 GPS 位置）相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           localPositionSetpoint READ localPositionSetpointFactGroup CONSTANT) //指向管理本地设定点位置相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           hygrometer      READ hygrometerFactGroup        CONSTANT) //指向管理气压计相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           generator       READ generatorFactGroup         CONSTANT) //指向管理发电机相关事实的 FactGroup 对象
    Q_PROPERTY(FactGroup*           efi             READ efiFactGroup               CONSTANT) //指向管理 EFI（电子燃油喷射）相关事实的 FactGroup 对象
    Q_PROPERTY(QmlObjectListModel*  hydrogenBatteries       READ hydrogenBatteries  CONSTANT     ) //用于在 QML 中显示电池状态列表 NOTIFY  hydrogenBatteriesChanged
    Q_PROPERTY(QmlObjectListModel*  batteries       READ batteries                  CONSTANT) //用于在 QML 中显示电池状态列表
    Q_PROPERTY(Actuators*           actuators       READ actuators                  CONSTANT) //管理无人机的执行器（如电机）
    Q_PROPERTY(HealthAndArmingCheckReport* healthAndArmingCheckReport READ healthAndArmingCheckReport CONSTANT) //可能包含有关无人机健康状况和是否准备好起飞的报告，指向一个包含无人机健康状况和是否准备好起飞的报告的对象

    Q_PROPERTY(int      firmwareMajorVersion        READ firmwareMajorVersion       NOTIFY firmwareVersionChanged) //表示固件的主版本号
    Q_PROPERTY(int      firmwareMinorVersion        READ firmwareMinorVersion       NOTIFY firmwareVersionChanged)//次版本号
    Q_PROPERTY(int      firmwarePatchVersion        READ firmwarePatchVersion       NOTIFY firmwareVersionChanged)//补丁版本
    Q_PROPERTY(int      firmwareVersionType         READ firmwareVersionType        NOTIFY firmwareVersionChanged)//表示固件的类型
    Q_PROPERTY(QString  firmwareVersionTypeString   READ firmwareVersionTypeString  NOTIFY firmwareVersionChanged) //表示固件类型的字符串描述
    Q_PROPERTY(int      firmwareCustomMajorVersion  READ firmwareCustomMajorVersion NOTIFY firmwareCustomVersionChanged) //自定义固件的主版本号
    Q_PROPERTY(int      firmwareCustomMinorVersion  READ firmwareCustomMinorVersion NOTIFY firmwareCustomVersionChanged)//次版本号
    Q_PROPERTY(int      firmwareCustomPatchVersion  READ firmwareCustomPatchVersion NOTIFY firmwareCustomVersionChanged)//补丁版本
    Q_PROPERTY(QString  gitHash                     READ gitHash                    NOTIFY gitHashChanged) //表示固件的 Git 提交云哈希值
    Q_PROPERTY(quint64  vehicleUID                  READ vehicleUID                 NOTIFY vehicleUIDChanged) //表示车辆的唯一标识符
    Q_PROPERTY(QString  vehicleUIDStr               READ vehicleUIDStr              NOTIFY vehicleUIDChanged) //表示车辆 UID 的字符串形式

    Q_PROPERTY(bool     mavlinkSigning              READ mavlinkSigning             NOTIFY mavlinkSigningChanged) //表示 MAVLink 遥测消息是否签名

    /// Resets link status counters
    //定义了 Vehicle 类的几个成员函数，这些函数用于控制无人机的行为。每个函数都使用了 Q_INVOKABLE 宏，这通常用于声明一个函数是不可调用的（可能是为了未来扩展而预留的接口）。
    //Q_INVOKABLE 是 Qt 中的一个宏，用于指示某个函数或方法在当前的上下文中不可用（即，该函数或方法在当前的类实现中是不可调用的）。这通常用于声明纯虚函数（pure virtual functions），即那些在基类中声明但未实现，需要在派生类中实现的函数。
    //Q_INVOKABLE 宏通常与 signals: 关键字一起使用，用于声明信号和槽，但也可以用于声明普通的纯虚函数。

    Q_INVOKABLE void resetCounters  ();//重置链路状态计数器

    Q_INVOKABLE void virtualTabletJoystickValue(double roll, double pitch, double yaw, double thrust); //设置操纵杆的值，滚转（roll）、俯仰（pitch）、偏航（yaw）和推力（thrust）

    /// Command vehicle to return to launch
    Q_INVOKABLE void guidedModeRTL(bool smartRTL);//命令无人机返回起飞点（Return-To-Launch） 。一个 bool 类型的参数，表示是否使用智能返回起飞点（smart RTL）

    /// Command vehicle to land at current location
    Q_INVOKABLE void guidedModeLand();//命令无人机在当前位置降落

    /// Command vehicle to takeoff from current location
    Q_INVOKABLE void guidedModeTakeoff(double altitudeRelative); //命令无人机从当前位置起飞到指定的相对高度

    /// @return The minimum takeoff altitude (relative) for guided takeoff.
    Q_INVOKABLE double minimumTakeoffAltitudeMeters();  //获取引导起飞的最小相对高度（米）

    /// @return Maximum horizontal speed multirotor.
    Q_INVOKABLE double maximumHorizontalSpeedMultirotor(); //获取多旋翼无人机的最大水平速度

    /// @return Maximum equivalent airspeed.
    Q_INVOKABLE double maximumEquivalentAirspeed(); //获取无人机的最大等效空速

    /// @return Minumum equivalent airspeed.
    Q_INVOKABLE double minimumEquivalentAirspeed(); //获取无人机的最小等效空速

    /// Command vehicle to move to specified location (altitude is ignored)
    Q_INVOKABLE void guidedModeGotoLocation(const QGeoCoordinate& gotoCoord); //命令无人机移动到指定的位置（高度被忽略），一个 QGeoCoordinate 类型的参数，表示目标坐标

    /// Command vehicle to change altitude
    ///     @param altitudeChange If > 0, go up by amount specified, if < 0, go down by amount specified
    ///     @param pauseVehicle true: pause vehicle prior to altitude change
    Q_INVOKABLE void guidedModeChangeAltitude(double altitudeChange, bool pauseVehicle); //命令无人机改变高度，一个 double 类型的参数表示高度变化量，一个 bool 类型的参数表示在改变高度前是否暂停无人机

    /// Command vehicle to change yaw
    ///     @param coordinate to rotate towards
    Q_INVOKABLE void guidedModeChangeHeading(const QGeoCoordinate &headingCoord);//命令无人机改变偏航向指定的坐标，headingCoord，表示旋转方向的坐标

    /// Command vehicle to change groundspeed
    ///     @param groundspeed Target horizontal groundspeed
    Q_INVOKABLE void guidedModeChangeGroundSpeedMetersSecond(double groundspeed); //命令无人机改变地速（地面速度），groundspeed，目标地速（米/秒）
    /// Command vehicle to change equivalent airspeed
    ///     @param airspeed Target equivalent airspeed
    Q_INVOKABLE void guidedModeChangeEquivalentAirspeedMetersSecond(double airspeed); //命令无人机改变等效空速（空速），airspeed，目标等效空速（米/秒）

    /// Command vehicle to orbit given center point
    ///     @param centerCoord Orbit around this point
    ///     @param radius Distance from vehicle to centerCoord
    ///     @param amslAltitude Desired vehicle altitude
    Q_INVOKABLE void guidedModeOrbit(const QGeoCoordinate& centerCoord, double radius, double amslAltitude);//命令无人机围绕给定的中心点进行轨道飞行，centerCoord（轨道中心点坐标），radius（距中心点的距离），amslAltitude（期望的飞行高度）

    /// Command vehicle to keep given point as ROI
    ///     @param centerCoord ROI coordinates
    Q_INVOKABLE void guidedModeROI(const QGeoCoordinate& centerCoord);//命令无人机保持给定点作为感兴趣区域（ROI），参数：centerCoord，ROI 坐标
    Q_INVOKABLE void stopGuidedModeROI(); //停止当前的 ROI 模式

    /// Command vehicle to pause at current location. If vehicle supports guide mode, vehicle will be left
    /// in guided mode after pause.
    Q_INVOKABLE void pauseVehicle(); //命令无人机在当前位置暂停。如果无人机支持引导模式，暂停后无人机将保持在引导

    /// Command vehicle to kill all motors no matter what state
    Q_INVOKABLE void emergencyStop();//命令无人机立即停止所有电机，无论处于什么状态

    /// Command vehicle to abort landing
    Q_INVOKABLE void abortLanding(double climbOutAltitude); //命令无人机中止降落，climbOutAltitude，爬升高度

    /// Command vichecle to deploy landing gear
    Q_INVOKABLE void landingGearDeploy(); //命令无人机部署起落架

    /// Command vichecle to retract landing gear
    Q_INVOKABLE void landingGearRetract(); //命令无人机收回起落架

    Q_INVOKABLE void startMission(); //开始执行任务

    /// Alter the current mission item on the vehicle
    Q_INVOKABLE void setCurrentMissionSequence(int seq); //更改无人机当前的任务项

    /// Reboot vehicle
    Q_INVOKABLE void rebootVehicle();//重启无人机

    Q_INVOKABLE void sendPlan(QString planFile);//发送飞行计划给无人机，planFile，表示飞行计划文件的路径或名称
    Q_INVOKABLE void setEstimatorOrigin(const QGeoCoordinate& centerCoord);  //设置估计器的原点（即，设置无人机的位置和姿态的参考点），参数：centerCoord，表示原点的地理坐标

    /// Used to check if running current version is equal or higher than the one being compared.
    //  returns 1 if current > compare, 0 if current == compare, -1 if current < compare
    Q_INVOKABLE int versionCompare(QString& compare) const; //比较当前运行的固件版本是否等于或高于指定的版本，compare，表示要比较的版本号，返回值：整数，1 表示当前版本大于比较版本，0 表示等于，-1 表示小于
    Q_INVOKABLE int versionCompare(int major, int minor, int patch) const;//与 versionCompare(QString& compare) 相同，但参数是三个整数，分别表示主版本号、次版本号和补丁号，返回值与 versionCompare(QString& compare)相同

    /// Test motor
    ///     @param motor Motor number, 1-based
    ///     @param percent 0-no power, 100-full power
    ///     @param timeoutSec Disabled motor after this amount of time
    Q_INVOKABLE void motorTest(int motor, int percent, int timeoutSecs, bool showError); //测试电机，motor，表示电机编号（从 1 开始）。percent，表示测试时电机的功率百分比（0 表示无功率，100 表示全功率）。timeoutSecs，表示电机在测试后禁用前的超时时间（秒）。showError，布尔值，表示是否在测试失败时显示错误

    // ModeDisabled：遥测模式被禁用。
    // ModeRateAndAttitude：遥测模式为速率和姿态。
    // ModeVelocityAndPosition：遥测模式为速度和位置。
    // ModeAltitudeAndAirspeed：遥测模式为高度和空速。
    enum PIDTuningTelemetryMode {
        ModeDisabled,
        ModeRateAndAttitude,
        ModeVelocityAndPosition,
        ModeAltitudeAndAirspeed,
    };
    Q_ENUM(PIDTuningTelemetryMode)//Q_ENUM 宏用于注册枚举类型 PIDTuningTelemetryMode 到 Qt 的元对象系统中，这样它就可以在 QML 中被识别和使用

    Q_INVOKABLE void setPIDTuningTelemetryMode(PIDTuningTelemetryMode mode); //设置 PID 调参遥测模式，mode，表示遥测模式的枚举值
    
    Q_INVOKABLE void forceArm ();//强制无人机进入武装状态（可能是指准备起飞的状态）

    /// Sends PARAM_MAP_RC message to vehicle
    Q_INVOKABLE void sendParamMapRC(const QString& paramName, double scale, double centerValue, int tuningID, double minValue, double maxValue);//发送 PARAM_MAP_RC 消息到无人机，包括参数名称、比例、中心值、调参 ID、最小值和最大值

    /// Clears all PARAM_MAP_RC settings from vehicle
    Q_INVOKABLE void clearAllParamMapRC(void);//清除无人机上所有的 PARAM_MAP_RC 设置

    /// Removes the vehicle from the system
    Q_INVOKABLE void closeVehicle(void) { _vehicleLinkManager->closeVehicle(); } //从系统中移除无人机，实现：调用 _vehicleLinkManager->closeVehicle() 来关闭与无人机的连接

    /// Trigger camera using MAV_CMD_DO_DIGICAM_CONTROL command
    Q_INVOKABLE void triggerSimpleCamera(void); //触发相机，使用 MAV_CMD_DO_DIGICAM_CONTROL 命令

#if !defined(QGC_NO_ARDUPILOT_DIALECT)
    Q_INVOKABLE void flashBootloader(); //闪烁引导加载程序，仅当未定义 QGC_NO_ARDUPILOT_DILECT 时可用
#endif
    /// Set home from flight map coordinate
    Q_INVOKABLE void doSetHome(const QGeoCoordinate& coord);//设置家的位置，从飞行地图坐标，coord，表示家的地理坐标

    /// Save the joystick enable setting to the settings group
    Q_INVOKABLE void saveJoystickSettings(void);//保存操纵杆设置到设置组

    Q_INVOKABLE void sendSetupSigning();//发送设置签名

    bool    isInitialConnectComplete() const;//检查初始连接是否完成
    bool    guidedModeSupported     () const;//检查是否支持引导模式
    bool    pauseVehicleSupported   () const;//检查是否支持暂停车辆
    bool    orbitModeSupported      () const;//检查是否支持轨道模式
    bool    roiModeSupported        () const;//检查是否支持感兴趣区域（ROI）模式
    bool    takeoffVehicleSupported () const; //检查是否支持引导起飞
    bool    changeHeadingSupported  () const;//检查是否支持改变航向
    QString gotoFlightMode          () const;//获取当前的“goto”飞行模式
    bool    hasGripper              () const;//检查是否有机械臂
    bool haveMRSpeedLimits() const { return _multirotor_speed_limits_available; }//检查是否有最大转速限制
    bool haveFWSpeedLimits() const { return _fixed_wing_airspeed_limits_available; }//检查是否有最大前向速度限制

    // Property accessors

    QGeoCoordinate coordinate() { return _coordinate; }//获取当前坐标位置
    QGeoCoordinate armedPosition    () { return _armedPosition; }//获取当前武装位置

    qreal getInitialGCSPressure() const { return _initialGCSPressure; }//获取初始大气压力
    qreal getInitialGCSTemperature() const { return _initialGCSTemperature; }//获取初始温度
    void setInitialGCSPressure(qreal pressure) { _initialGCSPressure = pressure; }//设置初始大气压力
    void setInitialGCSTemperature(qreal temperature) { _initialGCSTemperature = temperature; }//设置初始温度

    void updateFlightDistance(double distance); //更新飞行距离

    bool joystickEnabled            () const; //获取操纵杆是否启用
    void setJoystickEnabled         (bool enabled);//设置操纵杆是否启用
    void sendJoystickDataThreadSafe (float roll, float pitch, float yaw, float thrust, quint16 buttons);//线程安全地发送操纵杆数据，参数：操纵杆的值和按钮状态

    // Property accesors
    int id() const{ return _id; } //返回无人机的 ID
    int compId() const{ return _compID; } //返回组件的 ID
    MAV_AUTOPILOT firmwareType() const { return _firmwareType; } //返回固件类型
    MAV_TYPE vehicleType() const { return _vehicleType; } //返回无人机的类型
    QGCMAVLink::VehicleClass_t vehicleClass(void) const { return QGCMAVLink::vehicleClass(_vehicleType); }//返回无人机的类别
    Q_INVOKABLE QString vehicleClassInternalName() const; //返回无人机类别的内部名称返回无人机类别的内部名称

    /// Sends a message to the specified link
    /// @return true: message sent, false: Link no longer connected
    bool sendMessageOnLinkThreadSafe(LinkInterface* link, mavlink_message_t message); //安全地向指定的链路发送消息。link：指向链路接口的指针。message：要发送的 MAVLink 消息。返回值：bool 类型，true 表示消息已发送，false 表示链路不再连接。

    /// Sends the specified messages multiple times to the vehicle in order to attempt to
    /// guarantee that it makes it to the vehicle.
    void sendMessageMultiple(mavlink_message_t message);//多次发送指定的消息到无人机，以确保消息到达。参数：message，要发送的 MAVLink 消息

    /// Provides access to AutoPilotPlugin for this vehicle.
    AutoPilotPlugin* autopilotPlugin() { return _autopilotPlugin; } //提供对无人机的自动飞行插件的访问，返回值：AutoPilotPlugin* 类型，指向自动飞行插件的指针。AutoPilotPlugin* 类型，指向自动飞行插件的指针

    /// Provides access to the Firmware Plugin for this Vehicle
    FirmwarePlugin* firmwarePlugin() { return _firmwarePlugin; } //提供对无人机的固件插件的访问，FirmwarePlugin* 类型，指向固件插件的指针


    QGeoCoordinate homePosition(); //获取无人机的返航点（Home Position）坐标，返回值：QGeoCoordinate 类型，表示返航点的地理位置

    bool armed              () const{ return _armed; }//检查无人机是否已解锁（准备好起飞）
    void setArmed           (bool armed, bool showError);  //设置无人机的解锁状态，并可选地显示错误信息，armed：bool 类型，true 表示解锁，false 表示锁定。showError：bool 类型，true 表示显示错误信息，false 表示不显示
    void setArmedShowError  (bool armed) { setArmed(armed, true); }//设置无人机解锁状态并显示错误信息（如果有），参数：armed：bool 类型，true 表示解锁，false 表示锁定

    bool flightModeSetAvailable             ();//检查是否可以设置飞行模式
    QStringList flightModes                 ();//获取无人机支持的所有飞行模式列表
    QString flightMode                      () const;//获取当前的飞行模式
    void setFlightMode                      (const QString& flightMode); //设置无人机的飞行模式，flightMode：QString 类型，表示要设置的飞行模式名称

    bool airship() const;//查无人机是否为飞艇（Airship）类型

    /**
     * @brief Send MAV_CMD_DO_GRIPPER command to trigger specified action in the vehicle
     *
     * @param gripperAction Gripper action to trigger
    */

    void setGripperAction(GRIPPER_ACTIONS gripperAction); //设置机械臂的动作，参数：gripperAction：GRIPPER_ACTIONS 枚举，表示要执行的动作
    Q_INVOKABLE void sendGripperAction(QGCMAVLink::GRIPPER_OPTIONS gripperOption);//功能：发送机械臂动作命令到无人机，参数：gripperOption：QGCMAVLink::GRIPPER_OPTIONS 枚举，表示要执行的动作选项

    void pairRX(int rxType, int rxSubType);//配置接收器（可能用于无线电接收器或其他接收设备），rxType：接收器类型。rxSubType：接收器子类型

    bool fixedWing() const;//查无人机是否为固定翼类型
    bool multiRotor() const;//检查无人机是否为多旋翼类型
    bool vtol() const;//检查无人机是否为垂直起降类型
    bool rover() const;//检查无人机是否为地面车辆类型
    bool sub() const;//检查无人机是否为潜艇类型

    bool supportsThrottleModeCenterZero () const;//检查是否支持油门中位零
    bool supportsNegativeThrust         ();//检查是否支持负推力
    bool supportsRadio                  () const; //检查是否支持无线电控制
    bool supportsJSButton               () const;//检查是否支持JS按钮
    bool supportsMotorInterference      () const;//检查是否支持电机干扰检测
    bool supportsTerrainFrame           () const; //检查是否支持地形框架

    void setGuidedMode(bool guidedMode); //设置引导模式

    QString prearmError() const { return _prearmError; } //获取预武装错误信息
    void setPrearmError(const QString& prearmError); //设置预武装错误信息，参数：prearmError，QString 类型，包含错误信息

    QmlObjectListModel* cameraTriggerPoints () { return &_cameraTriggerPoints; } //获取相机触发点列表

    //-- Mavlink Logging
    void startMavlinkLog();//启动 MAVLink 日志记录
    void stopMavlinkLog();//停止 MAVLink 日志记录

    /// Requests the specified data stream from the vehicle
    ///     @param stream Stream which is being requested
    ///     @param rate Rate at which to send stream in Hz
    ///     @param sendMultiple Send multiple time to guarantee Vehicle reception
    void requestDataStream(MAV_DATA_STREAM stream, uint16_t rate, bool sendMultiple = true);//请求无人机发送指定的数据流。stream：指定请求的数据流类型。rate：指定发送数据流的速率（Hz）。sendMultiple：指定是否多次发送以确保无人机接收

    // The follow method are used to turn on/off the tracking of settings updates for firmware/vehicle type on offline vehicles.
    void trackFirmwareVehicleTypeChanges(void); //开启固件/车辆类型的离线车辆跟踪更新
    void stopTrackingFirmwareVehicleTypeChanges(void);//关闭固件/车辆类型的离线车辆跟踪更新

    float           latitude                    () { return static_cast<float>(_coordinate.latitude()); } //获取无人机的纬度值
    float           longitude                   () { return static_cast<float>(_coordinate.longitude()); }//获取无人机的经度值
    int             rcRSSI                      () const{ return _rcRSSI; } //获取接收信号强度指示（Received Signal Strength Indicator）
    bool            px4Firmware                 () const { return _firmwareType == MAV_AUTOPILOT_PX4; }//检查无人机的固件类型
    bool            apmFirmware                 () const { return _firmwareType == MAV_AUTOPILOT_ARDUPILOTMEGA; }
    bool            genericFirmware             () const { return !px4Firmware() && !apmFirmware(); }
    uint            messagesReceived            () const{ return _messagesReceived; }//获取遥测消息的接收数量
    uint            messagesSent                () const{ return _messagesSent; }//获取遥测消息的发送数量
    uint            messagesLost                () const{ return _messagesLost; }//获取遥测消息的丢失数量
    bool            flying                      () const { return _flying; }//检查无人机是否正在飞行
    bool            landing                     () const { return _landing; }//检查无人机是否正在飞行或正在降落
    bool            guidedMode                  () const;//检查无人机是否处于引导模式
    bool            vtolInFwdFlight             () const { return _vtolInFwdFlight; }//检查无人机是否在飞行中启用了垂直起降（VTOL）模式
    uint8_t         baseMode                    () const { return _base_mode; }//获取无人机的基础飞行模式，返回值：uint8_t 和 uint32_t 类型，表示模式编号
    uint32_t        customMode                  () const { return _custom_mode; }//获取无人机的自定义模式，返回值：uint8_t 和 uint32_t 类型，表示模式编号
    bool            isOfflineEditingVehicle     () const { return _offlineEditingVehicle; }//检查无人机是否处于离线编辑模式
    QString         brandImageIndoor            () const; //获取无人机品牌的室内图像路径
    QString         brandImageOutdoor           () const;//获取无人机品牌的室外图像路径
    int             sensorsPresentBits          () const { return static_cast<int>(_onboardControlSensorsPresent); }//获取传感器的状态位掩码
    int             sensorsEnabledBits          () const { return static_cast<int>(_onboardControlSensorsEnabled); }
    int             sensorsHealthBits           () const { return static_cast<int>(_onboardControlSensorsHealth); }
    int             sensorsUnhealthyBits        () const { return static_cast<int>(_onboardControlSensorsUnhealthy); }
    QString         missionFlightMode           () const; //获取当前任务飞行模式
    QString         pauseFlightMode             () const;//获取暂停飞行模式
    QString         rtlFlightMode               () const;//获取 RTL（Return-To-Launch）飞行模式
    QString         smartRTLFlightMode          () const;//获取智能 RTL 飞行模式
    bool            supportsSmartRTL            () const;
    QString         landFlightMode              () const; //获取着陆飞行模式
    QString         takeControlFlightMode       () const;//获取接管飞行模式
    QString         followFlightMode            () const;//获取跟随飞行模式
    QString         motorDetectionFlightMode    () const;//获取电机检测飞行模式
    QString         stabilizedFlightMode        () const;//获取稳定飞行模式
    double          defaultCruiseSpeed          () const { return _defaultCruiseSpeed; } //获取默认巡航速度
    double          defaultHoverSpeed           () const { return _defaultHoverSpeed; }//获取默认悬停速度
    QString         firmwareTypeString          () const; //获取固件类型字符串
    QString         vehicleTypeString           () const; //获取车辆类型字符串，返回值：QString 类型，表示车辆类型的描述
    int             telemetryRRSSI              () const{ return _telemetryRRSSI; }//获取遥测信号强度和统计信息
    int             telemetryLRSSI              () const{ return _telemetryLRSSI; }
    unsigned int    telemetryRXErrors           () const{ return _telemetryRXErrors; }
    unsigned int    telemetryFixed              () const{ return _telemetryFixed; }
    unsigned int    telemetryTXBuffer           () const{ return _telemetryTXBuffer; }
    int             telemetryLNoise             () const{ return _telemetryLNoise; }
    int             telemetryRNoise             () const{ return _telemetryRNoise; }
    bool            autoDisarm                  ();//检查是否自动解除武装
    bool            orbitActive                 () const { return _orbitActive; }//检查轨道模式是否激活
    QGCMapCircle*   orbitMapCircle              () { return &_orbitMapCircle; }//获取轨道圆的 QGCMapCircle 对象
    bool            readyToFlyAvailable         () const{ return _readyToFlyAvailable; }//检查是否准备好起飞
    bool            readyToFly                  () const{ return _readyToFly; }
    bool            allSensorsHealthy           () const{ return _allSensorsHealthy; }//检查所有传感器是否健康
    QObject*        sysStatusSensorInfo         () { return &_sysStatusSensorInfo; }//获取系统传感器信息对象
    bool            requiresGpsFix              () const { return static_cast<bool>(_onboardControlSensorsPresent & QGCMAVLink::SysStatusSensorGPS); }//检查是否需要 GPS 固定
    bool            hilMode                     () const { return _base_mode & MAV_MODE_FLAG_HIL_ENABLED; } //检查是否启用了高清晰模式（HIL）
    Actuators*      actuators                   () const { return _actuators; }//获取执行器对象列表

    /// Get the maximum MAVLink protocol version supported
    /// @return the maximum version
    unsigned        maxProtoVersion         () const { return _maxProtoVersion; }//获取支持的最大 MAVLink 协议版本

    bool            mavlinkSigning          () const { return _mavlinkSigning; }//检查 MAVLink 消息是否签名

    void startCalibration   (QGCMAVLink::CalibrationType calType);//开始特定类型的校准
    void stopCalibration    (bool showError);//停止校准，并可选地显示错误信息

    void startUAVCANBusConfig(void);//用于启动 UAVCAN 总线配置
    void stopUAVCANBusConfig(void);//用于停止 UAVCAN 总线配置

    //这些函数返回对各种事实组（Fact Groups）的引用，这些事实组包含了与无人机状态相关的各种事实（Fact
    FactGroup* vehicleFactGroup             () { return _vehicleFactGroup; }//管理无人机相关信息的事实组
    FactGroup* gpsFactGroup                 () { return &_gpsFactGroup; }//获取 GPS 相关事实组
    FactGroup* gps2FactGroup                () { return &_gps2FactGroup; }//获取第二个 GPS 相关事实组（如果有的话）
    FactGroup* windFactGroup                () { return &_windFactGroup; }//获取风速和风向相关的事实组
    FactGroup* vibrationFactGroup           () { return &_vibrationFactGroup; }//获取振动相关的事实组
    FactGroup* temperatureFactGroup         () { return &_temperatureFactGroup; }//获取温度相关的事实组动相关的事实组
    FactGroup* clockFactGroup               () { return &_clockFactGroup; }//获取时钟相关的事实组
    FactGroup* setpointFactGroup            () { return &_setpointFactGroup; }//获取设定点（如航点）相关的事实组
    FactGroup* distanceSensorFactGroup      () { return &_distanceSensorFactGroup; }//获取距离传感器相关的事实组
    FactGroup* localPositionFactGroup       () { return &_localPositionFactGroup; }//获取本地位置（例如 GPS 位置）相关的事实组
    FactGroup* localPositionSetpointFactGroup() { return &_localPositionSetpointFactGroup; }//获取本地设定点位置相关的事实组
    FactGroup* escStatusFactGroup           () { return &_escStatusFactGroup; }//获取紧急停止（ESC）状态相关的事实组
    FactGroup* estimatorStatusFactGroup     () { return &_estimatorStatusFactGroup; }//获取估计器状态相关的事实组
    FactGroup* terrainFactGroup             () { return &_terrainFactGroup; }//获取地形相关的事实组
    FactGroup* hygrometerFactGroup          () { return &_hygrometerFactGroup; }//获取气压计相关的事实组
    FactGroup* generatorFactGroup           () { return &_generatorFactGroup; }//获取发电机相关的事实组
    FactGroup* efiFactGroup                 () { return &_efiFactGroup; }//获取 EFI（电子燃油喷射）相关的事实组
    FactGroup* rpmFactGroup                 () { return &_rpmFactGroup; }//获取转速相关的事实组
    QmlObjectListModel* batteries           () { return &_batteryFactGroupListModel; } //获取电池状态相关的事实组列表
     QmlObjectListModel* hydrogenBatteries           () { return &_hydrogenbatteryFactGroupListModel; } //获取电池状态相关的事实组列表

    MissionManager*                 missionManager      () { return _missionManager; }//获取任务管理器对象的引用，该对象负责管理无人机的任务
    GeoFenceManager*                geoFenceManager     () { return _geoFenceManager; }//获取地理围栏管理器对象的引用，该对象负责处理地理围栏相关的功能
    RallyPointManager*              rallyPointManager   () { return _rallyPointManager; }//获取拉力赛点管理器对象的引用，该对象负责管理拉力赛点
    ParameterManager*               parameterManager    () { return _parameterManager; }//获取参数管理器对象的引用，该对象负责管理无人机的参数
    ParameterManager*               parameterManager    () const { return _parameterManager; }//获取参数管理器对象的引用，该对象负责管理无人机的参数，被标记为 const，表示它返回的对象是常量的，即在对象的生命周期内不会改变
    VehicleLinkManager*             vehicleLinkManager  () { return _vehicleLinkManager; }//获取车辆链接管理器对象的引用，该对象负责管理无人机的通信链接
    FTPManager*                     ftpManager          () { return _ftpManager; }//获取 FTP 管理器对象的引用，该对象负责处理 FTP 相关的功能
    ComponentInformationManager*    compInfoManager     () { return _componentInformationManager; }//获取组件信息管理器对象的引用，该对象负责管理无人机的组件信息
    VehicleObjectAvoidance*         objectAvoidance     () { return _objectAvoidance; }//获取避障管理器对象的引用，该对象负责处理避障相关功能
    Autotune*                       autotune            () const { return _autotune; }//获取自动调参对象的引用，该对象负责自动调参功能
    RemoteIDManager*                remoteIDManager     () { return _remoteIDManager; }//获取远程 ID 管理器对象的引用，该对象负责管理远程 ID

    static void showCommandAckError(const mavlink_command_ack_t& ack);//显示命令确认（acknowledgement）错误，参数：ack，表示收到的命令确认信息

    /// Sends the specified MAV_CMD to the vehicle. If no Ack is received command will be retried. If a sendMavCommand is already in progress
    /// the command will be queued and sent when the previous command completes.
    ///     @param compId Component to send to.
    ///     @param command MAV_CMD to send
    ///     @param showError true: Display error to user if command failed, false:  no error shown
    /// Signals: mavCommandResult on success or failure
    //发送指定的 MAVLink 命令到无人机。compId：组件 ID，指定发送命令的目标组件。command：要发送的 MAVLink 命令。showError：如果命令失败是否显示错误给用户。param1 到 param7：命令参数
    void sendMavCommand(int compId, MAV_CMD command, bool showError, float param1 = 0.0f, float param2 = 0.0f, float param3 = 0.0f, float param4 = 0.0f, float param5 = 0.0f, float param6 = 0.0f, float param7 = 0.0f);

    //延迟发送 MAVLink 命令。compId：组件 ID。command：要发送的命令。showError：如果命令失败是否显示错误给用户。milliseconds：延迟发送的时间（毫秒）。param1 到 param7：命令参数
    void sendMavCommandDelayed(int compId, MAV_CMD command, bool showError, int milliseconds, float param1 = 0.0f, float param2 = 0.0f, float param3 = 0.0f, float param4 = 0.0f, float param5 = 0.0f, float param6 = 0.0f, float param7 = 0.0f);

    //发送带有整数参数的 MAVLink 命令。compId：组件 ID。command：要发送的命令。frame：命令帧类型。showError：如果命令失败是否显示错误给用户。param1 到 param7：命令参数。
    void sendMavCommandInt(int compId, MAV_CMD command, MAV_FRAME frame, bool showError, float param1, float param2, float param3, float param4, double param5, double param6, float param7);

    ///
    /// \brief isMavCommandPending
    ///     Query whether the specified MAV_CMD is in queue to be sent or has
    /// already been sent but whose reply has not yet been received and whose
    /// timeout has not yet expired.
    ///
    ///     Or, said another way: if you call `sendMavCommand(compId, command, true, ...)`
    /// will an error be shown because you (or another part of QGC) has already
    /// sent that command?
    ///
    /// \param targetCompId
    /// \param command
    /// \return
    ///
    bool isMavCommandPending(int targetCompId, MAV_CMD command);//检查指定的 MAVLink 命令是否正在等待发送或确认。targetCompId：目标组件 ID。command：命令

    /// Same as sendMavCommand but available from Qml.
    //从 QML 发送 MAVLink 命令。compId：组件 ID。command：命令编号。showError：如果命令失败是否显示错误给用户。param1 到 param7：命令参数
    Q_INVOKABLE void sendCommand(int compId, int command, bool showError, double param1 = 0.0, double param2 = 0.0, double param3 = 0.0, double param4 = 0.0, double param5 = 0.0, double param6 = 0.0, double param7 = 0.0);




    //功能：定义命令失败的不同原因
    // MavCmdResultCommandResultOnly：命令结果仅指定成功/失败信息。
    // MavCmdResultFailureNoResponseToCommand：命令没有收到响应。
    // MavCmdResultFailureDuplicateCommand：无法发送命令，因为重复命令正在等待响应。
    typedef enum {
        MavCmdResultCommandResultOnly,          ///< commandResult specifies full success/fail info
        MavCmdResultFailureNoResponseToCommand, ///< No response from vehicle to command
        MavCmdResultFailureDuplicateCommand,    ///< Unable to send command since duplicate is already being waited on for response
    } MavCmdResultFailureCode_t;





    /// Callback for sendMavCommandWithHandler which handles MAV_RESULT_IN_PROGRESS acks
    ///     @param progressHandlerData  Opaque data passed in to sendMavCommand call
    ///     @param ack                  Received COMMAND_ACK
    typedef void (*MavCmdProgressHandler)(void* progressHandlerData, int compId, const mavlink_command_ack_t& ack);//回调函数类型，用于处理 MAVLink 命令的进度确认。progressHandlerData：传递给 sendMavCommand 调用的不透明数据。compId：组件 ID。ack：收到的命令确认信息。

    /// Callback for sendMavCommandWithHandler which handles all acks which are not MAV_RESULT_IN_PROGRESS
    ///     @param resultHandlerData    Opaque data passed in to sendMavCommand call
    ///     @param ack                  Received COMMAND_ACK
    ///     @param failureCode          Failure reason. If not MavCmdResultCommandResultOnly only ack.result == MAV_RESULT_FAILED is valid.

    //定义了一个回调函数的类型，该函数接受四个参数：一个指向 void 的指针、一个整数（组件 ID）、一个 mavlink_command_ack_t 类型（命令确认信息）和一个 MavCmdResultFailureCode_t 类型（命令执行失败代码）
    typedef void (*MavCmdResultHandler)(void* resultHandlerData, int compId, const mavlink_command_ack_t& ack, MavCmdResultFailureCode_t failureCode);

    // Callback info for sendMavCommandWithHandler
    //定义了一个结构体，用于存储与命令确认相关的回调信息。它包含回调函数指针、回调数据指针和进度处理函数指针
    typedef struct MavCmdAckHandlerInfo_s {
        MavCmdResultHandler     resultHandler;          ///> nullptr for no handler
        void*                   resultHandlerData; 
        MavCmdProgressHandler   progressHandler;
        void*                   progressHandlerData;    ///> nullptr for no handler
    } MavCmdAckHandlerInfo_t;

    /// Sends the command and calls the callback with the result
    //发送 MAVLink 命令并调用提供的回调函数，该函数接受命令确认信息和错误代码，ackHandlerInfo：指向 MavCmdAckHandlerInfo_t 结构的指针，包含回调信息。compId：组件 ID。command：要发送的 MAVLink 命令。param1 到 param7：命令参数。
    void sendMavCommandWithHandler(
        const MavCmdAckHandlerInfo_t* ackHandlerInfo,   ///> nullptr to signale no handlers
        int compId, MAV_CMD command, 
        float param1 = 0.0f, float param2 = 0.0f, float param3 = 0.0f, float param4 = 0.0f, float param5 = 0.0f, float param6 = 0.0f, float param7 = 0.0f);

    /// Sends the command and calls the callback with the result
    ///     @param resultHandler    Callback for result, nullptr for no callback
    ///     @param resultHandleData Opaque data passed through callback
    //与 sendMavCommandWithHandler 类似，但接受整数参数，ackHandlerInfo：指向 MavCmdAckHandlerInfo_t 结构的指针。compId：组件 ID。command：要发送的 MAVLink 命令。frame：命令帧类型。param1 到 param7：命令参数。
    void sendMavCommandIntWithHandler(
        const MavCmdAckHandlerInfo_t* ackHandlerInfo,   ///> nullptr to signale no handlers
        int compId, MAV_CMD command, MAV_FRAME frame, 
        float param1 = 0.0f, float param2 = 0.0f, float param3 = 0.0f, float param4 = 0.0f, double param5 = 0.0f, double param6 = 0.0f, float param7 = 0.0f);

    /// Sends the command and calls the fallback lambda function in
    /// case the command is MAV_RESULT_UNSUPPORTED
    //发送 MAVLink 命令并调用提供的 lambda 函数作为回调，如果命令不被支持则调用回退函数。lambda：一个 lambda 表达式，用于命令确认的回调。compId：组件 ID。command：要发送的 MAVLink 命令。showError：如果命令失败是否显示错误给用户。param1 到 param7：命令参数。
    void sendMavCommandWithLambdaFallback(
        std::function<void()> lambda,
        int compId, MAV_CMD command,
        bool showError,
        float param1 = 0.0f, float param2 = 0.0f, float param3 = 0.0f, float param4 = 0.0f, float param5 = 0.0f, float param6 = 0.0f, float param7 = 0.0f);


    //定义了请求消息操作可能遇到的不同类型的错误代码
    // RequestMessageNoFailure：没有失败。
    // RequestMessageFailureCommandError：命令错误。
    // RequestMessageFailureCommandNotAcked：命令未被确认。
    // RequestMessageFailureMessageNotReceived：未收到消息。
    // RequestMessageFailureDuplicateCommand：由于另一个请求消息正在等待响应，无法发送命令。
    typedef enum {
        RequestMessageNoFailure,
        RequestMessageFailureCommandError,
        RequestMessageFailureCommandNotAcked,
        RequestMessageFailureMessageNotReceived,
        RequestMessageFailureDuplicateCommand,    ///< Unabled to send command since another request message isduplicate is already being waited on for response
    } RequestMessageResultHandlerFailureCode_t;

    /// Callback for requestMessage
    ///     @param resultHandlerData    Opaque data which was passed in to requestMessage call
    ///     @param commandResult        Result from ack to REQUEST_MESSAGE command
    ///     @param failureCode          Failure code
    ///     @param message              Received message which was requested
    //定义了一个回调函数类型，用于处理请求消息操作的结果。resultHandlerData：传递给 requestMessage 调用的不透明数据。commandResult：MAV_RESULT 类型，表示 REQUEST_MESSAGE 命令的结果。failureCode：RequestMessageResultHandlerFailureCode_t 类型，表示失败代码。message：mavlink_message_t 类型，表示请求的消息
    typedef void (*RequestMessageResultHandler)(void* resultHandlerData, MAV_RESULT commandResult, RequestMessageResultHandlerFailureCode_t failureCode, const mavlink_message_t& message);

    /// Requests the vehicle to send the specified message. Will retry a number of times.
    ///     @param resultHandler Callback for result
    ///     @param resultHandlerData Opaque data passed back to resultHandler
    //请求无人机发送指定的消息，并重试多次。resultHandler：指向 RequestMessageResultHandler 类型的回调函数。resultHandlerData：回调函数使用的不透明数据。compId：组件 ID。messageId：消息 ID。param1 到 param5：消息参数。
    void requestMessage(RequestMessageResultHandler resultHandler, void* resultHandlerData, int compId, int messageId, float param1 = 0.0f, float param2 = 0.0f, float param3 = 0.0f, float param4 = 0.0f, float param5 = 0.0f);

    int firmwareMajorVersion() const { return _firmwareMajorVersion; } //功能：获取固件的主版本号
    int firmwareMinorVersion() const { return _firmwareMinorVersion; }//功能：获取固件的次版本号
    int firmwarePatchVersion() const { return _firmwarePatchVersion; }//获取固件的补丁版本号
    int firmwareVersionType() const { return _firmwareVersionType; }//获取固件的类型
    int firmwareCustomMajorVersion() const { return _firmwareCustomMajorVersion; } //获取自定义固件的主版本号
    int firmwareCustomMinorVersion() const { return _firmwareCustomMinorVersion; }//获取自定义固件的次版本号
    int firmwareCustomPatchVersion() const { return _firmwareCustomPatchVersion; }//获取自定义固件的补丁版本号
    int firmwareBoardVendorId() const { return _firmwareBoardVendorId; }//获取固件板的供应商 ID
    int firmwareBoardProductId() const { return _firmwareBoardProductId; } //获取固件板的产品 ID
    QString firmwareVersionTypeString() const;//获取固件版本的字符串表示
    void setFirmwareVersion(int majorVersion, int minorVersion, int patchVersion, FIRMWARE_VERSION_TYPE versionType = FIRMWARE_VERSION_TYPE_OFFICIAL);//设置固件版本信息。majorVersion、minorVersion、patchVersion：固件的主版本号、次版本号和补丁版本。versionType：固件版本类型，默认为官方版本
    void setFirmwareCustomVersion(int majorVersion, int minorVersion, int patchVersion);//设置自定义固件版本信息。majorVersion、minorVersion、patchVersion：自定义固件的主版本号、次版本号和补丁版本
    static const int versionNotSetValue = -1;

    QString gitHash() const { return _gitHash; }//获取固件的 Git 提交云哈希值
    quint64 vehicleUID() const { return _uid; } //获取无人机的唯一标识符（UID）
    QString vehicleUIDStr();//获取无人机 UID 的字符串表示

    bool soloFirmware() const { return _soloFirmware; } //检查是否为 Solo 固件
    void setSoloFirmware(bool soloFirmware);//设置是否为 Solo 固件。soloFirmware：bool 类型，true 表示是 Solo 固件，false 表示不是

    int defaultComponentId() const{ return _defaultComponentId; }//获取默认组件 ID

    /// Sets the default component id for an offline editing vehicle
    void setOfflineEditingDefaultComponentId(int defaultComponentId);//设置离线编辑无人机的默认组件 ID，defaultComponentId：默认组件 ID

    /// @return -1 = Unknown, Number of motors on vehicle
    int motorCount();//获取无人机的电机数量。返回值：int 类型，表示电机数量

    /// @return true: Motors are coaxial like an X8 config, false: Quadcopter for example
    bool coaxialMotors();//检查电机是否为同轴配置（例如 X8 配置）。bool 类型，true 表示同轴配置，false 表示非同轴配置（例如四旋翼）

    /// @return true: X confiuration, false: Plus configuration
    bool xConfigMotors();//检查是否为 X 配置（例如 Plus 配置）。返回值：bool 类型，true 表示 X 配置，false 表示非 X 配置

    /// @return Firmware plugin instance data associated with this Vehicle
    class FirmwarePluginInstanceData* firmwarePluginInstanceData() { return _firmwarePluginInstanceData; }//获取与此无人机关联的固件插件实例数据。返回值：FirmwarePluginInstanceData* 类型，指向固件插件实例数据

    /// Sets the firmware plugin instance data associated with this Vehicle. This object will be parented to the Vehicle
    /// and destroyed when the vehicle goes away.
    void setFirmwarePluginInstanceData(FirmwarePluginInstanceData* firmwarePluginInstanceData);//设置与此无人机关联的固件插件实例数据，

    QString vehicleImageOpaque  () const;//获取无人机的不透明图像。返回值：QString 类型，表示图像路径或URL
    QString vehicleImageOutline () const;//获取无人机的轮廓图像的路径或URL

    QVariant                    mainStatusIndicatorContentItem  ();//获取主状态指示器内容项。QVariant 类型，包含主状态指示器的内容。
    const QVariantList&         toolIndicators                  ();//获取工具指示器列表
    const QVariantList&         modeIndicators                  ();//获取模式指示器列表
    const QVariantList&         staticCameraList                () const;//获取静态相机列表

    bool capabilitiesKnown      () const { return _capabilityBitsKnown; }//检查能力是否已知和获取能力位掩码
    uint64_t capabilityBits     () const { return _capabilityBits; }    // Change signalled by capabilityBitsChanged

    QGCCameraManager*           cameraManager       () { return _cameraManager; } //获取相机管理器对象的引用。返回值：QGCCameraManager* 类型，指向相机管理器对象的指针
    QString                     hobbsMeter          ();//获取HOBBS（Health Of Board System）仪表，返回值：QString 类型，表示HOBBS仪表的值

    /// The vehicle is responsible for making the initial request for the Plan.
    /// @return: true: initial request is complete, false: initial request is still in progress;
    bool initialPlanRequestComplete() const { return _initialPlanRequestComplete; }

    void forceInitialPlanRequestComplete(); //强制标记初始计划请求为完成

    void _setFlying(bool flying); //设置无人机的飞行位置状态
    void _setLanding(bool landing);//设置无人机的降落位置状态
    void _setHomePosition(QGeoCoordinate& homeCoord);//设置无人机家位置状态
    void _setMaxProtoVersion(unsigned version);//设置最大协议版本
    void _setMaxProtoVersionFromBothSources();//设置无人机固件插件实例数据中的最大协议版本，该版本将从两个来源中获取（可能是本地和远程）

    /// Vehicle is about to be deleted
    void prepareDelete();//准备删除无人机

    /// Delete gimbal controller, handy for RequestMessageTest.cc, otherwise gimbal controller message requests will mess with this test
    void deleteGimbalController();//删除云台控制器，这在 RequestMessageTest.cc 中很有用，否则云台控制器的消息请求会干扰测试

    /// Delete camera manager, just for testing
    void deleteCameraManager();//删除相机管理器，仅用于测试

    quint64     mavlinkSentCount        () const{ return _mavlinkSentCount; }     //计算发送到无人机的 MAVLink 消息的总数   /// Calculated total number of messages sent to us
    quint64     mavlinkReceivedCount    () const{ return _mavlinkReceivedCount; }   //获取成功接收的 MAVLink 消息总数 /// Total number of sucessful messages received
    quint64     mavlinkLossCount        () const{ return _mavlinkLossCount; }      //获取丢失的 MAVLink 消息总数  /// Total number of lost messages
    float       mavlinkLossPercent      () const{ return _mavlinkLossPercent; }      //获取 MAVLink 消息的丢失率/// Running loss rate

    bool        isROIEnabled            () const{ return _isROIEnabled; }//检查 ROI（感兴趣区域）功能是否启用

    CheckList   checkListState          () { return _checkListState; }//获取检查列表的状态
    void        setCheckListState       (CheckList cl)  { _checkListState = cl; emit checkListStateChanged(); }//设置检查列表的状态，参数：cl：CheckList 枚举值，表示新的检查列表状态。触发信号：checkListStateChanged，当检查列表状态改变时发出

    double loadProgress                 () const { return _loadProgress; }//获取加载进度

    void setEventsMetadata(uint8_t compid, const QString& metadataJsonFileName);//设置事件的元数据。compid：组件 ID；metadataJsonFileName：元数据 JSON 文件名
    void setActuatorsMetadata(uint8_t compid, const QString& metadataJsonFileName);//设置执行器的元数据。参数：compid，组件 ID；metadataJsonFileName，元数据 JSON 文件名

    HealthAndArmingCheckReport* healthAndArmingCheckReport() { return &_healthAndArmingCheckReport; }//获取健康和武装检查报告

    GimbalController* gimbalController  () { return _gimbalController; }//获取云台控制器对象的引用

public slots:
    void setVtolInFwdFlight                 (bool vtolInFwdFlight);//设置 VTOL（垂直起降）飞行中的航向误差（VTOL），vtolInFwdFlight，布尔值，表示是否启用航向误差
    void _offlineFirmwareTypeSettingChanged (QVariant varFirmwareType); //设置离线固件类型。此槽函数应仅由任务控制器（MissionControler）使用，以从计划文件中设置固件。varFirmwareType，QVariant 类型，表示固件类型 Should only be used by MissionControler to set firmware from Plan file
    void _offlineVehicleTypeSettingChanged  (QVariant varVehicleType);  //设置离线车辆类型。此槽函数应仅由任务控制器使用，以从计划文件中设置车辆类型。参数：varVehicleType，QVariant 类型，表示车辆类型 Should only be used by MissionController to set vehicle type from Plan file

signals:
    void hydrogenBatteriesChanged();
    void coordinateChanged              (QGeoCoordinate coordinate);//当坐标改变时发出信号，参数：coordinate，QGeoCoordinate 类型，表示新的坐标
    void joystickEnabledChanged         (bool enabled);//当操纵杆启用状态改变时发出信号。参数：enabled，布尔值，表示操纵杆是否启用
    void mavlinkMessageReceived         (const mavlink_message_t& message);//当接收到 MAVLink 消息时发出信号，参数：message，mavlink_message_t 类型，表示接收到的消息
    void homePositionChanged            (const QGeoCoordinate& homePosition);//当返航点（home position）改变时发出信号，参数：homePosition，QGeoCoordinate 类型，表示新的返航点坐标
    void armedPositionChanged();//当武装位置改变时发出信号
    void armedChanged                   (bool armed);//当无人机武装状态改变时发出信号。参数：armed，布尔值，表示无人机是否已解锁（准备好起飞）
    void flightModeChanged              (const QString& flightMode);//当飞行模式改变时发出信号，参数：flightMode，QString 类型，表示新的飞行模式
    void flyingChanged                  (bool flying);//当无人机飞行状态改变时发出信号。参数：flying，布尔值，表示无人机是否正在飞行
    void landingChanged                 (bool landing);//当降落状态改变时发出信号，参数：landing，布尔值，表示无人机是否正在降落
    void guidedModeChanged              (bool guidedMode);//当引导模式改变时发出信号，参数：guidedMode，布尔值，表示是否处于引导模式
    void vtolInFwdFlightChanged         (bool vtolInFwdFlight);//当 VTOL 飞行中的航向误差改变时发出信号，参数：vtolInFwdFlight，布尔值，表示 VTOL 飞行中的航向误差是否启用
    void prearmErrorChanged             (const QString& prearmError);//当预武装错误信息改变时发出信号。参数：prearmError，QString 类型，表示预武装错误信息
    void soloFirmwareChanged            (bool soloFirmware);//功能：当 Solo 固件状态改变时发出信号。参数：soloFirmware，布尔值，表示是否为 Solo 固件
    void defaultCruiseSpeedChanged      (double cruiseSpeed);//当默认巡航速度改变时发出信号，参数：cruiseSpeed，double 类型，表示新的巡航速度
    void defaultHoverSpeedChanged       (double hoverSpeed);//当默认悬停速度改变时发出信号。参数：hoverSpeed，double 类型，表示新的悬停速度
    void firmwareTypeChanged            ();//当固件类型改变时发出信号
    void vehicleTypeChanged             ();//当车辆类型改变时发出信号
    void cameraManagerChanged           ();//当相机管理器改变时发出信号
    void hobbsMeterChanged              ();//当 HOBBS 仪表改变时发出信号
    void capabilitiesKnownChanged       (bool capabilitiesKnown);//当能力信息已知状态改变时发出信号
    void initialPlanRequestCompleteChanged(bool initialPlanRequestComplete); //当初始计划请求完成状态改变时发出信号
    void capabilityBitsChanged          (uint64_t capabilityBits);//当能力位掩码改变时发出信号
    void toolIndicatorsChanged          ();//当工具指示器改变时发出信号
    void modeIndicatorsChanged          ();//当模式指示器改变时发出信号
    void calibrationEventReceived       (int uasid, int componentid, int severity, QSharedPointer<events::parser::ParsedEvent> event);//当接收到校准事件时发出信号
    void checkListStateChanged          ();//当检查列表状态改变时发出信号
    void longitudeChanged               ();//当经度改变时发出信号
    void currentConfigChanged           ();//当当前配置发生变化时
    void rcRSSIChanged                  (int rcRSSI);//当接收信号强度指示（Received Signal Strength Indicator）发生变化时，参数：rcRSSI，表示新的接收信号强度值，
    void telemetryRRSSIChanged          (int value);//当遥测信号的接收信号强度发生变化时，参数：value，表示新的接收信号强度值
    void telemetryLRSSIChanged          (int value);//当遥测信号的发送信号强度发生变化，参数：value，表示新的发送信号强度值。
    void telemetryRXErrorsChanged       (unsigned int value);//当遥测信号的接收错误数量发生变化时，参数：value，表示新的接收错误数量
    void telemetryFixedChanged          (unsigned int value);//当遥测信号的固定计数发生变化时，参数：value，表示新的固定计数。
    void telemetryTXBufferChanged       (unsigned int value);//当遥测信号的发送缓冲区发生变化时，参数：value，表示新的发送缓冲区大小
    void telemetryLNoiseChanged         (int value);//当遥测信号的接收噪声水平发生变化时，参数：value，表示新的接收噪声水平
    void telemetryRNoiseChanged         (int value);//当遥测信号的发送噪声水平发生变化时，参数：value，表示新的发送噪声水平
    void autoDisarmChanged              ();//当自动解除武装状态发生变化时
    void flightModesChanged             ();//当飞行模式改变时发出信号
    void sensorsPresentBitsChanged      (int sensorsPresentBits);//当传感器存在位掩码改变时发出信号
    void sensorsEnabledBitsChanged      (int sensorsEnabledBits);//当传感器启用位掩码改变时发出信号
    void sensorsHealthBitsChanged       (int sensorsHealthBits);//当传感器健康位掩码改变时发出信号
    void sensorsUnhealthyBitsChanged    (int sensorsUnhealthyBits);//当传感器不健康位掩码改变时发出信号
    void orbitActiveChanged             (bool orbitActive);//当轨道活动状态改变时发出信号
    void readyToFlyAvailableChanged     (bool readyToFlyAvailable);//当允许准备好起飞的状态改变时发出信号
    void readyToFlyChanged              (bool readyToFy);//当准备好起飞的状态改变时发出信号
    void allSensorsHealthyChanged       (bool allSensorsHealthy);//当所有传感器健康状态改变时发出信号
    void requiresGpsFixChanged          ();//当是否需要 GPS 固定状态改变时发出信号
    void haveMRSpeedLimChanged          ();//当最大转速限制改变时发出信号
    void haveFWSpeedLimChanged          ();//当前向速度限制发生变化时

    void firmwareVersionChanged         ();//当固件版本改变时发出信号
    void firmwareCustomVersionChanged   ();//当自定义固件版本改变时发出信号
    void gitHashChanged                 (QString hash);//当 Git 提交云哈希改变时发出信号
    void vehicleUIDChanged              ();//当无人机 UID 改变时发出信号
    void loadProgressChanged            (float value);//当加载进度改变时发出信号

    /// New RC channel values coming from RC_CHANNELS message
    ///     @param channelCount Number of available channels, maxRcChannels max
    ///     @param pwmValues -1 signals channel not available
    void rcChannelsChanged              (int channelCount, int pwmValues[QGCMAVLink::maxRcChannels]);//当接收到新的遥控器通道值时发出信号，例如从 RC_CHANNELS 消息中接收到新的通道值，参数：通道数量和 PWM 值数组

    /// Remote control RSSI changed  (0% - 100%)
    void remoteControlRSSIChanged       (uint8_t rssi);//当远程控制信号强度指示（RSSI）改变时发出信号，参数：新的 RSSI 值

    // Mavlink Log Download
    //功能：处理 MAVLink 日志数据下载，参数：目标系统、组件、序列、首条消息、数据和确认状态
    void mavlinkLogData                 (Vehicle* vehicle, uint8_t target_system, uint8_t target_component, uint16_t sequence, uint8_t first_message, QByteArray data, bool acked);

    /// Signalled in response to usage of sendMavCommand
    ///     @param vehicleId        Vehicle which command was sent to
    ///     @param targetComponent  Component which command was sent to
    ///     @param command          Command which was sent
    ///     @param ackResult        MAV_RESULT returned in ack
    ///     @param failureCode      More detailed failure code Vehicle::MavCmdResultFailureCode_t
    void mavCommandResult               (int vehicleId, int targetComponent, int command, int ackResult, int failureCode);//响应发送 MAVLink 命令的结果。参数：车辆 ID、目标组件、命令、确认结果和失败代码

    // MAVlink Serial Data
    void mavlinkSerialControl           (uint8_t device, uint8_t flags, uint16_t timeout, uint32_t baudrate, QByteArray data);//控制 MAVLink 串行数据。参数：设备、标志、超时、波特率和数据

    // MAVLink protocol version
    void requestProtocolVersion         (unsigned version);//请求 MAVLink 协议版本，参数：协议版本
    void mavlinkStatusChanged           ();//功能：当 MAVLink 状态改变时发出信号
    void mavlinkSigningChanged          ();//功能：当 MAVLink 签名状态改变时发出信号

    void isROIEnabledChanged            ();//功能：当 ROI（感兴趣区域）功能启用状态改变时发出信号
    void roiCoordChanged                (const QGeoCoordinate& centerCoord);//当 ROI 坐标改变时发出信号。参数：新的 ROI 中心坐标
    void initialConnectComplete         ();//当初始连接完成时发出信号

    void sensorsParametersResetAck      (bool success);//当传感器参数重置确认时发出信号，重置操作是否成功

    void logEntry                       (uint32_t time_utc, uint32_t size, uint16_t id, uint16_t num_logs, uint16_t last_log_num);//记录日志条目信息，参数：时间、大小、ID、日志数量和最后日志编号
    void logData                        (uint32_t ofs, uint16_t id, uint8_t count, const uint8_t* data);//记录日志数据，参数：时间戳、ID、数据计数和数据

private slots:
    void _mavlinkMessageReceived            (LinkInterface* link, mavlink_message_t message);//功能：处理接收到的 MAVLink 消息
    void _sendMessageMultipleNext           ();//功能：发送下一个待发送的消息
    void _parametersReady                   (bool parametersReady);//功能：当参数准备好时调用
    void _remoteControlRSSIChanged          (uint8_t rssi);//处理远程控制信号强度指示（RSSI）变化。
    void _handleFlightModeChanged           (const QString& flightMode);//处理飞行模式改变
    void _announceArmedChanged              (bool armed);//宣布无人机是否已解锁（准备好起飞）
    void _offlineCruiseSpeedSettingChanged  (QVariant value);//处理离线巡航速度设置改变
    void _offlineHoverSpeedSettingChanged   (QVariant value);//处理离线悬停速度设置改变
    void _prearmErrorTimeout                ();//处理预解锁超时
    void _firstMissionLoadComplete          ();//处理首次任务加载完成
    void _firstGeoFenceLoadComplete         ();//处理首次地理围栏加载完成
    void _firstRallyPointLoadComplete       ();//处理首次拉力赛点加载完成
    void _sendMavCommandResponseTimeoutCheck();//检查发送 MAVLink 命令的响应超时
    void _clearCameraTriggerPoints          ();//清除相机触发点
    void _updateDistanceHeadingToHome       ();//更新到返航点的距离和航向
    void _updateMissionItemIndex            ();//更新任务项索引
    void _updateHeadingToNextWP             ();//更新航向到下一个航点的航向
    void _updateDistanceToGCS               ();//更新到地面控制站的距离
    void _updateHomepoint                   ();//更新返航点
    void _updateHobbsMeter                  ();//更新障碍物高度计
    void _vehicleParamLoaded                (bool ready);//当车辆参数加载完成时调用
    void _sendQGCTimeToVehicle              ();//发送 QGC 时间到车辆

    //处理和更新 MAVLink 遥测链路的状态。遥测链路的状态包括发送的消息数、接收的消息数和丢失的消息数，以及消息丢失的百分比
    //int uasId：表示无人机的系统 ID。uint64_t totalSent：表示发送的总消息数。uint64_t totalReceived：表示成功接收的总消息数。uint64_t totalLoss：表示丢失的总消息数。float lossPercent：表示消息丢失的百分比。
    void _mavlinkMessageStatus              (int uasId, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent);

    void _orbitTelemetryTimeout             ();//处理轨道遥测超时
    void _updateFlightTime                  ();//更新飞行时间
    void _gotProgressUpdate                 (float progressValue);//获取进度更新
    void _doSetHomeTerrainReceived          (bool success, QList<double> heights);//处理设置返航点地形成功或失败
    void _updateAltAboveTerrain             ();//更新高于地形的海拔
    void _altitudeAboveTerrainReceived      (bool sucess, QList<double> heights);//接收高于地形的海拔数据

   private:
    void _loadJoystickSettings          ();//加载操纵杆设置
    void _activeVehicleChanged          (Vehicle* newActiveVehicle);//当激活的无人机改变时调用
    void _captureJoystick               ();//捕获当前的操纵杆状态
    void _handlePing                    (LinkInterface* link, mavlink_message_t& message);//处理 PING 消息
    void _handleHomePosition            (mavlink_message_t& message);//处理返航点位置消息
    void _handleHeartbeat               (mavlink_message_t& message);//处理心跳消息，通常用于检测连接是否仍然活动
    void _handleCurrentMode             (mavlink_message_t& message);//处理当前飞行模式消息
    void _handleRadioStatus             (mavlink_message_t& message);//处理无线电状态消息
    void _handleRCChannels              (mavlink_message_t& message);//处理遥控器通道消息
    void _handleBatteryStatus           (mavlink_message_t& message);//处理电池状态消息


    void _handleHydrogenBattery       (mavlink_message_t& message); //处理氢燃料电池状态消息，我加的协议



    void _handleSysStatus               (mavlink_message_t& message);//处理系统状态消息
    void _handleExtendedSysState        (mavlink_message_t& message);//处理扩展系统状态消息
    void _handleCommandAck              (mavlink_message_t& message);//处理命令确认消息
    void _handleGpsRawInt               (mavlink_message_t& message);//处理原始 GPS 消息
    void _handleGlobalPositionInt       (mavlink_message_t& message);//处理全局位置整数消息
    void _handleHighLatency             (mavlink_message_t& message);//处理高延迟消息
    void _handleHighLatency2            (mavlink_message_t& message);//处理高延迟消息（第二种）
    void _handleOrbitExecutionStatus    (const mavlink_message_t& message);//处理执行或位执行状态消息
    void _handleGimbalOrientation       (const mavlink_message_t& message);//处理云台方向消息
    void _handleObstacleDistance        (const mavlink_message_t& message);//处理障碍物距离消息
    void _handleFenceStatus             (const mavlink_message_t& message);//处理围栏状态消息
    void _handleEvent(uint8_t comp_id, std::unique_ptr<events::parser::ParsedEvent> event);//处理特定组件的事件。
    // ArduPilot dialect messages
#if !defined(QGC_NO_ARDUPILOT_DIALECT)
    void _handleCameraFeedback          (const mavlink_message_t& message);//处理来自相机的反馈消息
#endif
    void _handleCameraImageCaptured     (const mavlink_message_t& message);//处理来自相机的捕获图像的消息
    void _missionManagerError           (int errorCode, const QString& errorMsg);//处理任务管理器错误
    void _geoFenceManagerError          (int errorCode, const QString& errorMsg);//处理地理围栏管理器的错误
    void _rallyPointManagerError        (int errorCode, const QString& errorMsg);//处理拉力赛点管理器的错误
    void _say                           (const QString& text);//输出一条文本信息
    QString _vehicleIdSpeech            ();//存储与无人机 ID 相关的语音信息
    void _handleMavlinkLoggingData      (mavlink_message_t& message);//处理 MAVLink 日志数据消息
    void _handleMavlinkLoggingDataAcked (mavlink_message_t& message);//处理 MAVLink 确认消息
    void _ackMavlinkLogData             (uint16_t sequence);//确认收到的 MAVLink 日志数据
    void _commonInit                    ();//初始化一些通用功能
    void _setupAutoDisarmSignalling     ();//设置自动解除武装信号
    void _setCapabilities               (uint64_t capabilityBits);//设置无人机的能力位掩码
    void _updateArmed                   (bool armed);//更新无人机的武装状态
    bool _apmArmingNotRequired          ();//否需要武装（arming）才能执行某些操作
    void _initializeCsv                 ();//初始化 CSV 文件处理相关的功能
    void _writeCsvLine                  ();//写入 CSV 文件的一行数据
    void _flightTimerStart              ();//控制飞行计时器的开始
    void _flightTimerStop               ();//控制飞行计时器的停止
    void _setMessageInterval            (int messageId, int rate);//设置消息发送的时间间隔
    EventHandler& _eventHandler         (uint8_t compid);//事件处理器和事件处理器的标识符
    bool setFlightModeCustom            (const QString& flightMode, uint8_t* base_mode, uint32_t* custom_mode);//设置自定义飞行模式

    static void _rebootCommandResultHandler(void* resultHandlerData, int compId, const mavlink_command_ack_t& ack, MavCmdResultFailureCode_t failureCode);//回调函数，用于处理命令执行结果

    int     _id;                   //MAVLink 系统的 ID ///< Mavlink system id
    int     _defaultComponentId;//MAVLink 默认组件 ID
    bool    _offlineEditingVehicle = false;//MAVLink 离线编辑车辆的状态 ///< true: This Vehicle is a "disconnected" vehicle for ui use while offline editing

    MAV_AUTOPILOT       _firmwareType;//MAV_AUTOPILOT 枚举，存储固件类型
    MAV_TYPE            _vehicleType;//存储无人机的类型
    FirmwarePlugin*     _firmwarePlugin = nullptr;//指向固件插件对象
    class FirmwarePluginInstanceData*            _firmwarePluginInstanceData = nullptr;//存储固件插件实例数据
    AutoPilotPlugin*    _autopilotPlugin = nullptr;//指向自动飞行插件对象
    bool                _soloFirmware = false;//指示是否为 Solo 固件

    QTimer              _csvLogTimer;//用于 CSV 日志记录的计时器
    QFile               _csvLogFile;//存储 CSV 日志文件


    //VehicleBatteryFactGroup*_batteryFactGroup;


    bool            _joystickEnabled = false;//指示操纵杆是否启用
    bool _isActiveVehicle = false; //指示无人机是否处于激活状态

    QGeoCoordinate  _coordinate; //存储无人机的地理位置坐标
    QGeoCoordinate  _homePosition; //存储无人机的返航点坐标
    QGeoCoordinate  _armedPosition; //存储无人机的武装位置

    qreal           _initialGCSPressure = 0.; //存储初始大气压力
    qreal           _initialGCSTemperature = 0.;//存储初始大气温度

    int             _rcRSSI = 255;//存储接收信号强度指示（RSSI）值
    double          _rcRSSIstore = 255;//存储接收信号强度存储值
    bool            _flying = false;//指示无人机是否正在飞行
    bool            _landing = false;//指示无人机是否正在降落或
    bool            _vtolInFwdFlight = false;//指示无人机是否正在VTOL 飞行模式下
    uint32_t        _onboardControlSensorsPresent = 0; //存储传感器的状态位掩码。
    uint32_t        _onboardControlSensorsEnabled = 0;//存储传感器的状态位掩码。
    uint32_t        _onboardControlSensorsHealth = 0;//存储传感器的状态位掩码。
    uint32_t        _onboardControlSensorsUnhealthy = 0;//存储传感器的状态位掩码。
    bool            _gpsRawIntMessageAvailable              = false;//指示 GPS 原始消息是否可用
    bool            _gps2RawMessageAvailable                = false;//指示 GPS 原始消息是否可用
    bool            _globalPositionIntMessageAvailable      = false;//断是否可以显示无人机的实时位置信息
    double          _defaultCruiseSpeed = qQNaN();//存储默认巡航速度
    double          _defaultHoverSpeed = qQNaN();//存储默认悬停速度
    int             _telemetryRRSSI = 0;//存储遥测信号的统计信息
    int             _telemetryLRSSI = 0;
    uint32_t        _telemetryRXErrors = 0;
    uint32_t        _telemetryFixed = 0;
    uint32_t        _telemetryTXBuffer = 0;
    int             _telemetryLNoise = 0;
    int             _telemetryRNoise = 0;
    bool            _mavlinkProtocolRequestComplete         = false;//管理 MAVLink 协议请求信息
    unsigned        _mavlinkProtocolRequestMaxProtoVersion  = 0;//管理 MAVLink 协议版本信息
    unsigned        _maxProtoVersion                        = 0;
    bool            _capabilityBitsKnown                    = false;//指示能力位掩码是否已知
    uint64_t        _capabilityBits                         = 0;//存储能力位掩码
    CheckList       _checkListState                         = CheckListNotSetup;//存储检查列表的状态
    bool            _readyToFlyAvailable                    = false;//是否指示无人机是否准备好起飞
    bool            _readyToFly                             = false;//指示无人机是否准备好起飞
    bool            _allSensorsHealthy                      = true;//指示无人机所有传感器是否健康
    bool            _mavlinkSigning                         = false;//指示无人机是否需要 GPS 固定

    SysStatusSensorInfo _sysStatusSensorInfo; //用于存储系统状态和传感器信息

    QGCCameraManager* _cameraManager = nullptr;//用于管理无人机的相机功能

    QString             _prearmError;//存储预检错误信息
    QTimer              _prearmErrorTimer;//定时器，用于处理预检错误的超时
    static const int    _prearmErrorTimeoutMSecs = 35 * 1000;  //预检错误的超时时间（35秒 ///< Take away prearm error after 35 seconds

    bool                _initialPlanRequestComplete = false;//表示初始飞行计划请求是否完成

    ParameterManager*               _parameterManager               = nullptr;
    ComponentInformationManager*    _componentInformationManager    = nullptr;//用于管理无人机的组件信息
    VehicleObjectAvoidance*         _objectAvoidance                = nullptr;//用于管理避障功能
    Autotune*                       _autotune                       = nullptr;//用于自动调参功能
    GimbalController*               _gimbalController               = nullptr;//用于控制云台
//用于与 UTM（无人机交通管理）相关的功能
#ifdef QGC_UTM_ADAPTER
    UTMSPVehicle*                    _utmspVehicle                    = nullptr;
#endif

    bool    _armed = false;        //表示无人机是否处于“已解锁”（armed）状态 ///< true: vehicle is armed
    uint8_t _base_mode = 0;   //从 MAVLink 的 HEARTBEAT 消息中获取的模式信息 ，基础模式，通常表示无人机的飞行模式（如手动、自动等） ///< base_mode from HEARTBEAT
    uint32_t _custom_mode = 0; //从 MAVLink 的 HEARTBEAT 消息中获取的模式信息，自定义模式，用于更详细的模式描述 ///< custom_mode from HEARTBEAT
    uint32_t _custom_mode_user_intention = 0; //与用户意图相关的自定义模式信息，可能用于记录用户期望的飞行模式 ///< custom_mode_user_intention from CURRENT_MODE
    bool _has_custom_mode_user_intention = false;//与用户意图相关的自定义模式信息，可能用于记录用户期望的飞行模式

    /// Used to store a message being sent by sendMessageMultiple
   //用于存储需要多次发送的消息及其重试次数
    typedef struct {
        mavlink_message_t   message;    ///< Message to send multiple times
        int                 retryCount; ///< Number of retries left
    } SendMessageMultipleInfo_t;

    QList<SendMessageMultipleInfo_t> _sendMessageMultipleList;  //存储需要多次发送的消息列表  ///< List of messages being sent multiple times

    static const int _sendMessageMultipleRetries = 5;//每次消息发送的最大重试次数（5次）
    static const int _sendMessageMultipleIntraMessageDelay = 500;//：每次发送消息之间的延迟时间（500毫秒）

    QTimer  _sendMultipleTimer;//用于管理消息的多次发送
    int     _nextSendMessageMultipleIndex = 0;//用于跟踪当前需要发送的消息索引

    QElapsedTimer                   _flightTimer;//用于记录飞行时间的计时器。QElapsedTimer 是 Qt 提供的高精度计时器，适合用于测量持续时间
    QTimer                          _flightTimeUpdater;//用于定期更新飞行时间的定时器。可能用于触发 UI 更新或其他与飞行时间相关的逻辑
    TrajectoryPoints*               _trajectoryPoints = nullptr;//指向 TrajectoryPoints 对象，可能用于存储无人机的飞行轨迹点
    QmlObjectListModel              _cameraTriggerPoints;//QmlObjectListModel 是一个用于在 QML 中管理对象列表的类。这里可能用于存储相机触发点，即在特定位置触发相机拍摄的照片或视频
    //QMap<QString, ADSBVehicle*>     _trafficVehicleMap;

    bool _allLinksRemovedSent = false;//布尔值，表示是否已经发送了“所有连接已移除”的信号 ///< true: allLinkRemoved signal already sent one time

    uint                _messagesReceived = 0; //用于统计接收到的消息数
    uint                _messagesSent = 0;//用于统计发送的消息数
    uint                _messagesLost = 0;//用于统计丢失的消息数
    uint8_t             _messageSeq = 0;//消息序列号，用于跟踪消息的顺序。
    uint8_t             _compID = 0;//组件 ID，用于标识消息的来源或目标组件
    bool                _heardFrom = false;//布尔值，表示是否从无人机接收到消息

    bool                _isROIEnabled   = false;//表示是否启用了“兴趣点”（ROI）功能

    Joystick*           _activeJoystick = nullptr;//指向当前激活的操纵杆对象

    bool _checkLatestStableFWDone = false;//布尔值，表示是否已经检查了最新的稳定固件版本

    //这些变量用于存储无人机固件的版本信息，包括主版本号、次版本号、补丁版本号以及自定义版本号
    int _firmwareMajorVersion = versionNotSetValue;
    int _firmwareMinorVersion = versionNotSetValue;
    int _firmwarePatchVersion = versionNotSetValue;
    int _firmwareCustomMajorVersion = versionNotSetValue;
    int _firmwareCustomMinorVersion = versionNotSetValue;
    int _firmwareCustomPatchVersion = versionNotSetValue;
    FIRMWARE_VERSION_TYPE _firmwareVersionType = FIRMWARE_VERSION_TYPE_OFFICIAL; //表示固件版本的类型（例如官方版本或自定义版本）

    // Vendor and Product as reported from the first autopilot version message
    // during the initial connect. They may be zero eg ArduPilot SITL reports 0
    // by default.
    uint16_t       _firmwareBoardVendorId = 0;//表示硬件的供应商 ID 。这些信息可能在连接时从无人机获取
    uint16_t       _firmwareBoardProductId = 0;//表示硬件的产品 ID。这些信息可能在连接时从无人机获取


    QString _gitHash; //可能用于存储无人机固件的 Git 提交哈希值，用于版本追踪
    quint64 _uid = 0;//无人机的唯一标识符（UID）

    //这些变量用于统计 MAVLink 消息的发送、接收和丢失情况，以及计算丢失率
    uint64_t    _mavlinkSentCount       = 0;
    uint64_t    _mavlinkReceivedCount   = 0;
    uint64_t    _mavlinkLossCount       = 0;
    float       _mavlinkLossPercent     = 0.0f;

    //用于表示某些操作（如固件加载或参数加载）的进度
    float       _loadProgress           = 0.0f;

    QMap<QString, QTime> _noisySpokenPrearmMap; //一个映射表，用于记录预检消息的最后发声时间，防止预检消息过于频繁地被重复播报///< Used to prevent PreArm messages from being spoken too often

    // Orbit status values
    bool            _orbitActive = false;//表示无人机是否处于绕圈（Orbit）模式
    QGCMapCircle    _orbitMapCircle;//QGCMapCircle 是一个用于表示地图上圆形轨迹的对象，可能用于定义绕圈飞行的路径
    QTimer          _orbitTelemetryTimer;//定时器，用于监控绕圈模式下的遥测数据更新
    static const int _orbitTelemetryTimeoutMsecs = 3000; //常量，表示如果在 3000 毫秒（3 秒）内没有收到遥测数据，绕圈模式将被标记为非活动状态 No telemetry for this amount and orbit will go inactive

    QMap<uint8_t, QSharedPointer<EventHandler>> _events; //一个映射表，将每个组件 ID（uint8_t）映射到一个事件处理器（EventHandler）。QSharedPointer 是 Qt 的智能指针，用于自动管理对象的生命周期///< One protocol handler for each component ID
    HealthAndArmingCheckReport _healthAndArmingCheckReport;//：用于存储健康和预检（Arming Check）报告的对象。这可能包含无人机的健康状态信息和预检结果

    MAVLinkStreamConfig _mavlinkStreamConfig;//用于配置 MAVLink 消息流的对象

    /// Callback for waitForMavlinkMessage
    ///     @param resultHandleData     Opaque data passed in to waitForMavlinkMessage call
    ///     @param commandResult        Ack result for command send
    ///     @param noReponseFromVehicle true: The vehicle did not responsed to the COMMAND_LONG message
    //这是一个函数指针类型，用于定义等待 MAVLink 消息的回调函数，回调函数的参数包括：resultHandlerData：用户提供的不透明数据。noResponsefromVehicle：布尔值，表示无人机是否对 COMMAND_LONG 消息无响应。message：接收到的 MAVLink 消息
    typedef void (*WaitForMavlinkMessageResultHandler)(void* resultHandlerData, bool noResponsefromVehicle, const mavlink_message_t& message);

    void _waitForMavlinkMessageMessageReceivedHandler(const mavlink_message_t& message);//这是一个成员函数，用于处理接收到的 MAVLink 消息。它可能是回调函数的实现，用于触发相关的逻辑

    // requestMessage handling
    //这是一个结构体，用于存储请求消息的相关信息
    // vehicle：指向 Vehicle 对象，表示与之通信的无人机。
    // compId：组件 ID，用于标识消息的目标组件。
    // msgId：消息 ID，用于标识请求的消息类型。
    // resultHandler：回调函数指针，用于处理请求结果。
    // resultHandlerData：用户提供的不透明数据，传递给回调函数。
    // commandAckReceived：布尔值，表示是否收到命令确认（ACK）。
    // messageReceived：布尔值，表示是否收到请求的消息。
    // messageWaitElapsedTimer：计时器，用于记录等待消息的时间。
    // message：存储接收到的 MAVLink 消息。
    typedef struct RequestMessageInfo {
        Vehicle*                    vehicle             = nullptr;
        int                         compId;
        int                         msgId;
        RequestMessageResultHandler resultHandler       = nullptr;
        void*                       resultHandlerData   = nullptr;
        bool                        commandAckReceived  = false;    // We keep track of the ack/message being received since the order in which this will come in is random
        bool                        messageReceived     = false;    // We only delete the allocated RequestMessageInfo_t when both happen (or the message wait times out)
        QElapsedTimer               messageWaitElapsedTimer;        // Elapsed time since we started waiting for the message to show up
        mavlink_message_t           message;
    } RequestMessageInfo_t;

    QMap<int /* compId */, QMap<int /* msgId */, RequestMessageInfo_t*>> _requestMessageInfoMap; //这是一个嵌套的映射表，用于管理当前正在等待响应的 MAVLink 消息请求，RequestMessageInfo_t 是之前定义的结构体，用于存储请求消息的相关信息， Map of all request message calls currently waiting on a response

    void _removeRequestMessageInfo(int compId, int msgId); //这是一个成员函数，用于从 _requestMessageInfoMap 中移除指定的请求消息信息。它通过组件 ID 和消息 ID 定位到对应的条目并将其删除

    static void _requestMessageCmdResultHandler             (void* resultHandlerData, int compId, const mavlink_command_ack_t& ack, MavCmdResultFailureCode_t failureCode);//这是一个静态回调函数，用于处理 MAVLink 命令的确认（ACK）结果，resultHandlerData：用户提供的不透明数据，compId：组件 ID，ack：MAVLink 的 COMMAND_ACK 消息，包含命令确认的结果，failureCode：命令失败的错误代码（如果失败）
    static void _requestMessageWaitForMessageResultHandler  (void* resultHandlerData, bool noResponsefromVehicle, const mavlink_message_t& message);//这是一个静态回调函数，用于处理等待 MAVLink 消息的结果，resultHandlerData：用户提供的不透明数据，noResponsefromVehicle：布尔值，表示是否从无人机收到响应。message：接收到的 MAVLink 消息



    // MAVLink 命令列表条目
    // MavCommandListEntry_t：这是一个结构体，用于存储 MAVLink 命令的详细信息：包括目标组件 ID、命令类型、参数、重试次数、超时时间等，这种结构体通常用于构建命令队列，支持命令的发送、确认和重试机制

    // targetCompId：目标组件 ID，默认值为 MAV_COMP_ID_AUTOPILOT1（通常是飞行控制器）。
    // useCommandInt：布尔值，表示是否使用整数参数的命令格式。
    // command：MAVLink 命令的类型（如 MAV_CMD_NAV_WAYPOINT）。
    // frame：命令的坐标系（如 MAV_FRAME_GLOBAL_RELATIVE_ALT）。
    // rgParam1 到 rgParam7：命令的参数，具体含义取决于命令类型。
    // showError：布尔值，表示是否显示错误信息。
    // ackHandlerInfo：用于处理命令确认（ACK）的回调信息。
    // maxTries：最大重试次数，默认值为 _mavCommandMaxRetryCount。
    // tryCount：当前重试次数。
    // elapsedTimer：计时器，用于记录命令发送后的时间。
    // ackTimeoutMSecs：命令确认的超时时间，默认值为 _mavCommandAckTimeoutMSecs。
    typedef struct MavCommandListEntry {
        int                     targetCompId        = MAV_COMP_ID_AUTOPILOT1;
        bool                    useCommandInt       = false;
        MAV_CMD                 command;
        MAV_FRAME               frame;
        float                   rgParam1            = 0;
        float                   rgParam2            = 0;
        float                   rgParam3            = 0;
        float                   rgParam4            = 0;
        double                  rgParam5            = 0;
        double                  rgParam6            = 0;
        float                   rgParam7            = 0;
        bool                    showError           = true;
        MavCmdAckHandlerInfo_t  ackHandlerInfo;
        int                     maxTries            = _mavCommandMaxRetryCount;
        int                     tryCount            = 0;
        QElapsedTimer           elapsedTimer;
        int                     ackTimeoutMSecs     = _mavCommandAckTimeoutMSecs;
    } MavCommandListEntry_t;




    QList<MavCommandListEntry_t>    _mavCommandList; //一个列表，用于存储待发送的 MAVLink 命令条目，每个条目包含命令的详细信息，如目标组件 ID、命令类型、参数等
    QTimer                          _mavCommandResponseCheckTimer;//一个定时器，用于定期检查 MAVLink 命令的响应情况
    static const int                _mavCommandMaxRetryCount                = 3;//命令的最大重试次数，默认为 3 次
    static const int                _mavCommandResponseCheckTimeoutMSecs    = 500;//检查命令响应的超时时间，默认为 500 毫秒
    static const int                _mavCommandAckTimeoutMSecs              = 3000;//命令确认（ACK）的超时时间，默认为 3000 毫秒。
    static const int                _mavCommandAckTimeoutMSecsHighLatency   = 120000; //在高延迟情况下，命令确认ACK）的超时时间，默认为 120000 毫秒（2 分钟）



    //一个工作函数，用于实际发送 MAVLink 命令
    // commandInt：是否使用整数参数的命令格式。
    // showError：是否显示错误信息。
    // ackHandlerInfo：ACK 回调信息，如果为 nullptr，表示没有回调。
    // compId：目标组件 ID。
    // command：命令类型。
    // frame：命令的坐标系。
    // param1 到 param7：命令的参数。
    void _sendMavCommandWorker  (
            bool commandInt, bool showError, 
            const MavCmdAckHandlerInfo_t* ackHandlerInfo,   ///> nullptr to signale no handlers
            int compId, MAV_CMD command, MAV_FRAME frame, 
            float param1, float param2, float param3, float param4, double param5, double param6, float param7);


    void _sendMavCommandFromList(int index);//从 _mavCommandList 中发送指定索引的命令
    int  _findMavCommandListEntryIndex(int targetCompId, MAV_CMD command);//在 _mavCommandList 中查找指定目标组件 ID 和命令类型的条目索引
    bool _sendMavCommandShouldRetry(MAV_CMD command);//判断是否应该重试发送某个命令
    bool _commandCanBeDuplicated(MAV_CMD command);//判断某个命令是否可以重复发送


    //电池状态管理
    QMap<uint8_t /* batteryId */, uint8_t /* MAV_BATTERY_CHARGE_STATE_OK */> _lowestBatteryChargeStateAnnouncedMap;//一个映射表，用于记录每个电池 ID 的最低充电状态（MAV_BATTERY_CHARGE_STATE_OK），这可能用于监控电池健康状态并通知用户。

    //电池状态管理
    QMap<uint8_t /* batteryId */, uint8_t /* MAV_BATTERY_CHARGE_STATE_OK */> _lowestHydrogenBatteryFaultAnnouncedMap;//一个映射表，用于记录每个电池 ID 的最低充电状态（MAV_BATTERY_CHARGE_STATE_OK），这可能用于监控电池健康状态并通知用户。


    //高度调整
    float _altitudeTuningOffset = qQNaN(); //高度调整偏移量，用于将高度值调整到接近 0 的范围。初始值为 qQNaN（表示不是一个数字） altitude offset, so the plotted value is around 0

    // these flags are used to determine if the speed change action from fly view should be shown
    bool _multirotor_speed_limits_available = false; //布尔值，表示多旋翼的速度限制是否可用
    bool _fixed_wing_airspeed_limits_available = false;//表示固定翼的空速限制是否可用


    // FactGroup facts
    //这些常量字符串定义了不同的参数组（FactGroup）名称，用于组织和管理无人机的各种状态和参数
    const QString _settingsGroup =               QStringLiteral("Vehicle%1");        // 用于存储车辆设置的组名，其中 %1 会被替换为 MAVLink 系统 ID，%1 replaced with mavlink system id
    const QString _joystickEnabledSettingsKey =  QStringLiteral("JoystickEnabled");  //用于存储是否启用操纵杆的设置键

    const QString _vehicleFactGroupName =            QStringLiteral("vehicle");  //车辆相关参数
    const QString _gpsFactGroupName =                QStringLiteral("gps"); //GPS 相关参数
    const QString _gps2FactGroupName =               QStringLiteral("gps2");
    const QString _windFactGroupName =               QStringLiteral("wind");//风速相关参数
    const QString _vibrationFactGroupName =          QStringLiteral("vibration");//振动相关参数
    const QString _temperatureFactGroupName =        QStringLiteral("temperature");//温度相关参数
    const QString _clockFactGroupName =              QStringLiteral("clock");//时钟相关参数
    const QString _setpointFactGroupName =           QStringLiteral("setpoint");//目标点相关参数
    const QString _distanceSensorFactGroupName =     QStringLiteral("distanceSensor");//距离传感器相关参数
    const QString _localPositionFactGroupName =      QStringLiteral("localPosition");
    const QString _localPositionSetpointFactGroupName = QStringLiteral("localPositionSetpoint");//局部位置相关参数
    const QString _escStatusFactGroupName =          QStringLiteral("escStatus");//电子调速器（ESC）状态
    const QString _estimatorStatusFactGroupName =    QStringLiteral("estimatorStatus");//估计器状态
    const QString _terrainFactGroupName =            QStringLiteral("terrain");//地形相关参数
    const QString _hygrometerFactGroupName =         QStringLiteral("hygrometer");//湿度计相关参数
    const QString _generatorFactGroupName =          QStringLiteral("generator");//发电机相关参数
    const QString _efiFactGroupName =                QStringLiteral("efi");//电子燃油喷射（EFI）相关参数
    const QString _rpmFactGroupName =                QStringLiteral("rpm");//转速相关参数


    //这些变量定义了一系列的“FactGroup”对象，用于管理无人机的各种状态和传感器数据。
    VehicleFactGroup*               _vehicleFactGroup;//管理与无人机整体状态相关的数据，例如飞行模式、电池状态等
    VehicleGPSFactGroup             _gpsFactGroup;//管理 GPS 数据，管理 GPS 数据，例如经纬度、高度、卫星数量等
    VehicleGPS2FactGroup            _gps2FactGroup;//管理第二个 GPS 模块的数据（如果无人机配备了多个 GPS 模块）
    VehicleWindFactGroup            _windFactGroup;//管理风速数据
    VehicleVibrationFactGroup       _vibrationFactGroup;//管理振动数据
    VehicleTemperatureFactGroup     _temperatureFactGroup;//管理温度数据
    VehicleClockFactGroup           _clockFactGroup;//管理时钟相关数据，例如系统时间和时间同步状态
    VehicleSetpointFactGroup        _setpointFactGroup;//管理目标点（Setpoint）数据，例如目标位置、速度等
    VehicleDistanceSensorFactGroup  _distanceSensorFactGroup;//管理距离传感器数据，例如障碍物距离
    VehicleLocalPositionFactGroup   _localPositionFactGroup;//管理局部位置数据，例如相对于起飞点的位置
    VehicleLocalPositionSetpointFactGroup _localPositionSetpointFactGroup; //管理局部位置目标点数据，例如目标局部位置
    VehicleEscStatusFactGroup       _escStatusFactGroup;//管理电子调速器（ESC）状态，例如电机转速和电流
    VehicleEstimatorStatusFactGroup _estimatorStatusFactGroup;//管理估计器状态，例如位置估计精度和传感器偏差
    VehicleHygrometerFactGroup      _hygrometerFactGroup;//管理湿度计数据，例如湿度
    VehicleGeneratorFactGroup       _generatorFactGroup;//管理发电机状态，例如发电机输出功率
    VehicleEFIFactGroup             _efiFactGroup;//管理电子燃油喷射（EFI）数据，例如燃油流量
    VehicleRPMFactGroup             _rpmFactGroup; //管理转速数据，例如发动机转速
    TerrainFactGroup                _terrainFactGroup;//管理地形数据，例如地形高度

    QmlObjectListModel              _batteryFactGroupListModel;//用于管理电池状态的列表模型。这可能是一个 QML 可用的模型，用于在用户界面中显示电池信息
    QmlObjectListModel              _hydrogenbatteryFactGroupListModel;

    TerrainProtocolHandler* _terrainProtocolHandler = nullptr; //地形协议处理器，指向 TerrainProtocolHandler 对象，用于处理地形数据的协议交互。这可能涉及从服务器获取地形高度等操作。

    MissionManager*                 _missionManager             = nullptr;  //管理无人机的任务（如航线规划和执行）
    GeoFenceManager*                _geoFenceManager            = nullptr;  //管理地理围栏（GeoFence），用于限制无人机的飞行区域
    RallyPointManager*              _rallyPointManager          = nullptr;  //管理集结点（Rally Point），用于定义无人机在特定情况下的返回点
    VehicleLinkManager*             _vehicleLinkManager         = nullptr;  //管理无人机的通信链路，例如 Wi-Fi、串口或无线电链路
    FTPManager*                     _ftpManager                 = nullptr;  //管理文件传输协议（FTP）相关的操作，可能用于上传或下载固件、日志文件等
    InitialConnectStateMachine*     _initialConnectStateMachine = nullptr;  //初始化状态机，用于管理无人机的初始连接状态，例如连接过程中的各个阶段

    // 执行器与模式管理器
    Actuators*                      _actuators                  = nullptr;//_actuators：管理无人机的执行器（如电机、舵机等）
    RemoteIDManager*                _remoteIDManager            = nullptr;//_remoteIDManager：管理远程识别（Remote ID）相关的功能，可能用于无人机的远程识别和跟踪
    StandardModes*                  _standardModes              = nullptr;//管理无人机的标准飞行模式



    //地形查询成员
    // Terrain query members, used to get terrain altitude for doSetHome()
    TerrainAtCoordinateQuery*   _currentDoSetHomeTerrainAtCoordinateQuery = nullptr;  //指向当前正在进行的“设置家点”（doSetHome）地形查询对象
    QGeoCoordinate              _doSetHomeCoordinate; //存储“设置家点”的地理坐标

    // Terrain query members, used to get altitude above terrain Fact
    QElapsedTimer               _altitudeAboveTerrQueryTimer;//用于记录地形查询的时间
    TerrainAtCoordinateQuery*   _altitudeAboveTerrTerrainAtCoordinateQuery = nullptr;//指向当前正在进行的“地形上方高度”查询对象

    // We use this to limit above terrain altitude queries based on distance and altitude change
    //用于记录上次查询的地理坐标和相对高度，以便限制重复查询
    QGeoCoordinate              _altitudeAboveTerrLastCoord;
    float                       _altitudeAboveTerrLastRelAlt = qQNaN();

public:
    int32_t getMessageRate(uint8_t compId, uint16_t msgId);//获取指定组件 ID 和消息 ID 的消息发送频率（单位：Hz）
    void setMessageRate(uint8_t compId, uint16_t msgId, int32_t rate);//设置指定组件 ID 和消息 ID 的消息发送频率

signals:
    void mavlinkMsgIntervalsChanged(uint8_t compid, uint16_t msgId, int32_t rate);//当消息间隔被修改时发出的信号，通知其他部分消息间隔已更改

private:
    void _handleMessageInterval(const mavlink_message_t& message);//处理接收到的 MAVLink 消息间隔消息

    static void _requestMessageMessageIntervalResultHandler(void* resultHandlerData, MAV_RESULT result, RequestMessageResultHandlerFailureCode_t failureCode, const mavlink_message_t& message);//请求消息间隔结果的回调函数
    void _requestMessageInterval(uint8_t compId, uint16_t msgId);//请求指定组件 ID 和消息 ID 的消息间隔。

    static void _setMessageRateCommandResultHandler(void* resultHandlerData, int compId, const mavlink_command_ack_t& ack, MavCmdResultFailureCode_t failureCode);//设置消息频率命令的结果回调函数

    typedef QPair<uint8_t, uint16_t> MavCompMsgId;
    QHash<MavCompMsgId, int32_t> _mavlinkMsgIntervals;//存储组件 ID 和消息 ID 的组合（MavCompMsgId）与消息发送频率的映射
    QMultiHash<uint8_t, uint16_t> _unsupportedMessageIds;//存储不支持的消息 ID 列表
    uint16_t _lastSetMsgIntervalMsgId = 0;//记录最后设置消息间隔的消息 ID

/*===========================================================================*/
/*                         Status Text Handler                               */
/*===========================================================================*/

private:
    //这些属性用于管理状态文本消息的类型（无、正常、警告、错误）和消息数量
    Q_PROPERTY(bool    messageTypeNone    READ messageTypeNone    NOTIFY messageTypeChanged)
    Q_PROPERTY(bool    messageTypeNormal  READ messageTypeNormal  NOTIFY messageTypeChanged)
    Q_PROPERTY(bool    messageTypeWarning READ messageTypeWarning NOTIFY messageTypeChanged)
    Q_PROPERTY(bool    messageTypeError   READ messageTypeError   NOTIFY messageTypeChanged)
    Q_PROPERTY(int     messageCount       READ messageCount       NOTIFY messageCountChanged)
    Q_PROPERTY(QString formattedMessages  READ formattedMessages  NOTIFY formattedMessagesChanged)//formattedMessages 属性用于存储格式化后的消息文本

    // Q_PROPERTY(StatusTextHandler *statusTextHandler READ statusTextHandler NOTIFY statusTextHandlerChanged)

public:
    Q_INVOKABLE void resetAllMessages();//重置所有消息
    Q_INVOKABLE void resetErrorLevelMessages();//重置错误级别消息
    Q_INVOKABLE void clearMessages();//清除所有消息


    //这些方法用于获取状态文本消息的类型、数量和格式化后的消息文本
    bool messageTypeNone() const;
    bool messageTypeNormal() const;
    bool messageTypeWarning() const;
    bool messageTypeError() const;
    int messageCount() const;
    QString formattedMessages() const;

    // StatusTextHandler* statusTextHandler() { return m_statusTextHandler; }

signals:
    //这些信号用于通知其他部分状态文本消息的接收、变化或更新
    void textMessageReceived(int sysid, int componentid, int severity, QString text, QString description);

    void messagesReceivedChanged();
    void messagesSentChanged();
    void messagesLostChanged();
    void messageTypeChanged();
    void messageCountChanged();
    void formattedMessagesChanged();
    void newFormattedMessage(QString formattedMessage);

    // void statusTextHandlerChanged();

private slots:
    void _textMessageReceived(MAV_COMPONENT componentid, MAV_SEVERITY severity, QString text, QString description);//处理接收到的状态文本消息
    void _errorMessageReceived(QString message); //处理接收到的错误消息

private:
    void _createStatusTextHandler();//用于创建和初始化 StatusTextHandler 对象。这个方法可能在类的构造函数中被调用，以确保状态文本处理器在类实例化时可用

    StatusTextHandler *m_statusTextHandler = nullptr;//状态文本处理器，：指向 StatusTextHandler 对象的指针，用于管理无人机的状态文本消息（如警告、错误等）
/*---------------------------------------------------------------------------*/
/*===========================================================================*/
/*                        Image Protocol Manager                             */
/*===========================================================================*/
private:
    Q_PROPERTY(uint flowImageIndex READ flowImageIndex NOTIFY flowImageIndexChanged)//图像协议管理器。flowImageIndex：一个属性，表示当前的图像索引。通过 flowImageIndex() 方法读取，当索引变化时发出 flowImageIndexChanged 信号

public:
    uint32_t flowImageIndex() const; //返回当前的图像索引

signals:
    void flowImageIndexChanged(); //当图像索引发生变化时发出的信号

private:
    void _createImageProtocolManager();//用于创建和初始化 ImageProtocolManager 对象。这个方法可能在类的构造函数中被调用，以确保图像协议管理器在类实例化时可用

    ImageProtocolManager *_imageProtocolManager = nullptr;//指向 ImageProtocolManager 对象的指针，用于管理图像传输协议
/*---------------------------------------------------------------------------*/
/*===========================================================================*/
/*                         MAVLink Log Manager                               */
/*===========================================================================*/
private:
    Q_PROPERTY(MAVLinkLogManager *mavlinkLogManager READ mavlinkLogManager NOTIFY mavlinkLogManagerChanged)//一个属性，表示 MAVLink 日志管理器对象。通过 mavlinkLogManager() 方法读取，当对象变化时发出 mavlinkLogManagerChanged 信号。

public:
    MAVLinkLogManager *mavlinkLogManager() const; //返回当前的 MAVLink 日志管理器对象

signals:
    void mavlinkLogManagerChanged(); //当 MAVLink 日志管理器对象发生变化时发出的信号

private:
    void _createMAVLinkLogManager(); //初始化 MAVLink 日志管理器

    MAVLinkLogManager *_mavlinkLogManager = nullptr;//mavlinkLogManager 属性和 mavlinkLogManagerChanged 信号用于管理 MAVLink 日志

/*---------------------------------------------------------------------------*/
};

//Q_DECLARE_METATYPE 是 Qt 框架中的一个宏，用于将自定义类型注册到 Qt 的元类型系统（Meta-Object System）中。通过注册，自定义类型可以在 Qt 的信号和槽机制、QVariant 类型、QSettings 等功能中使用
Q_DECLARE_METATYPE(Vehicle::MavCmdResultFailureCode_t)

// 假设 Vehicle::MavCmdResultFailureCode_t 是一个枚举类型，用于表示 MAVLink 命令执行失败的原因。例如：


//     namespace Vehicle {
//     enum MavCmdResultFailureCode_t {
//         FailureCode_None,
//         FailureCode_Timeout,
//         FailureCode_InvalidParameter,
//         FailureCode_Other
//     };
// }
// 为了在 Qt 的信号和槽机制中使用这个枚举类型，或者将其存储在 QVariant 中，需要在代码中注册它：

// Q_DECLARE_METATYPE(Vehicle::MavCmdResultFailureCode_t)
// 在信号和槽中使用自定义类型：
//     假设你有一个信号，需要传递 MavCmdResultFailureCode_t 类型的参数：
//             signals:
//                     void commandFailed(Vehicle::MavCmdResultFailureCode_t failureCode);
// 如果没有注册 MavCmdResultFailureCode_t，编译器会报错，提示该类型未注册到元类型系统中。
