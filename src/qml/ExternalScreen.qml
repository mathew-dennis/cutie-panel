import QtQuick
import Cutie

// Content of the window created per external screen (see external-screen.cpp):
// a thin status bar, plus a wallpaper cover while the lockscreen is up.
Item {
	id: root

	// Set from external-screen.cpp.
	property bool locked: false
	property date now: new Date()

	Timer {
		interval: 1000
		running: true
		repeat: true
		onTriggered: root.now = new Date()
	}

	Loader {
		anchors.fill: parent
		active: root.locked

		sourceComponent: Item {
			Image {
				anchors.fill: parent
				source: "file:/" + Atmosphere.path + "/wallpaper.jpg"
				fillMode: Image.PreserveAspectCrop
			}

			ParticleEffects {
				anchors.fill: parent
				effect: Atmosphere.particleEffects
				sprite: Atmosphere.particleSprite(Atmosphere.particleEffects)
			}

			CutieLabel {
				id: time
				text: Qt.formatDateTime(root.now, "HH:mm")
				font.pixelSize: 72
				font.weight: Font.Light
				anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 150 }
			}

			CutieLabel {
				text: Qt.formatDateTime(root.now, "dddd, MMMM d")
				font.pixelSize: 20
				font.weight: Font.Black
				anchors { horizontalCenter: parent.horizontalCenter; top: time.bottom; topMargin: 5 }
			}
		}
	}

	Rectangle {
		anchors { top: parent.top; left: parent.left; right: parent.right }
		height: 30
		color: Atmosphere.secondaryAlphaColor

		Text {
			anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
			text: Qt.formatDateTime(root.now, "ddd, MMM d")
			color: Atmosphere.textColor
			font.pixelSize: 12
			font.family: "Lato"
		}

		Text {
			anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
			text: Qt.formatDateTime(root.now, "HH:mm") + "  \u00b7  " + Math.floor(batteryStatus.Percentage) + " %"
			color: Atmosphere.textColor
			font.pixelSize: 12
			font.family: "Lato"
		}
	}
}
