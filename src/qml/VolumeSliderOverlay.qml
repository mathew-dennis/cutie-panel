import QtQuick
import QtQuick.Controls
import Cutie
import Cutie.Volume

Item {
	id: volumeSliderOverlay

	width: 64
	height: 220
	anchors.right: parent.right
	anchors.rightMargin: 14
	anchors.verticalCenter: parent.verticalCenter
	opacity: 0
	visible: opacity > 0

	// Call this whenever a volume key is pressed
	function show() {
		// The panel surface is shrunk to just the status-bar strip while
		// unlocked (see Lockscreen.qml); grow it back so this popup, which
		// is vertically centered on the full screen, has room to render.
		if (!lockscreen.visible)
			settingsState.height = Screen.height + 1;
		hideTimer.restart();
		opacity = 1;
	}

	Behavior on opacity {
		NumberAnimation {
			duration: 200
			easing.type: Easing.InOutQuad
			onRunningChanged: {
				// Shrink the surface back down once we've fully faded out,
				// but only if nothing else (e.g. the lockscreen) needs it.
				if (!running && volumeSliderOverlay.opacity === 0 && !lockscreen.visible)
					settingsState.height = setting.height;
			}
		}
	}

	Timer {
		id: hideTimer
		interval: 1500
		onTriggered: volumeSliderOverlay.opacity = 0
	}

	Rectangle {
		id: box
		anchors.fill: parent
		radius: 22
		color: Atmosphere.primaryColor
		opacity: 0.92
		border.width: 1
		border.color: Atmosphere.textColor
	}

	CutieSlider {
		id: volSlider
		orientation: Qt.Vertical
		from: 0.0
		to: 1.0
		value: CutieVolume.volume
		live: true

		anchors.top: parent.top
		anchors.bottom: percentLabel.top
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.topMargin: 14
		anchors.bottomMargin: 8

		onMoved: {
			CutieVolume.volume = value;
			hideTimer.restart();
		}

		Connections {
			target: CutieVolume
			function onVolumeChanged(vol) {
				volSlider.value = vol;
			}
		}
	}

	Text {
		id: percentLabel
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 12
		anchors.horizontalCenter: parent.horizontalCenter
		color: Atmosphere.textColor
		font.pixelSize: 15
		font.bold: true
		text: Math.round(CutieVolume.volume * 100)
	}
}
