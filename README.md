# Emacs binaries management for Windows v0.2.0

The project originates from gromnitsky's
[hunspell-windows](https://github.com/gromnitsky/hunspell-windows). Later I
found it is perfect for maintaining x64 binaries for my Emacs usage on Windows.

Right now it includes:
- hunspell (and dictionaries libreoffice repo)
- riggrep;
- SQLite;
- ninja-build;
- curl;
- coreutils;
- diffuitls;
- binutils;


The binaries are downloaded from the MSYS2 mirrors; the libreoffice dicts are
renamed to match `language_territory` locale names, like `uk_UA` or `en_GB`.

## Softwares that you should install on Windows directly
- [Git Windows](https://git-scm.com/download/win)
- [Imagemagick](https://imagemagick.org/) for `org-download-clipboard` to work
- [MikTek](https://miktex.org/) for `org-latex-preview`

## Usage

The makefile works under Cygwin, MSYS2 or any modern Linux distro.

The easiest way to run it under Windows is to download MSYS2, run
`msys2.exe` &:

~~~
$ pacman -S git patch curl base-devel
$ git clone ...
$ cd dotemacs-msbin
$ makepkg -s
~~~

The resulting .tar.zst (~100MB) should be in current directory

### On Starting Emacs Server
I use this [script](./StartEmacs.bat) to start the Emacs server, it boils down to `emacsclientw.exe -n -c -a ""` to start a server, then later you can use `emacsclientw.exe -create-frame` to start a frame.

## Result artifacts

Once you have the zip you can extract it some where (eg C:/Softwares/emacs-bin)
then adding bin folder to the PATH

## License

MIT
