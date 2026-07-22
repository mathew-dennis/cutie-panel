import QtQuick
import Qt5Compat.GraphicalEffects
import Cutie
import Cutie.Wlc

Item {
	id: powerMenu
    width: Screen.width
    height: Screen.height + 1
	opacity: 0
	visible: opacity > 0
	z: 1000

	// "initial"        -> Restart + Power off side by side
	// "powerConfirm"   -> Power off centered, Restart hidden
	// "rebootExpanded" -> Restart centered, Power off hidden,
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

	// Reusable circular icon + label button. Only ever moves horizontally
	// (smoothly) - size and visibility just snap, keeping this simple.
	component MenuCircleButton: Item {
		id: btn
		property real diameter: 64
		property string label: ""
		property string iconName: ""
		signal clicked()

		width: diameter
		height: diameter + 24
		visible: opacity > 0.01

		Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
		Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }

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
				visible: false
			}

			// Same technique StatusArea.qml uses for the wifi/modem/battery
			// icons: mask a flat color rect with the icon's alpha, so it
			// automatically follows the theme (black on light, white on dark).
			Rectangle {
				id: iconMask
				anchors.fill: icon
				visible: false
				color: Atmosphere.textColor

				Behavior on color {
					ColorAnimation { duration: 500; easing.type: Easing.InOutQuad }
				}
			}

			OpacityMask {
				anchors.fill: icon
				source: iconMask
				maskSource: icon
			}

			MouseArea {
				anchors.fill: parent
				onClicked: btn.clicked()
			}
		}

		Text {
			anchors.top: circle.bottom
			anchors.topMargin: 6
			anchors.horizontalCenter: circle.horizontalCenter
			width: Math.max(btn.diameter + 40, 80)
			text: btn.label
			color: Atmosphere.textColor
			font.pixelSize: 11
			horizontalAlignment: Text.AlignHCenter
		}
	}

	// Floating card containing the whole menu, tinted with the theme's
	// primary color, padded away from the screen edges.
	Rectangle {
		id: card
		width: Math.min(buttonsArea.width + 64, powerMenu.width - 64)
		height: buttonsArea.height + 48
		radius: 28
		anchors.centerIn: parent
		color: Atmosphere.primaryColor
		opacity: 0.92
        border.width: 1
		border.color: Atmosphere.textColor

		Behavior on color {
			ColorAnimation { duration: 500; easing.type: Easing.InOutQuad }
		}
	}

	Item {
		id: buttonsArea
		width: 260
		height: 130
		anchors.centerIn: card

		readonly property real normalSize: 64
		readonly property real sideSize: 48
		readonly property real gap: 18
		readonly property real rowCenterY: height / 2
		readonly property real pairStartX: width / 2 - (normalSize * 2 + gap) / 2
		readonly property real centerX: width / 2 - normalSize / 2
		readonly property real recoveryX: centerX - gap - sideSize
		readonly property real bootloaderX: centerX + normalSize + gap

		MenuCircleButton {
			id: rebootBtn
			diameter: buttonsArea.normalSize
			iconName: "image://icon/system-reboot-symbolic"
			label: powerMenu.menuState === "rebootExpanded" ? qsTr("Tap to reboot") : qsTr("Restart")
			opacity: powerMenu.menuState === "powerConfirm" ? 0 : 1
			x: powerMenu.menuState === "rebootExpanded" ? buttonsArea.centerX : buttonsArea.pairStartX
			y: buttonsArea.rowCenterY - diameter / 2

			onClicked: {
				if (powerMenu.menuState === "initial") {
					powerMenu.menuState = "rebootExpanded";
				} else if (powerMenu.menuState === "rebootExpanded") {
					powerMenu.hide();
					cutieWlc.execApp(reboot recovery);
				}
			}
		}

		MenuCircleButton {
			id: powerBtn
			diameter: buttonsArea.normalSize
			iconName: "image://icon/system-shutdown-symbolic"
			label: powerMenu.menuState === "powerConfirm" ? qsTr("Tap to power off") : qsTr("Power off")
			opacity: powerMenu.menuState === "rebootExpanded" ? 0 : 1
			x: powerMenu.menuState === "powerConfirm" ? buttonsArea.centerX : buttonsArea.pairStartX + buttonsArea.normalSize + buttonsArea.gap
			y: buttonsArea.rowCenterY - diameter / 2

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
			x: buttonsArea.recoveryX
			y: buttonsArea.rowCenterY - diameter / 2

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
			x: buttonsArea.bootloaderX
			y: buttonsArea.rowCenterY - diameter / 2

			onClicked: {
				powerMenu.hide();
				quicksettings.RebootToBootloader();
			}
		}
	}
}
