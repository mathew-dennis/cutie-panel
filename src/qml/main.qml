import QtQuick
import Cutie.Wlc
import Cutie.Volume

Item {
	id: settingsState

	width: Screen.width
	height: Screen.height + 1
    property bool ignoreRelease: false

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

		
		
		onKey: (key) => {
            if (key == CutieWlc.VolumeUpPress) {
				CutieVolume.volume = Math.min(1.0, CutieVolume.volume + 0.1);
				volumeSliderOverlay.show();
			}

           	if (key ==  CutieWlc.VolumeDownPress) {
                 		CutieVolume.volume = Math.max(0.0, CutieVolume.volume - 0.1);
				volumeSliderOverlay.show();
			}

			if (longPressTimer.running)
				longPressTimer.stop();

			if (ignoreRelease) {
				ignoreRelease = false;
				return;
			}

			if (key == CutieWlc.PowerPress && !outputPowerManager.mode) {
				setScreenOn(true);
				ignoreRelease = true;
				relockTimer.start();

			} else if (key == CutieWlc.PowerPress && outputPowerManager.mode) {
				longPressTimer.start();

			} else if (key == CutieWlc.PowerRelease && outputPowerManager.mode) {
				setScreenOn(false);
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

	// True while the phone display is on. Starts true and only follows
	// mode changes, so timers/particles keep running if no change arrives.
	property bool screenOn: true

	// Every place the panel itself turns the display on or off goes through
	// here, so screenOn follows even if the power manager never emits
	// modeChanged.
	function setScreenOn(on) {
		outputPowerManager.mode = on;
		screenOn = on;
		console.log("cutie-panel: screen", on ? "on" : "off", "(requested by panel)");
	}
	Connections {
		target: outputPowerManager
		function onModeChanged() {
			settingsState.screenOn = outputPowerManager.mode;
			console.log("cutie-panel: output power mode signal received, mode =",
				    outputPowerManager.mode, "-> screenOn =", settingsState.screenOn);
		}
	}

	Timer {
		id: longPressTimer
		interval: 500
		onTriggered: {
			powerMenu.show();
			ignoreRelease = true;
		}
	}
		Timer {
		id: relockTimer
		interval: 5000
		onTriggered: {
			if (lockscreen.visible) 
				setScreenOn(false);
		}
	}

    PowerMenu { id: powerMenu }
	VolumeSliderOverlay { id: volumeSliderOverlay }
	Lockscreen { id: lockscreen; objectName: "lockscreen" }
	SettingSheet { id: settingSheet }
	StatusArea { id: setting }
	}
