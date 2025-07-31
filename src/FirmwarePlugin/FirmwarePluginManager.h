/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>

#include "QGCMAVLink.h"

class FirmwarePlugin;
class FirmwarePluginFactory;

Q_DECLARE_LOGGING_CATEGORY(FirmwarePluginManagerLog)

//飞控固件插件的核心管理系统，担着固件类型与插件实例之间的桥梁角色
/// FirmwarePluginManager is a singleton which is used to return the correct FirmwarePlugin for a MAV_AUTOPILOT type.
class FirmwarePluginManager : public QObject
{
    Q_OBJECT

public:
    /// Constructs an FirmwarePluginManager object.
    ///     @param parent The parent QObject.
    explicit FirmwarePluginManager(QObject *parent = nullptr);

    /// Destructor for the FirmwarePluginManager class.
    ~FirmwarePluginManager();

    /// Gets the singleton instance of FirmwarePluginManager.
    ///     @return The singleton instance.
    static FirmwarePluginManager *instance(); //提供全局唯一的访问点（单例模式）

    /// Returns list of firmwares which are supported by the system
    QList<QGCMAVLink::FirmwareClass_t> supportedFirmwareClasses(); //返回系统支持的固件类型列表（如PX4、ArduPilot等）

    /// Returns the list of supported vehicle types for the specified firmware
    QList<QGCMAVLink::VehicleClass_t> supportedVehicleClasses(QGCMAVLink::FirmwareClass_t firmwareClass);//查询某类固件支持的载具类型（如四旋翼、固定翼等）

    /// Returns appropriate plugin for autopilot type.
    ///     @param firmwareType Type of firmwware to return plugin for.
    ///     @param vehicleType Vehicle type to return plugin for.
    /// @return Singleton FirmwarePlugin instance for the specified MAV_AUTOPILOT.
    FirmwarePlugin *firmwarePluginForAutopilot(MAV_AUTOPILOT firmwareType, MAV_TYPE vehicleType);//根据飞控类型和载具类型返回对应的插件实例（核心功能）

private:
    FirmwarePluginFactory *_findPluginFactory(QGCMAVLink::FirmwareClass_t firmwareClass);//内部方法，根据固件类型查找对应的插件工厂

    FirmwarePlugin *_genericFirmwarePlugin = nullptr;//通用回退插件（当无专门插件时使用）
    QList<QGCMAVLink::FirmwareClass_t> _supportedFirmwareClasses;
};
