/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "FirmwarePluginManager.h"
#include "FirmwarePlugin.h"
#include "FirmwarePluginFactory.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QGlobalStatic>

QGC_LOGGING_CATEGORY(FirmwarePluginManagerLog, "qgc.firmwareplugin.firmwarepluginmanager");

Q_GLOBAL_STATIC(FirmwarePluginManager, _firmwarePluginManagerInstance);

FirmwarePluginManager::FirmwarePluginManager(QObject *parent)
    : QObject(parent)
{
    // qCDebug(FirmwarePluginManagerLog) << Q_FUNC_INFO << this;
}

FirmwarePluginManager::~FirmwarePluginManager()
{
    // qCDebug(FirmwarePluginManagerLog) << Q_FUNC_INFO << this;
}

FirmwarePluginManager *FirmwarePluginManager::instance()
{
    return _firmwarePluginManagerInstance();
}

QList<QGCMAVLink::FirmwareClass_t> FirmwarePluginManager::supportedFirmwareClasses()
{
    if (_supportedFirmwareClasses.isEmpty()) {
        const QList<FirmwarePluginFactory*> factoryList = FirmwarePluginFactoryRegister::instance()->pluginFactories();
        for (const FirmwarePluginFactory *factory: factoryList) {
            _supportedFirmwareClasses.append(factory->supportedFirmwareClasses());
        }
        _supportedFirmwareClasses.append(QGCMAVLink::FirmwareClassGeneric);
    }

    return _supportedFirmwareClasses;
}

QList<QGCMAVLink::VehicleClass_t> FirmwarePluginManager::supportedVehicleClasses(QGCMAVLink::FirmwareClass_t firmwareClass)
{
    QList<QGCMAVLink::VehicleClass_t> vehicleClasses;
    const FirmwarePluginFactory *const factory = _findPluginFactory(firmwareClass);

    if (factory) {
        vehicleClasses = factory->supportedVehicleClasses();
    } else if (firmwareClass == QGCMAVLink::FirmwareClassGeneric) {
        // Generic supports all specific vehicle class
        vehicleClasses = QGCMAVLink::allVehicleClasses();
        (void) vehicleClasses.removeOne(QGCMAVLink::VehicleClassGeneric);
    } else {
        qCWarning(FirmwarePluginManagerLog) << "Request for unknown firmware plugin factory" << firmwareClass;
    }

    return vehicleClasses;
}


//这个函数是固件插件管理器的核心方法，用于根据飞行控制器类型和载具类型获取对应的固件插件实例。
//返回类型: FirmwarePlugin* - 返回对应固件的插件实例指针
//MAV_AUTOPILOT firmwareType: 飞控硬件类型(如PX4, ArduPilot等)
//MAV_TYPE vehicleType: 载具类型(如固定翼、多旋翼等)
//插件系统支持动态扩展，新飞控类型可通过注册新工厂来支持
//通用插件作为回退方案确保系统健壮性
//这个函数是飞行控制软件支持多种飞控固件的关键，通过灵活的插件架构实现对不同飞控平台的支持，同时保证在未知飞控类型时也能提供基本功能
FirmwarePlugin *FirmwarePluginManager::firmwarePluginForAutopilot(MAV_AUTOPILOT firmwareType, MAV_TYPE vehicleType)
{
    //调用_findPluginFactory(firmwareType)根据飞控类型查找对应的插件工厂，工厂模式用于创建特定固件的插件实例
    FirmwarePluginFactory *const factory = _findPluginFactory(firmwareType);
    FirmwarePlugin *plugin = nullptr;

    //如果找到对应工厂(factory不为空)，则调用工厂的firmwarePluginForAutopilot方法创建插件
    //此方法可能根据不同的vehicleType返回不同的插件变体
    if (factory) {
        plugin = factory->firmwarePluginForAutopilot(firmwareType, vehicleType);//调用的是子类中，也就是具体插件工厂例如APMFirmwarePluginFactory类重写的FirmwarePluginFactory的纯虚函数
    }

    //如果没有找到对应插件(!plugin)，则使用通用插件，确保总是返回一个有效的插件实例
    //通用插件(_genericFirmwarePlugin)采用延迟初始化模式(第一次需要时才创建)
    if (!plugin) {
        if (!_genericFirmwarePlugin) {
            _genericFirmwarePlugin = new FirmwarePlugin(this);
        }
        plugin = _genericFirmwarePlugin;
    }

    return plugin;
}


//这个私有函数用于根据固件类别查找对应的插件工厂，是固件插件管理系统的核心组件之一。
//返回类型: FirmwarePluginFactory* - 返回匹配的插件工厂指针，找不到则返回nullptr
//参数:QGCMAVLink::FirmwareClass_t firmwareClass - 要查找的固件类别枚举值
FirmwarePluginFactory *FirmwarePluginManager::_findPluginFactory(QGCMAVLink::FirmwareClass_t firmwareClass)
{
    //FirmwarePluginFactoryRegister单例获取所有已注册的插件工厂列表
    //pluginFactories()返回QList<FirmwarePluginFactory*>
    const QList<FirmwarePluginFactory*> factoryList = FirmwarePluginFactoryRegister::instance()->pluginFactories();

    //线性搜索匹配:遍历所有工厂实例
    //检查每个工厂的supportedFirmwareClasses()是否包含请求的固件类别
    //使用contains()方法进行匹配检查
    for (FirmwarePluginFactory *factory: factoryList)
    {
        if (factory->supportedFirmwareClasses().contains(firmwareClass)) {
            return factory;//找到匹配则立即返回对应工厂指针
        }
    }

    //遍历完所有工厂未找到匹配则返回nullptr
    return nullptr;
}
