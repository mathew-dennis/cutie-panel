import QtQuick
import Cutie

Item {
	id: powerMenu
    width: Screen.width
    height: Screen.height + 1
	opacity: 0
	visible: opacity > 0
	z: 1000

	function show() {
		// The panel surface is shrunk to just the status-bar strip while
		// unlocked (see Lockscreen.qml); grow it back so this full-screen
		// menu has room to render.
		if (!lockscreen.visible)
			settingsState.height = Screen.height + 1;
		opacity = 1;
	}

	function hide() {
		opacity = 0;
	}

	Behavior on opacity {
		NumberAnimation {
			duration: 180
			easing.type: Easing.InOutQuad
			onRunningChanged: {
				// Shrink the surface back down once we've fully faded out,
				// but only if nothing else (e.g. the lockscreen) needs it.
				if (!running && powerMenu.opacity === 0 && !lockscreen.visible)
					settingsState.height = setting.height;
			}
		}
	}

	// Dimmed backdrop; tapping it cancels
	Rectangle {
		anchors.fill: parent
		color: "black"
		opacity: 0.55

		MouseArea {
			anchors.fill: parent
			onClicked: powerMenu.hide()
		}
	}

	Rectangle {
		id: card
		width: Math.min(parent.width * 0.72, 320)
		height: column.implicitHeight + 32
		anchors.centerIn: parent
		radius: 24
		color: Atmosphere.primaryColor
		border.width: 1
		border.color: Atmosphere.textColor

		// Absorb clicks so they don't fall through to the backdrop
		MouseArea {
			anchors.fill: parent
		}

		Column {
			id: column
			anchors.centerIn: parent
			width: parent.width - 32
			spacing: 10

			Text {
				width: parent.width
				text: qsTr("Power")
				color: Atmosphere.textColor
				font.pixelSize: 16
				font.bold: true
				horizontalAlignment: Text.AlignHCenter
				bottomPadding: 6
			}

			Rectangle {
				width: parent.width
				height: 46
				radius: 14
				color: Atmosphere.accentColor

				Text {
					anchors.centerIn: parent
					text: qsTr("Restart")
					color: "white"
					font.pixelSize: 15
					font.bold: true
				}

				MouseArea {
					anchors.fill: parent
					onClicked: {
						powerMenu.hide();
						quicksettings.Reboot();
					}
				}
			}

			Rectangle {
				width: parent.width
				height: 46
				radius: 14
				color: "#d64545"

				Text {
					anchors.centerIn: parent
					text: qsTr("Power off")
					color: "white"
					font.pixelSize: 15
					font.bold: true
				}

				MouseArea {
					anchors.fill: parent
					onClicked: {
						powerMenu.hide();
						quicksettings.PowerOff();
					}
				}
			}

			Rectangle {
				width: parent.width
				height: 46
				radius: 14
				color: "transparent"
				border.width: 1
				border.color: Atmosphere.textColor

				Text {
					anchors.centerIn: parent
					text: qsTr("Cancel")
					color: Atmosphere.textColor
					font.pixelSize: 15
				}

				MouseArea {
					anchors.fill: parent
					onClicked: powerMenu.hide()
				}
			}
		}
	}
}
