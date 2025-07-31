/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "CompInfo.h"
#include "MAVLinkLib.h"
#include "FactMetaData.h"

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>

class Vehicle;
class FirmwarePlugin;

Q_DECLARE_LOGGING_CATEGORY(CompInfoParamLog)


// 核心职能

// 参数元数据管理

//             存储飞控参数的描述性信息（非参数值本身）：
//                 参数名称、单位、默认值
//                     数据类型（int/float/bool）
//                 取值范围/枚举选项
//     分组信息（如"电池"、"遥控器"组）
//     读写权限（只读/可写）
// 协议适配层

//             解析不同飞控固件（PX4/ArduPilot）的参数元数据格式
//         处理APM特有的.pdef.xml参数定义文件
//             适配PX4的参数动态发现机制
// 缓存优化
        //对参数元数据建立内存缓存，避免重复解析：
class CompInfoParam : public CompInfo
{
    Q_OBJECT

public:
    CompInfoParam(uint8_t compId, Vehicle* vehicle, QObject* parent = nullptr);

    FactMetaData* factMetaDataForName(const QString& name, FactMetaData::ValueType_t type);

    // Overrides from CompInfo
    void setJson(const QString& metadataJsonFileName) override;

    static void _cachePX4MetaDataFile(const QString& metaDataFile);

private:
    QObject* _getOpaqueParameterMetaData(void);

    static FirmwarePlugin*  _anyVehicleTypeFirmwarePlugin   (MAV_AUTOPILOT firmwareType);
    static QString          _parameterMetaDataFile          (Vehicle* vehicle, MAV_AUTOPILOT firmwareType, int& majorVersion, int& minorVersion);

    typedef QPair<QString /* indexed name */, FactMetaData*> RegexFactMetaDataPair_t;

    bool                                _noJsonMetadata             = true;
    FactMetaData::NameToMetaDataMap_t   _nameToMetaDataMap;
    QList<RegexFactMetaDataPair_t>      _indexedNameMetaDataList;
    QObject*                            _opaqueParameterMetaData    = nullptr;

    static constexpr const char* _jsonParametersKey           = "parameters";
    static constexpr const char* _cachedMetaDataFilePrefix    = "ParameterFactMetaData";
    static constexpr const char* _indexedNameTag              = "{n}";
};
