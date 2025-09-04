#ifndef ANDROIDBATTERY_H
#define ANDROIDBATTERY_H

#include <QObject>
#include <QTimer>


//获取安卓设备电量

class AndroidBattery : public QObject {
    Q_OBJECT
    Q_PROPERTY(int batteryLevel READ batteryLevel NOTIFY batteryLevelChanged)
    Q_PROPERTY(bool batteryLow READ batteryLow NOTIFY batteryLowChanged)


public:
    explicit AndroidBattery(QObject *parent = nullptr);
    int batteryLevel() const { return m_batteryLevel; }
    bool batteryLow() const { return m_batteryLevel <= 20; }//返回一个布尔值
    static AndroidBattery* instance(); // 单例获取



public slots:
        void updateBatteryLevel();//返回电量



       signals:
        void batteryLevelChanged(int level);
        void batteryLowChanged(int level);

private:
    int m_batteryLevel = 0;

    QTimer m_timer;
    //static AndroidBattery* _instance;
};

#endif  // ANDROIDBATTERY_H
