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

The easiest way to run it under Windows is to download MSYS2, open the
**UCRT64** terminal &:

~~~
$ pacman -S --needed git curl wget patch base-devel pacman-contrib coreutils mingw-w64-ucrt-x86_64-toolchain
$ git clone https://github.com/xeechou/dotemacs-msbin.git
$ cd dotemacs-msbin
$ MINGW_ARCH=ucrt64 makepkg-mingw -f -s --noconfirm
~~~

`MINGW_ARCH=ucrt64` builds only the ucrt64 flavor instead of every entry of
`mingw_arch`. The resulting `dotemacs-bin-<pkgver>-1-any.pkg.tar.zst` is in the
current directory; with the native compilation toolchain it is several times
larger than the ~100MB it used to be.

### Installing

Close Emacs first, Windows locks DLLs that are in use. Extract into a fresh
folder so files dropped by a new version do not linger:

~~~
$ mv /c/Softwares/dotEmacs /c/Softwares/dotEmacs.old
$ mkdir -p /c/Softwares/dotEmacs
$ tar -I zstd -xf dotemacs-bin-*-any.pkg.tar.zst -C /c/Softwares/dotEmacs
~~~

### On Starting Emacs Server
I use this [script](./StartEmacs.bat) to start the Emacs server, it boils down to `emacsclientw.exe -n -c -a ""` to start a server, then later you can use `emacsclientw.exe -create-frame` to start a frame.

The script rebuilds `PATH` from scratch and expects these user environment
variables:

| Variable          | Example                         | Required |
|-------------------|---------------------------------|----------|
| `SOFTWARE_ROOT`   | `C:\Softwares`                  | yes, `DotEmacs`, `Git`, `LLVM`, ... live under it |
| `EMACS_ROOT`      | `C:\Softwares\Emacs\emacs-31.1` | yes      |
| `VK_SDK_PATH`     | `C:\Softwares\VulkanSDK\1.4.x`  | yes      |
| `PYTHON_SDK_PATH` | `C:\Python312`                  | no       |

#### Notes
1. `HOME` is set to `%USERPROFILE%`. Without `HOME`, Emacs on Windows uses
   `%APPDATA%\.emacs.d` (`AppData\Roaming`) instead of `~\.emacs.d`, so
   launching `emacs.exe` directly from Explorer or the Start menu silently
   loads a different, empty configuration.

2. setup the `TMP` and `TEMP` variable

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

### Version compatibility

- **Emacs and libgccjit do not need to match.** Emacs on Windows does not link
  against libgccjit at build time; it loads `libgccjit-0.dll` at runtime and
  resolves the `gcc_jit_*` entry points by name. That C API only grows, so an
  Emacs 31 build works with whatever recent libgccjit MSYS2 ships, not only
  gcc 15.2. Moving to a newer gcc is a rebuild of this package.
- **libgccjit and the gcc toolchain must match exactly.** The DLL locates its
  toolchain through the versioned driver
  (`x86_64-w64-mingw32-gcc-<version>.exe`) on `PATH` and links against that
  version's `crtbegin.o`/`libgcc.a`. The MSYS2 `libgccjit` package pins the
  exact `gcc` release and this package ships the whole dependency closure, so
  never mix a DLL and a toolchain from different MSYS2 snapshots.
- **`.eln` files depend on the Emacs build, not on gcc.** The
  `eln-cache/<emacs-version>-<hash>/` directory is keyed on the Emacs build, so
  upgrading gcc keeps existing `.eln` files valid; upgrading Emacs does not.
  Likewise `.elc` files expand macros of the Emacs version that compiled them.
  After switching Emacs versions, run `M-x package-recompile-all` so the two do
  not mix.

### Troubleshooting

- **`error invoking gcc driver`, `ld: cannot find dllcrt2.o`, `-lmingw32`, ...**
  The gcc driver built into libgccjit ran but could not locate its toolchain,
  so it handed `ld` empty library paths, and `as`/`ld` came from whatever was
  first on `PATH`. Make sure `DotEmacs\ucrt64\bin` is on `PATH` at launch,
  ahead of any other gcc.
- **`(native-comp-available-p)` returns nil.** The DLL did not load. Check that
  no stale `libgccjit-0.dll` sits in the Emacs `bin` folder, since Windows
  searches it first. Also note that Windows resolves the DLL's *own*
  dependencies from the Emacs `bin` folder first: the official installer ships
  `libisl-23.dll`, `libmpc-3.dll`, `libmpfr-6.dll`, `libgmp-10.dll`,
  `libzstd.dll`, `zlib1.dll`, `libwinpthread-1.dll` and `libgcc_s_seh-1.dll`
  there. A new soname (say `libisl-24.dll`) is harmless and gets picked up from
  this package, but a newer libgccjit needing newer symbols from a DLL with the
  same name fails to load. After upgrading this package, compare those DLLs
  first.
- **`Symbol's value as variable is void: <mode>--set-explicitly`** or similar
  errors after an Emacs upgrade: stale `.elc` files compiled by the previous
  Emacs. Run
  `emacs --batch --eval '(progn (package-initialize) (package-recompile-all))'`
  with `HOME` set, then restart.

## Result artifacts

Once you have the package you can extract it some where (eg
`C:\Softwares\dotEmacs`, see [Installing](#installing)) then add its
`ucrt64\bin` and `usr\bin` folders to the `PATH`, or let
[StartEmacs.bat](./StartEmacs.bat) do it.



## License

MIT
