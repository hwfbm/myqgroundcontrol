/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SettingsManager.h"
#include "QGCLoggingCategory.h"
#include "ADSBVehicleManagerSettings.h"
#ifndef QGC_NO_ARDUPILOT_DIALECT
#include "APMMavlinkStreamRateSettings.h"
#endif
#include "AppSettings.h"
#include "AutoConnectSettings.h"
#include "BatteryIndicatorSettings.h"
#include "BrandImageSettings.h"
#include "MavlinkActionsSettings.h"
#include "FirmwareUpgradeSettings.h"
#include "FlightMapSettings.h"
#include "FlightModeSettings.h"
#include "FlyViewSettings.h"
#include "GimbalControllerSettings.h"
#include "MapsSettings.h"
#include "OfflineMapsSettings.h"
#include "PlanViewSettings.h"
#include "RemoteIDSettings.h"
#include "RTKSettings.h"
#include "UnitsSettings.h"
#include "VideoSettings.h"
#include "MavlinkSettings.h"
#ifdef QGC_VIEWER3D
#include "Viewer3DSettings.h"
#endif

#include <QtCore/qapplicationstatic.h>
#include <QtQml/qqml.h>

QGC_LOGGING_CATEGORY(SettingsManagerLog, "qgc.settings.settingsmanager")

Q_APPLICATION_STATIC(SettingsManager, _settingsManagerInstance);

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
{
    // qCDebug(SettingsManagerLog) << Q_FUNC_INFO << this;
}

SettingsManager::~SettingsManager()
{
    // qCDebug(SettingsManagerLog) << Q_FUNC_INFO << this;
}

SettingsManager *SettingsManager::instance()
{
    return _settingsManagerInstance();
}

void SettingsManager::registerQmlTypes()//这个方法使用了 qmlRegisterUncreatableType 函数，使得 SettingsManager 类可以在 QML 中被引用，但不能被直接实例化。
{
    //qmlRegisterUncreatableType：这是一个 Qt 提供的函数，用于将一个 C++ 类注册到 QML 环境中，但不允许在 QML 中直接实例化该类
    //SettingsManager：这是要注册的类，SettingsManager 类通常是一个单例类，这意味着在整个应用程序中只有一个 ，在 QML 中，可以通过 SettingsManager 类的单例实例来访问和操作设置
    //"QGroundControl.SettingsManager"：这是 QML 中使用的模块名称
    //1, 0：这是模块的版本号，表示主版本号为 1，次版本号为 0
    //"SettingsManager"：这是 QML 中使用的类名称
    //"Reference only"：这是一个描述字符串，用于在 QML 中提供关于该类的额外信息。这里表示该类只能被引用，不能被直接实例化
    (void) qmlRegisterUncreatableType<SettingsManager>("QGroundControl.SettingsManager", 1, 0, "SettingsManager", "Reference only");
}

void SettingsManager::init()
{
    _unitsSettings = new UnitsSettings(this); // Must be first since AppSettings references it

    _adsbVehicleManagerSettings = new ADSBVehicleManagerSettings(this);
#ifndef QGC_NO_ARDUPILOT_DIALECT
    _apmMavlinkStreamRateSettings = new APMMavlinkStreamRateSettings(this);
#endif
    _appSettings = new AppSettings(this);
    _autoConnectSettings = new AutoConnectSettings(this);
    _batteryIndicatorSettings = new BatteryIndicatorSettings(this);
    _brandImageSettings = new BrandImageSettings(this);
    _mavlinkActionsSettings = new MavlinkActionsSettings(this);
    _firmwareUpgradeSettings = new FirmwareUpgradeSettings(this);
    _flightMapSettings = new FlightMapSettings(this);
    _flightModeSettings = new FlightModeSettings(this);
    _flyViewSettings = new FlyViewSettings(this);
    _gimbalControllerSettings = new GimbalControllerSettings(this);
    _mapsSettings = new MapsSettings(this);
    _offlineMapsSettings = new OfflineMapsSettings(this);
    _planViewSettings = new PlanViewSettings(this);
    _remoteIDSettings = new RemoteIDSettings(this);
    _rtkSettings = new RTKSettings(this);
    _videoSettings = new VideoSettings(this);
    _mavlinkSettings = new MavlinkSettings(this);
#ifdef QGC_VIEWER3D
    _viewer3DSettings = new Viewer3DSettings(this);
#endif
}

ADSBVehicleManagerSettings *SettingsManager::adsbVehicleManagerSettings() const { return _adsbVehicleManagerSettings; }
#ifndef QGC_NO_ARDUPILOT_DIALECT
APMMavlinkStreamRateSettings *SettingsManager::apmMavlinkStreamRateSettings() const { return _apmMavlinkStreamRateSettings; }
#endif
AppSettings *SettingsManager::appSettings() const { return _appSettings; }
AutoConnectSettings *SettingsManager::autoConnectSettings() const { return _autoConnectSettings; }
BatteryIndicatorSettings *SettingsManager::batteryIndicatorSettings() const { return _batteryIndicatorSettings; }
BrandImageSettings *SettingsManager::brandImageSettings() const { return _brandImageSettings; }
MavlinkActionsSettings *SettingsManager::mavlinkActionsSettings() const { return _mavlinkActionsSettings; }
FirmwareUpgradeSettings *SettingsManager::firmwareUpgradeSettings() const { return _firmwareUpgradeSettings; }
FlightMapSettings *SettingsManager::flightMapSettings() const { return _flightMapSettings; }
FlightModeSettings *SettingsManager::flightModeSettings() const { return _flightModeSettings; }
FlyViewSettings *SettingsManager::flyViewSettings() const { return _flyViewSettings; }
GimbalControllerSettings *SettingsManager::gimbalControllerSettings() const { return _gimbalControllerSettings; }
MapsSettings *SettingsManager::mapsSettings() const { return _mapsSettings; }
OfflineMapsSettings *SettingsManager::offlineMapsSettings() const { return _offlineMapsSettings; }
PlanViewSettings *SettingsManager::planViewSettings() const { return _planViewSettings; }
RemoteIDSettings *SettingsManager::remoteIDSettings() const { return _remoteIDSettings; }
RTKSettings *SettingsManager::rtkSettings() const { return _rtkSettings; }
UnitsSettings *SettingsManager::unitsSettings() const { return _unitsSettings; }
VideoSettings *SettingsManager::videoSettings() const { return _videoSettings; }
MavlinkSettings *SettingsManager::mavlinkSettings() const { return _mavlinkSettings; }
#ifdef QGC_VIEWER3D
Viewer3DSettings *SettingsManager::viewer3DSettings() const { return _viewer3DSettings; }
#endif
