#ifndef HYDROGENBATTERYHANDLER_H
#define HYDROGENBATTERYHANDLER_H

#include <QObject>

class HydrogenBatteryHandler : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList batteryInfoList READ batteryInfoList NOTIFY batteryInfoChanged)
   public:

    explicit HydrogenBatteryHandler(QObject *parent = nullptr);


    QVariantList batteryInfoList() const { return m_batteryInfoList; }

    static HydrogenBatteryHandler* instance();

    Q_INVOKABLE void handleData32(const uint8_t* data, uint8_t len);


   signals:
    void dataUpdated(float batVoltage,
                     float servoCurrent,
                     float stackVoltage,
                     float servoVoltage,
                     float refuelCurrent,
                     float tankPressure,
                     float pipePressure,
                     float pcbTemp,
                     float stackTemp,
                     uint8_t workStatus,
                     uint8_t selfCheck,
                     uint16_t faultStatus,
                     uint8_t batteryId);

     void batteryInfoChanged(); //数据变化时发出的信号

   private:
    QVariantList m_batteryInfoList;

    static HydrogenBatteryHandler* _instance;
};

#endif  // HYDROGENBATTERYHANDLER_H
