rem Sets HOME for current shell if you haven't set HOME environment variable
rem already, now I align emacs home to %USERPROFILE%, this align with git-windows
set HOME=%USERPROFILE%

set http_proxy=https://your_proxy_address:port
set https_proxy=https://your_proxy_address:port
set ftp_proxy=https://your_proxy_address:port
rem set no proxy for local addresses
set no_proxy=localhost,127.0.0.1,192.168.1.1


set PATH=D:\Softwares\Emacs\emacs-29.1\bin;D:\Softwares\DotEmacs\mingw64\bin;D:\Softwares\DotEmacs\usr\bin;
set PATH=%PATH%D:\Softwares\Git\mingw64\bin;D:\Softwares\LLVM\bin;D:\Softwares\CMake\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\OpenSSH\
set MANPATH=D:\Softwares\DotEmacs\mingw64\share\man;D:\Softwares\DotEmacs\usr\share\man

rem set SSH_ASKPASS so git-ssh will work
set SSH_ASKPASS=D:\Softwares\Git\mingw64\libexec\git-core\git-gui--askpass
set GIT_PATH=D:\Softwares\Git\usr\bin

del /q %HOME%\.emacs.d\server\*
rem start emacs server, using emacsclientw.exe -create-frame to start new client
D:\Softwares\Emacs\emacs-29.1\bin\emacsclientw.exe -n -c -a ""
rem D:\Softwares\Emacs\emacs-29.1\bin\runemacs.exe --daemon --chdir %HOME%
