# Emacs binaries management for Windows v0.3.0

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
- libgccjit, with the matching gcc driver and mingw crt, for Emacs native
  compilation (see [Native compilation](#native-compilation));


The binaries are downloaded from the MSYS2 mirrors; the libreoffice dicts are
renamed to match `language_territory` locale names, like `uk_UA` or `en_GB`.

## Softwares that you should install on Windows directly
- [Git Windows](https://git-scm.com/download/win)
- [Imagemagick](https://imagemagick.org/) for `org-download-clipboard` to work
- [MikTek](https://miktex.org/) for `org-latex-preview`
- [Python](https://www.python.org/downloads/windows/) for `pylsp`
- [Ollama](https://ollama.com/) for `ellama` llm usage

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

#### Notes
1. setup the `TMP` and `TEMP` variable

Windows somehow gives you **ill-formed**
temporary path (some kind of abbreviation that I am sure), which makes
`temporary-file-directory` variable **ill-formed** in Emacs, which I use to
configure the `org-preview-latex-image-directory`. The `dvipng` never
gets the output `tex` path correctly because of it.


## Native compilation

The official GNU Emacs installers are built with native compilation but do not
ship `libgccjit`, so `(native-comp-available-p)` returns nil and third-party
packages stay byte-compiled. This package provides `libgccjit-0.dll` together
with the gcc driver, binutils and mingw crt it needs to assemble and link each
`.eln`, all from the same MSYS2 snapshot.

Do not copy `libgccjit-0.dll` into the Emacs `bin` folder. Emacs loads it with
the normal Windows DLL search, so it is enough for `ucrt64\bin` of this
package to be on `PATH` **when Emacs starts** (setting `PATH` from `init.el`
is too late for the DLL itself). Put it before any other gcc on `PATH`, such
as Strawberry Perl's, as [StartEmacs.bat](./StartEmacs.bat) does. Then:

~~~elisp
(native-comp-available-p) ;; => t
~~~

`.eln` files are tied to the Emacs build, and `.elc` files expand macros of
the Emacs version that compiled them. After switching Emacs versions, run
`M-x package-recompile-all` so the two do not mix.

## Result artifacts

Once you have the zip you can extract it some where (eg C:/Softwares/emacs-bin)
then adding bin folder to the PATH



## License

MIT
