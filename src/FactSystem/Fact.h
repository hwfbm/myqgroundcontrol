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
#include <QtCore/QVariant>

#include "FactMetaData.h"



class FactValueSliderListModel;

Q_DECLARE_LOGGING_CATEGORY(FactLog)

//act 类是 QGroundControl (QGC) 参数系统的核心组件，它远不止是一个简单的"数据格式中心"，而是一个功能丰富的参数管理系统
// Fact 类的主要职责：
//     参数值管理：存储和验证各种类型的参数值
//     元数据系统：维护参数的描述性信息（单位、范围、枚举等）
//     变更通知：提供值变更的信号通知机制
//     类型安全：确保参数操作的类型正确性
//     UI集成：为 QML 界面提供属性绑定支持
/// A Fact is used to hold a single value within the system.
//Q_PROPERTY 宏用于声明类中的属性，这些属性可以通过 Qt 的元对象系统进行访问和通知。这使得属性可以被 QML 绑定和使用
// 每个 Q_PROPERTY 宏定义了一个属性，包括其类型、名称、访问函数、默认值等。以下是一些关键点：
// READ：指定属性的访问器（getter）。
// WRITE：指定属性的设置器（setter）。
// NOTIFY：指定属性值改变时发出的信号。
// CONSTANT：指定属性是否为常量，即其值在对象的生命周期内不会改变。
class Fact : public QObject
{
    Q_OBJECT

    //与 QML 的深度集成
    //通过大量 Q_PROPERTY 声明实现
    // 使得在 QML 中可以这样使用：
    // Text {
    //     text: fact.valueString
    //     onFactValueChanged: console.log("New value:", fact.value)
    // }
    Q_PROPERTY(int          componentId             READ componentId                                       CONSTANT) //一个整数属性，用于标识组件
    Q_PROPERTY(QStringList  bitmaskStrings          READ bitmaskStrings                                         NOTIFY bitmaskStringsChanged)//一个字符串列表，用于表示位掩码字符串，bitmaskStringsChanged当位掩码字符串列表改变时发出的信号
    Q_PROPERTY(QVariantList bitmaskValues           READ bitmaskValues                                          NOTIFY bitmaskValuesChanged)//一个变体列表，用于表示位掩码值
    Q_PROPERTY(QStringList  selectedBitmaskStrings  READ selectedBitmaskStrings                                 NOTIFY valueChanged) //一个字符串列表，用于表示选中的位掩码字符串
    Q_PROPERTY(int          decimalPlaces           READ decimalPlaces                                          CONSTANT)   //一个整数属性，用于指定小数点位数
    Q_PROPERTY(QVariant     defaultValue            READ cookedDefaultValue                                     CONSTANT)  //一个变体属性，用于指定默认值
    Q_PROPERTY(QString      defaultValueString      READ cookedDefaultValueString                               CONSTANT)
    Q_PROPERTY(bool         defaultValueAvailable   READ defaultValueAvailable                                  CONSTANT)
    Q_PROPERTY(int          enumIndex               READ enumIndex                  WRITE setEnumIndex          NOTIFY valueChanged)//一个整数属性，用于指定枚举索引
    Q_PROPERTY(QStringList  enumStrings             READ enumStrings                                            NOTIFY enumsChanged)//一个字符串列表，用于表示枚举字符串，将数字参数映射为可读性更好的文本
    Q_PROPERTY(QString      enumStringValue         READ enumStringValue            WRITE setEnumStringValue    NOTIFY valueChanged) //一个字符串属性，用于指定枚举字符串值
    Q_PROPERTY(QVariantList enumValues              READ enumValues                                             NOTIFY enumsChanged) //一个变体列表，用于表示枚举值
    Q_PROPERTY(QString      category                READ category                                               CONSTANT) //一个字符串属性，用于指定类别
    Q_PROPERTY(QString      group                   READ group                                                  CONSTANT) //一个字符串属性，用于指定组
    Q_PROPERTY(QString      longDescription         READ longDescription                                        CONSTANT)//一个长字符串，用于描述
    Q_PROPERTY(QVariant     max                     READ cookedMax                                              CONSTANT) //一个变体属性，用于指定最大值
    Q_PROPERTY(QString      maxString               READ cookedMaxString                                        CONSTANT)
    Q_PROPERTY(bool         maxIsDefaultForType     READ maxIsDefaultForType                                    CONSTANT)
    Q_PROPERTY(QVariant     min                     READ cookedMin                                              CONSTANT)
    Q_PROPERTY(QString      minString               READ cookedMinString                                        CONSTANT)
    Q_PROPERTY(bool         minIsDefaultForType     READ minIsDefaultForType                                    CONSTANT)
    Q_PROPERTY(QString      name                    READ name                                                   CONSTANT) //一个字符串属性，用于指定名称
    Q_PROPERTY(bool         vehicleRebootRequired   READ vehicleRebootRequired                                  CONSTANT)
    Q_PROPERTY(bool         qgcRebootRequired       READ qgcRebootRequired                                      CONSTANT)
    Q_PROPERTY(QString      shortDescription        READ shortDescription                                       CONSTANT)//显示参数的辅助信息
    Q_PROPERTY(QString      units                   READ cookedUnits                                            CONSTANT)
    Q_PROPERTY(QVariant     value                   READ cookedValue                WRITE setCookedValue        NOTIFY valueChanged) //一个变体属性，用于表示属性值，经过单位换算/转换的"熟"值（用户友好）
    Q_PROPERTY(QVariant     rawValue                READ rawValue                   WRITE setRawValue           NOTIFY rawValueChanged)//提供参数值的双重访问接口，原始的"生"值（设备直接使用）
    Q_PROPERTY(bool         valueEqualsDefault      READ valueEqualsDefault                                     NOTIFY valueChanged)//显示参数的特殊状态
    Q_PROPERTY(QString      valueString             READ cookedValueString                                      NOTIFY valueChanged)
    Q_PROPERTY(QString      enumOrValueString       READ enumOrValueString                                      NOTIFY valueChanged)
    Q_PROPERTY(double       increment               READ cookedIncrement                                        CONSTANT) //为 UI 控件提供校验依据
    Q_PROPERTY(bool         typeIsString            READ typeIsString                                           CONSTANT)
    Q_PROPERTY(bool         typeIsBool              READ typeIsBool                                             CONSTANT)
    Q_PROPERTY(bool         hasControl              READ hasControl                                             CONSTANT)
    Q_PROPERTY(bool         readOnly                READ readOnly                                               CONSTANT)
    Q_PROPERTY(bool         writeOnly               READ writeOnly                                              CONSTANT)
    Q_PROPERTY(bool         volatileValue           READ volatileValue                                          CONSTANT)

public:
    //多用途构造函数，提供多种构造方式
    explicit Fact(QObject *parent = nullptr); // 基本构造
    explicit Fact(int componentId, const QString &name, FactMetaData::ValueType_t type, QObject *parent = nullptr);// 带类型指定
    explicit Fact(const Fact &other, QObject *parent = nullptr);// 拷贝构造

    /// Creates a Fact using the name and type from metaData. Also calls QGCCorePlugin::adjustSettingsMetaData allowing
    /// custom builds to override the metadata.
    //通过 FactMetaData 成员提供：数据类型 (ValueType_t)，最小/最大值，默认值，单位，枚举定义，描述信息，访问控制（只读/只写）
    explicit Fact(const QString &settingsGroup, FactMetaData *metaData, QObject *parent = nullptr); // 从元数据构造
    virtual ~Fact();

    const Fact &operator=(const Fact &other);

    /// Convert and validate value
    ///     @param cookedValue: Value to convert and validate
    ///     @param convertOnly true: validate type conversion only, false: validate against meta data as well


    //验证和限制
    //提供输入验证
    //自动钳制到有效范围
    Q_INVOKABLE QString validate(const QString &cookedValue, bool convertOnly);
    /// Convert and clamp value
    Q_INVOKABLE QVariant clamp(const QString &cookedValue);


    // 转换后的值（考虑单位换算等）
    QVariant cookedValue() const; /// Value after translation
    // 原始值（未转换）
    QVariant rawValue() const { return _rawValue; }  /// value prior to translation, careful


    int componentId() const { return _componentId; }
    int decimalPlaces() const;
    QVariant rawDefaultValue() const;
    QVariant cookedDefaultValue() const;
    bool defaultValueAvailable() const;
    QString cookedDefaultValueString() const;
    QStringList bitmaskStrings() const;
    QVariantList bitmaskValues() const;
    /// Provide a list of selected strings based on the fact value with the bitmaskString/bitmaskValues map
    QStringList selectedBitmaskStrings() const;

    //枚举和位掩码支持
    //完整支持枚举类型参数
    //支持位掩码参数的字符串表示
    int enumIndex(); // This is not const, since an unknown value can modify the enum lists
    QStringList enumStrings() const;
    QString enumStringValue();         // This is not const, since an unknown value can modify the enum lists
    QVariantList enumValues() const;
    QString category() const;
    QString group() const;
    QString longDescription() const;
    QVariant rawMax() const;
    QVariant cookedMax() const;
    QString cookedMaxString() const;
    bool maxIsDefaultForType() const;
    QVariant rawMin() const;
    QVariant cookedMin() const;
    QString cookedMinString() const;
    bool minIsDefaultForType() const;
    QString name() const { return _name; }
    QString shortDescription() const;
    FactMetaData::ValueType_t type() const { return _type; }
    QString cookedUnits() const;
    QString rawUnits() const;
    QString rawValueString() const;
    QString cookedValueString() const;
    bool valueEqualsDefault() const;
    bool vehicleRebootRequired() const;
    bool qgcRebootRequired() const;
    QString enumOrValueString();         // This is not const, since an unknown value can modify the enum lists
    double rawIncrement() const;
    double cookedIncrement() const;
    bool typeIsString() const { return (type() == FactMetaData::valueTypeString); }
    bool typeIsBool() const { return (type() == FactMetaData::valueTypeBool); }
    bool hasControl() const;
    bool readOnly() const;
    bool writeOnly() const;
    bool volatileValue() const;

    Q_INVOKABLE FactValueSliderListModel *valueSliderModel();

    /// Returns the values as a string with full 18 digit precision if float/double.
    QString rawValueStringFullPrecision() const;

    // 核心功能实现，自动类型转换和验证
    void setRawValue(const QVariant &value);
    void setCookedValue(const QVariant &value);
    /// Sets and sends new value to vehicle even if value is the same
    void forceSetRawValue(const QVariant &value);//提供强制设置 (forceSetRawValue) 用于跳过相等性检查

    void setEnumIndex(int index);
    void setEnumStringValue(const QString &value);
    int valueIndex(const QString &value) const;

    // The following methods allow you to defer sending of the valueChanged signals in order to implement
    // rate limited signalling for ui performance. Used by FactGroup for example.
    // 信号控制
    //支持信号发送的精细控制支持信号发送的精细控制
    //实现信号延迟发送（优化性能）
    void setSendValueChangedSignals (bool sendValueChangedSignals);
    bool sendValueChangedSignals () const { return _sendValueChangedSignals; }
    bool deferredValueChangeSignal() const { return _deferredValueChangeSignal; }
    void clearDeferredValueChangeSignal() { _deferredValueChangeSignal = false; }
    void sendDeferredValueChangedSignal();



    /// Sets the meta data associated with the Fact.
    ///     @param metaData FactMetaData for Fact
    ///     @param setDefaultFromMetaData true: set the fact value to the default specified in the meta data
    void setMetaData(FactMetaData *metaData, bool setDefaultFromMetaData = false);

    FactMetaData *metaData() { return _metaData; }

    /// Value coming from Vehicle. This does NOT send a _containerRawValueChanged signal.
    void containerSetRawValue(const QVariant &value);

    /// Generally you should not change the name of a fact. But if you know what you are doing, you can.
    void setName(const QString &name) { _name = name; }

    /// Generally this is done during parsing. But if you know what you are doing, you can.
    void setEnumInfo(const QStringList &strings, const QVariantList &values);

signals:
    void bitmaskStringsChanged();
    void bitmaskValuesChanged();
    void enumsChanged();
    void sendValueChangedSignalsChanged(bool sendValueChangedSignals);

    /// This signal is only meant for use by the QT property system. It should not be connected to by client code.
    void valueChanged(const QVariant &value);
    void rawValueChanged(const QVariant &value);

    /// Signalled when the param write ack comes back from the vehicle
    void vehicleUpdated(const QVariant &value);

    /// This signal is meant for use by Fact container implementations. Used to send changed values to vehicle.
    void containerRawValueChanged(const QVariant &value);

protected:
    QString _variantToString(const QVariant &variant, int decimalPlaces) const;
    void _sendValueChangedSignal(const QVariant &value);

    QString _name;
    int _componentId = -1;
    QVariant _rawValue = 0;
    FactMetaData::ValueType_t _type = FactMetaData::valueTypeInt32;
    FactMetaData *_metaData = nullptr;
    bool _sendValueChangedSignals = true;
    bool _deferredValueChangeSignal = false;
    FactValueSliderListModel *_valueSliderModel = nullptr;

    static constexpr const char *kMissingMetadata = "Meta data pointer missing";

private slots:
    void _checkForRebootMessaging();

private:
    void _init();
};
