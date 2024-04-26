/*
 * Copyright 2013-2017 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "tabs-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtCore/QObject>
#include <QtCore/QtGlobal>

/*!
    \class TabsModel
    \brief List model that stores the list of currently open tabs.

    TabsModel is a list model that stores the list of currently open tabs.
    Each tab holds a pointer to a Tab and associated metadata (URL, title,
    icon).

    The model doesn’t own the Tab, so it is the responsibility of whoever
    adds a tab to instantiate the corresponding Tab, and to destroy it after
    it’s removed from the model.
*/
TabsModel::TabsModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_currentIndex(-1)
{
}

TabsModel::~TabsModel()
{
}

QHash<int, QByteArray> TabsModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Url] = "url";
        roles[Title] = "title";
        roles[Icon] = "icon";
        roles[Tab] = "tab";
    }
    return roles;
}

int TabsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_tabs.count();
}

QVariant TabsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    QObject* tab = m_tabs.at(index.row());
    switch (role) {
    case Url:
        return tab->property("url");
    case Title:
        return tab->property("title");
    case Icon:
        return tab->property("icon");
    case Tab:
        return QVariant::fromValue(tab);
    default:
        return QVariant();
    }
}

int TabsModel::currentIndex() const
{
    return m_currentIndex;
}

void TabsModel::setCurrentIndex(int index)
{
    if (!checkValidTabIndex(index)) {
        return;
    }
    if (index != m_currentIndex) {
        m_currentIndex = index;
        Q_EMIT currentIndexChanged();
        Q_EMIT currentTabChanged();
    }
}

QObject* TabsModel::currentTab() const
{
    if (m_tabs.isEmpty() || !checkValidTabIndex(m_currentIndex)) {
        return nullptr;
    }
    return m_tabs.at(m_currentIndex);
}

/*!
    Append a tab to the model and return the corresponding index in the model.

    It is the responsibility of the caller to instantiate the corresponding
    Tab beforehand.
*/
int TabsModel::add(QObject* tab)
{
    return insert(tab, m_tabs.count());
}

/*!
    Add a tab to the model at the specified index, and return the index itself,
    or -1 if the operation failed.

    It is the responsibility of the caller to instantiate the corresponding
    Tab beforehand.
*/
int TabsModel::insert(QObject* tab, int index)
{
    if (tab == nullptr) {
        qWarning() << "Invalid Tab";
        return -1;
    }
    index = qMax(qMin(index, m_tabs.count()), 0);
    beginInsertRows(QModelIndex(), index, index);
    m_tabs.insert(index, tab);
    connect(tab, SIGNAL(urlChanged()), SLOT(onUrlChanged()));
    connect(tab, SIGNAL(titleChanged()), SLOT(onTitleChanged()));
    connect(tab, SIGNAL(iconChanged()), SLOT(onIconChanged()));
    endInsertRows();
    Q_EMIT countChanged();

    if (m_currentIndex == -1) {
        // Set the index to zero if this is the first item that gets added to the
        // model, as it should not be possible to have items in the model but no
        // current tab.
        m_currentIndex = 0;
        Q_EMIT currentIndexChanged();
        Q_EMIT currentTabChanged();
    } else if (index == m_currentIndex) {
        Q_EMIT currentTabChanged();
    } else if (index < m_currentIndex) {
        // Increment the index if we are inserting items before the current index.
        m_currentIndex++;
        Q_EMIT currentIndexChanged();
    }

    return index;
}

/*!
    Given its index, remove a tab from the model, and return the corresponding
    Tab.

    It is the responsibility of the caller to destroy the corresponding
    Tab afterwards.
*/
QObject* TabsModel::remove(int index)
{
    if (!checkValidTabIndex(index)) {
        return nullptr;
    }
    beginRemoveRows(QModelIndex(), index, index);
    QObject* tab = m_tabs.takeAt(index);
    tab->disconnect(this);
    endRemoveRows();
    Q_EMIT countChanged();

    if (index < m_currentIndex) {
        // If we removed any tab before the current one, decrease the
        // current index to match.
        m_currentIndex--;
        Q_EMIT currentIndexChanged();
    } else if (index == m_currentIndex) {
        // If the current tab was removed, the following one (if any) is made
        // current. If it was the last tab in the model, the current index needs
        // to be decreased.
        if (m_currentIndex == m_tabs.count()) {
            m_currentIndex--;
            Q_EMIT currentIndexChanged();
        }
        Q_EMIT currentTabChanged();
    }
    return tab;
}

QObject* TabsModel::get(int index) const
{
    if (!checkValidTabIndex(index)) {
        return nullptr;
    }
    return m_tabs.at(index);
}

/*!
    Returns the index position of the first occurrence of tab in the model.
    Returns -1 if no item matched.
*/
int TabsModel::indexOf(QObject* tab) const
{
    return m_tabs.indexOf(tab);
}

void TabsModel::move(int from, int to)
{
    if ((from == to) || !checkValidTabIndex(from) || !checkValidTabIndex(to)) {
        return;
    }

    int diff = to - from;
    int i = from;

    // Shuffle index along until destination
    while (i != to) {
        if (diff > 0) {
            beginMoveRows(QModelIndex(), i, i, QModelIndex(), i + 2);
            m_tabs.move(i + 1, i);
            i += 1;
        } else {
            beginMoveRows(QModelIndex(), i, i, QModelIndex(), i - 1);
            m_tabs.move(i, i - 1);
            i -= 1;
        }

        endMoveRows();
    }

    if (m_currentIndex == from) {
        m_currentIndex = to;
        Q_EMIT currentIndexChanged();
    } else if ((m_currentIndex >= to) && (m_currentIndex < from)) {
        m_currentIndex++;
        Q_EMIT currentIndexChanged();
    } else if ((m_currentIndex > from) && (m_currentIndex <= to)) {
        m_currentIndex--;
        Q_EMIT currentIndexChanged();
    }
}

bool TabsModel::checkValidTabIndex(int index) const
{
    if ((index < 0) || (index >= m_tabs.count())) {
        return false;
    }
    return true;
}

void TabsModel::onDataChanged(QObject* tab, int role)
{
    int index = m_tabs.indexOf(tab);
    if (checkValidTabIndex(index)) {
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << role);
    }
}

void TabsModel::onUrlChanged()
{
    onDataChanged(sender(), Url);
}

void TabsModel::onTitleChanged()
{
    onDataChanged(sender(), Title);
}

void TabsModel::onIconChanged()
{
    onDataChanged(sender(), Icon);
}
