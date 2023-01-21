@echo off
setlocal

pushd lib\bin\godot
    if exist Godot_v3.4.2-stable_win64.exe (
        echo Godot 3.4.2 is already downloaded.
    ) else (
        echo Downloading Godot 3.4.2...
        curl --output godot_download.zip https://downloads.tuxfamily.org/godotengine/3.4.2/Godot_v3.4.2-stable_win64.exe.zip
        tar -xvf godot_download.zip
        del godot_download.zip
        echo Successfully downloaded Godot 3.4.2.
    )
popd
