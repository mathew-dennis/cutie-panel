#include <QGuiApplication>
#include <QQuickView>
#include <QIcon>
#include <LayerShellQt/shell.h>
#include <LayerShellQt/window.h>

#include "quicksettings.h"
#include "lockscreen.h"
#include <cutiescreenlock/cutiescreenlockauth.h>

int main(int argc, char *argv[])
{
	LayerShellQt::Shell::useLayerShell();

	QCoreApplication::setOrganizationName("Cutie Community Project");
	QCoreApplication::setApplicationName("Cutie Panel");

	QGuiApplication app(argc, argv);

	PanelLockState lockState;
	QQuickView view;
	view.engine()->rootContext()->setContextProperty("lockState", &lockState);

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

	new CutieScreenLockAuthority(&app);

	view.setSource(QUrl("qrc:/main.qml"));
	view.setColor(QColor(Qt::transparent));
	view.show();

	// Initialize multi-display handler
	LockScreen externalDisplays(view.engine(), &lockState, &app);

	return app.exec();
}

#include "main.moc"
