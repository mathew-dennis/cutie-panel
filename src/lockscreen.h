#pragma once

#include <QObject>
#include <QHash>
#include <QList>
#include <QQuickView>
#include <QScreen>
#include <QGuiApplication>
#include <QQmlEngine>

class PanelLockState;

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