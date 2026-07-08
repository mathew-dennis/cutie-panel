#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QSettings>
#include <QTimer>
#include <QThread>
#include <QDateTime>

// Runs the blocking PAM call off the UI thread so a slow/locked-out auth
// stack never freezes the compositor.
class PamAuthWorker : public QObject {
	Q_OBJECT
    public:
	explicit PamAuthWorker(QObject *parent = nullptr);

    public Q_SLOTS:
	void authenticate(const QString &username, const QString &password);

    Q_SIGNALS:
	void finished(bool success, const QString &error);
};

// Exposed to QML as a context property ("lockAuth"). Handles three unlock
// methods:
//  - "password": the device's real Unix account password, verified via PAM
//    (same stack as login/sudo, uses the setuid unix_chkpwd helper so this
//    process needs no special privileges).
//  - "pin" / "pattern": a separate local secret (like Android's device
//    credential), stored as a salted+stretched hash via QSettings.
//  - "none": no lock configured, swipe-to-unlock like the original.
class LockAuth : public QObject {
	Q_OBJECT
	Q_PROPERTY(bool authenticating READ authenticating NOTIFY
			   authenticatingChanged)
	Q_PROPERTY(int failedAttempts READ failedAttempts NOTIFY
			   failedAttemptsChanged)
	Q_PROPERTY(int lockoutSecondsRemaining READ lockoutSecondsRemaining
			   NOTIFY lockoutSecondsRemainingChanged)
	Q_PROPERTY(
		QString method READ method WRITE setMethod NOTIFY methodChanged)

    public:
	explicit LockAuth(QObject *parent = nullptr);
	~LockAuth();

	bool authenticating() const { return m_authenticating; }
	int failedAttempts() const { return m_failedAttempts; }
	int lockoutSecondsRemaining() const;
	QString method() const { return m_method; }
	void setMethod(const QString &method);

	// Password (PAM) auth is async - result arrives via passwordAuthResult.
	Q_INVOKABLE void authenticatePassword(const QString &password);

	// PIN / pattern checks are local and fast enough to stay synchronous.
	Q_INVOKABLE bool verifyPin(const QString &pin);
	Q_INVOKABLE bool verifyPattern(const QString &patternSequence);
	Q_INVOKABLE void setPin(const QString &pin);
	Q_INVOKABLE void setPattern(const QString &patternSequence);
	Q_INVOKABLE bool hasCredentialConfigured() const;

    Q_SIGNALS:
	void authenticatingChanged();
	void failedAttemptsChanged();
	void lockoutSecondsRemainingChanged();
	void methodChanged();
	void passwordAuthResult(bool success, const QString &error);
	void unlocked();

    private Q_SLOTS:
	void onPamFinished(bool success, const QString &error);
	void onLockoutTick();

    private:
	QString hashSecret(const QString &secret, const QByteArray &salt) const;
	void registerFailure();
	void registerSuccess();

	bool m_authenticating = false;
	int m_failedAttempts = 0;
	QString m_method;

	// Backed by ~/.config/Cutie Community Project/CutieLock.conf,
	// permissions forced to 0600 in the constructor since it holds
	// PIN/pattern hashes.
	QSettings m_settings;

	QThread m_pamThread;
	PamAuthWorker *m_pamWorker;

	QTimer m_lockoutTimer;
	qint64 m_lockoutUntilEpoch = 0;
};
