import QtQuick
import Qt5Compat.GraphicalEffects
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
		buttonsArea.apply("initial", false);
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

		// Animates to a new position/size/opacity, moving into place first
		// and only growing/shrinking once the move has finished.
		function animateTo(newX, newDiameter, newOpacity) {
			moveGrowAnim.stop();
			moveGrowAnim.targetX = newX;
			moveGrowAnim.targetDiameter = newDiameter;
			moveGrowAnim.targetOpacity = newOpacity;
			moveGrowAnim.start();
		}

		// Jumps straight to a position/size/opacity with no animation,
		// used when the menu is (re)opened.
		function snapTo(newX, newDiameter, newOpacity) {
			moveGrowAnim.stop();
			x = newX;
			diameter = newDiameter;
			opacity = newOpacity;
		}

		SequentialAnimation {
			id: moveGrowAnim
			property real targetX: btn.x
			property real targetDiameter: btn.diameter
			property real targetOpacity: btn.opacity

			ParallelAnimation {
				NumberAnimation { target: btn; property: "x"; to: moveGrowAnim.targetX; duration: 260; easing.type: Easing.InOutCubic }
				NumberAnimation { target: btn; property: "opacity"; to: moveGrowAnim.targetOpacity; duration: 220; easing.type: Easing.InOutCubic }
			}
			NumberAnimation { target: btn; property: "diameter"; to: moveGrowAnim.targetDiameter; duration: 220; easing.type: Easing.InOutCubic }
		}

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
			anchors.topMargin: 8
			anchors.horizontalCenter: circle.horizontalCenter
			width: Math.max(btn.diameter + 50, 96)
			text: btn.label
			color: Atmosphere.textColor
			font.pixelSize: 12
			horizontalAlignment: Text.AlignHCenter
		}
	}

	// Card containing the whole menu, with a frosted-glass blur of the
	// real wallpaper behind it (like the very first prototype's card).
	Rectangle {
		id: card
		width: buttonsArea.width + 48
		height: buttonsArea.height + 48
		radius: 32
		anchors.centerIn: parent
		color: "transparent"
		border.width: 1
		border.color: Qt.rgba(1, 1, 1, 0.15)
		clip: true

		ShaderEffectSource {
			id: blurSource
			sourceItem: lockscreen.wallpaper
			sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
			live: true
			hideSource: false
		}

		FastBlur {
			anchors.fill: parent
			source: blurSource
			radius: 48
		}

		Rectangle {
			// Frosted tint over the blurred wallpaper
			anchors.fill: parent
			color: Atmosphere.secondaryAlphaColor
		}
	}

	Item {
		id: buttonsArea
		width: 320
		height: 180
		anchors.centerIn: card
		// Buttons keep their vertical center fixed as they grow/shrink.
		readonly property real rowCenterY: height / 2 - 14

		readonly property real normalSize: 84
		readonly property real bigSize: 112
		readonly property real sideSize: 64
		readonly property real gap: 26
		readonly property real pairStartX: width / 2 - (normalSize * 2 + gap) / 2
		readonly property real centerBigX: width / 2 - bigSize / 2
		readonly property real recoveryX: centerBigX - gap - sideSize
		readonly property real bootloaderX: centerBigX + bigSize + gap

		// Drives every button to the correct position/size/opacity for a
		// given menu state; used both to animate on click and to snap
		// instantly when the menu (re)opens.
		function apply(state, animated) {
			const rebootX = state === "rebootExpanded" ? centerBigX : pairStartX;
			const rebootD = state === "rebootExpanded" ? bigSize : normalSize;
			const rebootO = state === "powerConfirm" ? 0 : 1;
			const rebootLabel = state === "rebootExpanded" ? qsTr("Tap to reboot") : qsTr("Restart");

			const powerX = state === "powerConfirm" ? centerBigX : pairStartX + normalSize + gap;
			const powerD = state === "powerConfirm" ? bigSize : normalSize;
			const powerO = state === "rebootExpanded" ? 0 : 1;
			const powerLabel = state === "powerConfirm" ? qsTr("Tap to power off") : qsTr("Power off");

			const sideO = state === "rebootExpanded" ? 1 : 0;

			rebootBtn.label = rebootLabel;
			powerBtn.label = powerLabel;

			if (animated) {
				rebootBtn.animateTo(rebootX, rebootD, rebootO);
				powerBtn.animateTo(powerX, powerD, powerO);
				recoveryBtn.animateTo(recoveryX, sideSize, sideO);
				bootloaderBtn.animateTo(bootloaderX, sideSize, sideO);
			} else {
				rebootBtn.snapTo(rebootX, rebootD, rebootO);
				powerBtn.snapTo(powerX, powerD, powerO);
				recoveryBtn.snapTo(recoveryX, sideSize, sideO);
				bootloaderBtn.snapTo(bootloaderX, sideSize, sideO);
			}
		}

		MenuCircleButton {
			id: rebootBtn
			iconName: "image://icon/system-reboot-symbolic"
			label: qsTr("Restart")
			y: buttonsArea.rowCenterY - diameter / 2

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
			iconName: "image://icon/system-shutdown-symbolic"
			label: qsTr("Power off")
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
			iconName: "image://icon/drive-harddisk-symbolic"
			label: qsTr("Recovery")
			y: buttonsArea.rowCenterY - diameter / 2

			onClicked: {
				powerMenu.hide();
				quicksettings.RebootToRecovery();
			}
		}

		MenuCircleButton {
			id: bootloaderBtn
			iconName: "image://icon/media-flash-symbolic"
			label: qsTr("Bootloader")
			y: buttonsArea.rowCenterY - diameter / 2

			onClicked: {
				powerMenu.hide();
				quicksettings.RebootToBootloader();
			}
		}

		Connections {
			target: powerMenu
			function onMenuStateChanged() {
				buttonsArea.apply(powerMenu.menuState, true);
			}
		}
	}
}
