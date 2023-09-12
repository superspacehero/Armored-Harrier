#!/bin/bash

first_letter="$(echo $1 | head -c1)"
unity="/home/superspacehero/Applications/Unity/2022.3.8f1/Editor/Unity"
scenepath="$(pwd)/Assets/Main/Scenes"
scene="World.unity"
github="flatpak run io.github.shiftey.Desktop & git lfs pull"

case "$first_letter" in
    "p")
        $unity -openfile $scenepath/$scene & code . & $github &
        ;;
    "b")
        $unity -openfile $scenepath/$scene & flatpak run org.blender.Blender & $github &
        ;;
    "a")
        $unity -openfile $scenepath/$scene & flatpak run org.gimp.GIMP & $github &
        ;;
    "c")
        $unity -openfile $scenepath/$scene & clip-snap-paint & $github &
        ;;
    *)
        $unity -openfile $scenepath/$scene & $github &
        ;;
esac
