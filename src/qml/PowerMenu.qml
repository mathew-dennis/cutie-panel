import QtQuick
import Cutie

Item {
	id: powerMenu
    width: Screen.width
    height: Screen.height + 1
	opacity: 0
	visible: opacity > 0
	z: 1000

	// "initial"        -> Restart + Power off side by side
	// "powerConfirm"   -> Power off grown & centered, Restart hidden
	// "rebootExpanded" -> Restart grown & centered, Power off hidden,
	//                     Recovery + Bootloader appear on either side
	property string menuState: "initial"

	function show() {
		menuState = "initial";
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

	// Reusable circular icon + label button
	component MenuCircleButton: Item {
		id: btn
		property real diameter: 84
		property string label: ""
		property string iconName: ""
		signal clicked()

		width: diameter
		height: diameter + 28
		visible: opacity > 0.01

		Behavior on diameter { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
		Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
		Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }

		Rectangle {
			id: circle
			width: btn.diameter
			height: btn.diameter
			radius: width / 2
			color: Atmosphere.secondaryAlphaColor
			border.width: 1.5
			border.color: Atmosphere.textColor

			Image {
				id: icon
				anchors.centerIn: parent
				width: circle.width * 0.4
				height: width
				source: btn.iconName
				sourceSize.width: width * 2
				sourceSize.height: height * 2
			}

			MouseArea {
				anchors.fill: parent
				onClicked: btn.clicked()
			}
		}

		Text {
			anchors.top: circle.bottom
			anchors.topMargin: 8
			anchors.horizontalCenter: circle.horizontalCenter
			width: Math.max(btn.diameter + 50, 96)
			text: btn.label
			color: Atmosphere.textColor
			font.pixelSize: 12
			horizontalAlignment: Text.AlignHCenter
		}
	}

	Item {
		id: buttonsArea
		width: 320
		height: 180
		anchors.centerIn: parent

		readonly property real normalSize: 84
		readonly property real bigSize: 112
		readonly property real sideSize: 64
		readonly property real gap: 26
		readonly property real pairStartX: width / 2 - (normalSize * 2 + gap) / 2

		MenuCircleButton {
			id: rebootBtn
			diameter: powerMenu.menuState === "rebootExpanded" ? buttonsArea.bigSize : buttonsArea.normalSize
			iconName: "image://icon/system-reboot-symbolic"
			label: powerMenu.menuState === "rebootExpanded" ? qsTr("Tap to reboot") : qsTr("Restart")
			opacity: powerMenu.menuState === "powerConfirm" ? 0 : 1
			x: powerMenu.menuState === "rebootExpanded"
			   ? buttonsArea.width / 2 - diameter / 2
			   : buttonsArea.pairStartX
			y: buttonsArea.height / 2 - diameter / 2 - 14

			onClicked: {
				if (powerMenu.menuState === "initial") {
					powerMenu.menuState = "rebootExpanded";
				} else if (powerMenu.menuState === "rebootExpanded") {
					powerMenu.hide();
					quicksettings.Reboot();
				}
			}
		}

		MenuCircleButton {
			id: powerBtn
			diameter: powerMenu.menuState === "powerConfirm" ? buttonsArea.bigSize : buttonsArea.normalSize
			iconName: "image://icon/system-shutdown-symbolic"
			label: powerMenu.menuState === "powerConfirm" ? qsTr("Tap to power off") : qsTr("Power off")
			opacity: powerMenu.menuState === "rebootExpanded" ? 0 : 1
			x: powerMenu.menuState === "powerConfirm"
			   ? buttonsArea.width / 2 - diameter / 2
			   : buttonsArea.pairStartX + buttonsArea.normalSize + buttonsArea.gap
			y: buttonsArea.height / 2 - diameter / 2 - 14

			onClicked: {
				if (powerMenu.menuState === "initial") {
					powerMenu.menuState = "powerConfirm";
				} else if (powerMenu.menuState === "powerConfirm") {
					powerMenu.hide();
					quicksettings.PowerOff();
				}
			}
		}

		MenuCircleButton {
			id: recoveryBtn
			diameter: buttonsArea.sideSize
			iconName: "image://icon/drive-harddisk-symbolic"
			label: qsTr("Recovery")
			opacity: powerMenu.menuState === "rebootExpanded" ? 1 : 0
			x: buttonsArea.width / 2 - buttonsArea.bigSize / 2 - buttonsArea.gap - diameter
			y: buttonsArea.height / 2 - diameter / 2 - 14

			onClicked: {
				powerMenu.hide();
				quicksettings.RebootToRecovery();
			}
		}

		MenuCircleButton {
			id: bootloaderBtn
			diameter: buttonsArea.sideSize
			iconName: "image://icon/media-flash-symbolic"
			label: qsTr("Bootloader")
			opacity: powerMenu.menuState === "rebootExpanded" ? 1 : 0
			x: buttonsArea.width / 2 + buttonsArea.bigSize / 2 + buttonsArea.gap
			y: buttonsArea.height / 2 - diameter / 2 - 14

			onClicked: {
				powerMenu.hide();
				quicksettings.RebootToBootloader();
			}
		}
	}
}