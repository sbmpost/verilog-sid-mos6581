#!/bin/bash

cat song2.bin | cut -d' ' -f2- | xxd -r -p | xxd -c1 | cut -c5- | sed "s/\(.*\): \(.*\).../s_mem_contents[12'h\1] = 8\'h\2;/g" > ./memory.txt
