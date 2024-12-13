/*
 * Copyright (C) 2024  Alfred Neumayer
 *
 * This program is free software: you can redistribute it and/or modify
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

import QtQuick 2.12

import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3 as ListItems
import Lomiri.Components.Popups 1.3
import Lomiri.Components.Themes 1.3

import QtQuick.Controls 2.12 as QQC2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12
import QtGraphicalEffects 1.12
import Qt.labs.settings 1.0

import WebHunt 1.0
import org.wpewebkit.qtwpe 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'mimibrowser.fredldotme'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    readonly property int oskMargin : !Qt.inputMethod.visible
                                      ? 0
                                      : (Qt.inputMethod.keyboardRectangle.height / Screen.devicePixelRatio)

    readonly property string defaultPage : "https://duckduckgo.com/"

    Page {
        id: rootPage
        header: Item {}
        anchors.fill: parent

        QtObject {
            id: browserState

            property MimiTab __newTabTemplate : MimiTab {}

            function addTab(url, newViewRequest) {
                __newTabTemplate.url = url
                if (tabsModel.count > 0) {
                    takeSnapshot(function() {
                        browserState.tabsModel.add(__newTabTemplate)
                        browserState.currentTabIndex = (tabsModel.count - 1)
                    })
                } else {
                    browserState.tabsModel.add(__newTabTemplate)
                    browserState.currentTabIndex = (tabsModel.count - 1)
                }
                browserState.tabsModel.save()
                return __newTabTemplate
            }

            function takeSnapshot(callback) {
                if (webViewContainer.currentWebView == undefined || webViewContainer.currentWebView == null) {
                    callback()
                    return;
                }

                webViewContainer.currentWebView.grabToImage(function(result) {
                    const path = browserState.tabsModel.snapshotForUrl(webViewContainer.currentWebView.url)
                    result.saveToFile(path);
                    // browserState.tabsModel.get(browserState.currentTabIndex).snapshot = path
                    callback();
                })
            }

            property MimiTabsModel tabsModel : MimiTabsModel {
                onCountChanged: {
                    if (count == 0) {
                        bottomEdge.collapse()
                        browserState.addTab(root.defaultPage)
                    }
                }
            }
            property int currentTabIndex : 0
        }

        Component.onCompleted: {
            browserState.tabsModel.load()
            if (browserState.tabsModel.count === 0)
                browserState.addTab(root.defaultPage)
        }

        Connections {
            target: Qt.application
            onAboutToQuit: {
                browserState.tabsModel.save()
            }
        }

        Item {
            id: webViewContainer
            width: parent.width
            height: parent.height - urlBarContainer.height
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

            property var currentWebView: webViewContainerSwipeView.contentChildren[browserState.currentTabIndex]
            readonly property bool fullscreen: currentWebView !== null ? currentWebView.fullscreen : false

            QQC2.SwipeView {
                id: webViewContainerSwipeView
                //onCurrentIndexChanged: console.log("currentIndex now: " + currentIndex)
                interactive: false
                width: parent.width
                height: parent.height

                currentIndex: browserState.currentTabIndex
                
                Connections {
                    target: webViewContainerSwipeView.contentItem
                    onXChanged: {
                        let i = 0
                        let distance = 0
                        while (true) {
                            if (distance < Math.abs(webViewContainerSwipeView.contentItem.x)) {
                                distance += webViewContainerSwipeView.width
                                ++i
                            } else {
                                break
                            }
                        }
                        browserState.currentTabIndex = i
                    }
                }

                Repeater {
                    // Web content view
                    model: browserState.tabsModel

                    WPEView {
                        id: webView
                        url: browserState.tabsModel.get(index) ?
                                 browserState.tabsModel.get(index).url :
                                 "about:blank"
                        width: webViewContainerSwipeView.width
                        height: webViewContainerSwipeView.height
                        property int tabIndex : index
                        onUrlChanged: {
                            const snapshot = browserState.tabsModel.snapshotForUrl(webView.url)
                            urlField.text = webView.url
                            browserState.tabsModel.get(webView.tabIndex).url = webView.url
                            browserState.tabsModel.get(webView.tabIndex).snapshot = snapshot
                            browserState.tabsModel.save()
                        }
                        onLoadingChanged: {
                            if (loading || index !== browserState.currentTabIndex)
                                return;

                            browserState.takeSnapshot(function () {
                                console.log("Snapshot taken: " + webView.url);
                            })
                        }

                        readonly property color invertedThemeColor: Qt.rgba(1.0 - themeColor.r,
                                                                            1.0 - themeColor.g,
                                                                            1.0 - themeColor.b,
                                                                            themeColor.a)

                        property bool fullscreen : false
                        property alias filePicker : filePicker

                        onFileSelectionRequested: {
                            filePicker.open(multiple, mimeTypes)
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
                bottomMargin: bottomContainer.hidden ? -height : root.oskMargin + (bottomEdge.height * bottomEdge.dragProgress)
                
                Behavior on bottomMargin {
                    LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                }
            }
            height: implicitHeight
            opacity: 1.0 - bottomEdge.dragProgress

            readonly property bool hidden :
                webViewContainer.currentWebView.fullscreen || webViewContainer.currentWebView.filePicker.visible

            ProgressBar {
                minimumValue: 0.0
                maximumValue: 1.0
                value: webViewContainer.currentWebView.loadProgress / 100.0
                width: parent.width
                height: units.gu(0.5)
                visible: webViewContainer.currentWebView.loading
            }

            // Bottom edge container
            Item {
                id: urlBarContainer
                width: parent.width
                height: units.gu(4) + (units.gu(1) * 2)

                Rectangle {
                    anchors.fill: parent
                    color: webViewContainer.currentWebView.themeColor
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
                            iconColor: webViewContainer.currentWebView.invertedThemeColor
                            scale: !pressed ? 1.0 : 0.8

                            readonly property bool visibility: webViewContainer.currentWebView.canGoBack
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
                            onClicked: {
                                if (webViewContainer.currentWebView.loading)
                                    webViewContainer.currentWebView.stop()
                                webViewContainer.currentWebView.goBack()
                            }
                        }
                        MimiButton {
                            iconName: "go-next"
                            iconColor: webViewContainer.currentWebView.invertedThemeColor
                            scale: !pressed ? 1.0 : 0.8
                            
                            readonly property bool visibility: webViewContainer.currentWebView.canGoForward
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
                            onClicked: {
                                if (webViewContainer.currentWebView.loading)
                                    webViewContainer.currentWebView.stop()
                                webViewContainer.currentWebView.goForward()
                            }
                        }
                    }

                    UrlBar {
                        id: urlField

                        margins: units.gu(0.9)
                        anchors.margins: units.gu(1)
                        anchors.centerIn: parent
                        width: entryFocus ? parent.width - units.gu(4) : Math.min((parent.width / 3) * 2, parent.width - (navigationRow.width * 2) - (newTabButton.width * 2))
                        height: parent.height
                        placeholderText: webViewContainer.currentWebView.title !== "" ? webViewContainer.currentWebView.title : qsTr("Loading...")
                        placeholderColor: webViewContainer.currentWebView.invertedThemeColor
                        onFocusChanged: {
                            text = webViewContainer.currentWebView.url
                        }

                        Behavior on width {
                            LomiriNumberAnimation { duration: 75 }
                        }

                        onAccepted: {
                            if (!(text.startsWith("http://") || text.startsWith("https://") || text.startsWith("webkit://")))
                                webViewContainer.currentWebView.url = "https://" + urlField.text
                            else
                                webViewContainer.currentWebView.url = urlField.text
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
                        iconColor: webViewContainer.currentWebView.invertedThemeColor
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
                
                MouseArea {
                    id: swipeDetectionMouseArea
                    anchors.fill: parent
                    propagateComposedEvents: true
                    enabled: false // REENABLE ONCE FINISHED: !urlField.focused && bottomEdge.dragProgress == 0.0 && !swipeEndAnimation.running
                    drag.threshold: 0 // We track on our own and need the startPosX to be exact

                    property bool inUse : false
                    property int contentItemStartX : 0
                    property int startPosX : 0
                    property int endPosX : 0
                    property int targetPosX : 0
                    property int __nextTabIndex : 0

                    onPressed: {
                        contentItemStartX = webViewContainerSwipeView.contentItem.x
                        startPosX = mouse.x
                    }

                    onPositionChanged: {
                        if (!inUse)
                            inUse = Math.abs(mouse.x - startPosX) > units.gu(4)
                    
                        if (!inUse) {
                            mouse.accepted = false
                            return
                        }

                        endPosX = mouse.x
                        webViewContainerSwipeView.contentItem.x = contentItemStartX + (mouse.x - startPosX)
                        mouse.accepted = true
                    }

                    onReleased: {
                        if (!inUse) {
                            mouse.accepted = false
                            return
                        }

                        const distance = startPosX - endPosX
                        const isOverBoundary = Math.abs(distance) > (webViewContainerSwipeView.contentItem.width / 4)
                        const width = webViewContainerSwipeView.contentItem.width
                        if (isOverBoundary) {
                            if (distance < 0) {
                                __nextTabIndex = Math.min(browserState.currentTabIndex + 1, browserState.tabsModel.count - 1)
                                targetPosX = Math.min(width * (browserState.tabsModel.count - 1), __nextTabIndex * width)
                            } else {
                                __nextTabIndex = Math.max(browserState.currentTabIndex - 1, 0)
                                targetPosX = Math.max(__nextTabIndex * width, 0)
                            }
                        } else {
                            __nextTabIndex = browserState.currentTabIndex
                            targetPosX = startPosX
                        }

                        console.log("End Position: " + mouse.x)
                        endPosX = mouse.x
                        contentItemStartX = 0
                        inUse = false
                        swipeEndAnimation.start()
                        mouse.accepted = true
                    }

                    onCanceled: {
                        if (!inUse) {
                            return
                        }

                        targetPosX = startPosX
                        contentItemStartX = 0
                        inUse = false
                        swipeEndAnimation.start()
                    }

                    Connections {
                        target: webViewContainerSwipeView.contentItem
                        onXChanged: {
                            console.log("webViewContainerSwipeView.contentItem.x: " + webViewContainerSwipeView.contentItem.x)
                        }
                    }

                    LomiriNumberAnimation {
                        id: swipeEndAnimation
                        target: webViewContainerSwipeView.contentItem
                        property: "x"
                        from: swipeDetectionMouseArea.endPosX
                        to: swipeDetectionMouseArea.targetPosX
                        onRunningChanged: {
                            browserState.currentTabIndex = swipeDetectionMouseArea.__nextTabIndex
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

            onCommitStarted: hint.status = BottomEdgeHint.Hidden
            onCommitCompleted: hint.status = BottomEdgeHint.Hidden
            onCollapseStarted: hint.status = BottomEdgeHint.Hidden
            onCollapseCompleted: hint.status = BottomEdgeHint.Hidden

            property var tabsGrid : null

            contentComponent: Item {
                id: bottomEdgeContainer
                width: bottomEdge.width
                height: bottomEdge.height

                Rectangle {
                    anchors.fill: bottomEdgeContainer
                    opacity: 0.7
                    color: webViewContainer.currentWebView.themeColor
                }

                GridView {
                    id: tabsGrid
                    width: parent.width
                    height: parent.height
                    readonly property int spacing : units.gu(2)
                    clip: true

                    Component.onCompleted: {
                        bottomEdge.tabsGrid = tabsGrid
                    }

                    readonly property int __cellWidth : webViewContainer.width
                    readonly property int __cellHeight : webViewContainer.height

                    cellWidth: (__cellWidth - spacing) / 2
                    cellHeight: (__cellHeight - spacing) / 2

                    model: browserState.tabsModel
                    currentIndex: browserState.currentTabIndex

                    delegate: Flickable {
                        id: tabDelegate
                        width: tabsGrid.cellWidth
                        height: tabsGrid.cellHeight
                        flickableDirection: Flickable.HorizontalFlick
                        opacity: 1.0 - dragProgress

                        property var tab : browserState.tabsModel.get(tabIndex)

                        onDraggingHorizontallyChanged: {
                            tabsGrid.interactive = !draggingHorizontally
                            console.log("Dragging ended, dragProgress " + dragProgress)
                            if (!draggingHorizontally && dragProgress > 0.67) {
                                browserState.tabsModel.removeSnapshot(tabDelegate.tab.url)
                                browserState.tabsModel.remove(tabIndex)
                            }
                        }

                        readonly property int tabIndex : index

                        property real dragProgress : Math.abs(tabDelegate.contentX) / (tabDelegate.width / 2)
                        property string snapshotUrl : "file://" + tabDelegate.tab.snapshot
                        property alias tabSnapshot : tabSnapshot

                        LomiriShape {
                            id: tabPreviewShape
                            width: parent.width - (tabsGrid.spacing * 2)
                            height: parent.height - (tabsGrid.spacing * 2)
                            radius: units.gu(2)
                            backgroundColor: "transparent"
                            visible: false
                            source: ShaderEffectSource {
                                sourceItem: webViewContainerSwipeView.contentChildren[tabDelegate.tabIndex] // webViewContainer
                                anchors.fill: parent
                                sourceRect: Qt.rect(0, 0, sourceItem.width, sourceItem.height)
                            }
                            sourceFillMode: LomiriShape.Stretch
                        }

                        LomiriShape {
                            id: tabSnapshotShape
                            width: parent.width - (tabsGrid.spacing * 2)
                            height: parent.height - (tabsGrid.spacing * 2)
                            radius: units.gu(2)
                            backgroundColor: "transparent"
                            visible: false
                            source: Image {
                                id: tabSnapshot
                                anchors.fill: parent
                                source: tabDelegate.snapshotUrl
                            }
                            sourceFillMode: LomiriShape.Stretch
                        }

                        DropShadow {
                            width: parent.width - (tabsGrid.spacing * 2)
                            height: parent.height - (tabsGrid.spacing * 2)
                            anchors.centerIn: parent
                            horizontalOffset: 0
                            verticalOffset: 0
                            radius: units.gu(0.5)
                            color: tabDelegate.tabIndex === browserState.currentTabIndex ? Theme.palette.highlighted.selection : Theme.palette.normal.base
                            source: tabDelegate.tabIndex === browserState.currentTabIndex ? tabPreviewShape : tabSnapshotShape
                            onSourceChanged: { console.log("index: " + tabDelegate.tabIndex + " changed " + tabDelegate.tab.url) }
                            scale: !tabsGridCellMouseArea.pressed ? 1.0 : 0.9
                            Behavior on scale {
                                LomiriNumberAnimation { duration: LomiriAnimation.SnapDuration }
                            }

                            MouseArea {
                                id: tabsGridCellMouseArea
                                anchors.fill: parent
                                onClicked: {
                                    browserState.takeSnapshot(function () {
                                        tabSnapshot.source = ""
                                        tabSnapshot.source = "file://" + browserState.tabsModel.snapshotForUrl(tabDelegate.tab.url)
                                        browserState.currentTabIndex = tabDelegate.tabIndex
                                        bottomEdge.collapse()
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
