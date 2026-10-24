import QtQuick
import QtQuick.Particles

// Lockscreen particle effect. `effect` is the "particle-effects" key of the
// active atmosphere's settings.ini ("none" or unknown = nothing is shown) and
// `sprite` is the shared sprite for that effect (Atmosphere.particleSprite()).
Item {
	id: root
	property string effect: "none"   // none | snow | autumn | spring | rain | night
	property url sprite
	enabled: false

	readonly property var presets: ({
		snow:   { rate: 20,  life: 9000,  size: 12, sizeVar: 6,  angle: 90,  angleVar: 15, speed: 0.11, sway: 60, rotVel: 0,  auto: false },
		autumn: { rate: 6,   life: 9000,  size: 32, sizeVar: 10, angle: 90,  angleVar: 15, speed: 0.11, sway: 60, rotVel: 90, auto: false },
		spring: { rate: 8,   life: 11000, size: 22, sizeVar: 8,  angle: 90,  angleVar: 15, speed: 0.09, sway: 90, rotVel: 90, auto: false },
		rain:   { rate: 120, life: 1200,  size: 24, sizeVar: 6,  angle: 100, angleVar: 3,  speed: 1.1,  sway: 0,  rotVel: 0,  auto: true },
		night:  { rate: 0.6, life: 1400,  size: 40, sizeVar: 0,  angle: 135, angleVar: 8,  speed: 1.2,  sway: 0,  rotVel: 0,  auto: true }
	})
	readonly property bool valid: effect in presets
	readonly property var p: presets[effect] || presets.snow

	ParticleSystem {
		id: ps
		running: root.visible && root.valid
		onRunningChanged: console.log("ParticleEffects: running ->", running, "effect:", root.effect)
	}

	// DEBUG: every 2s while the system runs, log the property state and how
	// many frames the window actually swapped in that time. Remove when done.
	property int debugFrames: 0
	Connections {
		target: root.Window.window
		function onFrameSwapped() { root.debugFrames++ }
	}
	Timer {
		interval: 2000
		running: ps.running
		repeat: true
		onTriggered: {
			console.log("ParticleEffects: active, effect:", root.effect, "visible:", root.visible, "frames/2s:", root.debugFrames)
			root.debugFrames = 0
		}
	}

	Emitter {
		system: ps
		enabled: root.valid
		width: root.width; height: 1
		emitRate: root.p.rate
		lifeSpan: root.p.life
		size: root.p.size
		sizeVariation: root.p.sizeVar
		velocity: AngleDirection {
			angle: root.p.angle; angleVariation: root.p.angleVar
			magnitude: root.height * root.p.speed
			magnitudeVariation: 30
		}
	}

	Wander { system: ps; enabled: root.p.sway > 0; xVariance: root.p.sway; pace: 120 }

	ImageParticle {
		system: ps
		source: root.valid ? root.sprite : ""
		autoRotation: root.p.auto
		rotationVariation: root.p.auto ? 0 : 180
		rotationVelocityVariation: root.p.rotVel
	}
}
