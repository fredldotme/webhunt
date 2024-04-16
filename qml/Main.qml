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

import QtQuick 2.7
import Lomiri.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

import org.wpewebkit.qtwpe 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'webhunt.fredldotme'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    Page {
        header: Item {}
        anchors.fill: parent
        anchors.bottomMargin: !Qt.inputMethod.visible ? 0 : Qt.inputMethod.keyboardRectangle.height

        Item {
            anchors.fill: parent
            readonly property real visibilityAndScale: bottomEdge.dragProgress < (units.gu(4) / root.height) ? 1.0 : (1.0 - bottomEdge.dragProgress)
            scale: visibilityAndScale == 1.0 ? 1.0 : Math.min(visibilityAndScale * 3, 1.0)
            opacity: visibilityAndScale

            Behavior on scale {
                NumberAnimation { duration: 100 }
            }
            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }

            WPEView {
                id: webView
                url: "webkit://gpu"
                anchors.fill: parent
            }
        }

        BottomEdge {
            id: bottomEdge
            height: parent.height
            visible: !Qt.inputMethod.visible
            onCollapseCompleted: {
                webView.focus = false
                webView.focus = true
            }
            onCommitCompleted: {
                webView.focus = false
            }
            contentComponent: Item {
                width: bottomEdge.width
                height: bottomEdge.height

                ColumnLayout {
                    anchors.fill: parent
                    TextField {
                        id: urlField

                        Layout.margins: units.gu(2)
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        Layout.preferredWidth: (parent.width / 3) * 2
                        Layout.maximumWidth: parent.width - units.gu(4)
                        Layout.preferredHeight: units.gu(4)
                        Layout.fillWidth: focus

                        focus: !webView.focus
                        text: "https://weasel.firmfriends.us/HTMLVideoFromCloud/"
                        inputMethodHints: Qt.ImhUrlCharactersOnly

                        Behavior on width {
                            NumberAnimation { duration: 75 }
                        }
                        onAccepted: webView.url = text
                    }
                }
            }
            regions: [
                BottomEdgeRegion {
                    from: 0.0
                    to: units.gu(4) / root.height
                },
                BottomEdgeRegion {
                    from: (units.gu(4) / root.height) + 0.1
                    to: 1.0
                }
            ]
        }
    }
}
