import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Cutie

Item {
    id: settingSheet
    width: Screen.width
    height: Screen.height + 1
    y: -(Screen.height + 1)

    property alias containerOpacity: settingContainer.opacity
    property string wifiIcon: "icons/network-wireless-offline.svg"
    property string primaryModemIcon: "icons/network-cellular-offline.svg"

    CutieStore {
        id: quickStore
        appName: "cutie-panel"
        storeName: "quicksettings"
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file:/" + Atmosphere.path + "/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
        z: 1
    }

    FastBlur {
        id: wallpaperBlur
        anchors.fill: wallpaper
        source: wallpaper
        radius: 70
        visible: true
        opacity: settingSheet.containerOpacity
        z: 2
    }

    Rectangle {
        color: Atmosphere.secondaryAlphaColor
        anchors.fill: parent
        opacity: settingSheet.containerOpacity
        z: 3
    }

    function modemDataChangeHandler(n) {
        return () => {
            let modem = CutieModemSettings.modems[n];
            for (let i = 0; i < settingsModel.count; i++) {
                let btn = settingsModel.get(i)
                if (btn.tText == "Cellular " + (n + 1).toString()) {
                    if (!modem.online || !modem.powered) {
                        btn.bText = qsTr("Offline");
                        btn.icon = "icons/network-cellular-offline.svg"
                        if (n == 0)
                            settingSheet.primaryModemIcon = btn.icon;
                    }
                }
            }
        }
    }

    function modemNetStatusChangeHandler(n) {
        return () => {
            let netStatus = CutieModemSettings.modems[n].networkStatus;
            for (let i = 0; i < settingsModel.count; i++) {
                let btn = settingsModel.get(i)
                if (btn.tText == "Cellular " + (n + 1).toString()) {
                    if (netStatus === CutieModem.Unregistered
                        || netStatus === CutieModem.Denied) {
                        btn.bText = qsTr("Offline");
                        btn.icon = "icons/network-cellular-offline.svg"
                    } else if (netStatus === CutieModem.Searching) {
                        btn.bText = qsTr("Searching");
                        btn.icon = "icons/network-cellular-no-route.svg"
                    }

                    if (n == 0)
                        settingSheet.primaryModemIcon = btn.icon;
                }
            }
        }
    }

    function modemNetNameChangeHandler(n) {
        return () => {
            let netStatus = CutieModemSettings.modems[n].networkStatus;
            for (let i = 0; i < settingsModel.count; i++) {
                let btn = settingsModel.get(i)
                if (btn.tText == "Cellular " + (n + 1).toString()) {
                    if (netStatus === CutieModem.Registered
                        || netStatus === CutieModem.Roaming
                        || netStatus === CutieModem.Unknown) {
                        btn.bText = CutieModemSettings.modems[n].networkName;
                    }
                }
            }
        }
    }

    function modemNetStrengthChangeHandler(n) {
        return () => {
            let netStatus = CutieModemSettings.modems[n].networkStatus;
            let netStrength = CutieModemSettings.modems[n].networkStrength;
            for (let i = 0; i < settingsModel.count; i++) {
                let btn = settingsModel.get(i)
                if (btn.tText == "Cellular " + (n + 1).toString()) {
                    if (netStatus === CutieModem.Registered
                        || netStatus === CutieModem.Roaming
                        || netStatus === CutieModem.Unknown) {     
                        if (netStrength > 80) {
                            btn.icon = "icons/network-cellular-signal-excellent.svg"
                        } else if (netStrength > 50) {
                            btn.icon = "icons/network-cellular-signal-good.svg"
                        } else if (netStrength > 30) {
                            btn.icon = "icons/network-cellular-signal-ok.svg"
                        } else if (netStrength > 10) {
                            btn.icon = "icons/network-cellular-signal-low.svg"
                        } else {
                            btn.icon = "icons/network-cellular-signal-none.svg"
                        }

                        if (n == 0)
                            settingSheet.primaryModemIcon = btn.icon;
                    }
                }
            }
        }
    }

    function modemsChangeHandler(modems) {
        for (let n = 0; n < modems.length; n++) {
            let data = modems[n].data;
            CutieModemSettings.modems[n].poweredChanged.connect(modemDataChangeHandler(n));
            CutieModemSettings.modems[n].onlineChanged.connect(modemDataChangeHandler(n));
            CutieModemSettings.modems[n].networkStatusChanged.connect(modemNetStatusChangeHandler(n));
            CutieModemSettings.modems[n].networkNameChanged.connect(modemNetNameChangeHandler(n));
            CutieModemSettings.modems[n].networkStrengthChanged.connect(modemNetStrengthChangeHandler(n));

            CutieModemSettings.modems[n].powered = true;
            CutieModemSettings.modems[n].online = true;

            settingsModel.append({
                tText: qsTr("Cellular ") + (n + 1).toString(),
                bText: qsTr("Offline"),
                icon: "icons/network-cellular-offline.svg"
            });
            
            modemDataChangeHandler(n)();
            modemNetStatusChangeHandler(n)();
            modemNetNameChangeHandler(n)();
            modemNetStrengthChangeHandler(n)();
        }
    }

    function wirelessDataChangeHandler(wData) {
        for (let i = 0; i < settingsModel.count; i++) {
            let btn = settingsModel.get(i)
            if (btn.tText == qsTr("WiFi")) {
                btn.bText = CutieWifiSettings.activeAccessPoint.data["Ssid"].toString();
                if (wData.Strength > 80) {
                    btn.icon = "icons/network-wireless-signal-excellent-symbolic.svg"
                } else if (wData.Strength > 50) {
                    btn.icon = "icons/network-wireless-signal-good-symbolic.svg"
                } else if (wData.Strength > 30) {
                    btn.icon = "icons/network-wireless-signal-ok-symbolic.svg"
                } else if (wData.Strength > 10) {
                    btn.icon = "icons/network-wireless-signal-low-symbolic.svg"
                } else {
                    btn.icon = "icons/network-wireless-signal-none-symbolic.svg"
                }
                settingSheet.wifiIcon = btn.icon;
            }
        }
    }

    function wirelessActiveAccessPointHandler(activeAccessPoint) {
        if (activeAccessPoint) {
            let wData = CutieWifiSettings.activeAccessPoint.data;
            wirelessDataChangeHandler(wData);
            CutieWifiSettings.activeAccessPoint.dataChanged.connect(wirelessDataChangeHandler);
        } else {
            for (let i = 0; i < settingsModel.count; i++) {
                let btn = settingsModel.get(i)
                if (btn.tText == qsTr("WiFi")) {
                    btn.bText = qsTr("Offline");
                    btn.icon = "icons/network-wireless-offline.svg";
                    settingSheet.wifiIcon = btn.icon;
                }
            }
        }
    }

    function wirelessEnabledChangedHandler(wirelessEnabled) {
        if (!wirelessEnabled) {
            for (let i = 0; i < settingsModel.count; i++) {
                let btn = settingsModel.get(i)
                if (btn.tText == qsTr("WiFi")) {
                    btn.bText = qsTr("Disabled");
                    btn.icon = "icons/network-wireless-offline.svg";
                    settingSheet.wifiIcon = btn.icon;
                }
            }
        }
    }

    Component.onCompleted: {
        if (CutieWifiSettings.wirelessEnabled) {
            if (CutieWifiSettings.activeAccessPoint) {
                let wData = CutieWifiSettings.activeAccessPoint.data;

                wirelessDataChangeHandler(wData);
                CutieWifiSettings.activeAccessPoint.dataChanged.connect(wirelessDataChangeHandler);
            } else {
                wirelessActiveAccessPointHandler(null);
            }
        } else {
            wirelessEnabledChangedHandler(false);
        }

        CutieWifiSettings.activeAccessPointChanged.connect(wirelessActiveAccessPointHandler);
        CutieWifiSettings.wirelessEnabledChanged.connect(wirelessEnabledChangedHandler);

        let modems = CutieModemSettings.modems;
        modemsChangeHandler(modems);
        CutieModemSettings.modemsChanged.connect(modemsChangeHandler);
    }

    function setSettingContainerY(y) {
        settingContainer.y = y;
    }

    Item {
        id: dragArea
        x: 0
        y: parent.height - height
        height: 30
        width: parent.width

        MouseArea {
            drag.target: parent
            drag.axis: Drag.YAxis
            drag.minimumY: -parent.height
            drag.maximumY: Screen.height - parent.height
            enabled: settingsState.state != "closed"
            anchors.fill: parent
            propagateComposedEvents: true

            onPressed: {
                settingsState.state = "closing";
                settingContainer.opacity = (parent.y + parent.height) / Screen.height;
                settingContainer.y = parent.y - Screen.height;
            }

            onReleased: {
                if (parent.y < Screen.height - 2 * parent.height) {
                    settingsState.state = "closed"
                }
                else {
                    settingsState.state = "opened"
                }
                parent.y = parent.parent.height - 10
            }

            onPositionChanged: {
                if (drag.active) {
                    settingContainer.opacity = (parent.y + parent.height) / Screen.height;
                    settingContainer.y = parent.y - Screen.height;
                }
            }
        }
    }

    Item {
        id: settingContainer
        y: 0
        height: parent.height
        width: parent.width
        z: 4

        onOpacityChanged: {
            if (opacity === 0
                && settingsState.state === "closed"
                && !lockscreen.visible) {
                settingsState.height = setting.height;
            }
        }

        state: settingsState.state

        states: [
            State {
                name: "opened"
                PropertyChanges { target: settingContainer; y: 0; opacity: 1 }
                PropertyChanges { target: dragArea; y: Screen.height - dragArea.height }
            },
            State {
                name: "closed"
            },
            State {
                name: "opening"
            },
            State {
                name: "closing"
            }
        ]

        transitions: [
            Transition {
                to: "opened"
                ParallelAnimation {
                    NumberAnimation { target: settingContainer; properties: "y"; duration: 250; easing.type: Easing.InOutQuad; }
                    NumberAnimation { target: settingContainer; properties: "opacity"; duration: 250; easing.type: Easing.InOutQuad; }
                }
            },
            Transition {
                to: "closed"
                ParallelAnimation {
                    NumberAnimation { target: settingContainer; properties: "y"; duration: 250; easing.type: Easing.InOutQuad; to: -(Screen.height + 1) }
                    NumberAnimation { target: settingContainer; properties: "opacity"; duration: 250; easing.type: Easing.InOutQuad; to: 0}
                }
            }
        ]

        Rectangle {
            height: 160
            color: Atmosphere.primaryAlphaColor
            radius: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.leftMargin: 20
            y: 35
            clip: true

            Text {
                id: text2
                x: 20
                y: 20
                text: qsTr("Atmosphere")
                font.pixelSize: 24
                font.family: "Lato"
                font.weight: Font.Black
                color: Atmosphere.textColor
                transitions: Transition {
                    ColorAnimation { properties: "color"; duration: 500; easing.type: Easing.InOutQuad }
                }
            }

            ListView {
                anchors.fill: parent
                anchors.topMargin: 64
                model: Atmosphere.atmosphereList
                orientation: Qt.Horizontal
                clip: false
                spacing: -20
                delegate: Item {
                    width: 100
                    height: 100
                    Image {
                        x: 20
                        width: 60
                        height: 80
                        source: "file:/" + modelData.path + "/wallpaper.jpg"
                        fillMode: Image.PreserveAspectCrop

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name
                            font.pixelSize: 14
                            font.bold: false
                            color: (modelData.variant == "dark") ? "#FFFFFF" : "#000000"
                            font.family: "Lato"
                        }

                        MouseArea{
                            anchors.fill: parent
                            onClicked:{
                                Atmosphere.path = modelData.path;
                                atmosphereTimer.start();
                            }
                        }

                        Timer {
                            id: atmosphereTimer
                            interval: 500
                            repeat: false
                            onTriggered: {
                            }
                        }
                    }
                }
            }
        }


        ListModel {
            id: settingsModel

            ListElement {
                bText: ""
                tText: qsTr("WiFi")
                icon: "icons/network-wireless-offline.svg"
            }

        }

        GridView {
            id: widgetGrid
            anchors.fill: parent
            anchors.topMargin: 215
            anchors.bottomMargin: 100
            anchors.leftMargin: 20
            model: settingsModel
            cellWidth: width / Math.floor(width / 100)
            cellHeight: cellWidth
            clip: true

            delegate: Item {
                width: widgetGrid.cellWidth
                height: widgetGrid.cellWidth
                Rectangle {
                    id: settingBg
                    width: parent.width - 20
                    height: parent.width - 20
                    color: Atmosphere.secondaryAlphaColor
                    radius: 10

                    Text {
                        id: topText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 14
                        text: tText
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "Lato"
                        font.bold: false
                        color: Atmosphere.textColor
                        transitions: Transition {
                            ColorAnimation { properties: "color"; duration: 500; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        id: bottomText
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        text: bText
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "Lato"
                        font.bold: false
                        color: Atmosphere.textColor
                        transitions: Transition {
                            ColorAnimation { properties: "color"; duration: 500; easing.type: Easing.InOutQuad }
                        }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.width / 3
                        source: icon
                        sourceSize.height: 128
                        sourceSize.width: 128
                        fillMode: Image.PreserveAspectFit
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: clickHandler(this)
                    }
                }
            }
        }

        Rectangle {
            id: iconMask
            width: parent.height
            height: width
            visible: false
            color: Atmosphere.textColor

            Behavior on color {
                ColorAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }
        }

        Image {
            id: brightnessMin
            width: brightnessSlider.height / 2
            height: width
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.bottomMargin: 60
            source: "icons/gpm-brightness-lcd-disabled.svg"
            sourceSize.height: height*2
            sourceSize.width: width*2
            visible: false
        }

        OpacityMask {
            anchors.fill: brightnessMin
            source: iconMask
            maskSource: brightnessMin
        }

        Image {
            id: brightnessMax
            width: brightnessSlider.height / 2
            height: width
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 10
            anchors.bottomMargin: 60
            source: "icons/gpm-brightness-lcd"
            sourceSize.height: height*2
            sourceSize.width: width*2
            visible: false
        }

        OpacityMask {
            anchors.fill: brightnessMax
            source: iconMask
            maskSource: brightnessMax
        }

        CutieSlider {
            id: brightnessSlider
            value: "brightness" in quickStore.data ? quickStore.data["brightness"] : 1.0
            anchors.left: brightnessMin.right
            anchors.right: brightnessMax.left
            anchors.bottom: parent.bottom
            anchors.rightMargin: 10
            anchors.leftMargin: 10
            anchors.bottomMargin: 50

            property int maxBrightness: quicksettings.GetMaxBrightness()

            onMoved: {
                let data = quickStore.data;
                data["brightness"] = value;
                quickStore.data = data;
                quicksettings.SetBrightness(maxBrightness / 11 + maxBrightness * value / 1.1);
            }

            Connections {
                target: quickStore
                function onDataChanged() {
                    brightnessSlider.value = quickStore.data["brightness"];
                    quicksettings.SetBrightness(
                        brightnessSlider.maxBrightness / 11
                        + brightnessSlider.maxBrightness 
                        * brightnessSlider.value / 1.1);
                }
            }
        }
    }
}
