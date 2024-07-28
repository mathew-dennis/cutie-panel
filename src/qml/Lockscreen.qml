import Cutie
import QtQuick
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
	id: lockscreen
    visible: true
    width: Screen.width
    height: Screen.height + 1

	function timeChanged() {
        lockscreenTime.text = Qt.formatDateTime(new Date(), "HH:mm");
        lockscreenDate.text = Qt.formatDateTime(new Date(), "dddd, MMMM d");
    }

	NumberAnimation {
		id: openAnim
		target: lockscreen
		property: "opacity"
		to: 0

		onFinished: {
            settingsState.height = setting.height;
			lockscreen.visible = false;
		}
	}

	NumberAnimation {
		id: closeAnim
		target: lockscreen
		property: "opacity"
		to: 1
	}

    Image {
        id: wallpaper
		width: Screen.width
		height: Screen.height
        source: "file:/" + Atmosphere.path + "/wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
    }

	Item {
		id: mouseWrapper
		width: Screen.width
		height: Screen.height

		MouseArea { 
			id: lockscreenMouseArea
			drag.target: mouseWrapper
			drag.axis: Drag.YAxis
			drag.minimumY: -mouseWrapper.height; drag.maximumY: 0
			anchors.fill: parent

			onReleased: {
				if (parent.y < - 20) openAnim.start();
				else closeAnim.start();
				parent.y = 0;
			}

			onPositionChanged: {
				if (drag.active)
					lockscreen.opacity = 1 + mouseWrapper.y / Screen.height;
			}
		}
	}

	CutieLabel { 
        id: lockscreenTime
        text: Qt.formatDateTime(new Date(), "HH:mm")
        font.pixelSize: 72
        font.weight: Font.Light

        anchors { 
            horizontalCenter: parent.horizontalCenter
            top: parent.top; 
            topMargin: 150
        }

        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 2
            color: Atmosphere.textColor
            radius: 2
            samples: 3
        }
    }

    CutieLabel { 
        id: lockscreenDate
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        font.pixelSize: 20
        font.weight: Font.Black

        anchors { 
            horizontalCenter: parent.horizontalCenter
            top: lockscreenTime.bottom; 
            topMargin: 5
        }

        layer.enabled: true
        layer.effect: DropShadow {
            verticalOffset: 2
            color: Atmosphere.textColor
            radius: 5
            samples: 10
			opacity: 1/3
        }
    }

    Timer {
        interval: 100; running: true; repeat: true;
        onTriggered: timeChanged()
    }
}
