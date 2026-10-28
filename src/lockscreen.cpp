#include "lockscreen.h"
#include <QQmlError>
#include <QQuickItem>
#include <QDebug>
#include <LayerShellQt/window.h>

LockScreen::LockScreen(QQmlEngine *engine, PanelLockState *lockState, QGuiApplication *app, QObject *parent)
	: QObject(parent), m_engine(engine), m_lockState(lockState), m_app(app)
{
	connect(m_app, &QGuiApplication::screenAdded, this, [this](QScreen *screen) {
		create(screen);
	});
	connect(m_app, &QGuiApplication::screenRemoved, this, [this](QScreen *screen) {
		remove(screen);
	});

	for (QScreen *screen : m_app->screens()) {
		create(screen);
	}
}

LockScreen::~LockScreen()
{
	const auto screens = m_externalWindows.keys();
	for (QScreen *screen : screens) {
		remove(screen);
	}
}

void LockScreen::remove(QScreen *screen)
{
	const QList<QQuickView *> windows = m_externalWindows.take(screen);
	for (QQuickView *window : windows) {
		window->hide();
		delete window;
	}
}

void LockScreen::create(QScreen *screen)
{
	if (!screen || screen == m_app->primaryScreen() || m_externalWindows.contains(screen))
		return;

	qInfo() << "[cutie-panel] creating external UI for requested screen" << screen << screen->name()
		<< "geometry" << screen->geometry() << "size" << screen->size()
		<< "device pixel ratio" << screen->devicePixelRatio()
		<< "lock state" << m_lockState->locked();

	const QSize screenSize = screen->geometry().size();

	auto watchQml = [](QQuickView *window, const QString &label) {
		QObject::connect(window, &QQuickView::statusChanged, window,
				 [window, label](QQuickView::Status status) {
					 if (status == QQuickView::Ready)
						 qInfo() << label << "QML ready";
					 else if (status == QQuickView::Error)
						 for (const QQmlError &error : window->errors())
							 qWarning().noquote() << label << error.toString();
				 });
	};

	// --- Top Bar Panel View ---
	auto *panelView = new QQuickView(m_engine, nullptr);
	watchQml(panelView, QStringLiteral("[cutie-panel top bar]"));
	panelView->setResizeMode(QQuickView::SizeRootObjectToView);
	panelView->setScreen(screen);
	
	LayerShellQt::Window *panelLayer = LayerShellQt::Window::get(panelView);
	panelLayer->setScreenConfiguration(LayerShellQt::Window::ScreenFromQWindow);
	panelLayer->setLayer(LayerShellQt::Window::LayerTop);
	
	LayerShellQt::Window::Anchors panelAnchors;
	panelAnchors.setFlag(LayerShellQt::Window::AnchorTop);
	panelAnchors.setFlag(LayerShellQt::Window::AnchorLeft);
	panelLayer->setAnchors(panelAnchors);
	panelLayer->setDesiredSize(QSize(screenSize.width(), 36));
	panelLayer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
	panelLayer->setExclusiveZone(0);
	panelLayer->setScope("cutie-panel-external");
	
	panelView->setSource(QUrl("qrc:/ExternalPanel.qml"));
	panelView->setColor(QColor(Qt::transparent));
	panelView->resize(screenSize.width(), 36);
	
	auto *panelRoot = qobject_cast<QQuickItem *>(panelView->rootObject());
	if (panelRoot)
		panelRoot->setSize(QSizeF(screenSize.width(), 36));
	panelView->show();

	// --- Lockscreen View ---
	auto *lockView = new QQuickView(m_engine, nullptr);
	watchQml(lockView, QStringLiteral("[cutie-panel lockscreen]"));
	lockView->setResizeMode(QQuickView::SizeRootObjectToView);
	lockView->setScreen(screen);
	
	LayerShellQt::Window *lockLayer = LayerShellQt::Window::get(lockView);
	lockLayer->setScreenConfiguration(LayerShellQt::Window::ScreenFromQWindow);
	lockLayer->setLayer(LayerShellQt::Window::LayerOverlay);
	
	LayerShellQt::Window::Anchors lockAnchors;
	lockAnchors.setFlag(LayerShellQt::Window::LayerTop);
	lockAnchors.setFlag(LayerShellQt::Window::AnchorLeft);
	lockLayer->setAnchors(lockAnchors);
	lockLayer->setDesiredSize(screenSize);
	lockLayer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
	lockLayer->setExclusiveZone(-1);
	lockLayer->setScope("cutie-lockscreen-external");
	
	lockView->setSource(QUrl("qrc:/ExternalLock.qml"));
	lockView->setColor(QColor(Qt::transparent));
	lockView->resize(screenSize);
	
	auto *lockRoot = qobject_cast<QQuickItem *>(lockView->rootObject());
	if (lockRoot)
		lockRoot->setSize(QSizeF(screenSize));

	QObject::connect(m_lockState, &PanelLockState::lockedChanged, lockView, [lockView](bool locked) {
		if (locked)
			lockView->show();
		else
			lockView->hide();
	});
	
	if (m_lockState->locked())
		lockView->show();

	m_externalWindows.insert(screen, QList<QQuickView *>{ panelView, lockView });
}