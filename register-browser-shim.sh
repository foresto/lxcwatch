#!/bin/sh

# Register our browser shim script with gio/gvfs, for use with Gtk applications
gio mime x-scheme-handler/https x-www-browser.desktop
gio mime x-scheme-handler/http x-www-browser.desktop
gio mime inode/directory x-www-browser.desktop
