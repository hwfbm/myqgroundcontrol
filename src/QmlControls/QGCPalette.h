/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtGui/QColor>
#include <QtCore/QMap>
#include <QtQmlIntegration/QtQmlIntegration>

// 用于在 QML 界面中提供 颜色统一管理接口，实现：
// 按主题（Light / Dark）分配颜色；
// 按控件状态（Enabled / Disabled）分配颜色；
// 支持从 C++ 管理 QML UI 的颜色；
// 支持颜色自定义、更新和通知界面刷新。





//DECLARE_QGC_COLOR(button, "#aaaaaa", "#ffffff", "#444444", "#000000");
//会往 _colorInfoMap 中添加这 4 种状态下的颜色值，并将名字加入 _colors 列表
//QGCCorePlugin::instance()->paletteOverride(#name, colorInfo);
//意味着颜色初始化时，还允许由插件重写颜色配置，支持更高级定制
#define DECLARE_QGC_COLOR(name, lightDisabled, lightEnabled, darkDisabled, darkEnabled) \
    { \
        PaletteColorInfo_t colorInfo = { \
            { QColor(lightDisabled), QColor(lightEnabled) }, \
            { QColor(darkDisabled), QColor(darkEnabled) } \
        }; \
        QGCCorePlugin::instance()->paletteOverride(#name, colorInfo); \
        _colorInfoMap[Light][ColorGroupEnabled][QStringLiteral(#name)] = colorInfo[Light][ColorGroupEnabled]; \
        _colorInfoMap[Light][ColorGroupDisabled][QStringLiteral(#name)] = colorInfo[Light][ColorGroupDisabled]; \
        _colorInfoMap[Dark][ColorGroupEnabled][QStringLiteral(#name)] = colorInfo[Dark][ColorGroupEnabled]; \
        _colorInfoMap[Dark][ColorGroupDisabled][QStringLiteral(#name)] = colorInfo[Dark][ColorGroupDisabled]; \
        _colors << #name; \
    }

#define DECLARE_QGC_NONTHEMED_COLOR(name, disabledColor, enabledColor) \
    { \
        PaletteColorInfo_t colorInfo = { \
            { QColor(disabledColor), QColor(enabledColor) }, \
            { QColor(disabledColor), QColor(enabledColor) } \
        }; \
        QGCCorePlugin::instance()->paletteOverride(#name, colorInfo); \
        _colorInfoMap[Light][ColorGroupEnabled][QStringLiteral(#name)] = colorInfo[Light][ColorGroupEnabled]; \
        _colorInfoMap[Light][ColorGroupDisabled][QStringLiteral(#name)] = colorInfo[Light][ColorGroupDisabled]; \
        _colorInfoMap[Dark][ColorGroupEnabled][QStringLiteral(#name)] = colorInfo[Dark][ColorGroupEnabled]; \
        _colorInfoMap[Dark][ColorGroupDisabled][QStringLiteral(#name)] = colorInfo[Dark][ColorGroupDisabled]; \
        _colors << #name; \
    }

#define DECLARE_QGC_SINGLE_COLOR(name, color) \
    { \
        PaletteColorInfo_t colorInfo = { \
            { QColor(color), QColor(color) }, \
            { QColor(color), QColor(color) } \
        }; \
        QGCCorePlugin::instance()->paletteOverride(#name, colorInfo); \
        _colorInfoMap[Light][ColorGroupEnabled][QStringLiteral(#name)] = colorInfo[Light][ColorGroupEnabled]; \
        _colorInfoMap[Light][ColorGroupDisabled][QStringLiteral(#name)] = colorInfo[Light][ColorGroupDisabled]; \
        _colorInfoMap[Dark][ColorGroupEnabled][QStringLiteral(#name)] = colorInfo[Dark][ColorGroupEnabled]; \
        _colorInfoMap[Dark][ColorGroupDisabled][QStringLiteral(#name)] = colorInfo[Dark][ColorGroupDisabled]; \
        _colors << #name; \
    }



// Q_PROPERTY(QColor window READ window WRITE setWindow NOTIFY paletteChanged)

// QColor window() const {
//     return _colorInfoMap[_theme][_colorGroupEnabled ? ColorGroupEnabled : ColorGroupDisabled]["window"];
// }
// void setWindow(const QColor& color) {
//     _colorInfoMap[_theme][_colorGroupEnabled ? ColorGroupEnabled : ColorGroupDisabled]["window"] = color;
//     _signalPaletteChangeToAll();
// }
#define DEFINE_QGC_COLOR(NAME, SETNAME) \
    Q_PROPERTY(QColor NAME READ NAME WRITE SETNAME NOTIFY paletteChanged) \
    Q_PROPERTY(QStringList NAME ## Colors READ NAME ## Colors NOTIFY paletteChanged) \
    QColor NAME() const { return _colorInfoMap[_theme][_colorGroupEnabled  ? ColorGroupEnabled : ColorGroupDisabled][QStringLiteral(#NAME)]; } \
    QStringList NAME ## Colors() const { \
        QStringList c; \
        c << _colorInfoMap[Light][ColorGroupEnabled][QStringLiteral(#NAME)].name(QColor::HexRgb); \
        c << _colorInfoMap[Light][ColorGroupDisabled][QStringLiteral(#NAME)].name(QColor::HexRgb); \
        c << _colorInfoMap[Dark][ColorGroupEnabled][QStringLiteral(#NAME)].name(QColor::HexRgb); \
        c << _colorInfoMap[Dark][ColorGroupDisabled][QStringLiteral(#NAME)].name(QColor::HexRgb); \
        return c; \
    } \
    void SETNAME(const QColor& color) { _colorInfoMap[_theme][_colorGroupEnabled  ? ColorGroupEnabled : ColorGroupDisabled][QStringLiteral(#NAME)] = color; _signalPaletteChangeToAll(); }

/*!
 QGCPalette is used in QML ui to expose color properties for the QGC palette. There are two
 separate palettes in QGC, light and dark. The light palette is for outdoor use and the dark
 palette is for indoor use. Each palette also has a set of different colors for enabled and
 disabled states.

 Usage:

        import QGroundControl.Palette 1.0

        Rectangle {
            anchors.fill:   parent
            color:          qgcPal.window

            QGCPalette { id: qgcPal: colorGroupEnabled: enabled }
        }
*/

class QGCPalette : public QObject
{
    Q_OBJECT
    // QML_ELEMENT

public:
    //描述颜色的状态分组的，核心目的是区分在不同状态下所使用的颜色
    enum ColorGroup {
        ColorGroupDisabled = 0, // 颜色处于“禁用”状态时用的颜色
        ColorGroupEnabled,// 颜色处于“启用”状态时用的颜色
        cMaxColorGroup // 表示枚举总数量（通常用于数组或循环中）
    };//cMaxColorGroup 的作用是限定 PaletteColorInfo_t 数组大小

    //当前主题是浅色还是深色
    enum Theme {
        Light = 0,
        Dark,
        cMaxTheme
    };
    Q_ENUM(Theme)


    //每个颜色的四种状态值（亮启用、亮禁用、暗启用、暗禁用）
    //定义一个二维数组类型别名
   // 定义一个类型 PaletteColorInfo_t，它是一个：大小为 [主题数量][颜色状态数量] 的 二维 QColor 数组。
    //第一维：表示 主题（例如：Light / Dark）。第二维：表示 颜色状态（启用 / 禁用）
    typedef QColor PaletteColorInfo_t[cMaxTheme][cMaxColorGroup];

    Q_PROPERTY(Theme        globalTheme         READ globalTheme        WRITE setGlobalTheme        NOTIFY paletteChanged)
    Q_PROPERTY(bool         colorGroupEnabled   READ colorGroupEnabled  WRITE setColorGroupEnabled  NOTIFY paletteChanged)
    Q_PROPERTY(QStringList  colors              READ colors             CONSTANT)

    DEFINE_QGC_COLOR(window,                        setWindow)
    DEFINE_QGC_COLOR(windowShadeLight,              setWindowShadeLight)
    DEFINE_QGC_COLOR(windowShade,                   setWindowShade)
    DEFINE_QGC_COLOR(windowShadeDark,               setWindowShadeDark)
    DEFINE_QGC_COLOR(text,                          setText)
    DEFINE_QGC_COLOR(warningText,                   setWarningText)
    DEFINE_QGC_COLOR(button,                        setButton)
    DEFINE_QGC_COLOR(buttonBorder,                  setButtonBorder)
    DEFINE_QGC_COLOR(buttonText,                    setButtonText)
    DEFINE_QGC_COLOR(buttonHighlight,               setButtonHighlight)
    DEFINE_QGC_COLOR(buttonHighlightText,           setButtonHighlightText)
    DEFINE_QGC_COLOR(primaryButton,                 setPrimaryButton)
    DEFINE_QGC_COLOR(primaryButtonText,             setPrimaryButtonText)
    DEFINE_QGC_COLOR(textField,                     setTextField)
    DEFINE_QGC_COLOR(textFieldText,                 setTextFieldText)
    DEFINE_QGC_COLOR(mapButton,                     setMapButton)
    DEFINE_QGC_COLOR(mapButtonHighlight,            setMapButtonHighlight)
    DEFINE_QGC_COLOR(mapIndicator,                  setMapIndicator)
    DEFINE_QGC_COLOR(mapIndicatorChild,             setMapIndicatorChild)
    DEFINE_QGC_COLOR(mapWidgetBorderLight,          setMapWidgetBorderLight)
    DEFINE_QGC_COLOR(mapWidgetBorderDark,           setMapWidgetBorderDark)
    DEFINE_QGC_COLOR(mapMissionTrajectory,          setMapMissionTrajectory)
    DEFINE_QGC_COLOR(brandingPurple,                setBrandingPurple)
    DEFINE_QGC_COLOR(brandingBlue,                  setBrandingBlue)
    DEFINE_QGC_COLOR(colorGreen,                    setColorGreen)
    DEFINE_QGC_COLOR(colorYellow,                   setColorYellow)
    DEFINE_QGC_COLOR(colorYellowGreen,              setColorYellowGreen)
    DEFINE_QGC_COLOR(colorOrange,                   setColorOrange)
    DEFINE_QGC_COLOR(colorRed,                      setColorRed)
    DEFINE_QGC_COLOR(colorGrey,                     setColorGrey)
    DEFINE_QGC_COLOR(colorBlue,                     setColorBlue)
    DEFINE_QGC_COLOR(alertBackground,               setAlertBackground)
    DEFINE_QGC_COLOR(alertBorder,                   setAlertBorder)
    DEFINE_QGC_COLOR(alertText,                     setAlertText)
    DEFINE_QGC_COLOR(missionItemEditor,             setMissionItemEditor)
    DEFINE_QGC_COLOR(statusFailedText,              setstatusFailedText)
    DEFINE_QGC_COLOR(statusPassedText,              setstatusPassedText)
    DEFINE_QGC_COLOR(statusPendingText,             setstatusPendingText)
    DEFINE_QGC_COLOR(surveyPolygonInterior,         setSurveyPolygonInterior)
    DEFINE_QGC_COLOR(surveyPolygonTerrainCollision, setSurveyPolygonTerrainCollision)
    DEFINE_QGC_COLOR(toolbarBackground,             setToolbarBackground)
    DEFINE_QGC_COLOR(mytoolbarBackground,           setMytoolbarBackground)
    DEFINE_QGC_COLOR(toolStripFGColor,              setToolStripFGColor)
    DEFINE_QGC_COLOR(toolStripHoverColor,           setToolStripHoverColor)
    DEFINE_QGC_COLOR(groupBorder,                   setGroupBorder)

#ifdef QGC_UTM_ADAPTER
    DEFINE_QGC_COLOR(switchUTMSP,                    setSwitchUTMSP)
    DEFINE_QGC_COLOR(sliderUTMSP,                    setSliderUTMSP)
    DEFINE_QGC_COLOR(successNotifyUTMSP,             setSuccessNotifyUTMSP)
#endif

     QGCPalette(QObject* parent = nullptr);
    ~QGCPalette();

    QStringList colors                      () const { return _colors; }
    bool        colorGroupEnabled           () const { return _colorGroupEnabled; }
    void        setColorGroupEnabled        (bool enabled);

    static Theme    globalTheme             () { return _theme; }
    static void     setGlobalTheme          (Theme newTheme);

signals:
    void paletteChanged ();

private:
    static void _buildMap                   ();
    static void _signalPaletteChangeToAll   ();
    void        _signalPaletteChanged       ();
    void        _themeChanged               ();

    static Theme                _theme;             ///< There is a single theme for all palettes
    bool                        _colorGroupEnabled; ///< Currently selected ColorGroup. true: enabled, false: disabled
    static QStringList          _colors;


    //当主题发生变化时，所有已创建的 QGCPalette 实例都会收到 paletteChanged() 信号，从而刷新 UI
    static QMap<int, QMap<int, QMap<QString, QColor>>> _colorInfoMap;   // theme -> colorGroup -> color name -> color
    static QList<QGCPalette*> _paletteObjects;    ///< List of all active QGCPalette objects
};
