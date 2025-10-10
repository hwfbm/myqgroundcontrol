/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

// 3D Viewer modules
import Viewer3D


//这段代码构成了 QGroundControl 飞行视图的核心界面

Item {
    id: _root

     property alias toolbarVisible: toolbar.visible//用于toolmenu绑定toolbar的visible

    // These should only be used by MainRootWindow
    property var planController:    _planController
    property var guidedController:  _guidedController

    // Properties of UTM adapter
    property bool utmspSendActTrigger: false

    //飞行视图的规划主控制器，在组件完成时自动启动
    PlanMasterController {
        id:                     _planController
        flyView:                true //设置 flyView 为 true 表示这是飞行视图
        Component.onCompleted:  start()
    }
    // Connections {
    //       target: mainWindow
    //       onSideBarVisibleChanged: (visible) => {
    //              // 当侧边栏显示时，隐藏 toolbar；反之亦然
    //              toolbar.visible = !visible
    //          }
    //   }
    property bool   _mainWindowIsMap:       mapControl.pipState.state === mapControl.pipState.fullState//判断主窗口是否显示地图
    property bool   _isFullWindowItemDark:  _mainWindowIsMap ? mapControl.isSatelliteMap : true
    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle//获取当前活动飞行器
    property var    _missionController:     _planController.missionController//各种控制器引用(_missionController, _geoFenceController 等)
    property var    _geoFenceController:    _planController.geoFenceController
    property var    _rallyPointController:  _planController.rallyPointController
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2///布局相关属性(_margins, _toolsMargin, _rightPanelWidth 等)
    property var    _guidedController:      guidedActionsController
    property var    _guidedValueSlider:     guidedValueSlider
    property var    _widgetLayer:           widgetLayer
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30
    property var    _mapControl:            mapControl

    //Z 轴顺序定义(_fullItemZorder, _pipItemZorder)
    property real   _fullItemZorder:    0
    property real   _pipItemZorder:     QGroundControl.zOrderWidgets


    //_calcCenterViewPort(): 计算中心视口区域
    function _calcCenterViewPort() {
        var newToolInset = Qt.rect(0, 0, width, height)
        toolstrip.adjustToolInset(newToolInset)
    }

    //dropMainStatusIndicatorTool(): 移除主状态指示器工具
    function dropMainStatusIndicatorTool() {
        toolbar.dropMainStatusIndicatorTool();
    }

    //管理工具边距，用于处理 PIP(画中画)视图的插入
    QGCToolInsets {
        id:                     _toolInsets
        leftEdgeBottomInset:    _pipView.leftEdgeBottomInset
        bottomEdgeLeftInset:    _pipView.bottomEdgeLeftInset
    }

    //顶部工具栏，视频全屏时隐藏




    //主地图和视频的容器
    Item {
        id:                 mapHolder
        anchors.top:       parent.top// toolbar.bottom
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right

        //主地图控件。关联规划控制器，处理 PIP 模式。3D 查看器打开时禁用
        FlyViewMap {
            id:                     mapControl
            planMasterController:   _planController
            rightPanelWidth:        ScreenTools.defaultFontPixelHeight //* 9
            pipView:                _pipView
            pipMode:                !_mainWindowIsMap
            toolInsets:             customOverlay.totalToolInsets
            mapName:                "FlightDisplayView"
            enabled:                !viewer3DWindow.isOpen
        }

        //视频显示控件，支持 PIP 模式
        FlyViewVideo {
            id:         videoControl
            pipView:    _pipView
        }

        //画中画视图管理器，可以在主地图和视频之间切换，计算并管理边距插入
        PipView {
            id:                     _pipView
            anchors.left:           parent.left
            anchors.bottom:         parent.bottom
            anchors.margins:        _toolsMargin
            item1IsFullSettingsKey: "MainFlyWindowIsMap"
            item1:                  mapControl
            item2:                  QGroundControl.videoManager.hasVideo ? videoControl : null
            show:                   QGroundControl.videoManager.hasVideo && !QGroundControl.videoManager.fullScreen &&
                                        (videoControl.pipState.state === videoControl.pipState.pipState || mapControl.pipState.state === mapControl.pipState.pipState)
            z:                      QGroundControl.zOrderWidgets

            property real leftEdgeBottomInset: visible ? width + anchors.margins : 0
            property real bottomEdgeLeftInset: visible ? height + anchors.margins : 0
        }
        // TelemetryValuesBar {
        //     //Layout.alignment:   Qt.AlignBottom
        //     anchors.left: _pipView.right
        //         anchors.bottom: _pipView.bottom
        //         anchors.leftMargin: 8 // 你可以调整这个边距
        //         extraWidth: instrumentPanel.extraValuesWidth
        //         z: _pipView.z + 1     // 保证在 pip 上层显示，如果需要的话
        //     //extraWidth:         instrumentPanel.extraValuesWidth
        // }


        //显示数值的条
        TelemetryValuesBar {
            id: telemetryBar
            anchors.bottom: _pipView.bottom
            anchors.leftMargin: 8
            extraWidth: instrumentPanel.extraValuesWidth
            z: _pipView.z + 1

            states: [
                State {
                    name: "WithPip"
                    when: _pipView.visible
                    AnchorChanges {
                        target: telemetryBar
                        anchors.left: _pipView.right
                    }
                },
                State {
                    //没有画中画窗
                    name: "WithoutPip"
                    when: !_pipView.visible
                    AnchorChanges {
                        target: telemetryBar
                        anchors.left: parent.left
                    }
                }
            ]
        }


        //小部件层，显示各种飞行信息，处理 UTM 适配器触发信号，管理 3D 查看器状态
        FlyViewWidgetLayer {
            id:                     widgetLayer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      _fullItemZorder + 2 // we need to add one extra layer for map 3d viewer (normally was 1)
            parentToolInsets:       _toolInsets
            mapControl:             _mapControl
            visible:                !QGroundControl.videoManager.fullScreen
            utmspActTrigger:        utmspSendActTrigger
            isViewer3DOpen:         viewer3DWindow.isOpen
        }

        //自定义覆盖层，显示额外的自定义信息
        FlyViewCustomLayer {
            id:                 customOverlay
            anchors.fill:       widgetLayer
            z:                  _fullItemZorder + 2
            parentToolInsets:   widgetLayer.totalToolInsets
            mapControl:         _mapControl
            visible:            !QGroundControl.videoManager.fullScreen
        }

        // Development tool for visualizing the insets for a paticular layer, show if needed
        //用于可视化边距插入的开发工具，默认隐藏.开发的时候参考布局
        FlyViewInsetViewer {
            id:                     widgetLayerInsetViewer
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            anchors.left:           parent.left
            anchors.right:          guidedValueSlider.visible ? guidedValueSlider.left : parent.right
            z:                      widgetLayer.z + 1
            insetsToView:           widgetLayer.totalToolInsets
            visible:               /*true//*/false
        }

        //引导操作控制器，管理任务控制器和值滑块
        GuidedActionsController {
            id:                 guidedActionsController
            missionController:  _missionController
            guidedValueSlider:     _guidedValueSlider
        }

        //-- Guided value slider (e.g. altitude)
        //引导值滑块(如高度调整)，位于右侧，最顶层显示,起飞高度右侧尺
        GuidedValueSlider {
            id:                 guidedValueSlider
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            z:                  QGroundControl.zOrderTopMost
            visible:           false
        }

        //3D 查看器窗口，占据整个视图区域
        Viewer3D{
            id:                     viewer3DWindow
            anchors.fill:           parent
        }
    }
    //property bool showToolbar: true
    FlyViewToolBar {
        id:         toolbar
        visible:  /*flyView.showToolbar //*/!QGroundControl.videoManager.fullScreen
        Component.onCompleted: {
              console.log("Toolbar 初始值:", visible)
          }
          onVisibleChanged: {
              console.log("Toolbar visible改变:", visible)
    }
          }
}
