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
//qgcPal.mytoolbarBackground
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property color  _mainStatusBGColor: "red"
//qgcPal.brandingBlue
    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal }

    /// Bottom single pixel divider
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:         "yellow"
        visible:        qgcPal.globalTheme === QGCPalette.Light
    }

    Rectangle {
        anchors.fill: viewButtonRow

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;                                     color: _mainStatusBGColor }
            GradientStop { position: currentButton.x + currentButton.width; color: _mainStatusBGColor }
            GradientStop { position: 1;                                     color: _root.color }
        }
    }

    RowLayout {
        id:                     viewButtonRow
        width:                  parent.width * 0.5   // 占屏一半
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        spacing:                ScreenTools.defaultFontPixelWidth / 2




        MainStatusIndicator {
            id: mainStatusIndicator
            Layout.preferredHeight: viewButtonRow.height

        }
        Item{
            id:none
            width:mainStatusIndicator.width*0.6
        }

        // ToolButton {
        //     text: "静音"
        //     Layout.preferredHeight: viewButtonRow.height
        //      icon.source:            "/qmlimages/mute.svg"
        //     // onClicked: {
        //     //     criticalVehicleMessagePopup.close()
        //     //     muteCriticalPopup = true
        //     //     muteTimer.restart()
        //     // }
        //      onClicked:             confirmDialog.open()
        //      MessageDialog {
        //          id:             confirmDialog
        //          title:          qsTr("确认静音")
        //          text:           qsTr("确定要静吗？")
        //          buttons:        MessageDialog.Yes | MessageDialog.No
        //          //onAccepted:     _activeVehicle.closeVehicle()
        //      }
        // }


        // QGCButton {
        //     id:                 disconnectButton
        //     text:               qsTr("中断连接")
        //     iconSource:        "/qmlimages/Disconnect.svg"  // 内置警告图标
        //     primary:            true                      // 使用主按钮样式增强醒目度
        //     showBorder:         true                      // 强制显示边框
        //     //backgroundColor:    qgcPal.warningBackground  // 黄色警示背景
        //     pointSize:          ScreenTools.largeFontPointSize  // 加大字体

        //     // 动态属性：断连时显示红色边框，正常时恢复默认
        //     // QGCPalette {
        //     //     id:                 disconnectPalette
        //     //     buttonBorder:       _communicationLost ? qgcPal.colorRed : qgcPal.buttonBorder
        //     //     primaryButtonText:  _communicationLost ? qgcPal.colorRed : qgcPal.primaryButtonText
        //     // }
        //     //palette:            disconnectPalette  // 局部调色板覆盖

        //     // // 断连时添加闪烁动画
        //     // SequentialAnimation on opacity {
        //     //     running:        _communicationLost
        //     //     loops:         Animation.Infinite
        //     //     NumberAnimation { to: 0.6; duration: 800 }
        //     //     NumberAnimation { to: 1.0; duration: 800 }
        //     // }

        //     // 点击二次确认
        //     onClicked:          confirmDialog1.open()

        //     // 仅当飞行器存在且断连时显示
        //     visible:           true

        //     // 二次确认对话框
        //     MessageDialog {
        //         id:             confirmDialog1
        //         title:          qsTr("确认强制断开")
        //         text:           qsTr("飞行器通信已中断，确定要强制关闭链接吗？")
        //         buttons:        MessageDialog.Yes | MessageDialog.No
        //         onAccepted:     _activeVehicle.closeVehicle()
        //     }



        // }

        QGCButton {
            id:                 disconnectButton
            //text:               qsTr("Disconnect")
             text:               qsTr("中断连接")
            onClicked:          _activeVehicle.closeVehicle()
            visible:            _activeVehicle && _communicationLost
               //visible:            true
        }
    }





    QGCFlickable {
        id:                     toolsFlickable
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * ScreenTools.largeFontPointRatio * 1.5
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth / 2
        anchors.left:           viewButtonRow.right
        anchors.bottomMargin:   1
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        anchors.right:          currentButton.left
        contentWidth:           toolIndicators.width
        flickableDirection:     Flickable.HorizontalFlick

        FlyViewToolBarIndicators { id: toolIndicators }
    }


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
    Rectangle {
        anchors.bottom: parent.bottom
        height:         _root.height * 0.05
        width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
        color:          qgcPal.colorGreen
        visible:        !largeProgressBar.visible
    }

    //下载界面好像没有实际使用！
    // Large parameter download progress bar
    Rectangle {
        id:             largeProgressBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         parent.height
        color:          "blue"  //qgcPal.window
        visible:        _showLargeProgress

        property bool _initialDownloadComplete: _activeVehicle ? _activeVehicle.initialConnectComplete : true
        property bool _userHide:                false
        property bool _showLargeProgress:       !_initialDownloadComplete && !_userHide && qgcPal.globalTheme === QGCPalette.Light
        Component.onCompleted: {
            console.log("_showLargeProgress is", _showLargeProgress)
        }
        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) { largeProgressBar._userHide = false }
        }

        Rectangle {
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width:          _activeVehicle ? _activeVehicle.loadProgress * parent.width : 0
            color:          qgcPal.colorGreen
        }

        Label {
            anchors.centerIn:   parent
            text:               qsTr("Downloading")
            font.pointSize:     ScreenTools.largeFontPointSize
        }

        QGCLabel {
            anchors.margins:    _margin
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            text:               qsTr("Click anywhere to hide")

            property real _margin: ScreenTools.defaultFontPixelWidth / 2
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      largeProgressBar._userHide = true
        }
    }
}
