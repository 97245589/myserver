CC = gcc
export CC
CXX = g++
export CXX
CXXFLAGS = -std=c++17
export CXXFLAGS
THREAD_NUM = 16
export THREAD_NUM

SKYNET = skynet/skynet
LUACLIB = luaclib/lfs.so

all : $(SKYNET) $(LUACLIB) 

$(SKYNET):
	git submodule update --init &&  make linux -j$(THREAD_NUM) -Cskynet

$(LUACLIB):
	make -j$(THREAD_NUM) -Cluaclib
	
cleanskynet:
	make cleanall -Cskynet

cleanluaclib:
	make clean -Cluaclib

clean: cleanluaclib

cleanall: cleanskynet cleanluaclib 