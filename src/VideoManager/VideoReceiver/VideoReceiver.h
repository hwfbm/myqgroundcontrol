/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtCore/QSize>

class VideoReceiver : public QObject
{
    Q_OBJECT

public:
    explicit VideoReceiver(QObject *parent = nullptr)
        : QObject(parent)
    {}

    // QMediaFormat::FileFormat
    enum FILE_FORMAT {
        FILE_FORMAT_MIN = 0,
        FILE_FORMAT_MKV = FILE_FORMAT_MIN,
        FILE_FORMAT_MOV,
        FILE_FORMAT_MP4,
        FILE_FORMAT_MAX
    };
    Q_ENUM(FILE_FORMAT)

    enum STATUS {
        STATUS_OK = 0,
        STATUS_FAIL,
        STATUS_INVALID_STATE,
        STATUS_INVALID_URL,
        STATUS_NOT_IMPLEMENTED
    };
    Q_ENUM(STATUS)

signals:
    void timeout();
    void streamingChanged(bool active);//视频流开始/停止
    void decodingChanged(bool active);//解码开始/停止
    void recordingChanged(bool active);//录像开始/停止
    void recordingStarted(void);
    void videoSizeChanged(QSize size);//分辨率改变

    void onStartComplete(STATUS status);//操作完成回调
    void onStopComplete(STATUS status);
    void onStartDecodingComplete(STATUS status);
    void onStopDecodingComplete(STATUS status);
    void onStartRecordingComplete(STATUS status);
    void onStopRecordingComplete(STATUS status);
    void onTakeScreenshotComplete(STATUS status);

public slots:
    // buffer:
    //      -1 - disable buffer and video sync
    //      0 - default buffer length
    //      N - buffer length, ms
    virtual void start(const QString &uri, unsigned timeout, int buffer = 0) = 0;//拉流
    virtual void stop() = 0;
    virtual void startDecoding(void *sink) = 0;//解码显示（绑定到 QML 界面）
    virtual void stopDecoding() = 0;
    virtual void startRecording(const QString &videoFile, FILE_FORMAT format) = 0;//写入文件
    virtual void stopRecording() = 0;
    virtual void takeScreenshot(const QString &imageFile) = 0;
};
