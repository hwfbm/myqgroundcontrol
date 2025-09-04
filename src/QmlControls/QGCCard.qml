import QtQuick 2.15
import QtQuick.Controls 2.15
import QGroundControl.Palette 1.0

Rectangle {
    id: card
    property alias content: contentItem.data
    //radius: 8
    color:"transparent"
    //border.color: qgcPal.text
    //border.width: 1
    //anchors.margins: 8

    Column {
        id: contentItem
        anchors.fill: parent
        anchors.margins: 2
        spacing: 1
    }
}
