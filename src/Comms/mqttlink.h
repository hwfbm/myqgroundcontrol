#ifndef MQTTLINK_H
#define MQTTLINK_H
#include <QObject>
#include <QMqttClient>
#include <QJsonDocument>
#pragma once
//发布类
class Mqttlink : public QObject {
    Q_OBJECT

   public:

    // 单例访问接口
    static Mqttlink* instance();
    explicit Mqttlink(QObject* parent = nullptr);

     //按照我协议来的发布
    qint64 publish(const QString& topic,
                   const QJsonObject& json,
                   quint8 qos = 0,
                   bool retain = false);
       bool isConnected() const;


   public slots:

    void publishJson(const QJsonObject& json);
    void subscribeTopic(const QString& topic, quint8 qos = 0);
    void unsubscribeTopic(const QString& topic);

   private:
    QMqttClient* client;
    // 禁止拷贝
    Mqttlink(const Mqttlink&) = delete;
    Mqttlink& operator=(const Mqttlink&) = delete;
   signals:
    void mqttMessageReceived(const QString &topic, const QJsonObject &json);
};


#endif  // MQTTLINK_H
