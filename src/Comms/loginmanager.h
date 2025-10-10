#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QByteArray>
//#include <jwt-cpp/jwt.h>
#include <QTimer>


class LoginManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool loggedIn READ isLoggedIn NOTIFY loginSucceeded)

   public:
    explicit LoginManager(QObject *parent = nullptr);
     static LoginManager* instance();   // 单例入口
    // QML 调用接口
    Q_INVOKABLE void login(const QString &username, const QString &password);
    // 当前 JWT
    QString token() const { return m_token; }

    //是否已登录,用来看token状态，前端提示登录状态
    bool loggedIn() const { return !m_token.isEmpty(); }//有token返回true




    Q_INVOKABLE bool isLoggedIn() const;
    Q_INVOKABLE QString getToken() const;

   signals:
    void loginSucceeded();          // 登录成功
    void loginFailed(const QString &error); // 登录失败
    void tokenExpired();            // token 过期
    void tokenChanged();            // token 变化

   private slots:
    void handleTokenResponse(QNetworkReply *reply);//处理token
    void checkTokenExpired();//确认token是否过期


   private:
    bool isTestMode() const { return true; } // 仅测试用

    QNetworkAccessManager m_networkManager;
    QString m_token;//存token
    QDateTime m_expireTime;//检测token过期间隔
    QTimer *m_tokenTimer; // 用于过期检查

    LoginManager*_instance = nullptr;//单例

    void generateToken(const QString &username);
    void startTokenTimer();
};
