#!/bin/bash
tar -xvf pintos.tar.gz
chmod 700 -R pintos/
cd ~/pintos/src/threads && make
cd ~/pintos/src/threads/build && make
cd ~/pintos/src/utils && make
cd ~/pintos/src/threads/build
pintos --qemu -- -q run alarm-multiple
