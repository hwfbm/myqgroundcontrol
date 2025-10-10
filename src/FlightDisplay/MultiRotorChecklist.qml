/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQml.Models

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.Vehicle

//多旋翼飞行器的检查清单定义
Item {
    property var model: listModel
    //检查清单的数据模型容器，是ObjectModel
    //每个Group都有：
   // passed属性：标记该组是否全部通过
    //enabled属性：该组是否可操作
    //_checked属性：该组是否展开显示
    //reset()方法：重置该组所有检查项
    //通过model属性暴露PreFlightCheckModel给Repeater
    PreFlightCheckModel
    {
        id:     listModel
        // 检查分组在这里定义
        //第一组：多旋翼初始检查
        PreFlightCheckGroup {
            name: qsTr("Multirotor Initial Checks")

             // 具体的检查项目
            //硬件检查：手动确认螺旋桨安装牢固
            PreFlightCheckButton {
                name:           qsTr("Hardware")
                manualText:     qsTr("Props mounted and secured?")
            }

            //电池检查：电量低于40%时失败，不允许覆盖
            PreFlightBatteryCheck {
                failurePercent:                 40
                allowFailurePercentOverride:    false
            }

            //传感器健康检查：自动检查所有传感器状态
            PreFlightSensorsHealthCheck {
            }

            //GPS检查：卫星数少于9颗时失败，但允许手动覆盖
            PreFlightGPSCheck {
                failureSatCount:        9
                allowOverrideSatCount:  true
            }

            //遥控器检查：检查遥控器连接和信号
            PreFlightRCCheck {
            }
        }

        //第二组：解锁后检查
        PreFlightCheckGroup {
            name: qsTr("Please arm the vehicle here")

            //电机测试：解锁后轻推油门测试电机工作正常
            PreFlightCheckButton {
                name:            qsTr("Motors")
                manualText:      qsTr("Propellers free? Then throttle up gently. Working properly?")
            }

            //任务确认：手动确认航点任务有效且无地形碰撞
            PreFlightCheckButton {
                name:           qsTr("Mission")
                manualText:     qsTr("Please confirm mission is valid (waypoints valid, no terrain collision).")
            }

            //声音检查：检查报警声音系统正常工作
            PreFlightSoundCheck {
            }
        }

        //第三组：起飞前最终准备

        PreFlightCheckGroup {
            name: qsTr("Last preparations before launch")

            //载荷检查：确认载荷设备配置完成且舱门关闭
            // Check list item group 2 - Final checks before launch
            PreFlightCheckButton {
                name:           qsTr("Payload")
                manualText:     qsTr("Configured and started? Payload lid closed?")
            }

            //气象条件：确认风速天气适合飞行
            PreFlightCheckButton {
                name:           qsTr("Wind & weather")
                manualText:     qsTr("OK for your platform?")
            }

            //飞行区域：确认起降区域和航线无障碍物和人员
            PreFlightCheckButton {
                name:           qsTr("Flight area")
                manualText:     qsTr("Launch area and path free of obstacles/people?")
            }
        }
    }
}

