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
import Lomiri.Components.ListItems 1.3 as ListItems
import Lomiri.Components.Popups 1.3

import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import WebHunt 1.0
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

        QtObject {
            id: browserState

            property QtObject __newTabTemplate : QtObject {
                property string url: ""
                property string title: ""
                property string icon: ""
            }

            function addTab(url, newViewRequest) {
                __newTabTemplate.url = url
                browserState.tabsModel.add(__newTabTemplate)
                return __newTabTemplate
            }

            property TabsModel tabsModel: TabsModel {}
        }

        Component.onCompleted: {
            if (browserState.tabsModel.count === 0)
                browserState.addTab("https://duckduckgo.com/")
        }

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
                url: "https://duckduckgo.com/"
                width: parent.width
                height: parent.height - urlBarContainer.height
                onUrlChanged: urlField.text = webView.url
                readonly property color invertedThemeColor: Qt.rgba(1.0 - themeColor.r,
                                                                    1.0 - themeColor.g,
                                                                    1.0 - themeColor.b,
                                                                    themeColor.a)
                onFileSelectionRequested: {
                    filePicker.multiple = multiple
                    filePicker.open()
                }
            }

            MimiFilePicker {
                id: filePicker
                anchors.fill: parent

                onAccepted: {
                    webView.confirmFileSelection(filePicker.fileUrls)
                }
                onCanceled: {
                    webView.cancelFileSelection()
                }
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
            visible: opacity > 0.0 && bottomContainer.anchors.bottomMargin > 0.0
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

                Rectangle {
                    anchors.fill: parent
                    color: webView.themeColor
                    opacity: 0.7
                    Behavior on color {
                        ColorAnimation { duration: LomiriAnimation.SnapDuration }
                    }
                }

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
                        height: parent.height
                        visible: !urlField.entryFocus

                        Behavior on width {
                            LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                        }

                        MimiButton {
                            iconName: "go-previous"
                            iconColor: webView.invertedThemeColor
                            scale: !pressed ? 1.0 : 0.8

                            readonly property bool visibility: webView.canGoBack
                            y: units.gu(1)
                            width: visibility ? units.gu(4) : 0
                            height: parent.height - units.gu(2)
                            opacity: visibility ? 1.0 : 0.0
                            visible: width > 0

                            Behavior on scale {
                                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                            }
                            Behavior on width {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }
                            Behavior on opacity {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }
                            onClicked: webView.goBack()
                        }
                        MimiButton {
                            iconName: "go-next"
                            iconColor: webView.invertedThemeColor
                            scale: !pressed ? 1.0 : 0.8
                            
                            readonly property bool visibility: webView.canGoForward
                            y: units.gu(1)
                            width: visibility ? units.gu(4) : 0
                            height: parent.height - units.gu(2)
                            opacity: visibility ? 1.0 : 0.0
                            visible: width > 0

                            Behavior on scale {
                                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                            }
                            Behavior on width {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }
                            Behavior on opacity {
                                LomiriNumberAnimation { duration: LomiriAnimation.FastDuration }
                            }
                            onClicked: webView.goForward()
                        }
                    }

                    UrlBar {
                        id: urlField

                        margins: units.gu(0.9)
                        anchors.margins: units.gu(1)
                        anchors.centerIn: parent
                        width: entryFocus ? parent.width - units.gu(4) : Math.min((parent.width / 3) * 2, parent.width - (navigationRow.width * 2) - (newTabButton.width * 2))
                        height: parent.height
                        placeholderText: webView.title !== "" ? webView.title : qsTr("Loading...")
                        placeholderColor: webView.invertedThemeColor

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
                            entryFocus = false
                        }
                    }

                    MimiButton {
                        id: newTabButton
                        anchors {
                            right: parent.right
                            rightMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        y: units.gu(1)
                        height: parent.height - units.gu(2)
                        width: height
                        visible: !urlField.entryFocus
                        iconName: "add"
                        iconColor: webView.invertedThemeColor
                        scale: !pressed ? 1.0 : 0.8
                        Behavior on scale {
                            LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                        }
                        onClicked: {
                            browserState.addTab("https://duckduckgo.com/")
                        }
                        onPressAndHold: {
                            PopupUtils.open(addActionPopoverComponent, newTabButton)
                        }

                        /*Component {
                            id: addActionPopoverComponent
                            ActionSelectionPopover {
                                id: addActionPopover
                                width: implicitWidth
                                delegate: ListItems.Standard {
                                    text: action.text
                                    width: implicitWidthunits.gu(4)
                                }
                                actions: ActionList {
                                    Action {
                                        text: qsTr("New tab")
                                        onTriggered: print(text)
                                    }
                                    Action {
                                        text: qsTr("New window")
                                        onTriggered: print(text)
                                    }
                                    Action {
                                        text: qsTr("New private window")
                                        onTriggered: print(text)
                                    }
                                }
                            }
                        }*/
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

            onCommitStarted: hint.status = BottomEdgeHint.Hidden
            onCommitCompleted: hint.status = BottomEdgeHint.Hidden
            onCollapseStarted: hint.status = BottomEdgeHint.Hidden
            onCollapseCompleted: hint.status = BottomEdgeHint.Hidden

            contentComponent: Item {
                id: bottomEdgeContainer
                width: bottomEdge.width
                height: bottomEdge.height

                Rectangle {
                    anchors.fill: bottomEdgeContainer
                    opacity: 0.7
                    color: webView.themeColor
                }

                GridView {
                    id: tabsGrid
                    width: parent.width
                    height: parent.height
                    readonly property int spacing : units.gu(2)
                    clip: true

                    readonly property bool portrait : webView.height > webView.width
                    readonly property int __cellWidth : portrait ? (webView.width / 2) : (webView.height / 2)
                    readonly property int __cellHeight : portrait ? (webView.height / 2) : (webView.width / 2)

                    cellWidth: __cellWidth - (spacing / 2)
                    cellHeight: __cellHeight - (spacing / 2)

                    model: browserState.tabsModel
                    delegate: Item {
                        width: tabsGrid.cellWidth
                        height: tabsGrid.cellHeight

                        LomiriShape {
                            id: tabPreviewShape
                            anchors.fill: parent
                            anchors.margins: tabsGrid.spacing
                            radius: units.gu(2)
                            backgroundColor: "transparent"
                            visible: false
                            source: ShaderEffectSource {
                                sourceItem: webView
                                anchors.fill: parent
                                sourceRect: Qt.rect(0, 0, webView.width, webView.height)
                            }
                            sourceFillMode: LomiriShape.Stretch
                        }

                        DropShadow {
                            anchors.fill: tabPreviewShape
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: units.gu(0.5)
                            source: tabPreviewShape
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
