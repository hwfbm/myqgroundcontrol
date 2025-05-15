/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


#pragma once

#include <QtCore/QAbstractListModel>


// 继承自 QAbstractListModel，这是一个抽象基类，用于实现基于列表的数据模型
//QmlObjectListModel 是一个用于在 QML 中管理 QObject 列表的模型类。它提供了丰富的接口，用于添加、移除、插入、移动对象，以及管理列表的脏状态。
//通过继承 QAbstractListModel，它能够与 QML 的列表视图无缝集成，提供高效的数据绑定和更新机制
class QmlObjectListModel : public QAbstractListModel
{
    Q_OBJECT
    
public:
    QmlObjectListModel(QObject* parent = nullptr);
    ~QmlObjectListModel() override;
    
    Q_PROPERTY(int count READ count NOTIFY countChanged) //表示列表中对象的数量，countChanged：当列表中对象的数量发生变化时发出的信号
    
    /// Returns true if any of the items in the list are dirty. Requires each object to have
    /// a dirty property and dirtyChanged signal.
    Q_PROPERTY(bool dirty READ dirty WRITE setDirty NOTIFY dirtyChanged)//表示列表中是否有对象被标记为“脏”（即需要更新），当列表的脏状态发生变化时发出的信号

    Q_INVOKABLE QObject* get(int index);//返回指定索引处的对象
    const QObject *get(int index) const;//返回指定索引处的对象（常量版本）

    // Property accessors
    
    int         count               () const;//返回列表中对象的数量
    bool        dirty               () const { return _dirty; } //返回列表是否为脏

    void        setDirty            (bool dirty);//设置列表的脏状态
    void        append              (QObject* object); //向列表中追加一个对象
    void        append              (QList<QObject*> objects); //向列表中追加多个对象
    QObjectList swapObjectList      (const QObjectList& newlist);//交换当前列表与新列表
    void        clear               ();//清空列表
    QObject*    removeAt            (int i);//从指定索引处移除对象
    QObject*    removeOne           (const QObject* object) { return removeAt(indexOf(object)); }//移除指定对象
    void        insert              (int i, QObject* object); //：在指定位置插入一个对象
    void        insert              (int i, QList<QObject*> objects);//在指定位置插入多个对象
    bool        contains            (const QObject* object) { return _objectList.indexOf(object) != -1; } //检查列表是否包含指定对象
    int         indexOf             (const QObject* object) { return _objectList.indexOf(object); }//返回指定对象的索引

    /// Moves an item to a new position
    void move(int from, int to);//将对象从一个位置移动到另一个位置

    QObject*    operator[]          (int i); //通过索引访问对象
    const QObject* operator[]       (int i) const;//通过索引访问对象（常量版本）
    template<class T> T value       (int index) const { return qobject_cast<T>(_objectList[index]); }//通过索引获取对象的特定类型
    QList<QObject*>* objectList     () { return &_objectList; }//返回内部对象列表的指针

    /// Calls deleteLater on all items and this itself.
    void deleteListAndContents      ();//删除列表中的所有对象，并释放资源

    /// Clears the list and calls deleteLater on each entry
    void clearAndDeleteContents     ();//清空列表并删除所有对象

    void beginReset                 (); //用于在模型重置时发出信号
    void endReset                   ();

signals:
    void countChanged               (int count); //当列表中对象的数量发生变化时发出的信号
    void dirtyChanged               (bool dirtyChanged);//当列表的脏状态发生变化时发出的信号
    
private slots:
    void _childDirtyChanged         (bool dirty); //当列表中的对象的脏状态发生变化时调用的槽函数
    
private:
    // Overrides from QAbstractListModel
 //这些方法重写了 QAbstractListModel 的虚函数，用于实现模型的基本功能：
    int         rowCount    (const QModelIndex & parent = QModelIndex()) const override; //返回模型的行数
    QVariant    data        (const QModelIndex & index, int role = Qt::DisplayRole) const override;//返回指定索引处的数据
    bool        insertRows  (int position, int rows, const QModelIndex &index = QModelIndex()) override;//插入新行
    bool        removeRows  (int position, int rows, const QModelIndex &index = QModelIndex()) override;//移除行
    bool        setData     (const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;//设置指定索引处的数据
    QHash<int, QByteArray> roleNames(void) const override;//返回模型的角色名称

private:
    QList<QObject*> _objectList; //存储模型中的对象列表
    
    bool _dirty;//表示列表是否为脏
    bool _skipDirtyFirstItem;//用于控制是否跳过第一个对象的脏状态检查
    bool _externalBeginResetModel;//用于控制是否从外部调用 beginResetModel()

    //自定义角色，用于在 QML 中访问对象的特定属性
    static constexpr int ObjectRole = Qt::UserRole;
    static constexpr int TextRole = Qt::UserRole + 1;
};
