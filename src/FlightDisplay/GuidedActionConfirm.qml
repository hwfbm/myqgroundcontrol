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

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.UTMSP

// //这段 QML 是 QGroundControl 中用于执行 确认操作（比如紧急停止或引导命令）时的滑动确认组件。它叫做一个 "滑动确认对话框"，
Rectangle {
    id:         _root
    width:      ScreenTools.defaultFontPixelWidth * 35
    height:     mainLayout.height + (_margins * 2)
    radius:     ScreenTools.defaultFontPixelWidth / 2
    color:      qgcPal.window
    visible:    _utmspEnabled === true ? utmspSliderTrigger: false

    property var    guidedController
    property var    guidedValueSlider
    property string title                                       // Currently unused
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth / 2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    // Properties of UTM adapter
    property bool   utmspSliderTrigger
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported

    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            slider.focus = true
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        guidedValueSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    QGCPalette { id: qgcPal }

    ColumnLayout {
        id:                 mainLayout
        anchors.centerIn:   parent
        width:              parent.width - (_margins * 2)
        spacing:            _margins

        QGCLabel {
            id:                     messageText
            Layout.fillWidth:       true
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            font.pointSize:         ScreenTools.defaultFontPointSize
            font.bold:              true
        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth

            SliderSwitch {
                id:                 slider
                confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
                Layout.fillWidth:   true
                enabled: _utmspEnabled === true? utmspSliderTrigger : true
                opacity: if(_utmspEnabled){utmspSliderTrigger === true ? 1 : 0.5} else{1}

                onAccept: {
                    _root.visible = false
                    var sliderOutputValue = 0
                    if (guidedValueSlider.visible) {
                        sliderOutputValue = guidedValueSlider.getOutputValue()
                        guidedValueSlider.visible = false
                    }
                    hideTrigger = false
                    guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                    if (mapIndicator) {
                        mapIndicator.actionConfirmed()
                        mapIndicator = undefined
                    }

                    UTMSPStateStorage.indicatorOnMissionStatus = true
                    UTMSPStateStorage.currentNotificationIndex = 7
                    UTMSPStateStorage.currentStateIndex = 3
                }
            }

            Rectangle {
                height: slider.height * 0.75
                width:  height
                radius: height / 2
                color:  qgcPal.primaryButton

                QGCColoredImage {
                    anchors.margins:    parent.height / 4
                    anchors.fill:       parent
                    source:             "/res/XDelete.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.text
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  confirmCancelled()
                }
            }
        }
    }
}

// Item {
//     id: root
//     visible: false

//     // 提供原有接口兼容性
//     function show() { root.visible = true }
//     function hide() { root.visible = false }

//     Rectangle {
//         id: circularButton
//         width: 100
//         height: 100
//         radius: width / 2
//         color: "#444"

//         // 填充圈
//         Canvas {
//             id: progressCircle
//             anchors.fill: parent
//             onPaint: {
//                 var ctx = getContext("2d")
//                 ctx.clearRect(0, 0, width, height)
//                 ctx.beginPath()
//                 ctx.arc(width/2, height/2, width/2 - 5, -Math.PI/2, -Math.PI/2 + progress * 2 * Math.PI)
//                 ctx.lineWidth = 10
//                 ctx.strokeStyle = "green"
//                 ctx.stroke()
//             }

//             property real progress: 0.0

//             Timer {
//                 id: holdTimer
//                 interval: 50
//                 running: false
//                 repeat: true
//                 onTriggered: {
//                     if (progressCircle.progress >= 1.0) {
//                         holdTimer.stop()
//                         root.hide()
//                         guidedActionsController.confirmAction()  // 或其他触发函数
//                     } else {
//                         progressCircle.progress += 0.05
//                         progressCircle.requestPaint()
//                     }
//                 }
//             }

//             MouseArea {
//                 anchors.fill: parent
//                 onPressed: {
//                     progressCircle.progress = 0
//                     progressCircle.requestPaint()
//                     holdTimer.start()
//                 }
//                 onReleased: {
//                     holdTimer.stop()
//                     progressCircle.progress = 0
//                     progressCircle.requestPaint()
//                 }
//             }
//         }
//     }
// }
