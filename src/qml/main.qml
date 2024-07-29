import QtQuick
import Cutie.Wlc
import Cutie.Volume

Item {
    id: settingsState

    width: Screen.width
    height: Screen.height + 1

    state: "closed" 
    states: [
        State {
            name: "opened"
            PropertyChanges { target: setting; opacity: 1 }
            PropertyChanges { target: settingSheet; y: 0; }
        },
        State {
            name: "closed"
            PropertyChanges { target: setting; opacity: 1 }
        },
        State {
            name: "opening"
            PropertyChanges { target: setting; opacity: 0 }
        },
        State {
            name: "closing"
            PropertyChanges { target: setting; opacity: 0 }
            PropertyChanges { target: settingSheet; y: 0 }
        }
    ]

    transitions: [
        Transition {
            to: "opening"
            ParallelAnimation {
                NumberAnimation { target: setting; properties: "opacity"; duration: 800; easing.type: Easing.InOutQuad; }
                SequentialAnimation {
                    NumberAnimation { target: setting; properties: "anchors.topMargin"; duration: 300; easing.type: Easing.InOutQuad; to: -20 }
                }
            }
        },
        Transition {
            to: "closing"
            ParallelAnimation {
                NumberAnimation { target: setting; properties: "opacity"; duration: 800; easing.type: Easing.InOutQuad; }
                SequentialAnimation {
                    NumberAnimation { target: setting; properties: "anchors.topMargin"; duration: 300; easing.type: Easing.InOutQuad; to: -20 }
                }
            }
        },
        Transition {
            to: "opened"
            ParallelAnimation {
                NumberAnimation { target: setting; properties: "opacity"; duration: 800; easing.type: Easing.InOutQuad; }
                SequentialAnimation {
                    NumberAnimation { target: setting; properties: "anchors.topMargin"; duration: 600; easing.type: Easing.InOutQuad; to: 0 }
                }
            }
        },
        Transition {
            to: "closed"
            ParallelAnimation {
                NumberAnimation { target: setting; properties: "opacity"; duration: 800; easing.type: Easing.InOutQuad; }
                SequentialAnimation {
                    NumberAnimation { target: setting; properties: "anchors.topMargin"; duration: 600; easing.type: Easing.InOutQuad; to: 0 }
                    NumberAnimation { target: settingSheet; properties: "y"; duration: 10; easing.type: Easing.InOutQuad; to: -Screen.height }
                }
            }
        }
    ]

    CutieWlc {
        id: cutieWlc

        property bool ignoreRelease: false
        
        onKey: (key) => {
            switch (key) {
                case CutieWlc.PowerPress:
                    console.log("Power button pressed: " + key);
                    break;
                case 2:
                    console.log(CutieVolume.volume);
                    break;
               case CutieWlc.volumedownPress:
                    console.log("volume up button released: " + key);
                    break;
                default:
                    console.log("Unknown key pressed: " + key);
                    break;
            }

            if (ignoreRelease) {
                ignoreRelease = false;
                return;
            }

            if (key === CutieWlc.PowerPress && !outputPowerManager.mode) {
                outputPowerManager.mode = true;
                ignoreRelease = true;
                relockTimer.start();
            } else if (key === CutieWlc.PowerRelease && outputPowerManager.mode) {
                outputPowerManager.mode = false;
                lockscreen.visible = true;
                lockscreen.opacity = 1;
                settingsState.state = "closed";
                settingsState.height = Screen.height + 1;
            }
        }
    }

    OutputPowerManagerV1 {
        id: outputPowerManager
    }

    Timer {
        id: relockTimer
        interval: 5000
        onTriggered: {
            if (lockscreen.visible) 
                outputPowerManager.mode = false;
        }
    }

    Lockscreen { id: lockscreen }
    SettingSheet { id: settingSheet }
    StatusArea { id: setting }
}
