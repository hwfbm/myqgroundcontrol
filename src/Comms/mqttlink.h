#ifndef MQTTLINK_H
#define MQTTLINK_H
#include <QObject>
#include <QMqttClient>
#include "loginmanager.h" //登录类
#include <QJsonDocument>
#pragma once
//发布类
class Mqttlink : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY stateChanged)


   public:

    // 单例访问接口
    static Mqttlink* instance();
    explicit Mqttlink(QObject* parent = nullptr);

     //按照我协议来的发布
    qint64 publish(const QString& topic,
                   const QJsonObject& json,
                   quint8 qos = 0,
                   bool retain = false);
   Q_INVOKABLE bool isConnected() const;

    //qml种点击连接之后
   Q_INVOKABLE void connectToServer();//用于在前端连接
    // 只需要传入 token（作为 MQTT 密码）
    void disconnectFromServer();

   public slots:

    void publishJson(const QJsonObject& json);
    void subscribeTopic(const QString& topic, quint8 qos = 0);
    void unsubscribeTopic(const QString& topic);

   private:

    LoginManager *m_loginMgr;
    QMqttClient* client;
    // 禁止拷贝
    Mqttlink(const Mqttlink&) = delete;
    Mqttlink& operator=(const Mqttlink&) = delete;
    QTimer m_reconnectTimer;//自动重连时间

    // 固定连接参数（可改为配置文件读取）
    const QString m_host = "47.112.2.160";
    const quint16 m_port = 1883;
    const QString m_clientId = "uav-1001";
    const QString m_username = "admin";

    QString m_token; // 当前使用的 token



   signals:
    void stateChanged();//连接状态改变
    void mqttMessageReceived(const QString &topic, const QJsonObject &json);
};


#endif  // MQTTLINK_H
