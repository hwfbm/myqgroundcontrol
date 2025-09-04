import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl.FactSystem
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools


//门用于处理 Fact 对象的显示和编辑
QGCTextField {
    id:                 control
    //text: 直接绑定到 Fact 的字符串值表示
    text:               fact ? fact.valueString : ""
    unitsLabel:         fact ? fact.units : ""//显示参数的单位（如 "m"、"km" 等）
    showUnits:          true//总是显示单位
    showHelp:           false//// 默认不显示帮助按钮
    numericValuesOnly:  fact && !fact.typeIsString// // 如果是数值类型参数，只允许输入数字

    signal updated()// 值更新时发出的信号

    property Fact fact: null // 核心数据源

    //编辑完成处理
    onEditingFinished: _onEditingFinished()
    
    function _onEditingFinished() {
        var errorString = fact.validate(text, false /* convertOnly */)
        if (errorString === "") {
            clearValidationError()   // // 成功时：清除错误显示
            fact.value = text// 更新 Fact 值
            control.updated()// 发出更新信号
        } else {
            //失败
            //显示具体的错误信息和当前有效值
            showValidationError(errorString, fact.valueString)
        }
    }

    //点击帮助按钮时创建参数详情对话框
    //helpDialogComponent：是一个预先定义好的 Component（组件）
    //.createObject(mainWindow)：调用组件的 createObject() 方法动态创建一个对象实例
    //mainWindow：指定新创建的对象父对象为主窗口，确保正确的内存管理和显示层级
    onHelpClicked: helpDialogComponent.createObject(mainWindow).open()

    //使用 Component 动态创建对话框实例
    Component {
        id: helpDialogComponent

        //传递当前 Fact 对象给对话框
        ParameterEditorDialog {
            title:          qsTr("Value Details")
            fact:           control.fact
        }
    }
}
