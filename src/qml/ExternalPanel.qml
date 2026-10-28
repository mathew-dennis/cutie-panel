import QtQuick
import Cutie

Rectangle {
	id: root
	width: parent ? parent.width : Screen.width
	height: 36
	color: Atmosphere.secondaryAlphaColor

	Text {
		anchors.left: parent.left
		anchors.leftMargin: 16
		anchors.verticalCenter: parent.verticalCenter
		text: Qt.formatDateTime(new Date(), "ddd, MMM d")
		color: Atmosphere.textColor
		font.pixelSize: 14
	}

	Text {
		id: clock
		anchors.right: parent.right
		anchors.rightMargin: 16
		anchors.verticalCenter: parent.verticalCenter
		text: Qt.formatDateTime(new Date(), "HH:mm") + "  ·  " +
			Math.floor(batteryStatus.Percentage) + "%"
		color: Atmosphere.textColor
		font.pixelSize: 14

		Timer {
			interval: 30000
			running: true
			repeat: true
				onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm") +
						"  ·  " + Math.floor(batteryStatus.Percentage) + "%"
		}
	}
}
