/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "VehicleComponent.h"
#include "ParameterManager.h"
#include "QGCLoggingCategory.h"
#include "Vehicle.h"

#include <QtQml/QQmlContext>
#include <QtQuick/QQuickItem>

QGC_LOGGING_CATEGORY(VehicleComponentLog, "qgc.autopilotplugin.vehiclecomponent");

VehicleComponent::VehicleComponent(Vehicle *vehicle, AutoPilotPlugin *autopilot, AutoPilotPlugin::KnownVehicleComponent KnownVehicleComponent, QObject *parent)
    : QObject(parent)
    , _vehicle(vehicle)
    , _autopilot(autopilot)
    , _KnownVehicleComponent(KnownVehicleComponent)
{
    // qCDebug(VehicleComponentLog) << Q_FUNC_INFO << this;

    if (!vehicle || !autopilot) {
        qCWarning(VehicleComponentLog) << "Internal error";
    }
}

VehicleComponent::~VehicleComponent()
{
    // qCDebug(VehicleComponentLog) << Q_FUNC_INFO << this;
}

//动态创建并添加一个QML摘要按钮组件到父级QML项目中
//QQmlContext *context: QML上下文，用于组件创建
//QQuickItem *parent: 父级QML项目，用于放置新组件
void VehicleComponent::addSummaryQmlComponent(QQmlContext *context, QQuickItem *parent)
{
    //检查QML上下文是否有效
    if (!context) {
        qCWarning(VehicleComponentLog) << "Internal error";
        return;
    }

    //从QRC资源文件创建QML组件
    //qrc:/qml/VehicleComponentSummaryButton.qml: 组件QML文件路径
    //this: 设置父对象为当前VehicleComponent实例
    QQmlComponent component = new QQmlComponent(context->engine(), QUrl::fromUserInput("qrc:/qml/VehicleComponentSummaryButton.qml"), this);
    if (component.status() == QQmlComponent::Error)//检查组件创建是否成功，如果出错，输出错误信息并返回
    {
        qCWarning(VehicleComponentLog) << component.errors();
        return;
    }

    //实例化QML组件，转换为QQuickItem类型
    QQuickItem *const item = qobject_cast<QQuickItem*>(component.create(context));
    if (!item) {
        qCWarning(VehicleComponentLog) << "Internal error";
        return;
    }
  //设置父项和属性
    item->setParentItem(parent);// 设置视觉父级，确定位置和可见性
    //参数："vehicleComponent指定QML组件中要设置的属性名称，必须与QML中定义的属性名完全一致
    // QVariant::fromValue(this)：类型：QVariant（Qt的通用值容器）
    // 作用：将C++对象包装成QML可以识别的格式
    // this：指向当前VehicleComponent实例的指针
    //意味着在QML中，可以通过vehicleComponent来访问这个具体VehicleComponent对象的所有方法和属性
    item->setProperty("vehicleComponent", QVariant::fromValue(this));//向QML组件暴露当前C++对象，// C++代码：给名片贴上标签， 意思是：这个QML组件对应的C++对象是"我"（this）
}

void VehicleComponent::setupTriggerSignals()
{
    // Watch for changed on trigger list params
    //当组件关注的参数发生变化时，这个函数确保 _triggerUpdated() 会被调用
    for (const QString &paramName: setupCompleteChangedTriggerList()) {
        if (_vehicle->parameterManager()->parameterExists(ParameterManager::defaultComponentId, paramName)) {
            Fact *const fact = _vehicle->parameterManager()->getParameter(ParameterManager::defaultComponentId, paramName);
            (void) connect(fact, &Fact::valueChanged, this, &VehicleComponent::_triggerUpdated);
        }
    }
}
