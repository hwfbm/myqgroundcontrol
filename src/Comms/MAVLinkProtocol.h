/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QByteArray>
#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QString>

#include "LinkInterface.h"
#include "MAVLinkLib.h"

class QGCTemporaryFile;

Q_DECLARE_LOGGING_CATEGORY(MAVLinkProtocolLog)


//处理二进制数据与 MAVLink 消息的相互转换
//支持多链路并行通信（如串口、UDP、TCP）
//丢包率计算、消息计数
//日志记录：飞行数据记录与恢复

/// MAVLink micro air vehicle protocol reference implementation.
/// MAVLink is a generic communication protocol for micro air vehicles.
/// for more information, please see the official website: https://mavlink.io
class MAVLinkProtocol : public QObject
{
    Q_OBJECT

public:
    /// Constructs an MAVLinkProtocol object.
    ///     @param parent The parent QObject.
    explicit MAVLinkProtocol(QObject *parent = nullptr);

    /// Destructor for the MAVLinkProtocol class.
    ~MAVLinkProtocol();

    /// Gets the singleton instance of MAVLinkProtocol.
    ///     @return The singleton instance.
    static MAVLinkProtocol *instance();//单例模式保证全局唯一实例，统一管理 MAVLink 通信状态（全局只会有一个实例），通过 MAVLinkProtocol::instance() 获取它
//通过 instance() 获取全局访问点

    void init();//初始化方法，应该在程序启动时调用

    //获取协议名称（"MAVLink protocol"）、系统ID、组件ID、协议版本等
    /// Get the human-friendly name of this protocol
    static QString getName() { return QStringLiteral("MAVLink protocol"); }

    /// Get the system id of this application
    int getSystemId() const;

    /// Get the component id of this application
    static int getComponentId() { return MAV_COMP_ID_MISSIONPLANNER; }

    /// Get the protocol version
    static int getVersion() { return MAVLINK_VERSION; }

    /// Get the currently configured protocol version
    unsigned getCurrentVersion() const { return _currentVersion; }


    //管理跟每个“连接”相关的元数据（比如串口、UDP 通信）
    /// Reset the counters for all metadata for this link.
    void resetMetadataForLink(LinkInterface *link);

    /// Suspend/Restart logging during replay.
    void suspendLogForReplay(bool suspend) { _logSuspendReplay = suspend; }

    /// Set protocol version
    void setVersion(unsigned version);//版本协商机制（通过 _updateVersion 实现）

    /// Checks the temp directory for log files which may have been left there.
    /// This could happen if QGC crashes without the temp log file being saved.
    /// Give the user an option to save these orphaned files.
    //日志相关处理：暂停日志记录、检测丢失日志等
    void checkForLostLogFiles();//崩溃恢复机制（checkForLostLogFiles）


    //当心跳包或消息收到时发出信号，其他组件可以监听这些信号
signals:
    /// Heartbeat received on link
    void vehicleHeartbeatInfo(LinkInterface *link, int vehicleId, int componentId, int vehicleFirmwareType, int vehicleType);

    /// Message received and directly copied via signal
    void messageReceived(LinkInterface *link, const mavlink_message_t &message);

    void mavlinkMessageStatus(int sysid, uint64_t totalSent, uint64_t totalReceived, uint64_t totalLoss, float lossPercent);

public slots:


 /// Receive bytes from a communication interface and constructs a MAVLink packet
    ///     @param link The interface to read from


 //核心函数：从 link 接口读取字节流数据，并解析为 MAVLink 消息
 //每个 LinkInterface 维护独立的状态机
 //使用 mavlink_channel_t 区分不同链路
    void receiveBytes(LinkInterface *link, const QByteArray &data);

    /// Log bytes sent from a communication interface and logs a MAVLink packet.
    /// It can handle multiple links in parallel, as each link has it's own buffer/parsing state machine.
    ///     @param link The interface to read from
    //用于记录发送出去的数据
    void logSentBytes(const LinkInterface *link, const QByteArray &data);

    /// Deletes any log files which are in the temp directory
    //删除临时日志文件
    static void deleteTempLogFiles();


    //私有槽 / 私有函数
    //这些函数通常用于：
    // 日志写入
    // 消息转发
    // 统计数据更新
    // 通信状态检测
    // 保存日志等
private slots:
    void _vehicleCountChanged();

private:
    void _logData(LinkInterface *link, const mavlink_message_t &message);
    bool _closeLogFile();
    void _startLogging();
    void _stopLogging();

    void _forward(const mavlink_message_t &message);
    void _forwardSupport(const mavlink_message_t &message);

    void _updateCounters(uint8_t mavlinkChannel, const mavlink_message_t &message);
    bool _updateStatus(LinkInterface *link, const SharedLinkInterfacePtr linkPtr, uint8_t mavlinkChannel, const mavlink_message_t &message);
    void _updateVersion(LinkInterface *link, uint8_t mavlinkChannel);

    void _saveTelemetryLog(const QString &tempLogfile);
    bool _checkTelemetrySavePath();

    QGCTemporaryFile * const _tempLogFile = nullptr;//临时文件记录原始 MAVLink 数据，临时日志文件对象（使用 QTemporaryFile 机制）

    bool _logSuspendError = false;  ///< true: Logging suspended due to error
    bool _logSuspendReplay = false; ///< true: Logging suspended due to replay
    bool _vehicleWasArmed = false;  ///< true: Vehicle was armed during log sequence

    uint8_t _lastIndex[256][256]{};   //存储每个系统和组件收到的最后一个消息序号（用于丢包检测）                         ///< Store the last received sequence ID for each system/component pair
    uint8_t _firstMessage[256][256]{};

    //总接收/丢失计数器，基于 MAVLink 消息的 seq 字段计算丢包
    //公式：丢包率 = (期望序号 - 实际序号 - 1) / 总接收数    ///< First message flag
    uint64_t _totalReceiveCounter[MAVLINK_COMM_NUM_BUFFERS]{}; //各通道总接收消息数（MAVLINK_COMM_NUM_BUFFERS=16） ///< The total number of successfully received messages
    uint64_t _totalLossCounter[MAVLINK_COMM_NUM_BUFFERS]{};     ///< Total messages lost during transmission.
    float _runningLossPercent[MAVLINK_COMM_NUM_BUFFERS]{};  //动态计算的丢包率  ///< Loss rate

    unsigned _currentVersion = 100;//支持动态切换 MAVLink 1.0/2.0
    bool _initialized = false;

    static constexpr const char *_tempLogFileTemplate = "FlightDataXXXXXX"; ///< Template for temporary log file
    static constexpr const char *_logFileExtension = "mavlink";             ///< Extension for log files

    static constexpr uint8_t kMaxCompId = MAV_COMPONENT_ENUM_END - 1;//kMaxCompId 是最大组件ID（MAVLink 定义）
};
