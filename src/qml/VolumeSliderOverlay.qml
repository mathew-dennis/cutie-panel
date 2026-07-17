import QtQuick
import QtQuick.Controls
import Cutie
import Cutie.Volume

Item {
	id: volumeSliderOverlay

	width: 64
	height: 220
	anchors.left: parent.left
	anchors.leftMargin: 14
	anchors.verticalCenter: parent.verticalCenter
	opacity: 0
	visible: opacity > 0

	// Call this whenever a volume key is pressed
	function show() {
		hideTimer.restart();
		opacity = 1;
	}

	Behavior on opacity {
		NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
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
		color: Atmosphere.backgroundColor
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
