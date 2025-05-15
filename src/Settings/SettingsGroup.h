/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

//SettingsGroup 是一个继承自 QObject 的类，提供了一个统一的接口来访问和管理设置项
#include "SettingsFact.h"

//定义两个静态成员变量 name 和 settingsGroup，分别用于存储设置组的名称和 QSettings 的组名
#define DEFINE_SETTING_NAME_GROUP() \
    static const char* name; \
    static const char* settingsGroup;

//定义一个设置组类 NAME ## Settings，并初始化 name 和 settingsGroup
//NAME ## Settings：生成的类名，#NAME：将 NAME 转换为字符串，GROUP：设置组的 QSettings 组名
#define DECLARE_SETTINGGROUP(NAME, GROUP) \
    const char* NAME ## Settings::name = #NAME; \
    const char* NAME ## Settings::settingsGroup = GROUP; \
    NAME ## Settings::NAME ## Settings(QObject* parent) \
        : SettingsGroup(name, settingsGroup, parent)

//定义一个设置项 NAME，并提供一个方法来获取该设置项的 Fact 对象
//CLASS::NAME ## Name：生成的静态成员变量名
//_ ## NAME ## Fact：生成的私有成员变量名，用于存储 Fact 对象
#define DECLARE_SETTINGSFACT(CLASS, NAME) \
    const char* CLASS::NAME ## Name = #NAME; \
    Fact* CLASS::NAME() \
    { \
        if (!_ ## NAME ## Fact) { \
            _ ## NAME ## Fact = _createSettingsFact(NAME ## Name); \
        } \
        return _ ## NAME ## Fact; \
    }

//定义一个设置项 NAME，但不提供实现方法。这通常用于在子类中实现具体逻辑
#define DECLARE_SETTINGSFACT_NO_FUNC(CLASS, NAME) \
    const char* CLASS::NAME ## Name = #NAME; \
    Fact* CLASS::NAME()


//：定义一个设置项 NAME，并提供一个 Q_PROPERTY 属性和一个方法来获取该设置项的 Fact 对象
//_ ## NAME ## Fact：生成的私有成员变量名，用于存储 Fact 对象
//Q_PROPERTY：定义一个属性，使得该设置项可以在 QML 中使用
#define DEFINE_SETTINGFACT(NAME) \
    private: \
    SettingsFact* _ ## NAME ## Fact = nullptr; \
    public: \
    Q_PROPERTY(Fact* NAME READ NAME CONSTANT) \
    Fact* NAME(); \
    static const char* NAME ## Name;

/// Provides access to group of settings. The group is named and has a visible property associated with which can control whether the group
/// is shows in the ui.
class SettingsGroup : public QObject
{
    Q_OBJECT

public:
    /// @param name Name for this Settings group
    /// @param settingsGroup Group to place settings in for QSettings::setGroup
 //初始化设置组的名称和 QSettings 组名
 SettingsGroup(const QString &name, const QString &settingsGroup, QObject* parent = nullptr);

    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)

    //提供 visible 属性的 getter 和 setter 方法，并在设置值变化时发出信号
    virtual bool    visible             () { return _visible; }
    virtual void    setVisible          (bool vis) { _visible = vis; emit visibleChanged(); }

signals:
    void            visibleChanged      ();

protected:
    SettingsFact*   _createSettingsFact(const QString& factName); //创建一个新的 SettingsFact 对象，factName：设置项的名称
    bool            _visible;//定义一个属性 visible，表示该设置组是否可见
    QString         _name;//设置组的名称
    QString         _settingsGroup; //QSettings 的组名

    QMap<QString, FactMetaData*> _nameToMetaDataMap; //一个映射表，用于存储设置项的元数据

private:
    //这行代码定义了一个静态常量成员变量 kJsonFile，它是一个格式化的字符串，用于指定设置组的 JSON 文件路径
    //表示这是一个静态成员变量，属于类本身，而不是类的某个实例
 //constexpr：表示这是一个编译时常量，其值在编译时确定，且在程序运行期间不会改变
 //const char*：表示这是一个指向常量字符数组的指针，通常用于存储字符串
 //kJsonFile：变量名，通常以 k 开头表示这是一个常量
 //":/json/%1.SettingsGroup.json"：这是一个格式化的字符串，用于指定设置组的 JSON 文件路径
 //:/json/：表示文件位于资源系统中的 json 目录下，%1：这是一个占位符，可以在运行时被替换为具体的设置组名称
 //.SettingsGroup.json：文件的扩展名，表示这是一个 JSON 文件，用于存储设置组的相关信息
 static constexpr const char* kJsonFile = ":/json/%1.SettingsGroup.json";
};
