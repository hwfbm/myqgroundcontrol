#include "loginmanager.h"

LoginManager::LoginManager(QObject *parent)
    : QObject(parent),
      m_tokenTimer(new QTimer(this))
{
    // 定时器检查 token 是否过期，每分钟一次
    connect(m_tokenTimer, &QTimer::timeout, this,[this]()
    {
        if (!m_token.isEmpty() && QDateTime::currentDateTime() >= m_expireTime) {
            m_token.clear();
            emit tokenExpired();
            m_tokenTimer->stop();
        }
    });
}


LoginManager* LoginManager::instance() {
    static LoginManager* _instance = new LoginManager();
    return _instance;
}

//登录
void LoginManager::login(const QString &username, const QString &password)
{

    // 模拟测试：用户名和密码非空就登录成功
    if (!username.isEmpty() && !password.isEmpty()) {
        m_token = "mock-token-123456";
        m_expireTime = QDateTime::currentDateTime().addSecs(60); // 模拟 60 秒过期
        emit tokenChanged();
        emit loginSucceeded();
        startTokenTimer();
        qDebug() << "模拟登录成功，token:" << m_token;
    } else {
        emit loginFailed("用户名或密码为空");
        qDebug() << "模拟登录失败";
    }
    // QUrl url("http://server_ip:port/api/auth");
    // QNetworkRequest request(url);

    // request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // QJsonObject json;
    // json["username"] = username;
    // json["password"] = password;
    // json["sn"] = "your_sn";  // 可用设备 SN 或固定值

    // QNetworkReply *reply = m_networkManager.post(request, QJsonDocument(json).toJson());

    // //拿到服务器返回的token给到处理函数
    // connect(reply, &QNetworkReply::finished, this, [this, reply]() {
    //     handleTokenResponse(reply);
    //     reply->deleteLater();
    // });
}


//处理服务器返回的token
void LoginManager::handleTokenResponse(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        emit loginFailed(reply->errorString());
        return;
    }

            // 解析 JSON
    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    if (!doc.isObject()) {
        emit loginFailed("返回格式错误");
        return;
    }

    QJsonObject obj = doc.object();
    if (!obj.contains("token") || !obj.contains("expire")) {
        emit loginFailed("返回数据缺少 token 或 expire");
        return;
    }

    // 保存 token
    m_token = obj["token"].toString();
    emit tokenChanged();

    // 保存过期时间
    qint64 expireSecs = obj["expire"].toVariant().toLongLong();
    m_expireTime = QDateTime::fromSecsSinceEpoch(expireSecs);

    qDebug() << "登录成功，token:" << m_token << "过期时间:" << m_expireTime.toString();

    emit loginSucceeded();

    // 启动定时器
    m_tokenTimer->start();
}



void LoginManager::checkTokenExpired()
{
    if (!m_token.isEmpty() && QDateTime::currentDateTime() >= m_expireTime) {
        qDebug() << "Token已过期";
        m_token.clear();
        emit tokenChanged();
        emit tokenExpired();
        m_tokenTimer->stop();
    }
}





void LoginManager::generateToken(const QString &username)
{
    // using namespace std::chrono;

    // auto token = jwt::create()
    //                  .set_issuer("QGC")
    //                  .set_type("JWS")
    //                  .set_issued_at(system_clock::now())
    //                  .set_expires_at(system_clock::now() + minutes{30})
    //                  .set_payload_claim("username", jwt::claim(username.toStdString()))
    //                  .sign(jwt::algorithm::hs256{"secret"}); // 🔑 秘钥

    // m_token = QString::fromStdString(token);

    // // 记录过期时间
    // m_expireTime = QDateTime::currentDateTime().addSecs(30 * 60);

    // startTokenTimer();
}

void LoginManager::startTokenTimer()
{
    if (!m_tokenTimer->isActive())
        m_tokenTimer->start(60000); // 每分钟检查一次
}

//是否登录
bool LoginManager::isLoggedIn() const
{
    return !m_token.isEmpty() && QDateTime::currentDateTime() < m_expireTime;
}

QString LoginManager::getToken() const
{
    return m_token;
}
