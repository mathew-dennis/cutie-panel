#pragma once

#include <QObject>
#include <QHash>
#include <QList>
#include <QQuickView>
#include <QScreen>
#include <QGuiApplication>
#include <QQmlEngine>

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

class LockScreen : public QObject {
	Q_OBJECT
public:
	LockScreen(QQmlEngine *engine, PanelLockState *lockState, QGuiApplication *app, QObject *parent = nullptr);
	~LockScreen();

	void create(QScreen *screen);
	void remove(QScreen *screen);

private:
	QQmlEngine *m_engine;
	PanelLockState *m_lockState;
	QGuiApplication *m_app;
	QHash<QScreen *, QList<QQuickView *>> m_externalWindows;
};
