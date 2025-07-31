/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools

// ToolIndicatorPage
//      The base control for all Toolbar Indicator drop down pages. It supports a normal and expanded view.


// QGroundControl 中工具栏指示器下拉页面的基础控件，支持常规视图和扩展视图两种显示模式
// 核心功能
// 提供可折叠的双视图容器（常规视图 + 扩展视图）
// 支持参数加载等待状态显示
// 作为所有工具栏指示器页面的基础模板
RowLayout {
    id:         control
    spacing:    ScreenTools.defaultFontPixelWidth

    property bool       showExpand:         false   // 是否显示扩展控件（默认fals  Controls whether the expand widget is shown or not
    property bool       waitForParameters:  false   //  是否等待飞行器参数就绪（默认false）   UI won't show until parameters are ready
    property Component  contentComponent            // 常规视图的QML组件 Item for the normal view portion of the page
    property Component  expandedComponent           //扩展视图的QML组件  Item for the expanded portion of the page
    property var        pageProperties              //页面间共享的属性对象，property var pageProperties  // 可绑定到一个QtObject对象   Allows you to share a QtObject full of properties between pages
    //pageProperties 共享状态系统是 QGroundControl 中实现多组件间数据通信的巧妙设计
    // 类似多个组件（常规视图/扩展视图）都能读写这个白板上的数据
    // 任何修改都会自动同步到所有使用者
    // 避免了复杂的信号槽连接

    // These properties are bound by the MainRoowWindow loader
    property bool expanded: false //控制是否展开扩展视图
    property var  drawer //引用父抽屉容器

    property var    activeVehicle:      QGroundControl.multiVehicleManager.vehicle //当前活动飞行器引用
    property bool   parametersReady:    QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable //参数是否加载完成

    property bool _loadPages: !waitForParameters || parametersReady //动态加载控制。当waitForParameters=true时，会等待parametersReady信号，避免在参数未就绪时加载复杂UI

    //等待参数状态，显示条件：需要等待参数(waitForParameters)且参数未就绪
    QGCLabel {
        text:       qsTr("Waiting for parameters...") //提示等待参数
        visible:    waitForParameters && !parametersReady
    }

    Loader {
        id:                 contentItemLoader
        Layout.alignment:   Qt.AlignTop
        sourceComponent:    _loadPages ? contentComponent : undefined

        property var pageProperties: control.pageProperties
    }
//常规、拓展视图分隔线：仅在扩展时显示（visible: expanded）
    Rectangle {
        id:                     divider
        Layout.preferredWidth:  visible ? 1 : -1 //宽度动态调整
        Layout.fillHeight:      true
        color:                  QGroundControl.globalPalette.groupBorder
        visible:                control.expanded
    }
    
       //Loader延迟加载：expandedComponent只在需要时实例化
    Loader {
        id:                     expandedItemLoader
        Layout.alignment:       Qt.AlignTop
        Layout.preferredWidth:  visible ? -1 : 0
        visible:                expanded
        sourceComponent:        expanded ? expandedComponent : undefined

        //属性传递，将父组件的pageProperties传递给加载的子组件，实现跨组件状态共享
        property var pageProperties: control.pageProperties
    }
}
