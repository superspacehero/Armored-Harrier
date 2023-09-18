#!/bin/bash

first_letter="$(echo $1 | head -c1)"
godot="/home/superspacehero/.local/share/godot/app_userdata/Godots/versions/Godot_v4_1_1-stable_linux_x86_64/Godot_v4.1.1-stable_linux.x86_64" "--path"
project_path="/home/superspacehero/Projects/Armored Harrier"
scene="World.godot"
github="flatpak run io.github.shiftey.Desktop & git lfs pull"

case "$first_letter" in
    "p")
        $godot "--path" $project_path "-e" & code . & $github &
        ;;
    "b")
        $godot "--path" $project_path "-e" & flatpak run org.blender.Blender & $github &
        ;;
    "a")
        $godot "--path" $project_path "-e" & flatpak run org.gimp.GIMP & $github &
        ;;
    "c")
        $godot "--path" $project_path "-e" & clip-snap-paint & $github &
        ;;
    *)
        $godot "--path" $project_path "-e" & $github &
        ;;
esac
