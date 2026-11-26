import QtQuick
import Cutie

// Content of the window created per external screen (see external-screen.cpp):
// a thin status bar, plus an independent Lockscreen (which owns its wallpaper,
// ParticleEffects, clock, and unlock UI).
Item {
	id: settingsState

	property bool screenOn: true
	property date now: new Date()

	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: settingsState.now = new Date()
	}

	Lockscreen {
		id: lockscreen
		objectName: "lockscreen"
	}

	Rectangle {
		id: setting
		anchors { top: parent.top; left: parent.left; right: parent.right }
		height: 30
		color: Atmosphere.secondaryAlphaColor

		Text {
			anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
			text: Qt.formatDateTime(settingsState.now, "ddd, MMM d")
			color: Atmosphere.textColor
			font.pixelSize: 12
			font.family: "Lato"
		}

		Row {
			anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
			spacing: 12

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: Qt.formatDateTime(settingsState.now, "HH:mm") + "  \u00b7  " + Math.floor(batteryStatus.Percentage) + " %"
				color: Atmosphere.textColor
				font.pixelSize: 12
				font.family: "Lato"
			}

			Text {
				visible: !lockscreen.visible
				anchors.verticalCenter: parent.verticalCenter
				text: qsTr("Lock")
				color: Atmosphere.textColor
				font.pixelSize: 12
				font.family: "Lato"

				MouseArea {
					anchors.fill: parent
					anchors.margins: -6
					onClicked: {
						lockscreen.opacity = 1;
						lockscreen.visible = true;
					}
				}
			}
		}
	}
}
