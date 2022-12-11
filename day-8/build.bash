#!/bin/bash

g++ -c -o main.o main.cpp -std=c++11
yasm -f elf64 -o mainasm.o main.asm
g++ -no-pie -o main main.o mainasm.o

