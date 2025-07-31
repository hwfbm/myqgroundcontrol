import QtQuick
import QtQuick.Controls

import QGroundControl.Palette
import QGroundControl.ScreenTools

/// QGC version of Flickable control that shows horizontal/vertial scroll indicators
//自定义的 Flickable 控件实现，主要用于在触摸屏和桌面环境下提供流畅的滚动体验，并带有自定义的滚动指示器
Flickable {
    id:                     root
    boundsBehavior:         Flickable.StopAtBounds //控制滚动到边界时的行为，设置为在边界处停止而不是反弹或拖动越界
    clip:                   true //启用裁剪，确保内容不会超出控件边界显示
    maximumFlickVelocity:   (ScreenTools.realPixelDensity * 25.4) * 8   // About two inches per second
    // maximumFlickVelocity
    // 计算方式：(ScreenTools.realPixelDensity * 25.4) * 8
    // 这是基于物理尺寸的滚动速度控制：
    // ScreenTools.realPixelDensity 获取每毫米的像素数
    // * 25.4 转换为每英寸像素数
    // * 8 表示大约每秒2英寸的滚动速度
    // 这种计算方式确保了在不同DPI设备上有一致的物理滚动体验

    property color indicatorColor: qgcPal.text //自定义属性，允许外部设置滚动指示器颜色


    //滚动指示器动态创建
    Component.onCompleted: {
        //创建两个实例：水平和垂直方向各一个
        var indicatorComponent = Qt.createComponent("QGCFlickableScrollIndicator.qml") //从工具箱拿出"滚动条零件包"
        indicatorComponent.createObject(root, { orientation: QGCFlickableScrollIndicator.Horizontal })//组装一个横向滚动条，通过 createObject 的第二个参数设置 orientation 属性，设为横向模式
        indicatorComponent = Qt.createComponent("QGCFlickableScrollIndicator.qml")
        indicatorComponent.createObject(root, { orientation: QGCFlickableScrollIndicator.Vertical })//再组装一个竖向滚动条（重用同一个零件包）
    }
}
