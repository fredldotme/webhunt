import QtQuick 2.12
import Lomiri.Components 1.3
import Lomiri.Content 1.1

Item {
    id: dialogRoot
    anchors.fill: parent
    visible: false

    property list<ContentItem> importItems
    property var activeTransfer : null
    property var fileUrls : new Array
    property bool multiple : false
    property var types : ContentType.All

    onImportItemsChanged: {
        if (importItems.length > 0) {
            fileUrls = new Array

            for (var i = 0; i < importItems.length; i++) {
                const url = importItems[i].url
                if (fileUrls.indexOf(url) == -1) {
                    fileUrls.push(url)
                }
            }

            dialogRoot.accepted()
            dialogRoot.visible = false
        }
    }

    signal accepted()
    signal canceled()

    function __getTypesForMimeTypes(mimes) {
        let categories = new Set()

        for (let i = 0; i < mimes.length; i++) {
            const mimeType = mimes[i]
            console.log(mimeType)

            if (mimeType.startsWith("image/")) {
                categories.add(ContentType.Pictures)
            }
            else if (mimeType.startsWith("audio/")) {
                categories.add(ContentType.Music)
            }
            else if (mimeType.startsWith("video/")) {
                categories.add(ContentType.Videos)
            }
            else if (mimeType.startsWith("text/")) {
                categories.add(ContentType.Text)
            }
        }

        if (categories.size == 1) {
            return categories.values()[0]
        } else {
            return ContentType.All
        }
    }

    function open(multiple, mimes) {
        dialogRoot.multiple = multiple
        dialogRoot.types = __getTypesForMimeTypes(mimes)
        dialogRoot.visible = true
    }

    function cancel() {
        dialogRoot.canceled()
        dialogRoot.visible = false
    }

    ContentPeerPicker {
        id: contentPeer
        anchors.fill: parent
        contentType: dialogRoot.types
        handler: ContentHandler.Source
        onPeerSelected: {
            peer.selectionType = dialogRoot.multiple ? ContentTransfer.Multiple : ContentTransfer.Single
            activeTransfer = peer.request()
        }
        onCancelPressed: { dialogRoot.cancel() }
    }

    ContentTransferHint {
        id: importHint
        anchors.fill: parent
        activeTransfer: dialogRoot.activeTransfer
    }

    Connections {
        target: dialogRoot.activeTransfer
        onStateChanged: {
            if (dialogRoot.activeTransfer.state === ContentTransfer.Charged) {
                importItems = dialogRoot.activeTransfer.items;
            }
        }
    }
}
