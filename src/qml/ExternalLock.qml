import QtQuick

Item {
	width: parent ? parent.width : Screen.width
	height: parent ? parent.height : Screen.height

	Lockscreen {
		anchors.fill: parent
	}
}
