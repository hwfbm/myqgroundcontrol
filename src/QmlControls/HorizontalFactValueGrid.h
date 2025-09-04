/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "FactValueGrid.h"
//继承自 FactValueGrid，属于 QGroundControl 的 UI 组件之一，可以在qml中创建实例
//QML 中展示飞控数值的横向网格组件
class InstrumentValueData;
//FactValueGrid是它的父类，处理 Fact 的显示与布局
class HorizontalFactValueGrid : public FactValueGrid
{
    Q_OBJECT

public:
    HorizontalFactValueGrid(QQuickItem *parent = nullptr);
    HorizontalFactValueGrid(const QString& defaultSettingsGroup);

    Q_PROPERTY(QString telemetryBarDefaultSettingsGroup MEMBER telemetryBarDefaultSettingsGroup CONSTANT)//默认显示的配置组名
    Q_PROPERTY(QString telemetryBarUserSettingsGroup    MEMBER telemetryBarUserSettingsGroup    CONSTANT)//用户自定义配置组名

    static const QString telemetryBarDefaultSettingsGroup;
    static const QString telemetryBarUserSettingsGroup;

private:

 //这是 Qt 的宏，用来禁止拷贝构造函数和赋值运算符
 //目的是防止该类被误拷贝，避免对象状态混乱或资源冲突，尤其是继承了 QObject 的类通常不支持拷贝
    Q_DISABLE_COPY(HorizontalFactValueGrid)
};
//显式声明后，注册时编译器能更好地定位和生成代码，避免“隐式推断”带来的麻烦
// QML_DECLARE_TYPE 宏会在头文件中声明一些模板特化（比如 qmltype_traits 等），这让编译器在遇到该类型的 QML 注册和使用时，能正确识别这个类型。
// 这就像告诉编译器：“这个类型以后会用于 QML，需要生成相关的模板代码。”
// 避免编译时出现“未定义的模板特化”错误。
    //Qt 提供的一个宏，用来告诉编译器这个 C++ 类型是可以被 QML 识别和使用的
//这个宏只是声明，还不是真正完成注册。要在 QML 中使用，必须调用 qmlRegisterType<HorizontalFactValueGrid>(...) 进行注册
    // 使得这个类可以在 QML 中被 import 和使用，就像：
    //  HorizontalFactValueGrid {}
QML_DECLARE_TYPE(HorizontalFactValueGrid)
