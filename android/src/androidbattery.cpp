#include "androidbattery.h"
#include <QJniObject>//Qt6 提供的 JNI 封装类，用于调用 Android 原生 Java API
#include <QTimer>
#include <QDebug>

AndroidBattery::AndroidBattery(QObject *parent) : QObject{parent}, m_batteryLevel(0)
{
    // 每分钟更新一次电量
    connect(&m_timer, &QTimer::timeout, this, &AndroidBattery::updateBatteryLevel);
    m_timer.start(60000);//每 60 秒触发一次更新

    // 启动时立即更新一次
    updateBatteryLevel();
}

//单例模式，一直是一个对象
AndroidBattery* AndroidBattery::instance()
{
    static AndroidBattery s_instance;
    return &s_instance;
}


// 电量变化时，安卓系统会自动发出一个粘性广播 Intent.ACTION_BATTERY_CHANGED。
// 这不是普通广播，而是一个 sticky broadcast，所以即使注册时电量没变化，也能立即拿到当前的电池状态。
// 之后只要电量变化，系统就会推送事件给注册的BroadcastReceiver。
void AndroidBattery::updateBatteryLevel()
{
#ifdef Q_OS_ANDROID
   // 获取 Android Activity 对象，调用静态 Java 方法
    QJniObject context = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative", "activity", "()Landroid/app/Activity;");

    if (!context.isValid()) {
        qWarning() << "AndroidBattery: activity context invalid!";
        return;
    }

    // 创建 BATTERY_CHANGED 的 IntentFilter过滤器
    QJniObject intentFilter("android/content/IntentFilter",
                            "(Ljava/lang/String;)V",
                            QJniObject::fromString("android.intent.action.BATTERY_CHANGED").object());

    // 注册 receiver 获取当前电量 Intent， 广播接收器（系统会立即返回最新电量）
    // 但传入 nullptr 表示只是获取当前电量，不真正监听
    // 返回一个 Intent 对象，里面有 level 和 scale 字段
    QJniObject batteryStatus = context.callObjectMethod(
        "registerReceiver",
        "(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;",
        nullptr, intentFilter.object());

    if (!batteryStatus.isValid()) {
        qDebug() << "AndroidBattery: batteryStatus intent invalid";
        return;
    }

    // 使用 getIntExtra 获取 level 和 scale，获取电池当前电量
    // scale 表示满电值，一般是 100
    int level = batteryStatus.callMethod<jint>(
        "getIntExtra", "(Ljava/lang/String;I)I",
        QJniObject::fromString("level").object(),
        -1
        );

    int scale = batteryStatus.callMethod<jint>(
        "getIntExtra", "(Ljava/lang/String;I)I",
        QJniObject::fromString("scale").object(),
        -1
        );

    //计算百分比：percent = level * 100 / scale
    if (level >= 0 && scale > 0) {
        int percent = static_cast<int>((level * 100.0f) / scale);
        if (percent != m_batteryLevel) {
            m_batteryLevel = percent;
            emit batteryLevelChanged(m_batteryLevel);//发信号给 QML，QML 会自动刷新显示
            emit batteryLowChanged(batteryLow());//同时判断是不是低电量
            qDebug() << "AndroidBattery: level" << level << "scale" << scale << "percent" << m_batteryLevel;
        }
    } else {
        qDebug() << "AndroidBattery: level/scale invalid, using previous value" << m_batteryLevel;
    }
#endif
}

