# lxcwatch

A Gtk system tray icon that indicates when (unprivileged) lxc containers are
running, offers a menu for terminating processes within those containers, and
allows (limited) access to the host desktop's browser and file manager from
within containers.

I use this as a dashboard to remind me when one of my development or gaming
containers is still running, and to easily kill any games that have failed to
exit completely. (The latter is a fairly common problem with Windows games.)

If ~/.config/lxcwatch/procnames exists, only process names listed in that file
(one per line) will be shown in the menu.

If ~/.config/lxcwatch/socketpaths exists, a unix domain socket will be created
at each path listed in that file (one per line). Writing a directory path or
URL (plus a newline) to these sockets will cause lxcwatch to open it in the
host desktop session. The included x-www-browser script can be installed in a
container and edited to point its SOCKETPATH variable at one of these sockets;
the container's xdg-open will then work as expected even without a browser or
file manager installation in the container. This feature is mainly aimed at
game launchers, which often like to open web pages to display news or file
managers to show screenshots, but it can also make container admin tasks more
convenient.

The included x-www-browser.desktop file can be installed in a container
(normally in ~/.local/share/applications or /usr/share/applications) to declare
x-www-browser as a handler for URLs and directory paths. Gtk applications may
not honor it by default, but the included register-browser-shim.sh script will
register it with gio/gvfs. (The gio commands within require the libglib2.0-bin
package on Debian, Ubuntu, and derivatives.)

Requires python 3, [PyGObject](https://pygobject.readthedocs.io/), and the
lxc 1.x tools lxc-monitor and lxc-ls. (The lxc-utils debian package has these.)
