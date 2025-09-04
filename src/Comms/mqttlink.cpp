#include "mqttlink.h"
#include<QJsonObject>
Mqttlink::Mqttlink(QObject *parent) : QObject{parent}
{
    client = new QMqttClient(this);
    client->setHostname("47.112.2.160");
    client->setPort(1883);
    client->setClientId("uav-1001"); // 唯一 ID
    // 如果服务器需要认证：
    client->setUsername("admin");
    client->setPassword("admin123456");

    client->connectToHost();

    connect(client, &QMqttClient::stateChanged, this, [=](QMqttClient::ClientState state){
        qDebug() << "MQTT State:" << state;
    });

    connect(client, &QMqttClient::connected, this, [=](){
        qDebug() << "✅ MQTT connected!";

        //         // 连接成功后发送测试消息
        // QJsonObject test;
        // test["test"] = "hello mqtt";
        // publishJson(test);
    });

    connect(client, &QMqttClient::disconnected, this, [](){
        qDebug() << "❌ MQTT disconnected!";
    });

}
//测试发布
void Mqttlink::publishJson(const QJsonObject& json)
{
    QString topic = "qgc/mavlink";  // 固定 topic
    if (client->state() == QMqttClient::Connected) {
        QJsonDocument doc(json);
        QByteArray payload = doc.toJson(QJsonDocument::Compact);
        qint64 id = client->publish(topic, payload);  // 返回消息 ID
        qDebug() << "Publishing to MQTT:" << topic << payload << "id=" << id;
    } else {
        qDebug() << "MQTT not connected";
    }
}
Mqttlink* Mqttlink::instance()
{
    static Mqttlink* _instance = new Mqttlink();
    return _instance;
}

void Mqttlink::subscribeTopic(const QString& topic, quint8 qos)
{
    // if (client->state() != QMqttClient::Connected) {
    //     qDebug() << "MQTT not connected, cannot subscribe to" << topic;
    //     return;
    // }

    // auto subscription = client->subscribe(topic, qos);
    // if (!subscription) {
    //     qDebug() << "Failed to subscribe to" << topic;
    //     return;
    // }

    //         // 收到消息时的回调
    // connect(subscription, &QMqttSubscription::messageReceived,
    //         this, [=](const QMqttMessage &msg){
    //             QByteArray payload = msg.payload();
    //             qDebug() << "Received message on topic" << msg.topic() << ":" << payload;

    //             // 可以尝试解析 JSON
    //             QJsonDocument doc = QJsonDocument::fromJson(payload);
    //             if (!doc.isNull() && doc.isObject()) {
    //                 QJsonObject json = doc.object();
    //                 emit mqttMessageReceived(msg.topic(), json);
    //             }
    //         });

    // qDebug() << "Subscribed to topic" << topic;
}

void Mqttlink::unsubscribeTopic(const QString& topic)
{
    // auto subsList = client->subscriptions();
    // for (auto sub : subsList) {
    //     if (sub->topicName() == topic) {
    //         client->unsubscribe(sub);
    //         qDebug() << "Unsubscribed from topic" << topic;
    //         break;
    //     }
    // }
}

//按照我协议来的发布
qint64 Mqttlink::publish(const QString& topic,
                         const QJsonObject& json,
                         quint8 qos,
                         bool retain)
{
    if (client->state() != QMqttClient::Connected) {
        qDebug() << "MQTT not connected, skip publish";
        return -1;
    }
    QJsonDocument doc(json);
    QByteArray payload = doc.toJson(QJsonDocument::Compact);
    qint64 id = client->publish(topic, payload, qos, retain);
    qDebug() << "[MQTT] PUB" << topic << "qos" << qos << "retain" << retain
             << "id=" << id << payload;
    return id;
}

bool Mqttlink::isConnected() const {
    return client && client->state() == QMqttClient::Connected;
}

