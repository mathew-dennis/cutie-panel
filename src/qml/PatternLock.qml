import Cutie
import QtQuick

Item {
	id: patternLock

	property int gridSize: 3
	property real nodeRadius: 14
	property real hitRadius: 40
	property int minimumLength: 4
	signal patternEntered(string sequence)

	width: 280
	height: 280

	property var nodes: []
	property var visited: []
	property bool dragging: false
	property var _cursor: null

	Component.onCompleted: _layoutNodes()
	onWidthChanged: _layoutNodes()
	onHeightChanged: _layoutNodes()

	function _layoutNodes() {
		var list = [];
		var cellW = width / gridSize;
		var cellH = height / gridSize;
		for (var row = 0; row < gridSize; row++) {
			for (var col = 0; col < gridSize; col++) {
				list.push({
					x: cellW * col + cellW / 2,
					y: cellH * row + cellH / 2,
					index: row * gridSize + col
				});
			}
		}
		nodes = list;
	}

	function _nodeAt(px, py) {
		for (var i = 0; i < nodes.length; i++) {
			var n = nodes[i];
			var dx = n.x - px, dy = n.y - py;
			if (Math.sqrt(dx * dx + dy * dy) < hitRadius)
				return n;
		}
		return null;
	}

	function reset() {
		visited = [];
		dragging = false;
		canvas.requestPaint();
	}

	Canvas {
		id: canvas
		anchors.fill: parent

		onPaint: {
			var ctx = getContext("2d");
			ctx.reset();

			if (patternLock.visited.length > 0) {
				ctx.strokeStyle = Atmosphere.accentColor;
				ctx.lineWidth = 4;
				ctx.lineCap = "round";
				ctx.beginPath();
				var first = patternLock.nodes[patternLock.visited[0]];
				ctx.moveTo(first.x, first.y);
				for (var i = 1; i < patternLock.visited.length; i++) {
					var n = patternLock.nodes[patternLock.visited[i]];
					ctx.lineTo(n.x, n.y);
				}
				if (patternLock.dragging && patternLock._cursor)
					ctx.lineTo(patternLock._cursor.x, patternLock._cursor.y);
				ctx.stroke();
			}

			for (var j = 0; j < patternLock.nodes.length; j++) {
				var node = patternLock.nodes[j];
				var isVisited = patternLock.visited.indexOf(node.index) !== -1;
				ctx.beginPath();
				ctx.arc(node.x, node.y, patternLock.nodeRadius, 0, 2 * Math.PI);
				ctx.fillStyle = isVisited
					? Atmosphere.accentColor
					: Qt.rgba(1, 1, 1, 0.3);
				ctx.fill();
			}
		}
	}

	MouseArea {
		anchors.fill: parent

		onPressed: (mouse) => {
			var n = patternLock._nodeAt(mouse.x, mouse.y);
			patternLock.visited = n ? [n.index] : [];
			patternLock.dragging = true;
			canvas.requestPaint();
		}

		onPositionChanged: (mouse) => {
			if (!patternLock.dragging)
				return;
			patternLock._cursor = { x: mouse.x, y: mouse.y };
			var n = patternLock._nodeAt(mouse.x, mouse.y);
			if (n && patternLock.visited.indexOf(n.index) === -1)
				patternLock.visited = patternLock.visited.concat([n.index]);
			canvas.requestPaint();
		}

		onReleased: {
			patternLock.dragging = false;
			if (patternLock.visited.length >= patternLock.minimumLength)
				patternLock.patternEntered(patternLock.visited.join("-"));
			else
				patternLock.reset();
			canvas.requestPaint();
		}
	}
}
