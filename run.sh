#!/bin/bash

for i in {1..10}; do
    time taskset -c 1 ./tvsp -p 400 -i 10000
    time taskset -c 1 -t ./tvsp -p 400 -i 10000
done
