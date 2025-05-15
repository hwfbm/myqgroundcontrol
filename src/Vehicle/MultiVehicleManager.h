/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/// @file
///     @author Don Gagne <don@thegagnes.com>

#pragma once

#include <QtCore/QObject>
#include <QtCore/QLoggingCategory>

class LinkInterface;
class Vehicle;
class QmlObjectListModel;
class QTimer;

Q_DECLARE_LOGGING_CATEGORY(MultiVehicleManagerLog)

//管理多个无人机（Vehicle）的核心类，负责处理无人机的连接、选择、参数同步以及心跳信息等
class MultiVehicleManager : public QObject
{
    Q_OBJECT
    //确保相关头文件被 MOC 处理，以便在 QML 中使用
    Q_MOC_INCLUDE("QmlObjectListModel.h")
    Q_MOC_INCLUDE("LinkInterface.h")
    Q_MOC_INCLUDE("Vehicle.h")
    //定义了几个属性，用于在 QML 中访问 MultiVehicleManager 的状态
    Q_PROPERTY(bool                 activeVehicleAvailable          READ _getActiveVehicleAvailable                                         NOTIFY activeVehicleAvailableChanged)
    Q_PROPERTY(bool                 parameterReadyVehicleAvailable  READ _getParameterReadyVehicleAvailable                                 NOTIFY parameterReadyVehicleAvailableChanged)
    Q_PROPERTY(Vehicle              *activeVehicle                  READ activeVehicle                      WRITE setActiveVehicle          NOTIFY activeVehicleChanged)
    Q_PROPERTY(QmlObjectListModel   *vehicles                       READ vehicles                                                           CONSTANT)
    Q_PROPERTY(QmlObjectListModel   *selectedVehicles               READ selectedVehicles                                                   CONSTANT)
    Q_PROPERTY(Vehicle              *offlineEditingVehicle          READ offlineEditingVehicle                                              CONSTANT)

public:
    explicit MultiVehicleManager(QObject *parent = nullptr);
    ~MultiVehicleManager();

    static MultiVehicleManager *instance(); //返回 MultiVehicleManager 的单例实例
    static void registerQmlTypes(); //注册 QML 类型，使得 MultiVehicleManager 及其相关类可以在 QML 中使用

    void init(); //初始化 MultiVehicleManager，通常在应用程序启动时调用

    Q_INVOKABLE Vehicle *getVehicleById(int vehicleId) const;//根据无人机的 ID 获取对应的 Vehicle 对象，返回对应的 Vehicle 对象，如果未找到则返回 nullptr
    Q_INVOKABLE void      selectVehicle(int vehicleId);//选择一个无人机
    Q_INVOKABLE void    deselectVehicle(int vehicleId);//取消选择一个无人机
    Q_INVOKABLE void    deselectAllVehicles();//取消选择所有无人机
    QmlObjectListModel *vehicles() const { return _vehicles; }//返回所有无人机的列表
    QmlObjectListModel *selectedVehicles() const { return _selectedVehicles; } //返回已选择的无人机的列表
    Vehicle *offlineEditingVehicle() const { return _offlineEditingVehicle; }//返回用于离线编辑的无人机
    Vehicle *activeVehicle() const { return _activeVehicle; } //返回当前激活的无人机
    void setActiveVehicle(Vehicle *vehicle); //设置当前激活的无人机

signals:
    void vehicleAdded(Vehicle *vehicle); //当一个新的无人机被添加时发出
    void vehicleRemoved(Vehicle *vehicle);//当一个无人机被移除时发出
    void activeVehicleAvailableChanged(bool activeVehicleAvailable);//当激活的无人机可用状态发生变化时发出
    void parameterReadyVehicleAvailableChanged(bool parameterReadyVehicleAvailable);//当参数准备好的无人机可用状态发生变化时发出
    void activeVehicleChanged(Vehicle *activeVehicle);//当激活的无人机发生变化时发出

private slots:
    void _deleteVehiclePhase1(Vehicle *vehicle);//第一阶段删除无人机，通常用于清理资源 /// This slot is connected to the Vehicle::allLinksDestroyed signal such that the Vehicle is deleted and all other right things happen when the Vehicle goes away.
    void _deleteVehiclePhase2(Vehicle *vehicle);//第二阶段删除无人机，通常用于最终删除
    void _setActiveVehiclePhase2(Vehicle *vehicle);//设置激活无人机的第二阶段
    void _vehicleParametersReadyChanged(bool parametersReady);//当无人机的参数准备状态发生变化时调用
    void _sendGCSHeartbeat();//发送地面站的心跳信息
    void _vehicleHeartbeatInfo(LinkInterface *link, int vehicleId, int componentId, int vehicleFirmwareType, int vehicleType);//处理无人机的心跳信息
    void _requestProtocolVersion(unsigned version) const;//请求协议版本 /// This slot is connected to the Vehicle::requestProtocolVersion signal such that the vehicle manager tries to switch MAVLink to v2 if all vehicles support it

private:
    bool _vehicleExists(int vehicleId); //检查是否存在指定 ID 的无人机
    bool _vehicleSelected(int vehicleId);//检查指定 ID 的无人机是否被选中
    void _setActiveVehicle(Vehicle *vehicle); //设置当前激活的无人机。更新 _activeVehicle 成员变量，并触发相关信号
    bool _getActiveVehicleAvailable() const { return _activeVehicleAvailable; } //获取是否有激活的无人机，返回布尔值，表示是否有激活的无人机。提供 activeVehicleAvailable 属性的 getter 方法
    void _setActiveVehicleAvailable(bool activeVehicleAvailable);//设置是否有激活的无人机，更新 _activeVehicleAvailable 成员变量，并触发 activeVehicleAvailableChanged 信号
    bool _getParameterReadyVehicleAvailable() const { return _parameterReadyVehicleAvailable; }//获取是否有参数准备好的无人机。提供 parameterReadyVehicleAvailable 属性的 getter 方法
    void _setParameterReadyVehicleAvailable(bool parametersReady);//设置是否有参数准备好的无人机。：更新 _parameterReadyVehicleAvailable 成员变量，并触发 parameterReadyVehicleAvailableChanged 信号

    QTimer *_gcsHeartbeatTimer = nullptr;      //用于发送地面站心跳信息的定时器     ///< Timer to emit heartbeats
    Vehicle *_offlineEditingVehicle = nullptr;  //：用于离线编辑的无人机    ///< Disconnected vechicle used for offline editing
    QmlObjectListModel *_vehicles = nullptr; //所有无人机的列表
    QmlObjectListModel *_selectedVehicles = nullptr; //已选择的无人机的列表
    bool _activeVehicleAvailable = false;       //表示是否有激活的无人机     ///< true: An active vehicle is available
    bool _parameterReadyVehicleAvailable = false;   //表示是否有参数准备好的无人机 ///< true: An active vehicle with ready parameters is available
    Vehicle *_activeVehicle = nullptr;    //当前激活的无人机          ///< Currently active vehicle from a ui perspective
    QList<int> _ignoreVehicleIds;          //忽略通信的无人机 ID 列表          ///< List of vehicle id for which we ignore further communication
    bool _initialized = false;//表示是否已初始化

    static constexpr int kGCSHeartbeatRateMSecs = 1000; //地面站心跳信息的发送频率（1000 毫秒） ///< Heartbeat rate
};
