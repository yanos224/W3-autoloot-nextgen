@ECHO OFF
echo.
echo *************************************
echo *                                   *
echo *   AutoLoot Configurable AIO 3.0   *
echo *   Menu Installer  --  by AeroHD   *
echo *                                   *
echo *************************************
echo.
echo This file will install the AutoLoot Configurable AIO menu for you into your
echo Witcher 3 config directory. No further action from you is required to install.
echo.
echo *************************************
echo.
cd /D ../..
echo Copying AutoLoot config menu:
echo - From: %cd%\mods\modAutoLootMenu\bin
echo - To:   %cd%\bin
echo.
xcopy /S /Y /Q "mods\modAutoLootMenu\bin" "bin"
pause