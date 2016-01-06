#!/bin/bash - 

VERSION=1.0.0
CONFIG_FILE=bin/build.json
while true; do
  case "$1" in
    -v | --version ) 
      VERSION=$2
      shift 2;;
    -d | --debug ) 
      CONFIG_FILE=bin/build-debug.json
      shift ;;
    -s | --signed ) 
      CONFIG_FILE=bin/build-signed.json
      shift ;;
    -h | --help ) 
      echo "usage:
  [-d | --debug] build for debug
  [-s | --signed] build for developer signed app
  [-v | --version] version for the image
  [-h | --help] view manual" 
      exit;;
    * ) break ;;
  esac
done

appdmg $CONFIG_FILE ~/Desktop/Rallets-${VERSION}.dmg
