#!/bin/bash

set -euo pipefail

pushd lib/bin/godot
    if [ -e Godot.app ]; then
        echo 'Godot 3.4.2 is already downloaded.'
    else
        wget https://downloads.tuxfamily.org/godotengine/3.4.2/Godot_v3.4.2-stable_osx.universal.zip
        unzip Godot_v3.4.2-stable_osx.universal.zip
        rm Godot_v3.4.2-stable_osx.universal.zip
    fi
popd
