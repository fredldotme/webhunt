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
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import Qt.labs.settings 1.0

import org.wpewebkit.qtwpe 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'webhunt.fredldotme'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    readonly property int oskMargin : !Qt.inputMethod.visible ? 0 : (Qt.inputMethod.keyboardRectangle.height / Screen.devicePixelRatio)

    Page {
        id: rootPage
        header: Item {}
        anchors.fill: parent

        Item {
            id: webViewContainer
            anchors.fill: parent
            // readonly property real visibilityAndScale: bottomEdge.dragProgress < (units.gu(4) / root.height) ? 1.0 : (1.0 - bottomEdge.dragProgress)
            readonly property real visibilityAndScale: 1.0
            scale: visibilityAndScale == 1.0 ? 1.0 : Math.min(visibilityAndScale * 3, 1.0)
            opacity: visibilityAndScale

            Behavior on scale {
                LomiriNumberAnimation { duration: 100 }
            }
            Behavior on opacity {
                LomiriNumberAnimation { duration: 100 }
            }

            // Web content view
            WPEView {
                id: webView
                url: "https://duckduckgo.com"
                width: parent.width
                height: parent.height - bottomContainer.height
                onUrlChanged: urlField.text = webView.url
            }
        }

        ShaderEffectSource {
            id: effectSource
            sourceItem: webViewContainer
            anchors.centerIn: bottomContainer
            width: bottomContainer.width
            height: bottomContainer.height
            sourceRect: Qt.rect(x, y, width, height)
        }

        FastBlur {
            id: blur
            anchors.fill: effectSource
            source: effectSource
            radius: units.gu(4)
            opacity: bottomContainer.opacity
        }

        Rectangle {
            anchors.fill: blur
            opacity: 0.7 * bottomContainer.opacity
            color: LomiriColors.porcelain
        }

        Column {
            id: bottomContainer
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: root.oskMargin + (bottomEdge.height * bottomEdge.dragProgress)
            }
            height: implicitHeight
            opacity: 1.0 - bottomEdge.dragProgress

            ProgressBar {
                id: determinateBar
                minimumValue: 0.0
                maximumValue: 1.0
                value: webView.loadProgress / 100.0
                width: parent.width
                height: units.gu(0.5)
                visible: webView.loading
            }
            
            // Bottom edge container
            Item {
                id: urlBarContainer
                width: parent.width
                height: units.gu(4) + (units.gu(1) * 2)

                Item {
                    anchors.fill: parent

                    Row {
                        id: navigationRow
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        width: implicitWidth
                        height: implicitHeight
                        visible: !urlField.focus

                        Button {
                            width: height
                            color: "transparent"
                            iconName: "go-previous"
                            scale: !pressed ? 1.0 : 0.8
                            visible: webView.canGoBack
                            Behavior on scale {
                                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                            }
                            onClicked: webView.goBack()
                        }
                        Button {
                            width: height
                            color: "transparent"
                            iconName: "go-next"
                            scale: !pressed ? 1.0 : 0.8
                            visible: webView.canGoForward
                            Behavior on scale {
                                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                            }
                            onClicked: webView.goForward()
                        }
                    }

                    TextField {
                        id: urlField

                        anchors.margins: units.gu(1)
                        anchors.centerIn: parent
                        width: focus ? parent.width - units.gu(4) : Math.min((parent.width / 3) * 2, parent.width - (navigationRow.width * 2) - (newTabButton.width * 2))

                        inputMethodHints: Qt.ImhUrlCharactersOnly
                        onFocusChanged: {
                            urlField.text = webView.url
                        }

                        Behavior on width {
                            LomiriNumberAnimation { duration: 75 }
                        }

                        onAccepted: {
                            if (!(text.startsWith("http://") || text.startsWith("https://") || text.startsWith("webkit://")))
                                webView.url = "https://" + urlField.text
                            else
                                webView.url = urlField.text
                        }
                    }

                    Button {
                        id: newTabButton
                        anchors {
                            right: parent.right
                            rightMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        width: height
                        visible: !urlField.focus
                        color: "transparent"
                        iconName: "add"
                        scale: !pressed ? 1.0 : 0.8
                        Behavior on scale {
                            LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                        }
                    }
                }
            }
        }

        BottomEdge {
            id: bottomEdge
            height: ((parent.height / 4) * 3) - bottomContainer.height
            width: parent.width
            visible: !Qt.inputMethod.visible
            preloadContent: true
            hint.status: BottomEdgeHint.Hidden
            onCollapseCompleted: hint.status = BottomEdgeHint.Hidden
            contentComponent: Item {
                id: bottomEdgeContainer
                width: bottomEdge.width
                height: bottomEdge.height

                /*ShaderEffectSource {
                    id: bottomEdgeEffectSource
                    sourceItem: webViewContainer
                    anchors.centerIn: bottomEdgeContainer
                    width: bottomEdgeContainer.width
                    height: bottomEdgeContainer.height
                    sourceRect: Qt.rect(0, webViewContainer.height - (bottomEdge.height * bottomEdge.dragProgress), width, height)
                }

                FastBlur {
                    id: blur
                    anchors.fill: bottomEdgeEffectSource
                    source: bottomEdgeEffectSource
                    radius: units.gu(4)
                }*/

                Rectangle {
                    anchors.fill: bottomEdgeContainer
                    opacity: 0.7
                    color: LomiriColors.porcelain
                }

                GridView {
                    id: tabsGrid
                    width: parent.width
                    height: parent.height
                    readonly property int spacing : units.gu(2)
                    clip: true

                    cellWidth: tabsGrid.width / 2
                    cellHeight: units.gu(40)

                    model: 7
                    delegate: Item {
                        width: tabsGrid.cellWidth
                        height: tabsGrid.cellHeight
                        LomiriShape {
                            anchors.fill: parent
                            anchors.margins: tabsGrid.spacing
                            radius: units.gu(2)
                            backgroundColor: "green"
                            scale: !tabsGridCellMouseArea.pressed ? 1.0 : 0.9
                            Behavior on scale {
                                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                            }

                            MouseArea {
                                id: tabsGridCellMouseArea
                                anchors.fill: parent
                                onClicked: {
                                    bottomEdge.collapse()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
