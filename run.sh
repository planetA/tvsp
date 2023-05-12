#!/bin/bash

lscpu
perf stat --table -r 10 -e "cpu_core/ref-cycles/,cpu_core/instructions/,faults,migrations,cs,cpu-clock,duration_time" -C 8 taskset -c 8 ./tvsp -p 400 -i 10000
perf stat --table -r 10 -e "cpu_core/ref-cycles/,cpu_core/instructions/,faults,migrations,cs,cpu-clock,duration_time" -C 8 taskset -c 8 ./tvsp -p 400 -i 10000 -t
perf stat --table -r 10 -e "cpu_atom/ref-cycles/,cpu_atom/instructions/,faults,migrations,cs,cpu-clock,duration_time" -C 24 taskset -c 24 ./tvsp -p 400 -i 10000
perf stat --table -r 10 -e "cpu_atom/ref-cycles/,cpu_atom/instructions/,faults,migrations,cs,cpu-clock,duration_time" -C 24 taskset -c 24 ./tvsp -p 400 -i 10000 -t

uname -a
