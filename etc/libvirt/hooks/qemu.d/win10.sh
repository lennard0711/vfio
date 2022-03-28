#!/bin/bash

# Script for win10
if [[ $1 == "win10" ]]; then
  if [[ $2 == "started" ]]; then
    # CPU isolation
    systemctl set-property --runtime -- user.slice AllowedCPUs=2,3,4,5,6,7,10,11,12,13,14,15
    systemctl set-property --runtime -- system.slice AllowedCPUs=2,3,4,5,6,7,10,11,12,13,14,15
    systemctl set-property --runtime -- init.scope AllowedCPUs=2,3,4,5,6,7,10,11,12,13,14,15
    # Disable DVI-D-0
    su -l lennard0711 -c "DISPLAY=:0 xrandr --output DVI-D-0 --off"
  fi
  if [[ $2 == "stopped" ]]; then
    # Free all CPUs
    systemctl set-property --runtime -- user.slice AllowedCPUs=0-15
    systemctl set-property --runtime -- system.slice AllowedCPUs=0-15
    systemctl set-property --runtime -- init.scope AllowedCPUs=0-15
    # Enable DVI-D-0
    su -l lennard0711 -c "DISPLAY=:0 xrandr --output DVI-D-0 --auto --left-of HDMI-0"
    su -l lennard0711 -c "DISPLAY=:0 xrandr --output HDMI-0 --primary"
  fi
fi
