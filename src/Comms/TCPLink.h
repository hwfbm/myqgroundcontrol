/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QByteArray>
#include <QtCore/QLoggingCategory>
#include <QtCore/QString>
#include <QtNetwork/QAbstractSocket>
#include <QtNetwork/QHostAddress>

#include "LinkConfiguration.h"
#include "LinkInterface.h"

class QTcpSocket;
class QThread;

Q_DECLARE_LOGGING_CATEGORY(TCPLinkLog)

/*===========================================================================*/
//保存链接配置，QML 可直接绑定（host、port）
//QML 可直接通过 host、port 属性访问和修改
class TCPConfiguration : public LinkConfiguration
{
    Q_OBJECT

    Q_PROPERTY(QString host READ host WRITE setHost NOTIFY hostChanged)
    Q_PROPERTY(quint16 port READ port WRITE setPort NOTIFY portChanged)

public:
    explicit TCPConfiguration(const QString &name, QObject *parent = nullptr);
    explicit TCPConfiguration(const TCPConfiguration *copy, QObject *parent = nullptr);
    virtual ~TCPConfiguration();

    LinkType type() const override { return LinkConfiguration::TypeTcp; }
    void copyFrom(const LinkConfiguration *source) override;//支持复制已有配置
    //序列化/反序列化连接配置，方便下次启动直接加载
    void loadSettings(QSettings &settings, const QString &root) override;
    void saveSettings(QSettings &settings, const QString &root) const override;

    //提供 QML 页面信息
    QString settingsURL() const override { return QStringLiteral("TcpSettings.qml"); }
    QString settingsTitle() const override { return tr("TCP Link Settings"); }

    QString host() const { return _host.toString(); }
    void setHost(const QString &host) { if (host != _host.toString()) { _host.setAddress(host); emit hostChanged(); } }
    quint16 port() const { return _port; }
    void setPort(quint16 port) { if (port != _port) { _port = port; emit portChanged(); } }

signals:
    void hostChanged();
    void portChanged();

private:
    //提供默认值 5760（MAVLink TCP 默认端口）
    QHostAddress _host;
    quint16 _port = 5760;
};

/*===========================================================================*/
//负责实际的 QTcpSocket 操作，运行在独立线程，发信号通知上层
//真正和 TCP Socket 打交道，负责异步连接、读取、写入、错误处理
//运行在 独立线程 中，保证 GUI 不会被阻塞
//Worker 完全和 Qt 网络 API 打交道，与 QGC MAVLink 逻辑分离
//上层不关心线程和 socket 细节，只收发信号
class TCPWorker : public QObject
{
    Q_OBJECT

public:
    explicit TCPWorker(const TCPConfiguration *config, QObject *parent = nullptr);
    ~TCPWorker();

    bool isConnected() const;

signals:
    //Worker 通过信号通知上层 TCPLink 或 QML
    void connected();
    void disconnected();
    void errorOccurred(const QString &errorString);
    void dataReceived(const QByteArray &data);//dataReceived 是核心信号，QGC 的 MAVLink 处理会订阅它
    void dataSent(const QByteArray &data);

public slots:
    //以及内部槽 _onSocketReadyRead，负责读取数据并 emit dataReceived
    void setupSocket();
    void connectToHost();
    void disconnectFromHost();
    void writeData(const QByteArray &data);

private slots:
    void _onSocketConnected();
    void _onSocketDisconnected();
    void _onSocketReadyRead();
    void _onSocketBytesWritten(qint64 bytes);
    void _onSocketErrorOccurred(QAbstractSocket::SocketError socketError);

private:
    const TCPConfiguration *_config = nullptr;//Worker 持有的配置指针
    QTcpSocket *_socket = nullptr;//实际的 TCP 套接字
    bool _errorEmitted = false;//防止重复发射错误信号
};

/*===========================================================================*/
//实现 LinkInterface，对 QGC 来说就是一个 Link，可在 VehicleManager/LinkManager 中注册，内部把信号槽连接到 Worker
//把 TCPWorker 封装成 QGC 的 LinkInterface，可以被 Vehicle/LinkManager 使用
//创建 Worker 并移动到独立线程,将 Worker 的信号连接到自己的槽
//实现 LinkInterface 的虚函数
class TCPLink : public LinkInterface
{
    Q_OBJECT

public:
    explicit TCPLink(SharedLinkConfigurationPtr &config, QObject *parent = nullptr);
    virtual ~TCPLink();

    bool isConnected() const override;
    void disconnect() override;
    bool isSecureConnection() const override;

private slots:
    void _writeBytes(const QByteArray &bytes) override;//重写 LinkInterface 的写入接口，将 MAVLink 数据传给 Worker
    void _onConnected();
    void _onDisconnected();
    void _onErrorOccurred(const QString &errorString);
    void _onDataReceived(const QByteArray &data);//Worker 收到 TCP 数据后，Link 转发给 QGC MAVLink 处理层
    void _onDataSent(const QByteArray &data);

private:
    bool _connect() override;

    const TCPConfiguration *_tcpConfig = nullptr;
    TCPWorker *_worker = nullptr;
    QThread *_workerThread = nullptr;
};
