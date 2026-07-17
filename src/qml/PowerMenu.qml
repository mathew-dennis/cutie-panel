import QtQuick
import Cutie

Item {
	id: powerMenu

	anchors.fill: parent
	opacity: 0
	visible: opacity > 0
	z: 1000

	function show() {
		opacity = 1;
	}

	function hide() {
		opacity = 0;
	}

	Behavior on opacity {
		NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
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
		color: Atmosphere.backgroundColor
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
