/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QList>
#include <QtCore/QLoggingCategory>

#include "QGCMAVLink.h"

class FirmwarePlugin;

Q_DECLARE_LOGGING_CATEGORY(FirmwarePluginFactoryLog)
//抽象基类。这是所有具体工厂类的基类，采用典型的工厂方法模式设计：

class FirmwarePluginFactory : public QObject
{
    Q_OBJECT

public:
    explicit FirmwarePluginFactory(QObject *parent = nullptr);
    // 纯虚函数 - 必须由子类实现
    //两个纯虚函数强制子类实现特定功能
    virtual ~FirmwarePluginFactory();

    /// Returns appropriate plugin for autopilot type.
    ///     @param autopilotType Type of autopilot to return plugin for.
    ///     @param vehicleType Vehicle type of autopilot to return plugin for.
    /// @return Singleton FirmwarePlugin instance for the specified MAV_AUTOPILOT.
    virtual FirmwarePlugin *firmwarePluginForAutopilot(MAV_AUTOPILOT autopilotType, MAV_TYPE vehicleType) = 0;

    /// @return List of firmware classes this plugin supports.
    virtual QList<QGCMAVLink::FirmwareClass_t> supportedFirmwareClasses() const = 0;

    /// @return List of vehicle classes this plugin supports.
    // 虚函数 - 可选择性重写
    //一个虚函数提供默认实现，允许子类按需覆盖
    virtual QList<QGCMAVLink::VehicleClass_t> supportedVehicleClasses() const { return QGCMAVLink::allVehicleClasses(); }
};

/*===========================================================================*/
//使用FirmwarePluginFactoryRegister作为中央注册表管理所有工厂，单例模式实现的全局注册中心
//工厂需要提前注册才能被发现
//不同工厂支持不同固件类别
//运行时根据需求选择合适工厂
//工厂注册表使用单例确保全局唯一访问
class FirmwarePluginFactoryRegister : public QObject
{
    Q_OBJECT

public:
    static FirmwarePluginFactoryRegister *instance();//系统通过 instance() 获取全局单例

    /// Registers the specified logging category to the system.
    //各具体工厂在程序启动时注册自己，这个函数的调用放在了构造函数中，只要继承了工厂类，都会调用这个方法，创建工厂
    void registerPluginFactory(FirmwarePluginFactory *pluginFactory) { _factoryList.append(pluginFactory); }
//查询已注册的工厂列表进行插件创建
    QList<FirmwarePluginFactory*> pluginFactories() const { return _factoryList; }

private:
    QList<FirmwarePluginFactory*> _factoryList; //使用Qt容器QList存储工厂指针。这个列表是全局常驻的，只要 QGC 程序在运行，它就会一直存在
};
