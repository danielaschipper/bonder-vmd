#!/bin/bash
path=$1
cd wfn
make
cd ..
cp bonder $path"/plugins/noarch/tcl" -r
cp wfn/wfnplugin.so $path"/plugins/LINUXAMD64/molfile/wfnplugin.so"

