/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SettingsGroup.h"
#include "QGCCorePlugin.h"

#include <QtQml/QQmlEngine>

SettingsGroup::SettingsGroup(const QString& name, const QString& settingsGroup, QObject* parent)
    : QObject       (parent)
    , _visible      (QGCCorePlugin::instance()->overrideSettingsGroupVisibility(name))
    , _name         (name)
    , _settingsGroup(settingsGroup)
{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

    _nameToMetaDataMap = FactMetaData::createMapFromJsonFile(QString(kJsonFile).arg(name), this);
}

SettingsFact* SettingsGroup::_createSettingsFact(const QString& factName)
{
    FactMetaData* m = _nameToMetaDataMap[factName];
    //如果找不到对应元数据，说明 JSON 文件里没定义这个设置项，直接报错退出
    //所以要声明一个 DEFINE_SETTINGFACT(foo)，就必须在对应 JSON 里定义它
    if(!m) {
        qCritical() << "Fact name " << factName << "not found in" << QString(kJsonFile).arg(_name);
        exit(-1);
    }
    //SettingsFact 是 Fact 的子类，用来表示一个绑定在设置系统中的配置项
    //_settingsGroup：对应的组
    //m：上面查找到的元数据
    //this：所属的 SettingsGroup，用于信号通信
    return new SettingsFact(_settingsGroup, m, this);
}

