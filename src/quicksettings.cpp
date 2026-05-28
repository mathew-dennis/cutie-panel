#include <QtGui/QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QScreen>
#include <qpa/qplatformscreen.h>

#include "quicksettings.h"

QuickSettings::QuickSettings(QObject *parent)
	: QObject(parent)
{
	this->battery = new org::freedesktop::DBus::Properties(
		"org.freedesktop.UPower",
		"/org/freedesktop/UPower/devices/DisplayDevice",
		QDBusConnection::systemBus());
	connect(this->battery,
		SIGNAL(PropertiesChanged(QString, QVariantMap, QStringList)),
		this,
		SLOT(onUPowerInfoChanged(QString, QVariantMap, QStringList)));
	refreshBatteryInfo();

	udevInstance = udev_new();
    udevDevice = udev_device_new_from_syspath(udevInstance, "/sys/class/backlight/panel0-backlight");
    if (!udevDevice) {
        udevEnumerator = udev_enumerate_new(udevInstance);
        udev_enumerate_add_match_subsystem(udevEnumerator, "backlight");
        udev_enumerate_scan_devices(udevEnumerator);
        udevEntry = udev_enumerate_get_list_entry(udevEnumerator);
        const char *udevPath = udev_list_entry_get_name(udevEntry);
        udevDevice = udev_device_new_from_syspath(udevInstance, udevPath);
	}
    if (!udevDevice) 
		udevDevice = udev_device_new_from_syspath(
			udevInstance, "/sys/class/leds/lcd-backlight");
	p_maxBrightness = QString(udev_device_get_sysattr_value(
					  udevDevice, "max_brightness"))
				  .toInt();
}

QuickSettings::~QuickSettings()
{
}

unsigned int QuickSettings::GetMaxBrightness()
{
	return p_maxBrightness;
}

void QuickSettings::SetBrightness(unsigned int value)
{
	if (udevDevice)
		udev_device_set_sysattr_value(udevDevice, "brightness",
					      std::to_string(value).c_str());
}

void QuickSettings::onUPowerInfoChanged(QString interface, QVariantMap,
					QStringList)
{
	if (interface == "org.freedesktop.UPower.Device") {
		refreshBatteryInfo();
	}
}

void QuickSettings::refreshBatteryInfo()
{
	QVariantMap upower_display =
		this->battery->GetAll("org.freedesktop.UPower.Device");
	((QQmlApplicationEngine *)parent())
		->rootContext()
		->setContextProperty("batteryStatus", upower_display);
}