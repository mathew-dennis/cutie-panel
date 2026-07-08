import Cutie
import QtQuick

Item {
	id: pinPad

	property int pinLength: 0
	property int requiredLength: 4
	property int maxPinLength: 8
	signal pinEntered(string pin)

	property string _pin: ""

	width: grid.width
	height: dotsRow.height + grid.height + 30

	function reset() {
		_pin = "";
		pinLength = 0;
	}

	function _append(digit) {
		if (_pin.length >= maxPinLength)
			return;
		_pin += digit;
		pinLength = _pin.length;
		if (pinLength === requiredLength) {
			pinPad.pinEntered(_pin);
		}
	}

	function _backspace() {
		if (_pin.length === 0)
			return;
		_pin = _pin.slice(0, -1);
		pinLength = _pin.length;
	}

	Row {
		id: dotsRow
		anchors.horizontalCenter: parent.horizontalCenter
		spacing: 16

		Repeater {
			model: pinPad.requiredLength
			Rectangle {
				width: 14; height: 14; radius: 7
				color: index < pinPad.pinLength
					   ? Atmosphere.accentColor
					   : Qt.rgba(1, 1, 1, 0.25)
				Behavior on color { ColorAnimation { duration: 150 } }
			}
		}
	}

	Grid {
		id: grid
		anchors.top: dotsRow.bottom
		anchors.topMargin: 30
		anchors.horizontalCenter: parent.horizontalCenter
		columns: 3
		spacing: 18

		Repeater {
			model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]

			Rectangle {
				width: 70; height: 70; radius: 35
				color: keyArea.pressed
					   ? Atmosphere.secondaryAlphaLightColor
					   : "transparent"
				Behavior on color { ColorAnimation { duration: 150 } }

				CutieLabel {
					anchors.centerIn: parent
					text: modelData
					font.pixelSize: 26
					visible: modelData !== ""
				}

				MouseArea {
					id: keyArea
					anchors.fill: parent
					enabled: modelData !== ""
					onClicked: {
						if (modelData === "⌫")
							pinPad._backspace();
						else
							pinPad._append(modelData);
					}
				}
			}
		}
	}
}
