#include <QGuiApplication>
#include <QQuickView>
#include <QDebug>
#include <QIcon>
#include <QQmlError>
#include <QHash>
#include <QScreen>
#include <QSize>
#include <LayerShellQt/shell.h>
#include <LayerShellQt/window.h>

#include "quicksettings.h"
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

	// Owns PAM auth + PIN/pattern hashing, and registers the
	// org.cutie_shell.ScreenLock D-Bus service that Lockscreen.qml (via
	// `import Cutie.ScreenLock; CutieScreenLock {}`) and cutie-settings both
	// talk to. Deliberately not exposed to QML directly - see
	// cutiescreenlockauth.h for why there must be exactly one of these.
	new CutieScreenLockAuthority(&app);

	view.setSource(QUrl("qrc:/main.qml"));
	view.setColor(QColor(Qt::transparent));

	view.show();

	QHash<QScreen *, QList<QQuickView *>> externalWindows;
	auto watchQml = [](QQuickView *window, const QString &label) {
		QObject::connect(window, &QQuickView::statusChanged, window,
				 [window, label](QQuickView::Status status) {
					 if (status == QQuickView::Ready)
						 qInfo() << label << "QML ready";
					 else if (status == QQuickView::Error)
						 for (const QQmlError &error :
					      window->errors())
							 qWarning().noquote()
								 << label << error.toString();
				 });
	};
	auto removeExternalScreen = [&externalWindows](QScreen *screen) {
		const QList<QQuickView *> windows = externalWindows.take(screen);
		for (QQuickView *window : windows) {
			window->hide();
			delete window;
		}
	};
	auto addExternalScreen = [&view, &lockState,
				  &externalWindows,
				  watchQml](QScreen *screen) {
		if (!screen || screen == view.screen() ||
		    externalWindows.contains(screen))
			return;
		qInfo() << "[cutie-panel] creating external UI for"
			<< screen->name() << screen->geometry()
			<< "screen size" << screen->size()
			<< "lock state" << lockState.locked();
		const QSize screenSize = screen->geometry().size();

		auto *panelView = new QQuickView(view.engine(), nullptr);
		watchQml(panelView, QStringLiteral("[cutie-panel top bar]"));
		panelView->setResizeMode(QQuickView::SizeRootObjectToView);
		panelView->setScreen(screen);
		LayerShellQt::Window *panelLayer =
			LayerShellQt::Window::get(panelView);
		panelLayer->setScreenConfiguration(
			LayerShellQt::Window::ScreenFromQWindow);
		panelLayer->setLayer(LayerShellQt::Window::LayerTop);
		LayerShellQt::Window::Anchors panelAnchors;
		panelAnchors.setFlag(LayerShellQt::Window::AnchorTop);
		panelAnchors.setFlag(LayerShellQt::Window::AnchorLeft);
		panelAnchors.setFlag(LayerShellQt::Window::AnchorRight);
		panelLayer->setAnchors(panelAnchors);
		panelLayer->setDesiredSize(QSize(screenSize.width(), 36));
		panelLayer->setKeyboardInteractivity(
			LayerShellQt::Window::KeyboardInteractivityNone);
		panelLayer->setExclusiveZone(0);
		panelLayer->setScope("cutie-panel-external");
		panelView->setSource(QUrl("qrc:/ExternalPanel.qml"));
		panelView->setColor(QColor(Qt::transparent));
		panelView->resize(screenSize.width(), 36);
		panelView->show();
		qInfo() << "[cutie-panel] top bar window screen"
			<< panelView->screen()->name() << "window size"
			<< panelView->size();

		auto *lockView = new QQuickView(view.engine(), nullptr);
		watchQml(lockView, QStringLiteral("[cutie-panel lockscreen]"));
		lockView->setResizeMode(QQuickView::SizeRootObjectToView);
		lockView->setScreen(screen);
		LayerShellQt::Window *lockLayer =
			LayerShellQt::Window::get(lockView);
		lockLayer->setScreenConfiguration(
			LayerShellQt::Window::ScreenFromQWindow);
		lockLayer->setLayer(LayerShellQt::Window::LayerOverlay);
		LayerShellQt::Window::Anchors lockAnchors;
		lockAnchors.setFlag(LayerShellQt::Window::AnchorTop);
		lockAnchors.setFlag(LayerShellQt::Window::AnchorBottom);
		lockAnchors.setFlag(LayerShellQt::Window::AnchorLeft);
		lockAnchors.setFlag(LayerShellQt::Window::AnchorRight);
		lockLayer->setAnchors(lockAnchors);
		lockLayer->setDesiredSize(screenSize);
		lockLayer->setKeyboardInteractivity(
			LayerShellQt::Window::KeyboardInteractivityOnDemand);
		lockLayer->setExclusiveZone(-1);
		lockLayer->setScope("cutie-lockscreen-external");
		lockView->setSource(QUrl("qrc:/ExternalLock.qml"));
		lockView->setColor(QColor(Qt::transparent));
		lockView->resize(screenSize);
		QObject::connect(&lockState, &PanelLockState::lockedChanged,
				 lockView, [lockView](bool locked) {
					 if (locked)
						 lockView->show();
					 else
						 lockView->hide();
				 });
		if (lockState.locked())
			lockView->show();
		qInfo() << "[cutie-panel] lock window screen"
			<< lockView->screen()->name() << "window size"
			<< lockView->size();

		externalWindows.insert(
			screen, QList<QQuickView *>{ panelView, lockView });
	};

	QObject::connect(&app, &QGuiApplication::screenAdded, &app,
			 [addExternalScreen](QScreen *screen) {
				 addExternalScreen(screen);
			 });
	QObject::connect(&app, &QGuiApplication::screenRemoved, &app,
			 [removeExternalScreen](QScreen *screen) {
				 removeExternalScreen(screen);
			 });
	for (QScreen *screen : app.screens())
		addExternalScreen(screen);
	QObject::connect(&app, &QCoreApplication::aboutToQuit, &app,
			 [&externalWindows, &removeExternalScreen]() {
				 const auto screens = externalWindows.keys();
				 for (QScreen *screen : screens)
					 removeExternalScreen(screen);
			 });

	return app.exec();
}

#include "main.moc"
