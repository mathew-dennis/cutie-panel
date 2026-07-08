#include "lockauth.h"

#include <security/pam_appl.h>

#include <QCryptographicHash>
#include <QFile>
#include <QRandomGenerator>

#include <pwd.h>
#include <unistd.h>

namespace {

struct PamConvData {
	QByteArray password;
};

int pamConversation(int num_msg, const struct pam_message **msg,
		     struct pam_response **resp, void *appdata_ptr)
{
	if (num_msg <= 0)
		return PAM_CONV_ERR;

	auto *data = static_cast<PamConvData *>(appdata_ptr);
	auto *responses = static_cast<pam_response *>(
		calloc(num_msg, sizeof(pam_response)));
	if (!responses)
		return PAM_BUF_ERR;

	for (int i = 0; i < num_msg; ++i) {
		switch (msg[i]->msg_style) {
		case PAM_PROMPT_ECHO_OFF:
		case PAM_PROMPT_ECHO_ON:
			responses[i].resp = strdup(data->password.constData());
			responses[i].resp_retcode = 0;
			break;
		default:
			responses[i].resp = nullptr;
			responses[i].resp_retcode = 0;
			break;
		}
	}

	*resp = responses;
	return PAM_SUCCESS;
}

} // namespace

PamAuthWorker::PamAuthWorker(QObject *parent) : QObject(parent)
{
}

void PamAuthWorker::authenticate(const QString &username,
				  const QString &password)
{
	PamConvData convData{ password.toUtf8() };
	struct pam_conv conv = { pamConversation, &convData };
	pam_handle_t *pamh = nullptr;

	// Requires a PAM service file at /etc/pam.d/cutie-lockscreen (ship one
	// in debian/, see integration notes).
	int rc = pam_start("cutie-lockscreen", username.toUtf8().constData(),
			    &conv, &pamh);
	if (rc != PAM_SUCCESS) {
		Q_EMIT finished(false, QStringLiteral("pam_start failed"));
		return;
	}

	rc = pam_authenticate(pamh, 0);
	bool success = (rc == PAM_SUCCESS);
	QString error = success ? QString()
				 : QString::fromLocal8Bit(pam_strerror(pamh, rc));

	if (success) {
		// Also make sure the account isn't expired/locked/disabled.
		rc = pam_acct_mgmt(pamh, 0);
		success = (rc == PAM_SUCCESS);
		if (!success)
			error = QString::fromLocal8Bit(pam_strerror(pamh, rc));
	}

	pam_end(pamh, rc);

	Q_EMIT finished(success, error);
}

LockAuth::LockAuth(QObject *parent)
	: QObject(parent)
	, m_settings(QSettings::IniFormat, QSettings::UserScope,
		     QStringLiteral("Cutie Community Project"),
		     QStringLiteral("CutieLock"))
{
	m_pamWorker = new PamAuthWorker;
	m_pamWorker->moveToThread(&m_pamThread);
	connect(&m_pamThread, &QThread::finished, m_pamWorker,
		&QObject::deleteLater);
	connect(m_pamWorker, &PamAuthWorker::finished, this,
		&LockAuth::onPamFinished);
	m_pamThread.start();

	m_method = m_settings.value("method", "pin").toString();

	connect(&m_lockoutTimer, &QTimer::timeout, this,
		&LockAuth::onLockoutTick);
	m_lockoutTimer.setInterval(1000);

	// The QSettings file holds PIN/pattern hashes - lock it down.
	QFile file(m_settings.fileName());
	if (file.exists())
		file.setPermissions(QFile::ReadOwner | QFile::WriteOwner);
}

LockAuth::~LockAuth()
{
	m_pamThread.quit();
	m_pamThread.wait();
}

void LockAuth::setMethod(const QString &method)
{
	if (m_method == method)
		return;
	m_method = method;
	m_settings.setValue("method", m_method);
	Q_EMIT methodChanged();
}

int LockAuth::lockoutSecondsRemaining() const
{
	qint64 now = QDateTime::currentSecsSinceEpoch();
	return m_lockoutUntilEpoch > now ? int(m_lockoutUntilEpoch - now) : 0;
}

void LockAuth::authenticatePassword(const QString &password)
{
	if (lockoutSecondsRemaining() > 0 || m_authenticating)
		return;

	m_authenticating = true;
	Q_EMIT authenticatingChanged();

	struct passwd *pw = getpwuid(getuid());
	const QString username =
		pw ? QString::fromLocal8Bit(pw->pw_name) : qgetenv("USER");

	QMetaObject::invokeMethod(m_pamWorker, "authenticate",
				   Qt::QueuedConnection,
				   Q_ARG(QString, username),
				   Q_ARG(QString, password));
}

void LockAuth::onPamFinished(bool success, const QString &error)
{
	m_authenticating = false;
	Q_EMIT authenticatingChanged();

	if (success)
		registerSuccess();
	else
		registerFailure();

	Q_EMIT passwordAuthResult(success, error);
}

QString LockAuth::hashSecret(const QString &secret,
			      const QByteArray &salt) const
{
	// Deliberate stretching so a stolen config file isn't a fast offline
	// crack. Swap for Argon2/PBKDF2-HMAC if libsodium is on the target -
	// this is a dependency-free fallback, not a strong recommendation.
	QByteArray data = salt + secret.toUtf8();
	for (int i = 0; i < 100000; ++i)
		data = QCryptographicHash::hash(data,
						 QCryptographicHash::Sha256);
	return QString::fromLatin1(data.toHex());
}

static QByteArray randomSalt()
{
	QByteArray salt(16, 0);
	for (int i = 0; i < salt.size(); ++i)
		salt[i] = char(QRandomGenerator::global()->bounded(256));
	return salt;
}

void LockAuth::setPin(const QString &pin)
{
	QByteArray salt = randomSalt();
	m_settings.setValue("pin/salt", salt.toHex());
	m_settings.setValue("pin/hash", hashSecret(pin, salt));
	m_settings.sync();
}

bool LockAuth::verifyPin(const QString &pin)
{
	if (lockoutSecondsRemaining() > 0)
		return false;
	QByteArray salt =
		QByteArray::fromHex(m_settings.value("pin/salt").toByteArray());
	QString expected = m_settings.value("pin/hash").toString();
	bool ok = !expected.isEmpty() && hashSecret(pin, salt) == expected;
	ok ? registerSuccess() : registerFailure();
	return ok;
}

void LockAuth::setPattern(const QString &patternSequence)
{
	QByteArray salt = randomSalt();
	m_settings.setValue("pattern/salt", salt.toHex());
	m_settings.setValue("pattern/hash", hashSecret(patternSequence, salt));
	m_settings.sync();
}

bool LockAuth::verifyPattern(const QString &patternSequence)
{
	if (lockoutSecondsRemaining() > 0)
		return false;
	QByteArray salt = QByteArray::fromHex(
		m_settings.value("pattern/salt").toByteArray());
	QString expected = m_settings.value("pattern/hash").toString();
	bool ok = !expected.isEmpty() &&
		  hashSecret(patternSequence, salt) == expected;
	ok ? registerSuccess() : registerFailure();
	return ok;
}

bool LockAuth::hasCredentialConfigured() const
{
	if (m_method == "pin")
		return m_settings.contains("pin/hash");
	if (m_method == "pattern")
		return m_settings.contains("pattern/hash");
	return true; // password always available via PAM
}

void LockAuth::registerFailure()
{
	m_failedAttempts++;
	Q_EMIT failedAttemptsChanged();

	// Android-style progressive backoff after 5 attempts: 30s, 60s, 120s,
	// 240s, capped at 5 minutes.
	if (m_failedAttempts >= 5) {
		int extra = m_failedAttempts - 5;
		int delay = qMin(30 * (1 << qMin(extra, 4)), 300);
		m_lockoutUntilEpoch = QDateTime::currentSecsSinceEpoch() + delay;
		m_lockoutTimer.start();
		Q_EMIT lockoutSecondsRemainingChanged();
	}
}

void LockAuth::registerSuccess()
{
	m_failedAttempts = 0;
	m_lockoutUntilEpoch = 0;
	m_lockoutTimer.stop();
	Q_EMIT failedAttemptsChanged();
	Q_EMIT lockoutSecondsRemainingChanged();
	Q_EMIT unlocked();
}

void LockAuth::onLockoutTick()
{
	Q_EMIT lockoutSecondsRemainingChanged();
	if (lockoutSecondsRemaining() <= 0)
		m_lockoutTimer.stop();
}
