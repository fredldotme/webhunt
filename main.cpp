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

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORM_PLUGIN_PATH", "/opt/click.ubuntu.com/webhunt.fredldotme/current/lib/aarch64-linux-gnu");
    qputenv("QT_QPA_PLATFORM", "wayland-egl");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    qputenv("WEBKIT_EXEC_PATH", "/opt/click.ubuntu.com/webhunt.fredldotme/current/lib/aarch64-linux-gnu/wpe-webkit-2.0");
    qputenv("GIO_EXTRA_MODULES", "/opt/click.ubuntu.com/webhunt.fredldotme/current/lib/aarch64-linux-gnu/gio/modules");
    qputenv("HYBRIS_EGLPLATFORM", "wayland");

    qputenv("GST_GL_API", "gles2");
    qputenv("GST_GL_PLATFORM", "egl");
    qputenv("GST_GL_WINDOW", "wayland");

    //qputenv("WAYLAND_DEBUG", "client");

    qputenv("WEBKIT_FORCE_VBLANK_TIMER", "1");
    //qputenv("WEBKIT_GST_CUSTOM_VIDEO_SINK", "hybrissink");
    //qputenv("WEBKIT_GST_USE_PLAYBIN3", "0");
    //qputenv("WEBKIT_WPE_BACKEND", "libWPEBackend-hybris.so");
    qputenv("WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS", "1");
    //qputenv("WEBKIT_SHOW_FPS", "1");

    if (getenv("GRID_UNIT_PX")) {
        auto scaleFactor = std::atoi(getenv("GRID_UNIT_PX")) / 8.0f;
        char buf[32];
        std::sprintf(buf, "%.2f", scaleFactor);
        const auto scaleFactorStr = QString::fromStdString(std::string(buf));
        qputenv("QT_SCALE_FACTOR", scaleFactorStr.toUtf8());
        qInfo() << "Scaling to " << scaleFactorStr << "x";
    }

    qmlRegisterType<TabsModel>("WebHunt", 1, 0, "TabsModel");

    g_set_prgname("webhunt.fredldotme");

    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    app->setApplicationName("webhunt.fredldotme");

    qDebug() << "Starting app from main.cpp";

    QQuickView *view = new QQuickView();
    view->setSource(QUrl("qrc:/Main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->show();

    return app->exec();
}
