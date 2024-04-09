# Statusbar (got any better names?)
This is a filesystem-based statusbar for Nimdow and other `xsetroot -name` based
statusbar WMs. After you run statusbar and give it an empty folder it will mount
a virtual filesystem. In this filesystem you can use `mkdir` to create new
"blocks" on your statusbar. When you create folders they get populated with
three files: "foreground", "background", and "content" which control the text
color, the block color, and the content of the block respectively. Both
foreground and background gets pre-populated with colors from the Nord theme.
To change the colour write a 6 byte hexademical color to these files. To change
the contents of a block write anything to the contents file. Doing so sets the
name of your root window to a series of blocks (using airline characters and
ANSI escape codes) sorted by the name of their folders. It also writes this
string to the terminal, so if you run statusbar with the `-f` flag (to run in
the foreground and not daemonize it) you can see the blocks in your terminal.

This assumes your window manager parses ANSI escape codes for the statusbar.
Nimdow does this, but not sure if any other window manager does it, so YMMV.

Currently this is a pretty dirty first draft of this application, but it is
functional. Ultimately I'd like to add support for more block styles and themes.
The goal of this statusbar is not to be able to collect statusbar information,
but simply as an easy way to display this information as neat little blocks in
the statusbar. To put useful information on the bar use other scripts which
writes to the content files.
