#pragma once

#include <QHash>
#include <QObject>

class QQuickView;
class QScreen;

// One small layer-shell window per non-primary screen. It is a thin status
// bar normally and grows to a full-screen cover while the lockscreen of the
// primary panel is visible.
class ExternalScreens : public QObject {
public:
	explicit ExternalScreens(QQuickView *mainView);
	~ExternalScreens();

private:
	void add(QScreen *screen);
	void remove(QScreen *screen);
	void setLocked(bool locked);
	void apply(QQuickView *view);

	QQuickView *m_mainView;
	QHash<QScreen *, QQuickView *> m_views;
	bool m_locked = false;
};
