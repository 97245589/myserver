THREAD_NUM = 16

SKYNET = skynet/skynet
LUACLIB = luaclib/lkcp.so
MAP = map.so

all : $(SKYNET) $(LUACLIB) $(MAP)

$(SKYNET):
	git submodule update --init &&  make linux -j$(THREAD_NUM) -Cskynet

$(LUACLIB):
	make -j$(THREAD_NUM) -Cluaclib

$(MAP):
	make -j$(THREAD_NUM) -Cmap
	
cleanskynet:
	make cleanall -Cskynet

cleanluaclib:
	make clean -Cluaclib

cleanmap:
	make clean -Cmap

clean: cleanluaclib cleanmap

cleanall: cleanskynet cleanluaclib cleanmap