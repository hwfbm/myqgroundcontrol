import QtQuick

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls

//QGCTabBar 是 QGC 封装的 标签栏控件（类似 TabBar），可以放多个 QGCTabButton 来切换不同的页面
// 界面加载时，根据设置决定默认选中哪个 Tab。
// 用户点击某个 Tab 按钮 → currentIndex 会自动更新。
// QGC 其他地方可能会监听 currentIndex，切换到对应的页面内容
QGCTabBar {
    id: tabBar

    Component.onCompleted: currentIndex = QGroundControl.settingsManager.planViewSettings.displayPresetsTabFirst.rawValue ? 2 : 0

    //根据后端出传来的信息，有gps的图
    QGCTabButton { icon.source: "/qmlimages/PatternGrid.png"; icon.height: ScreenTools.defaultFontPixelHeight }//网格飞行模式
    QGCTabButton { icon.source: "/qmlimages/PatternCamera.png"; icon.height: ScreenTools.defaultFontPixelHeight }// 相机任务模式
    QGCTabButton { icon.source: "/qmlimages/PatternTerrain.png"; icon.height: ScreenTools.defaultFontPixelHeight }//地形任务模式
    QGCTabButton { icon.source: "/qmlimages/PatternPresets.png"; icon.height: ScreenTools.defaultFontPixelHeight }//任务预设
}
