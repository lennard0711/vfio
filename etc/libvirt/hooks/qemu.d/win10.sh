#!/bin/bash

# Script for win10
if [[ $1 == "win10" ]]; then
  if [[ $2 == "started" ]]; then
    # Disable DVI-D-0
    su -l lennard0711 -c "DISPLAY=:0 xrandr --output DVI-D-0 --off"
  fi
  if [[ $2 == "stopped" ]]; then
    # Enable DVI-D-0
    su -l lennard0711 -c "DISPLAY=:0 xrandr --output DVI-D-0 --auto --right-of HDMI-0"
  fi
fi