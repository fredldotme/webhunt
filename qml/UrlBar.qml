/*
 * Copyright (C) 2024  Alfred Neumayer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webhunt is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import Lomiri.Components 1.3

Item {
    id: itemRoot

    property int margins : 0
    property alias text: urlField.text
    property alias entryFocus: urlField.focus
    property alias placeholderText: titleButton.text

    signal focusChanged()
    signal accepted()

    Button {
        id: titleButton

        y: itemRoot.margins
        width: parent.width
        height: parent.height - (itemRoot.margins * 2)
        font.underline: true
        opacity: urlField.focus ? 0.0 : 1.0
        visible: opacity > 0.0
        onClicked: urlField.focus = true

        Behavior on opacity {
            LomiriNumberAnimation { duration: 75 }
        }
    }

    TextField {
        id: urlField

        y: itemRoot.margins
        width: parent.width
        height: parent.height - (itemRoot.margins * 2)
        opacity: focus ? 1.0 : 0.0
        visible: opacity > 0.0
        inputMethodHints: Qt.ImhUrlCharactersOnly

        Behavior on opacity {
            LomiriNumberAnimation { duration: 75 }
        }

        onFocusChanged: {
            itemRoot.focusChanged()
        }

        onAccepted: {
            itemRoot.accepted()
        }
    }
}
