#include "external-screen.h"

#include <QDebug>
#include <QGuiApplication>
#include <QQuickItem>
#include <QQuickView>
#include <QScreen>
#include <LayerShellQt/window.h>

static const int BarHeight = 30;

ExternalScreens::ExternalScreens(QQuickView *mainView)
	: m_mainView(mainView)
{
	// The primary lockscreen is the single source of truth: its visibility
	// is the locked state.
	QQuickItem *lockscreen =
		mainView->rootObject()->findChild<QQuickItem *>("lockscreen");
	if (lockscreen) {
		m_locked = lockscreen->isVisible();
		connect(lockscreen, &QQuickItem::visibleChanged, this,
			[this, lockscreen]() { setLocked(lockscreen->isVisible()); });
	} else {
		qWarning() << "[cutie-panel] lockscreen item not found, external screens will not lock";
	}

	connect(qApp, &QGuiApplication::screenAdded, this, &ExternalScreens::add);
	connect(qApp, &QGuiApplication::screenRemoved, this, &ExternalScreens::remove);

	for (QScreen *screen : qApp->screens())
		add(screen);
}

ExternalScreens::~ExternalScreens()
{
	qDeleteAll(m_views);
}

void ExternalScreens::add(QScreen *screen)
{
	if (screen == qApp->primaryScreen() || m_views.contains(screen))
		return;

	auto *view = new QQuickView(m_mainView->engine(), nullptr);
	view->setScreen(screen);
	view->setColor(QColor(Qt::transparent));
	view->setResizeMode(QQuickView::SizeRootObjectToView);

	LayerShellQt::Window *layer = LayerShellQt::Window::get(view);
	layer->setScreenConfiguration(LayerShellQt::Window::ScreenFromQWindow);
	layer->setLayer(LayerShellQt::Window::LayerOverlay);
	LayerShellQt::Window::Anchors anchors;
	anchors.setFlag(LayerShellQt::Window::AnchorTop);
	anchors.setFlag(LayerShellQt::Window::AnchorLeft);
	layer->setAnchors(anchors);
	layer->setKeyboardInteractivity(
		LayerShellQt::Window::KeyboardInteractivityNone);
	layer->setScope("cutie-panel-external");

	view->setSource(QUrl("qrc:/ExternalScreen.qml"));
	m_views.insert(screen, view);
	apply(view);

	// A freshly connected output can report its real mode after the QScreen
	// already exists, so follow geometry changes instead of trusting the
	// size read at creation time.
	connect(screen, &QScreen::geometryChanged, view, [this, view]() { apply(view); });

	view->show();
}

void ExternalScreens::remove(QScreen *screen)
{
	delete m_views.take(screen);
}

void ExternalScreens::setLocked(bool locked)
{
	m_locked = locked;
	for (QQuickView *view : std::as_const(m_views))
		apply(view);
}

void ExternalScreens::apply(QQuickView *view)
{
	const QSize screenSize = view->screen()->geometry().size();
	const QSize size = m_locked ? screenSize
				    : QSize(screenSize.width(), BarHeight);

	qInfo() << "[cutie-panel] external screen" << view->screen()->name()
		<< "geometry" << view->screen()->geometry()
		<< (m_locked ? "locked" : "bar") << "window" << size;

	LayerShellQt::Window *layer = LayerShellQt::Window::get(view);
	layer->setDesiredSize(size);
	layer->setExclusiveZone(m_locked ? -1 : BarHeight);
	view->resize(size);

	if (QQuickItem *root = view->rootObject())
		root->setProperty("locked", m_locked);
}