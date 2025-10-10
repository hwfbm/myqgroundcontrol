/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

/**
 * @file
 *   @brief QGC Video Receiver
 *   @author Gus Grubba <gus@auterion.com>
 */

#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QTimer>
#include <QtCore/QThread>
#include <QtCore/QWaitCondition>
#include <QtCore/QMutex>
#include <QtCore/QQueue>

#include "VideoReceiver.h"

#include <gst/gst.h>

Q_DECLARE_LOGGING_CATEGORY(VideoReceiverLog)

//视频流处理引擎
//基于 GStreamer 的视频接收器实现
// 拉流：从指定的 URI（如 rtsp://, udp://）获取视频流。
// 分发：使用 tee 元件将一路视频流分成多路。
// 处理：将分发的视频流送到不同的“分支”进行处理，主要包括：
// 解码显示：将视频解码并渲染到屏幕上的某个控件（如 QVideoWidget）。
// 录制存盘：将视频流保存为文件（如 MP4、MOV）。
// 截图：捕获单帧图像。
// 为了实现高效率和线程安全，它使用了一个工作线程 (Worker 类) 来处理所有 GStreamer 相关的操作，因为 GStreamer 的管道操作必须在同一个线程中完成



class Worker : public QThread
{
    Q_OBJECT

//确保所有对 GStreamer 管道（GstElement）的操作都在创建它的同一个线程（即 Worker 线程）中执行，否则会导致崩溃
public:
    bool needDispatch() {
        return QThread::currentThread() != this;
    }

    //主线程或其他线程想操作管道时，不直接调用，而是将一个“任务”（lambda 函数）放入队列
    void dispatch(std::function<void()> t) {
        QMutexLocker lock(&_taskQueueSync);
        _taskQueue.enqueue(t);
        _taskQueueUpdate.wakeOne();
    }

    //安全地通知工作线程退出
    void shutdown() {
        if (needDispatch()) {
            dispatch([this](){
                _shutdown = true;
            });
            QThread::wait();
        } else {
            QThread::terminate();
        }
    }

protected:
    //Worker 线程在自己的循环里不断从队列中取出任务并执行
    void run()
 {
        while(!_shutdown) {
            _taskQueueSync.lock();

            while (_taskQueue.isEmpty()) {
                _taskQueueUpdate.wait(&_taskQueueSync);
            }

            Task t = _taskQueue.dequeue();

            _taskQueueSync.unlock();

            t();
        }
    }

private:
    typedef std::function<void()> Task;
    QWaitCondition      _taskQueueUpdate;
    QMutex              _taskQueueSync;
    QQueue<Task>        _taskQueue;
    bool                _shutdown = false;
};

class GstVideoReceiver : public VideoReceiver
{
    Q_OBJECT

public:
    explicit GstVideoReceiver(QObject* parent = nullptr);
    ~GstVideoReceiver(void);

public slots:
    //开始拉流
    virtual void start(const QString& uri, unsigned timeout, int buffer = 0);


    virtual void stop(void);//停止拉流
    virtual void startDecoding(void* sink);
    virtual void stopDecoding(void);
    virtual void startRecording(const QString& videoFile, FILE_FORMAT format);//开始录制
    virtual void stopRecording(void);//停止录制
    //截图 (takeScreenshot)：原理是_addDecoder里在解码器后连接一个jpegenc+filesink，捕获一帧后立刻断开
    virtual void takeScreenshot(const QString& imageFile);


    void startStreaming(const QString &rtmpUrl);
    void stopStreaming();

protected slots:
    virtual void _watchdog(void);
    virtual void _handleEOS(void);

protected:


    virtual GstElement* _makeSource(const QString& uri);
    virtual GstElement* _makeDecoder(GstCaps* caps = nullptr, GstElement* videoSink = nullptr);
    virtual GstElement* _makeFileSink(const QString& videoFile, FILE_FORMAT format);
    virtual GstElement* _makeRtmpSink(const QString& rtmpUrl);

    virtual void _onNewSourcePad(GstPad* pad);
    virtual void _onNewDecoderPad(GstPad* pad);
    virtual bool _addDecoder(GstElement* src);
    virtual bool _addVideoSink(GstPad* pad);
    virtual void _noteTeeFrame(void);
    virtual void _noteVideoSinkFrame(void);
    virtual void _noteEndOfStream(void);
    virtual bool _unlinkBranch(GstElement* from);
    virtual void _shutdownDecodingBranch (void);
    virtual void _shutdownRecordingBranch(void);

    bool _needDispatch(void);
    void _dispatchSignal(std::function<void()> emitter);

    //监听GStreamer管道的消息总线，处理诸如错误（ERROR）、警告（WARNING）、流结束（EOS）等事件
    static gboolean _onBusMessage(GstBus* bus, GstMessage* message, gpointer user_data);


    static void _onNewPad(GstElement* element, GstPad* pad, gpointer data);
    static void _wrapWithGhostPad(GstElement* element, GstPad* pad, gpointer data);
    static void _linkPad(GstElement* element, GstPad* pad, gpointer data);
    static gboolean _padProbe(GstElement* element, GstPad* pad, gpointer user_data);
    static gboolean _filterParserCaps(GstElement* bin, GstPad* pad, GstElement* element, GstQuery* query, gpointer data);
    static GstPadProbeReturn _teeProbe(GstPad* pad, GstPadProbeInfo* info, gpointer user_data);
    static GstPadProbeReturn _videoSinkProbe(GstPad* pad, GstPadProbeInfo* info, gpointer user_data);//可能在视频渲染前做一些处理（如绘制OSD信息）
    static GstPadProbeReturn _eosProbe(GstPad* pad, GstPadProbeInfo* info, gpointer user_data);//用于录制时处理文件格式问题（如确保从关键帧开始录制）
    static GstPadProbeReturn _keyframeWatch(GstPad* pad, GstPadProbeInfo* info, gpointer user_data);//用于录制时处理文件格式问题（如确保从关键帧开始录制）

    //记录当前引擎的状态（是否在拉流、解码、录制）
    bool                _streaming;
    bool                _decoding;
    bool                _recording;
    bool                _removingDecoder;
    bool                _removingRecorder;

    bool _makeRtmpBranch(const QString &rtmpUrl);
    void _shutdownRtmpBranch();

    //GStreamer 元件指针，构成了整个处理流水线
    GstElement*         _source;//源元件只生产数据。如：从文件读取（filesrc）、从网络拉流（rtspsrc）、从摄像头采集（v4l2src）
    GstElement*         _tee;//最重要的元件之一。它像一个三通水管，将一路输入视频流复制成多路输出，分别送给“解码显示”和“录制存盘”分支
    //过滤元件（Filter）：处理数据。如：视频解码（decodebin）、视频编码（x264enc）、格式转换（videoconvert）、缩放（videoscale）
    GstElement*         _decoderValve;
    GstElement*         _recorderValve;
    GstElement*         _decoder;
    //输出元件。：只消费数据。如：播放到屏幕（autovideosink）、输出到扬声器（autoaudiosink）、写入文件（filesink）、推流到服务器（rtmpsink）
    GstElement*         _videoSink;
    GstElement*         _fileSink;
    GstElement*         _pipeline;

    qint64              _lastSourceFrameTime;
    qint64              _lastVideoFrameTime;
    bool                _resetVideoSink;
    gulong              _videoSinkProbeId = 0;

    gulong              _teeProbeId = 0;

    QTimer              _watchdogTimer;

    //-- RTSP UDP reconnect timeout
    uint64_t            _udpReconnect_us;

    QString             _uri;
    unsigned            _timeout;
    int                 _buffer;

    //所有 public slots（如 start, stop）被调用时，它们会通过 _dispatchSignal 方法将实际工作“派发”到 _slotHandler 线程中去执行
    Worker              _slotHandler;
    uint32_t            _signalDepth;

    bool                _endOfStream;

    static const char*  _kFileMux[FILE_FORMAT_MAX - FILE_FORMAT_MIN];


    // add to GstVideoReceiver class members
    GstElement*         _rtmpQueue = nullptr;
    GstElement*         _rtmpParser = nullptr; // h264parse
    GstElement*         _rtmpFlvMux = nullptr;
    GstElement*         _rtmpSink = nullptr;
    GstPad*             _rtmpTeePad = nullptr; // request pad from _tee
    bool                _streamingToRtmp = false;
    QString             _currentRtmpUrl;

};

void* createVideoSink(void* widget);

void initializeVideoReceiver(int argc, char* argv[], int debuglevel);
