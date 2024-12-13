/*
 * Copyright 2024 Alfred Neumayer
 *
 * This file is part of Mimi Browser.
 *
 * Mimi Browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * Mimi Browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __TAB_H__
#define __TAB_H__

#include <QObject>
#include <QString>

class MimiTab : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString url MEMBER url NOTIFY urlChanged)
    Q_PROPERTY(QString title MEMBER title NOTIFY titleChanged)
    Q_PROPERTY(QString icon MEMBER icon NOTIFY iconChanged)
    Q_PROPERTY(QString snapshot MEMBER snapshot NOTIFY snapshotChanged)

public:
    MimiTab() = default;

    QString url;
    QString title;
    QString icon;
    QString snapshot;

Q_SIGNALS:
    void urlChanged() const;
    void titleChanged() const;
    void iconChanged() const;
    void snapshotChanged() const;
};

#endif
