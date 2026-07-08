cmake_minimum_required(VERSION 3.16)
project(cutie-panel VERSION 1.0 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOMOC ON)

include( GNUInstallDirs )

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Network Qml DBus)
find_package(LayerShellQt REQUIRED)
find_package(Libudev)

find_library(PAM_LIBRARIES pam REQUIRED)
find_path(PAM_INCLUDE_DIR security/pam_appl.h REQUIRED)

set(cutie-shell_SOURCES 
	src/main.cpp
	src/quicksettings.cpp
	src/quicksettings.h
	src/lockauth.cpp
	src/lockauth.h)

qt6_add_resources(APP_RESOURCES 
	${CMAKE_CURRENT_SOURCE_DIR}/src/qml/qml.qrc)

qt_add_dbus_interface(cutie-shell_SOURCES src/org.freedesktop.DBus.xml dbus_interface)

qt_add_executable(cutie-panel ${cutie-shell_SOURCES} ${APP_RESOURCES})

target_include_directories(cutie-panel PUBLIC src ${PAM_INCLUDE_DIR})

target_link_libraries(cutie-panel PUBLIC LayerShellQtInterface PkgConfig::Libudev Qt::Core Qt::Gui Qt::GuiPrivate Qt::DBus Qt::Quick Qt::QuickControls2 Qt::Network Qt::Qml ${PAM_LIBRARIES})

install(TARGETS cutie-panel RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
