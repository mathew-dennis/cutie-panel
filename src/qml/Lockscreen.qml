import Cutie
import Cutie.ScreenLock
import QtQuick
import QtQuick.Controls
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
	id: lockscreen
    visible: true
    width: Screen.width
    height: Screen.height + 1

	CutieScreenLock {
		id: lockAuth
	}

	function timeChanged() {
        lockscreenTime.text = Qt.formatDateTime(new Date(), "HH:mm");
        lockscreenDate.text = Qt.formatDateTime(new Date(), "dddd, MMMM d");
    }

	// Swiping up used to unlock directly. Now it only unlocks directly when
	// no credential is configured; otherwise it reveals the auth sheet.
	function requestUnlock() {
		if (lockAuth.method === "none") {
			openAnim.start();
			return;
		}
		// closeAnim.start();
		authOverlay.visible = true;
		authOverlay.opacity = 1;
		if (lockAuth.method === "password")
			passwordField.forceActiveFocus();
	}

	function onAuthSuccess() {
		pinPad.reset();
		patternLock.reset();
		passwordField.text = "";
		authOverlay.visible = false;
		authOverlay.opacity = 0;
		openAnim.start();
	}

	function onAuthFailure() {
		shakeAnim.start();
		pinPad.reset();
		patternLock.reset();
		passwordField.text = "";
	}

	Connections {
		target: lockAuth
		function onUnlocked() { lockscreen.onAuthSuccess(); }
		function onPasswordAuthResult(success, error) {
			if (success) lockscreen.onAuthSuccess();
			else lockscreen.onAuthFailure();
		}
	}

	NumberAnimation {
		id: openAnim
		target: lockscreen
		property: "opacity"
		to: 0

		onFinished: {
            settingsState.height = setting.height;
			lockscreen.visible = false;
		}
	}

	NumberAnimation {
		id: closeAnim
		target: lockscreen
		property: "opacity"
		to: 1
	}

    Image {
        id: wallpaper
		width: Screen.width
		height: Screen.height
        source: "file:/" + Atmosphere.path + "/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
    }

	Item {
		id: mouseWrapper
		width: Screen.width
		height: Screen.height
		visible: !authOverlay.visible

		MouseArea { 
			id: lockscreenMouseArea
			drag.target: mouseWrapper
			drag.axis: Drag.YAxis
			drag.minimumY: -mouseWrapper.height; drag.maximumY: 0
			anchors.fill: parent

			onReleased: {
				if (parent.y < - 20) lockscreen.requestUnlock();
				else closeAnim.start();
				parent.y = 0;
			}

			onPositionChanged: {
				if (drag.active)
					lockscreen.opacity = 1 + mouseWrapper.y / Screen.height;
			}
		}
	}

    CutieLabel { 
        id: lockscreenTime
        text: Qt.formatDateTime(new Date(), "HH:mm")
        font.pixelSize: 72
        font.weight: Font.Light
        visible: !authOverlay.visible

        anchors { 
            horizontalCenter: parent.horizontalCenter
            top: parent.top; 
            topMargin: 150
        }

        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 2
            color: Atmosphere.accentColor
            radius: 2
            samples: 3
        }
    }

    CutieLabel { 
        id: lockscreenDate
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        font.pixelSize: 20
        font.weight: Font.Black
        visible: !authOverlay.visible

        anchors { 
            horizontalCenter: parent.horizontalCenter
            top: lockscreenTime.bottom; 
            topMargin: 5
        }

        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 2
            color: Atmosphere.accentColor
            radius: 5
            samples: 10
			opacity: 1/3
        }
    }

	// --- Authentication sheet -----------------------------------------
	Rectangle {
		id: authOverlay
		anchors.fill: parent
		color: Qt.rgba(0, 0, 0, 0.55)
		opacity: 0
		visible: false

		Behavior on opacity { NumberAnimation { duration: 200 } }

		// Eat clicks so they don't fall through to the swipe MouseArea.
		MouseArea { anchors.fill: parent }

		SequentialAnimation {
			id: shakeAnim
			NumberAnimation { target: authCard; property: "anchors.horizontalCenterOffset"; to: -20; duration: 50 }
			NumberAnimation { target: authCard; property: "anchors.horizontalCenterOffset"; to: 20; duration: 50 }
			NumberAnimation { target: authCard; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
			NumberAnimation { target: authCard; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
		}

		Column {
			id: authCard
			anchors.bottom: parent.bottom          
			anchors.bottomMargin: 40             
			anchors.horizontalCenter: parent.horizontalCenter 
			spacing: 24

			CutieLabel {
				anchors.horizontalCenter: parent.horizontalCenter
				text: lockAuth.lockoutSecondsRemaining > 0
					  ? qsTr("Try again in %1s").arg(lockAuth.lockoutSecondsRemaining)
					  : (lockAuth.authenticating
						 ? qsTr("Checking\u2026")
						 : qsTr("Enter your %1").arg(lockAuth.method))
				font.pixelSize: 18
				font.family: "Lato"
			}

			PinPad {
				id: pinPad
				anchors.horizontalCenter: parent.horizontalCenter
				visible: lockAuth.method === "pin"
				enabled: lockAuth.lockoutSecondsRemaining === 0
				onPinEntered: (pin) => {
					if (!lockAuth.verifyPin(pin))
						lockscreen.onAuthFailure();
				}
			}

			PatternLock {
				id: patternLock
				anchors.horizontalCenter: parent.horizontalCenter
				visible: lockAuth.method === "pattern"
				enabled: lockAuth.lockoutSecondsRemaining === 0
				onPatternEntered: (sequence) => {
					if (!lockAuth.verifyPattern(sequence))
						lockscreen.onAuthFailure();
				}
			}

			TextField {
				id: passwordField
				visible: lockAuth.method === "password"
				echoMode: TextInput.Password
				enabled: lockAuth.lockoutSecondsRemaining === 0 && !lockAuth.authenticating
				width: 220
				font.family: "Lato"
				anchors.horizontalCenter: parent.horizontalCenter
				onAccepted: lockAuth.authenticatePassword(text)
			}
		}
	}

    Timer {
        interval: 100; running: true; repeat: true;
        onTriggered: timeChanged()
    }
}
