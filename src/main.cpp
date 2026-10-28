#include <QGuiApplication>
#include <QQuickView>
#include <QIcon>
#include <LayerShellQt/shell.h>
#include <LayerShellQt/window.h>

#include "quicksettings.h"
#include "lockscreen.h"
#include <cutiescreenlock/cutiescreenlockauth.h>

class PanelLockState : public QObject {
	Q_OBJECT
	Q_PROPERTY(bool locked READ locked WRITE setLocked NOTIFY lockedChanged)

public:
	bool locked() const { return m_locked; }

public slots:
	void setLocked(bool locked)
	{
		if (m_locked == locked)
			return;
		m_locked = locked;
		emit lockedChanged(m_locked);
	}

signals:
	void lockedChanged(bool locked);

private:
	bool m_locked = true;
};

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