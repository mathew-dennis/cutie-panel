#include <QGuiApplication>
#include <QQuickView>
#include <QIcon>
#include <LayerShellQt/shell.h>
#include <LayerShellQt/window.h>

#include "quicksettings.h"
#include <cutiescreenlock/cutiescreenlockauth.h>

int main(int argc, char *argv[])
{
	LayerShellQt::Shell::useLayerShell();

	QCoreApplication::setOrganizationName("Cutie Community Project");
	QCoreApplication::setApplicationName("Cutie Panel");

	QGuiApplication app(argc, argv);

	QQuickView view;

	LayerShellQt::Window *layerShell = LayerShellQt::Window::get(&view);
	layerShell->setLayer(LayerShellQt::Window::LayerOverlay);
	layerShell->setAnchors(LayerShellQt::Window::AnchorTop);
	layerShell->setKeyboardInteractivity(
		LayerShellQt::Window::KeyboardInteractivityNone);
	layerShell->setExclusiveZone(30);
	layerShell->setScope("cutie-panel");

	QuickSettings *quicksettings = new QuickSettings(view.engine());
	view.engine()->rootContext()->setContextProperty("quicksettings",
							 quicksettings);

	// Owns PAM auth + PIN/pattern hashing, and registers the
	// org.cutie_shell.ScreenLock D-Bus service that Lockscreen.qml (via
	// `import Cutie.ScreenLock; CutieScreenLock {}`) and cutie-settings both
	// talk to. Deliberately not exposed to QML directly - see
	// cutiescreenlockauth.h for why there must be exactly one of these.
	new CutieScreenLockAuthority(&app);

	view.setSource(QUrl("qrc:/main.qml"));
	view.setColor(QColor(Qt::transparent));

	view.show();

	return app.exec();
}
