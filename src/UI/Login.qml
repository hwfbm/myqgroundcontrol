import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette

import QGroundControl.ScreenTools

Item {
    id: root
    anchors.fill: parent
    property var linkManager: QGroundControl.linkManager


    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias mqttserver:   mqttserverField.text
    property alias rtmpserver:   rtmpserverField.text

    // Rectangle {
    //     anchors.centerIn: parent
    //     width: parent.width * 0.4
    //     height: parent.height * 0.5
    //     radius: 12
    //     color: qgcPal.window

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScreenTools.defaultFontPixelHeight * 2
            spacing: ScreenTools.defaultFontPixelHeight

            QGCLabel {
                text: "用户登录"
                font.pointSize: ScreenTools.largeFontPointSize
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                color: qgcPal.text
            }

            QGCTextField {
                id: usernameField
                placeholderText: "用户名"
                Layout.fillWidth: true
            }

            QGCTextField {
                id: passwordField
                placeholderText: "密码"
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }

            Row{
                id:mqttrow
               Layout.fillWidth: true
               spacing:ScreenTools.defaultFontPointSize
            QGCTextField {
                id: mqttserverField
                width:(parent.width - ScreenTools.defaultFontPointSize) * 0.78  // 计算剩余空间减去间隔的 70%
                text: "47.112.2.160" // 直接写死地址
                readOnly: true //设置为只读
                enabled: false //让外观变灰，明确表示不可用
                //placeholderText: "MQTT服务器地址"
                Layout.fillWidth: true
            }
            QGCButton {
                text: "连接MQTT"
                //enabled: linkManager.loginManager.isLoggedIn() //取决于是否登录并返回token
                width:(parent.width - ScreenTools.defaultFontPointSize) * 0.22
                 onClicked: {
                   linkManager.mqttLink.connectToServer()//连接的槽
                }
              }
            }

            Row{
                id:rtmprow
               Layout.fillWidth: true
               spacing:ScreenTools.defaultFontPointSize
            QGCTextField {
                id: rtmpserverField
                width:(parent.width - ScreenTools.defaultFontPointSize) * 0.78  // 计算剩余空间减去间隔的 70%
                placeholderText: "RTMP服务器地址"
                Layout.fillWidth: true
            }
            QGCButton {
                text: "连接RTMP"
                width:(parent.width - ScreenTools.defaultFontPointSize) * 0.22
                // onClicked: {
                //     loginManager.login(usernameField.text,
                //                        passwordField.text,
                //                        mqttserverField.text,
                //                        rtmpserverField.text)
                // }
              }

            }
            QGCButton {
                text: "登录"
                Layout.fillWidth: true
                onClicked: {
                   linkManager.loginManager.login(usernameField.text,
                                       passwordField.text)
                }
             }

            Label {
                id: message
                Layout.fillWidth: true
                text: linkManager.loginManager.loggedIn
                      ? (linkManager.mqttLink.isConnected ? "MQTT 已连接，无需重复点击" : "已登录，可连接 MQTT")
                      : "未登录，图传、数传不可用！"
                color: linkManager.loginManager.loggedIn
                      ? (linkManager.mqttLink.isConnected ? "orange" : "green")
                      : "red"
            }
            // Label {
            //     id: statusLabel
            //     text: loginManager.statusMessage
            //     color: loginManager.loginSuccess ? "green" : "red"
            //     horizontalAlignment: Text.AlignHCenter
            //     Layout.fillWidth: true
            // }
        }
    //}
}
