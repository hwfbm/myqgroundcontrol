/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SettingsFact.h"
#include "QGCApplication.h"
#include "QGCCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QSettings>

QGC_LOGGING_CATEGORY(SettingsFactLog, "qgc.factsystem.settingsfact")

SettingsFact::SettingsFact(QObject *parent)
    : Fact(parent)
{
    // qCDebug(SettingsFactLog) << Q_FUNC_INFO << this;
}

//SettingsFact 是继承自 Fact 的类，表示一个「可持久化、带元数据的设置项」
//这里会调用父类 Fact 的构造函数，设置 ID 为 0，名称和类型都来自 metaData
//_settingsGroup 保存所属分组
SettingsFact::SettingsFact(const QString &settingsGroup, FactMetaData *metaData, QObject *parent)
    : Fact(0, metaData->name(), metaData->type(), parent)
    , _settingsGroup(settingsGroup)
{
    // qCDebug(SettingsFactLog) << Q_FUNC_INFO << this;
    //读取 QSettings（本地配置文件）
    QSettings settings;   // 构造本地配置访问器

    if (!_settingsGroup.isEmpty()) {
        settings.beginGroup(_settingsGroup);// 分组名，如 App、Battery 等
    }

    // Allow core plugin a chance to override the default value
    //给插件（如 QGC 的内核插件）一个钩子机会去动态调整设置项的元数据（比如隐藏、改范围），返回值 _visible 代表该设置项是否对 UI 可见
    _visible = QGCCorePlugin::instance()->adjustSettingMetaData(settingsGroup, *metaData);
    setMetaData(metaData);//设置 _metaData 成员，供后续类型转换、值验证、UI 展示描述等功能使用

    //初始化 _rawValue（当前值）
    if (metaData->defaultValueAvailable()) {
        const QVariant rawDefaultValue = metaData->rawDefaultValue();
        if (qgcApp()->runningUnitTests()) {
            // Don't use saved settings
            _rawValue = rawDefaultValue;
        } else if (_visible) {
            //否则就从本地持久化读取（如果没有就用默认值）。还会调用 convertAndValidateRaw() 进行数据校验和类型转换
            QVariant typedValue;
            QString errorString;
            (void) metaData->convertAndValidateRaw(settings.value(_name, rawDefaultValue), true /* conertOnly */, typedValue, errorString);
            _rawValue = typedValue;  // 是从配置文件读取的值
        } else {
            //如果设置项不可见，就直接强制写回默认值
            // Setting is not visible, force to default value always
            settings.setValue(_name, rawDefaultValue);
            _rawValue = rawDefaultValue;//从 JSON 中读取该 Fact 的默认值
        }
    }

    //信号连接，数据变化自动通知
    //一旦值变了（比如在 UI 中修改 threshold1），会自动触发 _rawValueChanged()，从而保存回 QSettings，并发出变化信号
    (void) connect(this, &Fact::rawValueChanged, this, &SettingsFact::_rawValueChanged);
}

SettingsFact::SettingsFact(const SettingsFact &other, QObject *parent)
    : Fact(other, parent)
{
    // qCDebug(SettingsFactLog) << Q_FUNC_INFO << this;
    *this = other;
}

SettingsFact::~SettingsFact()
{
    // qCDebug(SettingsFactLog) << Q_FUNC_INFO << this;
}

const SettingsFact &SettingsFact::operator=(const SettingsFact &other)
{
    Fact::operator=(other);

    _settingsGroup = other._settingsGroup;

    return *this;
}

//点击开关、输入数值等操作触发 rawValue 改变后写入配置的地方
void SettingsFact::_rawValueChanged(const QVariant &value)
{
    QSettings settings;

    if (!_settingsGroup.isEmpty()) {
        settings.beginGroup(_settingsGroup);
    }

    settings.setValue(_name, value);//写入到 QSettings（= 写入配置文件）
}
