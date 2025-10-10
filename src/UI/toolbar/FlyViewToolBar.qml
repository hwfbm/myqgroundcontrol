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
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Controllers

Rectangle {
    id:     _root
    width:  parent.width
    height: ScreenTools.toolbarHeight
    //color:  qgcPal.mytoolbarBackground
    color: "transparent"

     property bool  toolbarvisible: true
    visible:toolbarvisible//外部传入

//qgcPal.mytoolbarBackground
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: "red"
//qgcPal.brandingBlue
    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider底部单像素分隔器
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:         "blue"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }

    //任务栏背景色
    Rectangle {
        anchors.fill: parent//viewButtonRow

        // gradient: Gradient {
        //     orientation: Gradient.Horizontal
        //     GradientStop { position: 0;                                     color: _mainStatusBGColor }
        //     GradientStop { position: currentButton.x + currentButton.width; color: _mainStatusBGColor }
        //     GradientStop { position: 1;                                     color: _root.color }
        // }
        color: Qt.rgba(0, 0, 0, 0.65)   // 黑色 + 60% 不透明度（即透明度为 0.6）

    }

    // RowLayout {
    //     id:                     viewButtonRow
    //     width:                  parent.width// * 0.5   // 占屏一半
    //     anchors.bottomMargin:   1
    //     anchors.top:            parent.top
    //     anchors.bottom:         parent.bottom
    //     spacing:                ScreenTools.defaultFontPixelWidth  // / 2

    //     Image {
    //         id: hlogo
    //         source: "/qmlimages/hlogo.png"    //logo 路径
    //         fillMode: Image.PreserveAspectFit
    //         Layout.preferredHeight: viewButtonRow.height //* 0.8
    //         Layout.preferredWidth:  hlogo.paintedWidth    // 保持原始比例
    //          Layout.alignment: Qt.AlignVCenter      // 可选：垂直居中
    //     }


    //     MainStatusIndicator {
    //         id: mainStatusIndicator
    //         Layout.preferredHeight: viewButtonRow.height

    //     }
    //     Item{
    //         id:none

    //         width:parent.width*0.5
    //     }

    //     // ToolButton {
    //     //     text: "静音"
    //     //     Layout.preferredHeight: viewButtonRow.height
    //     //      icon.source:            "/qmlimages/mute.svg"
    //     //     // onClicked: {
    //     //     //     criticalVehicleMessagePopup.close()
    //     //     //     muteCriticalPopup = true
    //     //     //     muteTimer.restart()
    //     //     // }
    //     //      onClicked:             confirmDialog.open()
    //     //      MessageDialog {
    //     //          id:             confirmDialog
    //     //          title:          qsTr("确认静音")
    //     //          text:           qsTr("确定要静吗？")
    //     //          buttons:        MessageDialog.Yes | MessageDialog.No
    //     //          //onAccepted:     _activeVehicle.closeVehicle()
    //     //      }
    //     // }


    //     // QGCButton {
    //     //     id:                 disconnectButton
    //     //     text:               qsTr("中断连接")
    //     //     iconSource:        "/qmlimages/Disconnect.svg"  // 内置警告图标
    //     //     primary:            true                      // 使用主按钮样式增强醒目度
    //     //     showBorder:         true                      // 强制显示边框
    //     //     //backgroundColor:    qgcPal.warningBackground  // 黄色警示背景
    //     //     pointSize:          ScreenTools.largeFontPointSize  // 加大字体

    //     //     // 动态属性：断连时显示红色边框，正常时恢复默认
    //     //     // QGCPalette {
    //     //     //     id:                 disconnectPalette
    //     //     //     buttonBorder:       _communicationLost ? qgcPal.colorRed : qgcPal.buttonBorder
    //     //     //     primaryButtonText:  _communicationLost ? qgcPal.colorRed : qgcPal.primaryButtonText
    //     //     // }
    //     //     //palette:            disconnectPalette  // 局部调色板覆盖

    //     //     // // 断连时添加闪烁动画
    //     //     // SequentialAnimation on opacity {
    //     //     //     running:        _communicationLost
    //     //     //     loops:         Animation.Infinite
    //     //     //     NumberAnimation { to: 0.6; duration: 800 }
    //     //     //     NumberAnimation { to: 1.0; duration: 800 }
    //     //     // }

    //     //     // 点击二次确认
    //     //     onClicked:          confirmDialog1.open()

    //     //     // 仅当飞行器存在且断连时显示
    //     //     visible:           true

    //     //     // 二次确认对话框
    //     //     MessageDialog {
    //     //         id:             confirmDialog1
    //     //         title:          qsTr("确认强制断开")
    //     //         text:           qsTr("飞行器通信已中断，确定要强制关闭链接吗？")
    //     //         buttons:        MessageDialog.Yes | MessageDialog.No
    //     //         onAccepted:     _activeVehicle.closeVehicle()
    //     //     }



    //     // }

    //     QGCButton {
    //         id:                 disconnectButton
    //         //text:               qsTr("Disconnect")
    //          text:               qsTr("中断连接")
    //         onClicked:          _activeVehicle.closeVehicle()
    //         visible:            _activeVehicle && _communicationLost
    //            //visible:            true
    //     }


    //     // QGCFlickable {
    //     //     id:                     toolsFlickable
    //     //     anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
    //     //     anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 2
    //     //     anchors.left:           viewButtonRow.right
    //     //     anchors.bottomMargin:   1
    //     //     anchors.top:            parent.top
    //     //     anchors.bottom:         parent.bottom
    //     //     anchors.right:          currentButton.left
    //     //     contentWidth:           toolIndicators.width
    //     //     flickableDirection:     Flickable.HorizontalFlick

    //     //     FlyViewToolBarIndicators { id: toolIndicators }
    //     // }

    //     // 中间滑动区域（原本 QGCFlickable）
    //     QGCFlickable {
    //         id: toolsFlickable
    //         Layout.fillHeight: true
    //         Layout.fillWidth: true // 可改成 Layout.preferredWidth: xxx，具体看需求
    //         contentWidth: toolIndicators.width
    //         flickableDirection: Flickable.HorizontalFlick

    //         FlyViewToolBarIndicators {
    //             id: toolIndicators
    //         }
    //     }

    // }

    // Row {
    //     id: viewButtonRow
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     anchors.top: parent.top
    //     anchors.bottom: parent.bottom
    //     spacing: ScreenTools.defaultFontPixelWidth

        Image {
            id: hlogo
            source: "/qmlimages/hitlogo.png"
            fillMode: Image.PreserveAspectFit
             anchors.left: parent.left
             anchors.top: parent.top
             anchors.bottom: parent.bottom
            height: parent.height*0.9
            width: height*2
        }
        Rectangle {
            id: divider
            width: 1

            anchors.topMargin:      3
            anchors.bottomMargin:   3
            anchors.leftMargin:     6
           // anchors.rightMargin:
            anchors.left:           hlogo.right
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            //height:parent.height+1000 //超过滑条高度
            color: "#888888"
        }

        MainStatusIndicator {
            id: mainStatusIndicator
             anchors.leftMargin:     4
            anchors.left: divider.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            height: parent.height
            width:parent.width*0.2
        }

        // Item {
        //     id: none
        //     anchors.left: mainStatusIndicator.right
        //     anchors.top: parent.top
        //     anchors.bottom: parent.bottom
        //     width: parent.width * 0.1
        //     height: parent.height
        // }


        QGCButton {
            id: disconnectButton
            text: qsTr("中断连接")
             anchors.left: mainStatusIndicator.right
            // anchors.top: parent.top
            // anchors.bottom: parent.bottom
              anchors.leftMargin:     4
            onClicked: _activeVehicle.closeVehicle()
            visible: _activeVehicle && _communicationLost
            height: parent.height
        }





        QGCFlickable {
            id: toolsFlickable
            height: parent.height
            width: Math.min(toolIndicators.width, parent.width * 0.6)
            //width: parent.width * 0.4
            anchors.right: batteryRow.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth
            contentWidth: toolIndicators.width
            flickableDirection: Flickable.HorizontalFlick

            FlyViewToolBarIndicators {
                id: toolIndicators
            }
        }


        Row {
            id: batteryRow
            spacing:  ScreenTools.defaultFontPixelWidth*0.5
            anchors.right: divider2.left
            anchors.verticalCenter: parent.verticalCenter   // 垂直居中
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth*2

                visible: Qt.platform.os === "android"   // 🚀 只在 Android 下显示
            QGCColoredImage {
                id: batteryIcon
                source: "/qmlimages/remote_battery.svg"
                height: parent.height
                width: height

                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                color: androidBattery.batteryLow ? "red" : "white"
            }

            Label {
                id: batteryLabel
                text: androidBattery.batteryLevel + "%"
                color: androidBattery.batteryLow ? "red" : "white"
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.8
                verticalAlignment: Label.AlignVCenter
            }

            Connections {
                target: androidBattery
                onBatteryLevelChanged: {
                    // QML 会自动刷新 text
                    batteryLabel.text = androidBattery.batteryLevel + "%"
                }
            }
        }

   // }






    //-------------------------------------------------------------------------
    //-- Branding Logo
    // Image {
    //     id:logo
    //     anchors.right:          currentButton.left
    //     anchors.top:            parent.top
    //     anchors.bottom:         parent.bottom
    //     anchors.margins:        ScreenTools.defaultFontPixelHeight * 0.66
    //     visible:                _activeVehicle && !_communicationLost && x > (toolsFlickable.x + toolsFlickable.contentWidth + ScreenTools.defaultFontPixelWidth)
    //     fillMode:               Image.PreserveAspectFit
    //     source:                 _outdoorPalette ? _brandImageOutdoor : _brandImageIndoor
    //     mipmap:                 true

    //     property bool   _outdoorPalette:        qgcPal.globalTheme === QGCPalette.Light
    //     property bool   _corePluginBranding:    QGroundControl.corePlugin.brandImageIndoor.length != 0
    //     property string _userBrandImageIndoor:  QGroundControl.settingsManager.brandImageSettings.userBrandImageIndoor.value
    //     property string _userBrandImageOutdoor: QGroundControl.settingsManager.brandImageSettings.userBrandImageOutdoor.value
    //     property bool   _userBrandingIndoor:    QGroundControl.settingsManager.brandImageSettings.visible && _userBrandImageIndoor.length != 0
    //     property bool   _userBrandingOutdoor:   QGroundControl.settingsManager.brandImageSettings.visible && _userBrandImageOutdoor.length != 0
    //     property string _brandImageIndoor:      brandImageIndoor()
    //     property string _brandImageOutdoor:     brandImageOutdoor()

    //     function brandImageIndoor() {
    //         if (_userBrandingIndoor) {
    //             return _userBrandImageIndoor
    //         } else {
    //             if (_userBrandingOutdoor) {
    //                 return _userBrandImageOutdoor
    //             } else {
    //                 if (_corePluginBranding) {
    //                     return QGroundControl.corePlugin.brandImageIndoor
    //                 } else {
    //                     return _activeVehicle ? _activeVehicle.brandImageIndoor : ""
    //                 }
    //             }
    //         }
    //     }

    //     function brandImageOutdoor() {
    //         if (_userBrandingOutdoor) {
    //             return _userBrandImageOutdoor
    //         } else {
    //             if (_userBrandingIndoor) {
    //                 return _userBrandImageIndoor
    //             } else {
    //                 if (_corePluginBranding) {
    //                     return QGroundControl.corePlugin.brandImageOutdoor
    //                 } else {
    //                     return _activeVehicle ? _activeVehicle.brandImageOutdoor : ""
    //                 }
    //             }
    //         }
    //     }
    // }

        Rectangle {
            id: divider2
            width: 1

            anchors.topMargin:      3
            anchors.bottomMargin:   3
            anchors.rightMargin:     4
            anchors.right:           currentButton.left
            anchors.top:            parent.top
            anchors.bottom:         parent.bottom
            //height:parent.height+1000 //超过滑条高度
            color: "#888888"
        }

    QGCToolBarButton {
        id:                     currentButton

        //anchors.left:           toolsFlickable.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:         parent.right
        icon.source:           "/qmlimages/common.svg"
        //"/res/QGCLogoFull.svg"
        logo:                   true
        onClicked:              mainWindow.showToolSelectDialog()
    }


    // Small parameter download progress bar
    //下方的进度条(细)
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:        Qt.rgba(255, 255, 255, 0.6) //qgcPal.colorGreen
        visible:     true/* !largeProgressBar.visible*/
    }


    // 表示当前活跃飞机是否完成了初始连接（参数等下载完成）。
    // 第一次连接飞控、还没完成参数下载，并且使用的是浅色主题，且用户没手动隐藏进度条时会显示
    // 来自 _activeVehicle.initialConnectComplete 属性（C++ 层 Vehicle 对象）。
    // 如果还没下载完参数（首次连接），则为 false。
    // Large parameter download progress bar


    // Rectangle {
    //     id:             largeProgressBar
    //     anchors.bottom: parent.bottom
    //     anchors.left:   parent.left
    //     anchors.right:  parent.right
    //     height:         parent.height
    //     color:          "blue"  //qgcPal.window
    //     visible:       _showLargeProgress//仅在使用 浅色主题时显示（QGC 默认是浅色主题，但你也可以在设置中切换到深色）

    //     property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
    //     property bool _userHide:                false//用户点击该区域后会设置为 true，一旦用户手动点击隐藏，就不会再自动显示
    //     property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light
    //     Component.onCompleted: {
    //         console.log("_showLargeProgress is", _showLargeProgress)
    //     }
    //     Connections {
    //         target:                 QGroundControl.multiVehicleManager
    //         function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
    //     }

    //     Rectangle {
    //         anchors.top:    parent.top
    //         anchors.bottom: parent.bottom
    //         width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
    //         color:          qgcPal.colorGreen
    //     }

    //     Label {
    //         anchors.centerIn:   parent
    //         text:               qsTr("Downloading")
    //         font.pointSize:     ScreenTools.largeFontPointSize
    //     }

    //     QGCLabel {
    //         anchors.margins:    _margin
    //         anchors.right:      parent.right
    //         anchors.bottom:     parent.bottom
    //         text:               qsTr("Click anywhere to hide")

    //         property real _margin: ScreenTools.defaultFontPixelWidth / 2
    //     }

    //     MouseArea {
    //         anchors.fill:   parent
    //         onClicked:      largeProgressBar._userHide = true
    //     }
    // }
}

