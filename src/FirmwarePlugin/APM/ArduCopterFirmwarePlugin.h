/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "APMFirmwarePlugin.h"

struct APMCopterMode
{
    enum Mode : uint32_t{
        STABILIZE   = 0,   // hold level position
        ACRO        = 1,   // rate control
        ALT_HOLD    = 2,   // AUTO control
        AUTO        = 3,   // AUTO control
        GUIDED      = 4,   // AUTO control
        LOITER      = 5,   // Hold a single location
        RTL         = 6,   // AUTO control
        CIRCLE      = 7,   // AUTO control
        POSITION    = 8,   // Deprecated
        LAND        = 9,   // AUTO control
        OF_LOITER   = 10,  // Deprecated
        DRIFT       = 11,  // Drift 'Car Like' mode
        RESERVED_12 = 12,  // RESERVED FOR FUTURE USE
        SPORT       = 13,
        FLIP        = 14,
        AUTOTUNE    = 15,
        POS_HOLD    = 16, // HYBRID LOITER.
        BRAKE       = 17,
        THROW       = 18,
        AVOID_ADSB  = 19,
        GUIDED_NOGPS= 20,
        SMART_RTL   = 21,  // SMART_RTL returns to home by retracing its steps
        FLOWHOLD    = 22,  // FLOWHOLD holds position with optical flow without rangefinder
        FOLLOW      = 23,  // follow attempts to follow another vehicle or ground station
        ZIGZAG      = 24,  // ZIGZAG mode is able to fly in a zigzag manner with predefined point A and point B
        SYSTEMID    = 25,
        AUTOROTATE  = 26,
        AUTO_RTL    = 27,
        TURTLE      = 28,
    };
};

class ArduCopterFirmwarePlugin : public APMFirmwarePlugin
{
    Q_OBJECT

public:
    explicit ArduCopterFirmwarePlugin(QObject *parent = nullptr);
    ~ArduCopterFirmwarePlugin();

    void guidedModeLand(Vehicle *vehicle) const override { _setFlightModeAndValidate(vehicle, landFlightMode()); }
    const FirmwarePlugin::remapParamNameMajorVersionMap_t &paramNameRemapMajorVersionMap() const override { return _remapParamName; }
    int remapParamNameHigestMinorVersionNumber(int majorVersionNumber) const override;
    bool multiRotorCoaxialMotors(Vehicle* /*vehicle*/) const override { return _coaxialMotors; }
    bool multiRotorXConfig(Vehicle *vehicle) const override;
    QString offlineEditingParamFile(Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral(":/FirmwarePlugin/APM/Copter.OfflineEditing.params"); }
    QString pauseFlightMode() const override;
    QString landFlightMode() const override;
    QString takeControlFlightMode() const override;
    QString followFlightMode() const override;
    QString gotoFlightMode() const override { return guidedFlightMode(); }
    QString takeOffFlightMode() const override { return guidedFlightMode(); }
    QString stabilizedFlightMode() const override;
    QString autoDisarmParameter(Vehicle *vehicle) const override { Q_UNUSED(vehicle); return QStringLiteral("DISARM_DELAY"); }
    bool supportsSmartRTL() const override { return true; }

    void updateAvailableFlightModes(FlightModeList &modeList) override;

protected:
    uint32_t _convertToCustomFlightModeEnum(uint32_t val) const override;

private:
    const QString _stabilizeFlightMode = tr("自稳模式");
    const QString _acroFlightMode = tr("特技模式");
    const QString _altHoldFlightMode = tr("高度保持");
    const QString _autoFlightMode = tr("自动模式");
    const QString _guidedFlightMode = tr("引导模式");
    const QString _loiterFlightMode = tr("悬停模式");
    const QString _rtlFlightMode = tr("返航模式");
    const QString _circleFlightMode = tr("绕圈模式");
    const QString _landFlightMode = tr("着陆");
    const QString _driftFlightMode = tr("漂移模式");
    const QString _sportFlightMode = tr("运动模式");
    const QString _flipFlightMode = tr("折叠模式");
    const QString _autotuneFlightMode = tr("自动调谐模式");
    const QString _posHoldFlightMode = tr("定点模式");
    const QString _brakeFlightMode = tr("刹车锁定模式");
    const QString _throwFlightMode = tr("抛飞模式");
    const QString _avoidADSBFlightMode = tr("避开ADSB");
    const QString _guidedNoGPSFlightMode = tr("无GPS引导");
    const QString _smartRtlFlightMode = tr("智能返航");
    const QString _flowHoldFlightMode = tr("光流定高模式");
    const QString _followFlightMode = tr("跟随模式");
    const QString _zigzagFlightMode = tr("Z字形模式");
    const QString _systemIDFlightMode = tr("系统ID模式");
    const QString _autoRotateFlightMode = tr("自动旋转模式");
    const QString _autoRTLFlightMode = tr("自动返航模式");
    const QString _turtleFlightMode = tr("乌龟模式");

    static bool _remapParamNameIntialized;
    static FirmwarePlugin::remapParamNameMajorVersionMap_t _remapParamName;
};
