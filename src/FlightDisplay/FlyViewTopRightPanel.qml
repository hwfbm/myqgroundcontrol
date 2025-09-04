/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools


//于右上角的多无人机控制面板（Multi-Vehicle Panel）。这个面板允许用户在有多个无人机连接时进行统一操作，例如“选择所有无人机”、“一键起飞”、“一键暂停任务”等功能
Rectangle {
    id:             topRightPanel
    width:          contentWidth
    height:         Math.max(contentHeight, minimumHeight)
    color:          Qt.rgba(0, 0, 0, 0.65)/*qgcPal.toolbarBackground*/
    radius:         ScreenTools.defaultFontPixelHeight / 2
    visible:        !QGroundControl.videoManager.fullScreen && _multipleVehicles && _settingEnableMVPanel
    clip:           true

    property bool  _settingEnableMVPanel:    QGroundControl.settingsManager.appSettings.enableMultiVehiclePanel.value
    property bool  _multipleVehicles:       QGroundControl.multiVehicleManager.vehicles.count > 1
    property var   vehicles:                QGroundControl.multiVehicleManager.vehicles
    property var   selectedVehicles:        QGroundControl.multiVehicleManager.selectedVehicles
    property real  contentWidth:            Math.max(
                                                multiVehicleList.implicitWidth,
                                                swipeViewContainer.implicitWidth
                                            ) + ScreenTools.defaultFontPixelHeight
    property real  contentHeight:           Math.min(
                                                maximumHeight,
                                                topRightPanelColumnLayout.implicitHeight + topRightPanelColumnLayout.spacing * ( topRightPanelColumnLayout.children.length - 1)
                                            )
    property real  minimumHeight:           selectedVehiclesLabel.height + swipeViewContainer.height
    property real  maximumHeight

    QGCPalette { id: qgcPal }

    ColumnLayout {
        id:                 topRightPanelColumnLayout
        anchors.fill:       parent
        anchors.margins:    ScreenTools.defaultFontPixelHeight / 2
        spacing:            ScreenTools.defaultFontPixelHeight / 2

        QGCLabel {
            id: selectedVehiclesLabel
            text: {
                let ids = Array.from({length: selectedVehicles.count}, (_, i) =>
                    selectedVehicles.get(i).id
                ).sort((a, b) => a - b)
                .join(", ")
                return qsTr("选择: ") + ids
            }
        }

        MultiVehicleList {
            id:                    multiVehicleList
            Layout.fillWidth:      true
            Layout.fillHeight:     true
            implicitHeight:        multiVehicleList.innerColumnHeight * vehicles.count - _margins * 3

            Rectangle {
                anchors.fill: parent
                visible:     true// topRightPanel.height === maximumHeight//当 topRightPanel 展开到最大高度时才显示这个背景效果

                Rectangle {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.top:        parent.top
                    anchors.margins:    0
                    height:             1
                    color:              QGroundControl.globalPalette.groupBorder
                }

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    // GradientStop { position: 0.00; color: "#A6C8FF" }    // 顶部淡蓝
                    // GradientStop { position: 0.05; color: "transparent" }
                    // GradientStop { position: 0.95; color: "transparent" }
                    // GradientStop { position: 1.00; color: "#A6C8FF" }    // 底部淡蓝

                    GradientStop { position: 0.00; color:topRightPanel.color }
                    GradientStop { position: 0.05; color: "transparent" }

                    GradientStop { position: 0.95; color: "transparent" }
                    GradientStop { position: 1.00; color:topRightPanel.color }
                }

                Rectangle {
                    anchors.left:       parent.left
                    anchors.right:      parent.right
                    anchors.bottom:     parent.bottom
                    anchors.margins:    0
                    height:             1
                    color:              QGroundControl.globalPalette.groupBorder
                }
            }

        }

        Rectangle {
            id:                     swipeViewContainer
            Layout.fillWidth:       true
            implicitHeight:         swipePages.implicitHeight
            implicitWidth:          swipePages.implicitWidth
            color:                  "transparent"

            QGCSwipeView {
                id:                swipePages
                anchors.fill:      parent
                spacing:           ScreenTools.defaultFontPixelHeight
                implicitHeight:    Math.max(buttonsPage.implicitHeight, photoVideoPage.implicitHeight)
                implicitWidth:     Math.max(buttonsPage.implicitWidth, photoVideoPage.implicitWidth)

                MvPanelPage {
                    id:                buttonsPage
                    implicitHeight:    buttonsColumnLayout.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                    implicitWidth:     buttonsColumnLayout.implicitWidth + ScreenTools.defaultFontPixelHeight * 2

                    ColumnLayout {
                        id:                     buttonsColumnLayout
                        anchors.right:          parent.right
                        anchors.left:           parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing:                ScreenTools.defaultFontPixelHeight / 2
                        implicitHeight:         Math.max(selectionRowLayout.height, actionRowLayout.height) + ScreenTools.defaultFontPixelHeight * 2
                        implicitWidth:          Math.max(selectionRowLayout.width, actionRowLayout.width) + ScreenTools.defaultFontPixelHeight * 4

                        QGCLabel {
                            text:               qsTr("多飞行器选择")
                            Layout.alignment:   Qt.AlignHCenter
                        }

                        RowLayout {
                            id:                 selectionRowLayout
                            Layout.alignment:   Qt.AlignHCenter

                            QGCButton {
                                text:                  qsTr("选择所有")
                                enabled:               multiVehicleList.selectedVehicles && multiVehicleList.selectedVehicles.count !== QGroundControl.multiVehicleManager.vehicles.count
                                onClicked:             multiVehicleList.selectAll()
                            }

                            QGCButton {
                                text:                  qsTr("放弃选择所有")
                                enabled:               multiVehicleList.selectedVehicles && multiVehicleList.selectedVehicles.count > 0
                                onClicked:             multiVehicleList.deselectAll()
                            }

                        }


                        QGCLabel {
                            text:              qsTr("Multi Vehicle Actions")
                            Layout.alignment:  Qt.AlignHCenter
                        }

                        RowLayout {
                            id:                actionRowLayout
                            Layout.alignment:  Qt.AlignHCenter

                            QGCButton {
                                text:                  qsTr("解锁")
                                enabled:               multiVehicleList.armAvailable()
                                onClicked:             _guidedController.confirmAction(_guidedController.actionMVArm)
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.75
                                leftPadding:           0
                                rightPadding:          0
                            }

                            QGCButton {
                                text:                  qsTr("上锁")
                                enabled:               multiVehicleList.disarmAvailable()
                                onClicked:             _guidedController.confirmAction(_guidedController.actionMVDisarm)
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.75
                                leftPadding:           0
                                rightPadding:          0
                            }

                            QGCButton {
                                text:                  qsTr("开始")
                                enabled:               multiVehicleList.startAvailable()
                                onClicked:             _guidedController.confirmAction(_guidedController.actionMVStartMission)
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.75
                                leftPadding:           0
                                rightPadding:          0
                            }

                            QGCButton {
                                text:                  qsTr("暂停")
                                enabled:               multiVehicleList.pauseAvailable()
                                onClicked:             _guidedController.confirmAction(_guidedController.actionMVPause)
                                Layout.preferredWidth: ScreenTools.defaultFontPixelHeight * 2.75
                                leftPadding:           0
                                rightPadding:          0
                            }
                        }
                    }
                } // Page 1

                MvPanelPage {

                    id:                  photoVideoPage
                    implicitHeight:      photoVideoControlLoader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                    implicitWidth:       photoVideoControlLoader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2

                    // We use a Loader to load the photoVideoControlComponent only when the active vehicle is not null
                    // This make it easier to implement PhotoVideoControl without having to check for the mavlink camera
                    // to be null all over the place

                    Loader {
                        id:                         photoVideoControlLoader
                        anchors.horizontalCenter:   parent.horizontalCenter
                        sourceComponent:            globals.activeVehicle ? photoVideoControlComponent : undefined

                        property real rightEdgeCenterInset: visible ? parent.width - x : 0

                        Component {
                            id: photoVideoControlComponent

                            PhotoVideoControl {
                            }
                        }
                    }
                } // Page 2
            } // QGCSwipeView

            //用于分页显示的控件，通常在滑动页面（比如 SwipeView）下方出现，用来显示当前是第几页、总共有多少页，类似于 App 引导页底部的小圆点导航
            QGCPageIndicator {
                id:                       pageIndicator
                count:                    swipePages.count// 总页数
                currentIndex:             swipePages.currentIndex
                anchors.bottom:           parent.bottom

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins:          ScreenTools.defaultFontPixelHeight / 4

                //控制小圆点样式
                delegate: Rectangle {
                    height:    ScreenTools.defaultFontPixelHeight  / 2
                    width:     height
                    radius:    width / 2
                    //如果当前小圆点是当前页：使用 activeColor（比如高亮的颜色）
                    //否则：使用 inactiveColor（比如半透明灰色）
                    color:     model.index === pageIndicator.currentIndex ? "#2196F3" : "#E0E0E0"//model.index === pageIndicator.currentIndex ? qgcPal.text : qgcPal.button
                    opacity:   model.index === pageIndicator.currentIndex ? 0.9 : 0.3
                     border.color: model.index === pageIndicator.currentIndex ? "#1976D2" : "transparent"
                }
            }
        }
    }
}

