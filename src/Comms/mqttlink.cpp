#include "mqttlink.h"
#include<QJsonObject>
Mqttlink::Mqttlink(QObject *parent) : QObject(parent),
    m_loginMgr(new LoginManager(this)),
    client(new QMqttClient(this))

{
    // client = new QMqttClient(this);
    // client->setHostname("47.112.2.160");
    // client->setPort(1883);
    // client->setClientId("uav-1001"); // 唯一 ID
    // //服务器需要认证：
    // client->setUsername("admin");
    // client->setPassword("admin123456");

    // client->connectToHost();

    // connect(client, &QMqttClient::stateChanged, this, [=](QMqttClient::ClientState state){
    //     qDebug() << "MQTT State:" << state;
    // });

    // connect(client, &QMqttClient::connected, this, [=](){
    //     qDebug() << "MQTT connected!";

    //     //         // 连接成功后发送测试消息
    //     // QJsonObject test;
    //     // test["test"] = "hello mqtt";
    //     // publishJson(test);
    // });

    // connect(client, &QMqttClient::disconnected, this, [](){
    //     qDebug() << "MQTT disconnected!";
    // });

    //唯一id
     client->setClientId("uav-1001");
    // 监听 MQTT 状态
    connect(client, &QMqttClient::stateChanged, this, [this](QMqttClient::ClientState state) {
          emit stateChanged();
         qDebug() << "MQTT即时状态:" << state;
    });


    // 监听连接成功
    connect(client, &QMqttClient::connected, this, [this]() {
        qDebug() << "MQTT 已连接！";
        // 可以在这里自动订阅某个 topic
        // client->subscribe("test/topic");
    });

    // 监听断开
    connect(client, &QMqttClient::disconnected, this, []() {
        qDebug() << " MQTT 断开连接!";
    });

    // 监听 token 过期 → 自动断开
    // connect(m_loginMgr, &LoginManager::tokenExpired, this, [this]() {
    //     qDebug() << "⚠️ Token 已经过期，断开 MQTT";
    //     client->disconnectFromHost();
    // });

}

//连接服务器
void Mqttlink::connectToServer()
{
    client->setHostname(m_host);
    client->setPort(m_port);
    client->setClientId(m_clientId);
    client->setUsername(m_username);
   // client->setClientId("uav-1001"); // 唯一 ID
    // //若token存在就用token作为密码，没有就默认为原始密码
    // if (!m_loginMgr->token().isEmpty()) {
    //     client->setPassword(m_loginMgr->token());   //用token作为密码
    // } else {
    //     client->setPassword("admin123456");         //原始测试密码
    // }

    // 判断 LoginManager 是否有 token
    if (m_loginMgr && m_loginMgr->isLoggedIn()) {
        client->setPassword(m_loginMgr->getToken());
        qDebug() << "使用 token 登录 MQTT";
    } else {
        client->setPassword("admin123456");
        qDebug() << "没有 token，用默认密码登录 MQTT";
    }
    qDebug() << "正在连接 MQTT:" << m_host << m_port;



    client->connectToHost();
    //client->setPassword("admin123456");

    client->connectToHost();

    connect(client, &QMqttClient::stateChanged, this, [=](QMqttClient::ClientState state){
        qDebug() << "MQTT State:" << state;
    });

    connect(client, &QMqttClient::connected, this, [=](){
        qDebug() << "MQTT connected!";

                //         // 连接成功后发送测试消息
                // QJsonObject test;
                // test["test"] = "hello mqtt";
                // publishJson(test);
    });

    connect(client, &QMqttClient::disconnected, this, [](){
        qDebug() << "MQTT disconnected!";
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
    qint64 id = client->publish(topic, payload, qos, retain);//主题；消息体；消息传递的保证级别；保留消息标志，true，代理会持久化存储这条消息
    qDebug() << "[MQTT] PUB" << topic << "qos" << qos << "retain" << retain
             << "id=" << id << payload;
    return id;
}

bool Mqttlink::isConnected() const {
    return client && client->state() == QMqttClient::Connected;
}

