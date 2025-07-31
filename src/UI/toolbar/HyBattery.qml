import QtQuick


Item {
    width: 400
    height: 300

    ListView {
        id: batteryListView
        width: parent.width
        height: parent.height
        model: hydrogenBatteryHandler.batteryInfoList

        delegate: Row {
            spacing: 10
            Text { text: modelData.label }
            Text { text: modelData.value + " " + modelData.unit }
        }
    }

    // ✅ 监听信号 batteryInfoListChanged
    Connections {
        target: hydrogenBatteryHandler
        function onBatteryInfoChanged() {
            console.log("电池数据更新")
            // ListView 会自动更新，但你也可以手动触发其它逻辑
        }
    }
}
