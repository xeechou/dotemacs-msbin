rem Sets HOME for current shell if you haven't set HOME environment variable
rem already, now I align emacs home to %USERPROFILE%, this align with git-windows.
rem Without HOME, Emacs falls back to %APPDATA%\.emacs.d instead of ~\.emacs.d
set HOME=%USERPROFILE%
rem Correcting the temp directory, it is somehow corrupted on windows, this is crucial for correcting temporary-file-direcotory for org-latex-preview
set TMP=%HOME%\AppData\Local\Temp
set TEMP=%HOME%\AppData\Local\Temp

rem setup the proxies
rem set http_proxy=https://your_proxy_address:port
rem set https_proxy=https://your_proxy_address:port
rem set ftp_proxy=https://your_proxy_address:port
rem set no proxy for local addresses
rem set no_proxy=localhost,127.0.0.1,192.168.1.1

rem Required user environment variables, for example
rem   SOFTWARE_ROOT=C:\Softwares                    (DotEmacs, Git, LLVM, ... live under it)
rem   EMACS_ROOT=C:\Softwares\Emacs\emacs-31.1
rem   VK_SDK_PATH=C:\Softwares\VulkanSDK\<version>
rem Optional: PYTHON_SDK_PATH
if "%SOFTWARE_ROOT%"=="" (
    set /p DUMMY=SOFTWARE_ROOT ENV variable not exists...
    exit 1
) else (
    set ROOT=%SOFTWARE_ROOT%
)

if "%EMACS_ROOT%"=="" (
    set /p DUMMY=EMACS_ROOT not defined, please install Emacs...
    exit 1
)

if "%VK_SDK_PATH%"=="" (
   set /p DUMMY=VK_SDK_PATH not defined, please install vulkan...
   exit 1
)

rem set PATH and MANPATH
rem PATH is rebuilt from scratch on purpose. DotEmacs\ucrt64\bin must be on it
rem before Emacs starts and ahead of any other gcc (e.g. Strawberry Perl's):
rem Emacs loads libgccjit-0.dll from PATH at runtime, and libgccjit finds its
rem toolchain (crt, libgcc, as, ld) through the gcc driver next to it.
set PATH=%EMACS_ROOT%\bin;%ROOT%\DotEmacs\ucrt64\bin;%ROOT%\DotEmacs\usr\bin;
rem set PATH=%PATH%%ROOT%\ImageMagick-7.1.1-Q16-HDRI;

rem add PYTHON to PATH
if "%PYTHON_SDK_PATH%"=="" (
   set /p DUMMY=Python not, you may want to install a python distribution...
) else (
  set PATH=%PATH%%PYTHON_SDK_PATH%;%PYTHON_SDK_PATH%\Scripts;
)

set PATH=%PATH%%ROOT%\MiKTeX\miktex\bin\x64;
set PATH=%PATH%%ROOT%\flutter\bin;
set PATH=%PATH%%ROOT%\nodejs;
set PATH=%PATH%%ROOT%\Git\mingw64\bin;%ROOT%\LLVM\bin;%ROOT%\CMake\bin;%VK_SDK_PATH%\Bin;
set PATH=%PATH%C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\OpenSSH;C:\Windows\System32\WindowsPowerShell\v1.0;
set PATH=%PATH%%USERPROFILE%\.local\bin;
set PATH=%PATH%%USERPROFILE%\.elan\bin;
set MANPATH=%ROOT%\DotEmacs\ucrt64\share\man;%ROOT%\DotEmacs\usr\share\man

rem RUST variables
set PATH=%PATH%%HOME%\.cargo\bin;
set RUSTUP_HOME=%HOME%\.rustup;
set CARGO_HOME=%HOME%\.cargo;

rem set SSH_ASKPASS so git-ssh will work
set SSH_ASKPASS=%ROOT%\Git\mingw64\libexec\git-core\git-gui--askpass
set GIT_BINPATH=%ROOT%\Git\usr\bin

del /q %HOME%\.emacs.d\server\*
rem start emacs server, using emacsclientw.exe -create-frame to start new client
%EMACS_ROOT%\bin\emacsclientw.exe -n -c -a ""
rem %EMACS_ROOT%\bin\runemacs.exe --chdir %HOME%

rem to start an Emacs client
rem %EMACS_ROOT%\bin\emacsclientw.exe -n -c --server-file %USERPROFILE%\.emacs.d\server\server
