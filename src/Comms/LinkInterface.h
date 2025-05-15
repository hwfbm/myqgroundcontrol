/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

//它是所有用于与地面站应用程序通信的链接的接口
//定义了所有链接的接口，提供了连接、数据传输和状态管理的功能
#pragma once

#include <QtCore/QLoggingCategory>

#include "LinkConfiguration.h"

class LinkManager;

Q_DECLARE_LOGGING_CATEGORY(LinkInterfaceLog)

/// The link interface defines the interface for all links used to communicate with the ground station application.
class LinkInterface : public QObject
{
    Q_OBJECT

    friend class LinkManager;

public:
    virtual ~LinkInterface();//抽象类的析构函数必须声明为 virtual，确保派生类对象能正确释放，确保派生类的析构函数被正确调用

    //虚函数（Pure Virtual Function）是 C++ 中实现抽象类和接口设计的核心机制，它的存在强制派生类必须提供具体实现，从而定义清晰的类层次结构契约
    //创建抽象类，抽象类：包含至少一个纯虚函数的类，不能直接实例化
    //) 强制派生类实现：派生类必须覆盖（override）所有纯虚函数，否则也会成为抽象类
    //纯虚函数本质上是一种接口契约，在成员函数声明后添加 = 0，表示该函数没有默认实现
    Q_INVOKABLE virtual void disconnect() = 0; //纯虚函数，用于断开连接，强制派生类实现断开连接逻辑 FIXME: This gets called 3x when closing link

    virtual bool isConnected() const = 0; //纯虚函数，用于检查链接是否已连接，必须返回当前连接状态

    virtual bool isLogReplay() const { return false; }
    virtual bool isSecureConnection() const { return false; } ///< Returns true if the connection is secure (e.g. USB, wired ethernet)

    SharedLinkConfigurationPtr linkConfiguration() { return _config; }//返回链接的配置
    const SharedLinkConfigurationPtr linkConfiguration() const { return _config; }

    uint8_t mavlinkChannel() const; //返回 MAVLink 通道，每个链路分配独立 MAVLink 通道（0-15），通道分配由 LinkManager 集中管理

    bool mavlinkChannelIsSet() const; //检查 MAVLink 通道是否已经设置，在需要确认通道是否可用时调用此函数
    bool decodedFirstMavlinkPacket() const { return _decodedFirstMavlinkPacket; }//查是否解码了第一个 MAVLink 数据包
    void setDecodedFirstMavlinkPacket(bool decodedFirstMavlinkPacket) { _decodedFirstMavlinkPacket = decodedFirstMavlinkPacket; }
    void writeBytesThreadSafe(const char *bytes, int length);//线程安全地写入字节，公开线程安全写入接口，内部通过信号槽机制跳转到对象所属线程执行 _writeBytes
    void addVehicleReference() { ++_vehicleReferenceCount; }//避免车辆仍在使用时链路被意外关闭
    void removeVehicleReference();//避免车辆仍在使用时链路被意外关闭
    bool initMavlinkSigning(); //初始化 MAVLink 签名，在需要启用 MAVLink 签名功能时调用此函数
    void setSigningSignatureFailure(bool failure); //设置签名验证失败的状态

signals:
    void bytesReceived(LinkInterface *link, const QByteArray &data);//数据接收信号，当链路收到数据时触发
    void bytesSent(LinkInterface *link, const QByteArray &data); //数据发送信号。当数据成功发送时触发
    void connected(); //连接成功信号
    void disconnected(); //断开连接信号。链路断开时（主动/被动触发
    void communicationError(const QString &title, const QString &error);//通信错误信号

protected:
    //构造函数为 protected，只能通过 LinkManager 创建实例
    /// Links are only created by LinkManager so constructor is not public
    explicit LinkInterface(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);

    /// Called by the LinkManager during LinkInterface construction instructing the link to setup channels.
    /// Default implementation allocates a single channel. But some link types (such as MockLink) need more than one.
    virtual bool _allocateMavlinkChannel(); //分配一个 MAVLink 通道，默认实现分配一个通道，但某些链接类型（如 MockLink）可能需要多个通道

    virtual void _freeMavlinkChannel(); //释放当前分配的 MAVLink 通道，在不再需要当前通道时调用此函数，以释放资源

    void _connectionRemoved();//处理连接移除的逻辑，在连接被移除时调用此函数，以执行必要的清理工作

    SharedLinkConfigurationPtr _config;

private slots:
    /// Not thread safe if called directly, only writeBytesThreadSafe is thread safe
    virtual void _writeBytes(const QByteArray &bytes) = 0; //纯虚函数，用于写入字节，内部字节写入方法（线程不安全）

private:
    //connect是私有的，因为所有链接都应该通过LinkManager::createConnectedLink创建
    /// connect is private since all links should be created through LinkManager::createConnectedLink calls
    virtual bool _connect() = 0;//内部字节写入方法（线程不安全）

    uint8_t _mavlinkChannel = std::numeric_limits<uint8_t>::max(); //存储当前分配的 MAVLink 通道编号，初始值：std::numeric_limits<uint8_t>::max()，表示通道未分配
    bool _decodedFirstMavlinkPacket = false; //表示是否解码了第一个 MAVLink 数据包
    int _vehicleReferenceCount = 0; //记录引用该链接的车辆数量。这可能用于管理链接的生命周期，确保在没有车辆引用时释放链接资源
    bool _signingSignatureFailure = false; //记录签名验证失败的状态
};

//当需要一个强引用时，使用 SharedLinkInterfacePtr。这意味着只要这个指针存在，它所指向的对象就不会被销毁
//std::shared_ptr 是一个强引用智能指针，它通过引用计数机制来管理对象的生命周期。当最后一个 std::shared_ptr 被销毁时，它所指向的对象也会被自动销毁。
typedef std::shared_ptr<LinkInterface> SharedLinkInterfacePtr; //强引用智能指针。这是一个类型别名，表示一个强引用智能指针，指向 LinkInterface 类型的对象


//std::weak_ptr 提供了一个 lock 方法，用于检查对象是否仍然存在。如果对象仍然存在，lock 方法返回一个 std::shared_ptr；如果对象已经被销毁，lock 方法返回一个空的 std::shared_ptr
//std::weak_ptr 是一个弱引用智能指针，它也通过引用计数机制来管理对象，但它不会影响对象的生命周期。std::weak_ptr 通常用于打破 std::shared_ptr 之间的循环引用
//当您需要一个弱引用时，使用 WeakLinkInterfacePtr。这意味着即使这个指针存在，它所指向的对象也可能被销毁。在访问对象之前，您需要通过 lock 方法检查对象是否仍然存在
typedef std::weak_ptr<LinkInterface> WeakLinkInterfacePtr; //弱引用智能指针
