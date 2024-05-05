/*
 * Copyright (C) 2024  Alfred Neumayer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webhunt is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QGuiApplication>
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QUrl>
#include <QString>
#include <QQuickView>

#include <glib.h>

#include "src/tabs-model.h"

#define APP_ID "webhunt.fredldotme"

#if defined(__aarch64__)
#define ARCH_TRIPLET "aarch64-linux-gnu"
#elif defined(__arm__)
#define ARCH_TRIPLET "arm-linux-gnueabihf"
#elif defined(__x86_64__)
#define ARCH_TRIPLET "x86_64-linux-gnu"
#elif defined(__i386__)
#define ARCH_TRIPLET "i386-linux-gnu"
#else
#error "No supported architecture detected"
#endif

int main(int argc, char *argv[])
{
    const QString xdgCachePath = QString::fromUtf8(qgetenv("XDG_CACHE_HOME"));
    const QString cachePath = QStringLiteral("%1/%2").arg(xdgCachePath, APP_ID);

    qputenv("QT_QPA_PLATFORM_PLUGIN_PATH", "/opt/click.ubuntu.com/" APP_ID "/current/lib/" ARCH_TRIPLET);
    qputenv("QT_QPA_PLATFORM", "wayland-egl");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    qputenv("WEBKIT_EXEC_PATH", "/opt/click.ubuntu.com/" APP_ID "/current/lib/" ARCH_TRIPLET "/wpe-webkit-2.0");
    qputenv("GIO_EXTRA_MODULES", "/opt/click.ubuntu.com/" APP_ID "/current/lib/" ARCH_TRIPLET "/gio/modules");
    qputenv("HYBRIS_EGLPLATFORM", "wayland");

    qputenv("GST_GL_API", "gles2");
    qputenv("GST_GL_PLATFORM", "egl");
    qputenv("GST_GL_WINDOW", "wayland");

    qputenv("WEBKIT_FORCE_VBLANK_TIMER", "1");
    qputenv("WEBKIT_GST_CUSTOM_VIDEO_SINK", "hybrissink");
    //qputenv("GST_DEBUG", "*hybris*:7,*mir*:7");
    qputenv("WEBKIT_GST_USE_PLAYBIN3", "0");

    qputenv("WPE_SHELL_MEDIA_DISK_CACHE_PATH", cachePath.toUtf8());

    if (getenv("GRID_UNIT_PX")) {
        auto scaleFactor = std::atoi(getenv("GRID_UNIT_PX")) / 8.0f;
        char buf[32];
        std::sprintf(buf, "%.2f", scaleFactor);
        const auto scaleFactorStr = QString::fromStdString(std::string(buf));
        qputenv("QT_SCALE_FACTOR", scaleFactorStr.toUtf8());
        qInfo() << "Scaling to " << scaleFactorStr << "x";
    }

    qmlRegisterType<TabsModel>("WebHunt", 1, 0, "TabsModel");

    g_set_prgname(APP_ID);

    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    app->setApplicationName(APP_ID);

    qDebug() << "Starting app from main.cpp";

    QQuickView *view = new QQuickView();
    view->setSource(QUrl("qrc:/Main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}
