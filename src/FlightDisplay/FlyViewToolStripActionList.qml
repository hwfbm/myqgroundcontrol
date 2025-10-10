/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models

import QGroundControl
import QGroundControl.Controls

//工具条动作列表，专门用于飞行视图(FlyView)的工具条
//每个动作都继承自ToolStripAction

//3D视图切换动作
ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist // 显示预飞行检查清单的信号
 // 动作模型数组
    model: [
        ToolStripAction {
            property bool _is3DViewOpen:            viewer3DWindow.isOpen
            property bool   _viewer3DEnabled:       QGroundControl.settingsManager.viewer3DSettings.enabled.rawValue

            id: view3DIcon
            visible: _viewer3DEnabled// 根据设置决定是否显示
            text:       qsTr("3D View")
            iconSource:     "/qmlimages/Viewer3D/City3DMapIcon.svg"
            onTriggered:{
                if(_is3DViewOpen === false){
                    viewer3DWindow.open() // 打开3D视图
                }else{
                    viewer3DWindow.close()
                }
            }

            on_Is3DViewOpenChanged: {
                if(_is3DViewOpen === true){
                    view3DIcon.iconSource =     "/qmlimages/PaperPlane.svg"
                    text=           qsTr("Fly")// 3D视图打开时显示"Fly"
                }else{
                    iconSource =     "/qmlimages/Viewer3D/City3DMapIcon.svg"
                    text =           qsTr("3D View")
                }
            }
        },
        //预飞行检查清单动作
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() /*触发显示检查清单*/ },
        // 自主起飞动作,起飞、降落、返航等标准操作
        GuidedActionTakeoff { },
        // 自主降落动作
        GuidedActionLand { },
        // 返航动作 (Return To Launch)
        GuidedActionRTL { },
        // 暂停任务动作
        GuidedActionPause { },
        //附加动作按钮
        FlyViewAdditionalActionsButton { },
        // 抓取器控制动作
        GuidedActionGripper { }
    ]
}
