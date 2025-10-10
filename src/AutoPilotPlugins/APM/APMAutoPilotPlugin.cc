/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "APMAutoPilotPlugin.h"
#include "APMAirframeComponent.h"
#include "APMCameraComponent.h"
#include "APMFlightModesComponent.h"
#include "APMHeliComponent.h"
#include "APMLightsComponent.h"
#include "APMMotorComponent.h"
#include "APMPowerComponent.h"
#include "APMRadioComponent.h"
#include "APMRemoteSupportComponent.h"
#include "APMSafetyComponent.h"
#include "APMSensorsComponent.h"
#include "APMSubFrameComponent.h"
#include "APMTuningComponent.h"
#include "ESP8266Component.h"
#include "ParameterManager.h"
#include "QGCApplication.h"
#include "QGCLoggingCategory.h"
#include "Vehicle.h"
#include "VehicleComponent.h"
#ifdef QT_DEBUG
#include "APMFollowComponent.h"
#include "ArduCopterFirmwarePlugin.h"
#include "ArduRoverFirmwarePlugin.h"
#endif
#ifndef QGC_NO_SERIAL_LINK
#include "QGCSerialPortInfo.h"
#include "SerialLink.h"
#endif

QGC_LOGGING_CATEGORY(APMAutoPilotPluginLog, "qgc.autopilotplugins.apm.apmautopilotplugin")

APMAutoPilotPlugin::APMAutoPilotPlugin(Vehicle *vehicle, QObject *parent)
    : AutoPilotPlugin(vehicle, parent)
{
    // qCDebug(APMAutoPilotPluginLog) << Q_FUNC_INFO << this;

#ifndef QGC_NO_SERIAL_LINK
    (void) connect(vehicle->parameterManager(), &ParameterManager::parametersReadyChanged, this, &APMAutoPilotPlugin::_checkForBadCubeBlack);
#endif
}

APMAutoPilotPlugin::~APMAutoPilotPlugin()
{
    // qCDebug(APMAutoPilotPluginLog) << Q_FUNC_INFO << this;
}

//其核心功能是为apm不同类型的无人机（Vehicle）动态构建一个配置组件列表
//const QVariantList 一个常量引用，指向一个存储了所有配置组件的列表
// 根据当前连接的无人机类型、固件版本、参数支持情况等条件，创建并组装一系列特定的配置组件（如机架、电台、传感器等），并返回这个列表。
//这些组件将在 QGC 的“设置”界面中呈现给用户，用于配置无人机
//setupTriggerSignals(): 连接组件内部的信号（如要求检查校准、显示消息等）到插件的相应槽函数，实现交互。
const QVariantList &APMAutoPilotPlugin::vehicleComponents()
{
    //这是一个缓存机制。只有当组件列表 _components 为空（即尚未创建）且参数版本正确时，才执行内部复杂的创建逻辑。
    //一旦创建完成，下次调用此函数将直接返回已缓存的 _components，避免重复创建，提高效率
    if (_components.isEmpty() && !_incorrectParameterVersion)
    {
        //安全性检查。确保无人机的所有参数都已经从飞控板下载完毕并准备就绪
        if (_vehicle->parameterManager()->parametersReady())
        {
            _airframeComponent = new APMAirframeComponent(_vehicle, this);// 机架选择
            _airframeComponent->setupTriggerSignals();
            _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_airframeComponent)));

            if (_vehicle->supportsRadio()) {
                _radioComponent = new APMRadioComponent(_vehicle, this);// 遥控器校准 (如果支持)
                _radioComponent->setupTriggerSignals();// 连接组件内部的信号（如要求检查校准、显示消息等）到插件的相应槽函数，实现交互
                //qobject_cast<VehicleComponent*>(...): 将具体的组件指针（如 APMAirframeComponent*）转换为统一的基类接口 VehicleComponent*，然后存入列表。
                //这是多态性的应用，允许外部代码通过基类接口操作所有不同类型的组件
                //QVariant::fromValue(...): 将指针包裹到 QVariant 中，因为 QVariantList 是 QList<QVariant>
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_radioComponent)));
            }

            // No flight modes component for Sub versions 3.5 and up
            //如果不是潜艇 (!sub()) 或者 是潜艇但固件版本 低于 3.5.0
            //在 ArduSub (潜艇固件) 3.5.0 及以后版本中，飞行模式的设置方式发生了变化，可能移到了其他地方或不再需要单独的UI组件，因此跳过创建
            if (!_vehicle->sub() || (_vehicle->versionCompare(3, 5, 0) < 0)) {
                _flightModesComponent = new APMFlightModesComponent(_vehicle, this);
                _flightModesComponent->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_flightModesComponent)));
            }

            // 传感器校准 (加速度计, 罗盘等)
            _sensorsComponent = new APMSensorsComponent(_vehicle, this);
            _sensorsComponent->setupTriggerSignals();
            _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_sensorsComponent)));

            _powerComponent = new APMPowerComponent(_vehicle, this);// 电源设置 (电池监控等)
            _powerComponent->setupTriggerSignals();
            _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_powerComponent)));



            // 如果不是潜艇 或者 是潜艇且固件版本 大于等于 3.5.3。
            //电机配置对于多旋翼和固定翼是必需的。对于潜艇，只有在较新的版本 (3.5.3+) 中才支持/需要电机配置界面
            if (!_vehicle->sub() || (_vehicle->sub() && (_vehicle->versionCompare(3, 5, 3) >= 0))) {
                _motorComponent = new APMMotorComponent(_vehicle, this);
                _motorComponent->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_motorComponent)));
            }

            // 安全设置 (解锁开关, 返航高度
            _safetyComponent = new APMSafetyComponent(_vehicle, this);
            _safetyComponent->setupTriggerSignals();
            _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_safetyComponent)));

//在 调试模式 (QT_DEBUG) 下编译的版本中，并且是 Copter 或 Rover 固件，并且 飞控参数中存在 FOLL_ENABLE (跟随模式使能参数)
#ifdef QT_DEBUG
            if ((qobject_cast<ArduCopterFirmwarePlugin*>(_vehicle->firmwarePlugin()) || qobject_cast<ArduRoverFirmwarePlugin*>(_vehicle->firmwarePlugin())) &&
                    _vehicle->parameterManager()->parameterExists(-1, QStringLiteral("FOLL_ENABLE"))) {
                _followComponent = new APMFollowComponent(_vehicle, this);
                _followComponent->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_followComponent)));
            }
#endif


            //无人机类型是直升机 并且 固件版本大于等于 4.0.0
            // 直升机有特殊的设置（如舵机/swashplate设置），这些功能只在较新的固件版本中才通过QGC暴露出来
            if (_vehicle->vehicleType() == MAV_TYPE_HELICOPTER && (_vehicle->versionCompare(4, 0, 0) >= 0)) {
                _heliComponent = new APMHeliComponent(_vehicle, this);
                _heliComponent->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_heliComponent)));
            }

            _tuningComponent = new APMTuningComponent(_vehicle, this);// PID调试
            _tuningComponent->setupTriggerSignals();
            _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_tuningComponent)));

            //检查是否存在 MNT1_TYPE 参数
            //这是动态检测无人机是否配置了云台的最可靠方法。如果存在这个参数，说明用户可能安装了云台，于是创建云台配置组件
            if (_vehicle->parameterManager()->parameterExists(-1, "MNT1_TYPE")) {
                _cameraComponent = new APMCameraComponent(_vehicle, this);
                _cameraComponent->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_cameraComponent)));
            }


            // 如果是潜艇，则创建灯光组件
            //灯光控制是潜艇的特色功能。框架配置可能是为新一代潜艇固件添加的
            if (_vehicle->sub()) {
                _lightsComponent = new APMLightsComponent(_vehicle, this);
                _lightsComponent->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_lightsComponent)));

                // 如果是潜艇且版本达标，则创建框架组件
                if (_vehicle->versionCompare(3, 5, 0) >= 0) {
                    _subFrameComponent = new APMSubFrameComponent(_vehicle, this);
                    _subFrameComponent->setupTriggerSignals();
                    _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_subFrameComponent)));
                }
            }

            //-- Is there an ESP8266 Connected?
            //在组件ID MAV_COMP_ID_UDP_BRIDGE (通常是WiFi模块的组件ID) 上存在 SW_VER (软件版本) 参数
            //wifi模块
            //这是一种非常精确的检测方法，用于判断是否有 ESP8266 之类的辅助网络模块连接到飞控。它不仅仅检查参数名，还检查参数所在的组件ID，可靠性极高
            if (_vehicle->parameterManager()->parameterExists(MAV_COMP_ID_UDP_BRIDGE, "SW_VER")) {
                _esp8266Component = new ESP8266Component(_vehicle, this);
                _esp8266Component->setupTriggerSignals();
                _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_esp8266Component)));
            }

            _apmRemoteSupportComponent = new APMRemoteSupportComponent(_vehicle, this);
            _apmRemoteSupportComponent->setupTriggerSignals();
            _components.append(QVariant::fromValue(qobject_cast<VehicleComponent*>(_apmRemoteSupportComponent)));
        } else {
            //如果参数尚未就绪就调用此函数，会记录一条警告日志
            qCWarning(APMAutoPilotPluginLog) << "Call to vehicleComponents prior to parametersReady";
        }
    }

    //最终，函数返回构建好的（或已缓存的）组件列表 _components
    return _components;
}

QString APMAutoPilotPlugin::prerequisiteSetup(VehicleComponent *component) const
{
    bool requiresAirframeCheck = false;

    if (qobject_cast<const APMFlightModesComponent*>(component)) {
        if (_airframeComponent && !_airframeComponent->setupComplete()) {
            return _airframeComponent->name();
        }
        if (_radioComponent && !_radioComponent->setupComplete()) {
            return _radioComponent->name();
        }
        requiresAirframeCheck = true;
    } else if (qobject_cast<const APMRadioComponent*>(component)) {
        requiresAirframeCheck = true;
    } else if (qobject_cast<const APMCameraComponent*>(component)) {
        requiresAirframeCheck = true;
    } else if (qobject_cast<const APMPowerComponent*>(component)) {
        requiresAirframeCheck = true;
    } else if (qobject_cast<const APMSafetyComponent*>(component)) {
        requiresAirframeCheck = true;
    } else if (qobject_cast<const APMTuningComponent*>(component)) {
        requiresAirframeCheck = true;
    } else if (qobject_cast<const APMSensorsComponent*>(component)) {
        requiresAirframeCheck = true;
    }

    if (requiresAirframeCheck) {
        if (_airframeComponent && !_airframeComponent->setupComplete()) {
            return _airframeComponent->name();
        }
    }

    return QString();
}

#ifndef QGC_NO_SERIAL_LINK
void APMAutoPilotPlugin::_checkForBadCubeBlack(bool parametersReady)
{
    if (!parametersReady) {
        return;
    }

    const SharedLinkInterfacePtr sharedLink = _vehicle->vehicleLinkManager()->primaryLink().lock();
    if (!sharedLink) {
        return;
    }

    if (sharedLink->linkConfiguration()->type() != LinkConfiguration::TypeSerial) {
        return;
    }

    const SerialLink *serialLink = qobject_cast<const SerialLink*>(sharedLink.get());
    if (!serialLink) {
        return;
    }

    if (!QGCSerialPortInfo(*serialLink->port()).isBlackCube()) {
        return;
    }

    ParameterManager *const paramMgr = _vehicle->parameterManager();

    static const QString paramAcc3 = QStringLiteral("INS_ACC3_ID");
    static const QString paramGyr3 = QStringLiteral("INS_GYR3_ID");
    static const QString paramEnableMask = QStringLiteral("INS_ENABLE_MASK");

    if (paramMgr->parameterExists(-1, paramAcc3) && (paramMgr->getParameter(-1, paramAcc3)->rawValue().toInt() == 0) &&
        paramMgr->parameterExists(-1, paramGyr3) && (paramMgr->getParameter(-1, paramGyr3)->rawValue().toInt() == 0) &&
        paramMgr->parameterExists(-1, paramEnableMask) && (paramMgr->getParameter(-1, paramEnableMask)->rawValue().toInt() >= 7)) {
        qgcApp()->showAppMessage(tr(
            "WARNING: The flight board you are using has a critical service bulletin against it which advises against flying. "
            "For details see: https://discuss.cubepilot.org/t/sb-0000002-critical-service-bulletin-for-cubes-purchased-between-january-2019-to-present-do-not-fly/406"
        ));
    }
}
#endif
