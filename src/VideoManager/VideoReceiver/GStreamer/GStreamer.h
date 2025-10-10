/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>



//用于日志输出，方便调试 GStreamer 管道。
Q_DECLARE_LOGGING_CATEGORY(GStreamerLog)
Q_DECLARE_LOGGING_CATEGORY(GStreamerAPILog)

class VideoReceiver; //QGC 内部用来拉 RTSP/视频流的核心类
class QQuickItem; //绑定到 QML 的 UI 控件，用于显示视频

namespace GStreamer
{
enum VideoDecoderOptions {
    ForceVideoDecoderDefault = 0,
    ForceVideoDecoderSoftware,
    ForceVideoDecoderNVIDIA,
    ForceVideoDecoderVAAPI,
    ForceVideoDecoderDirectX3D,
    ForceVideoDecoderVideoToolbox,
};

void initialize();//初始化 GStreamer
void blacklist(VideoDecoderOptions option);//禁用某些硬件解码器
void *createVideoSink(QObject *parent, QQuickItem *widget);//创建视频显示控件
void releaseVideoSink(void *sink);//销毁控件
VideoReceiver *createVideoReceiver(QObject *parent = nullptr);//创建 RTSP 视频接收器
};
