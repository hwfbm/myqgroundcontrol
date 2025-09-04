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
#include <QtQml/QQmlComponent>

//类是 QGroundControl 项目中用于 控制工具栏按钮行为 的模型类,核心功能是为工具栏上的图标按钮（ToolStrip）提供一组 属性、状态管理、点击响应 等功能
// 在 QML 代码中，按钮是这样绑定这个类的对象的：
//ToolStripAction {
// text: "Settings"
// iconSource: "/res/icons/settings.svg"
// checkable: true
// dropPanelComponent: settingsPanelComponent
// }然后工具栏会通过这个对象来决定按钮是否显示、图标是哪个、是否可选、是否已选、点击时弹出哪个页面

class ToolStripAction : public QObject
{
    Q_OBJECT
    
public:
    ToolStripAction(QObject* parent = nullptr);
    
    Q_PROPERTY(bool             enabled             READ enabled                WRITE setEnabled                NOTIFY enabledChanged)
    Q_PROPERTY(bool             visible             READ visible                WRITE setVisible                NOTIFY visibleChanged)
    Q_PROPERTY(bool             checkable           READ checkable              WRITE setCheckable              NOTIFY checkableChanged)
    Q_PROPERTY(bool             checked             READ checked                WRITE setChecked                NOTIFY checkedChanged)//是否是一个“可勾选”的按钮（比如切换模式）
    Q_PROPERTY(bool             showAlternateIcon   READ showAlternateIcon      WRITE setShowAlternateIcon      NOTIFY showAlternateIconChanged)
    Q_PROPERTY(bool             biColorIcon         READ biColorIcon            WRITE setbiColorIcon            NOTIFY biColorIconChanged)
    Q_PROPERTY(bool             fullColorIcon       READ fullColorIcon          WRITE setfullColorIcon          NOTIFY fullColorIconChanged)   
    Q_PROPERTY(bool             nonExclusive        READ nonExclusive           WRITE setNonExclusive           NOTIFY nonExclusiveChanged)   
    Q_PROPERTY(int              toolStripIndex      READ toolStripIndex         WRITE setToolStripIndex         NOTIFY toolStripIndexChanged)
    Q_PROPERTY(QString          text                READ text                   WRITE setText                   NOTIFY textChanged) //按钮的文字（可用于 tooltip 或辅助说明）
    Q_PROPERTY(QString          iconSource          READ iconSource             WRITE setIconSource             NOTIFY iconSourceChanged)  //图标路径
    Q_PROPERTY(QString          alternateIconSource READ alternateIconSource    WRITE setAlternateIconSource    NOTIFY alternateIconSourceChanged)//替代图标路径，用于状态切换时
    Q_PROPERTY(QQmlComponent*   dropPanelComponent  READ dropPanelComponent     WRITE setDropPanelComponent     NOTIFY dropPanelComponentChanged)

    bool            enabled             (void) const { return _enabled; }
    bool            visible             (void) const { return _visible; }
    bool            checkable           (void) const { return _checkable; }
    bool            checked             (void) const { return _checked; }
    bool            showAlternateIcon   (void) const { return _showAlternateIcon; } //	是否显示备用图标
    bool            biColorIcon         (void) const { return _biColorIcon; }//	控制图标的着色方案（单色 / 全色）
    bool            fullColorIcon       (void) const { return _fullColorIcon; }// 全色）
    bool            nonExclusive        (void) const { return _nonExclusive; }//是否是非互斥的按钮（多个可同时按下）
    int             toolStripIndex      (void) const { return _toolStripIndex; }//在工具栏中的排序位置
    QString         text                (void) const { return _text; }
    QString         iconSource          (void) const { return _iconSource; }
    QString         alternateIconSource (void) const { return _alternateIconSource; }
    QQmlComponent* dropPanelComponent   (void) const { return _dropPanelComponent; }//	点击按钮时弹出的面板组件（一个 QML 页面）

    void setEnabled             (bool enabled);
    void setVisible             (bool visible);
    void setCheckable           (bool checkable);
    void setChecked             (bool checked);
    void setShowAlternateIcon   (bool showAlternateIcon);
    void setbiColorIcon         (bool biColorIcon);
    void setfullColorIcon       (bool fullColorIcon);
    void setNonExclusive        (bool nonExclusive);
    void setToolStripIndex      (int  toolStripIndex);
    void setText                (const QString& text);
    void setIconSource          (const QString& iconSource);
    void setAlternateIconSource (const QString& alternateIconSource);
    void setDropPanelComponent  (QQmlComponent* dropPanelComponent);

signals:
    void enabledChanged             (bool enabled);
    void visibleChanged             (bool visible);
    void checkableChanged           (bool checkable);
    void checkedChanged             (bool checked);
    void showAlternateIconChanged   (bool showAlternateIcon);
    void biColorIconChanged         (bool biColorIcon);
    void fullColorIconChanged       (bool fullColorIcon);
    void nonExclusiveChanged        (bool nonExclusive);
    void toolStripIndexChanged      (int toolStripIndex);
    void textChanged                (QString text);
    void iconSourceChanged          (QString iconSource);
    void alternateIconSourceChanged (QString alternateIconSource);
    void triggered                  (QObject* source);//按钮被点击时触发的信号


    void dropPanelComponentChanged  (void);

protected:
    bool            _enabled =              true;
    bool            _visible =              true;
    bool            _checkable =            false;
    bool            _checked =              false;
    bool            _showAlternateIcon =    false;
    bool            _biColorIcon =          false;
    bool            _fullColorIcon =        false;
    bool            _nonExclusive =         false;
    int             _toolStripIndex =       -1;
    QString         _text;
    QString         _iconSource;
    QString         _alternateIconSource;
    QQmlComponent*  _dropPanelComponent =   nullptr;
};
