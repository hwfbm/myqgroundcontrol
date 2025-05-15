/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QString>

#include "Fact.h"

Q_DECLARE_LOGGING_CATEGORY(SettingsFactLog)

/// A SettingsFact is Fact which holds a QSettings value.
//个继承自 Fact 的类，用于表示一个与 QSettings 相关的设置值
class SettingsFact : public Fact
{
    Q_OBJECT
    Q_PROPERTY(bool visible MEMBER _visible CONSTANT) //定义了一个属性 visible，表示该设置项是否可见

public:
    explicit SettingsFact(QObject *parent = nullptr);
    explicit SettingsFact(const QString &settingsGroup, FactMetaData *metaData, QObject *parent = nullptr);//带参数的构造函数，用于初始化设置组和元数据
    explicit SettingsFact(const SettingsFact &other, QObject *parent = nullptr);//拷贝构造函数，用于从另一个 SettingsFact 对象创建新对象
    ~SettingsFact();

    const SettingsFact &operator=(const SettingsFact &other);//提供了一个赋值运算符，用于从另一个 SettingsFact 对象赋值

    // Must be called before any references to fact
    void setVisible(bool visible) { _visible = visible; }//设置该设置项是否可见

private slots:
    void _rawValueChanged(const QVariant &value); //当设置值发生变化时调用的槽函数

private:
    QString _settingsGroup; //设置组的名称
    bool _visible = true;//表示该设置项是否可见，默认值为 true
};
