CC = gcc
CXX = g++
CXXFLAGS = -std=c++17

LUA_DIR = ../skynet/3rd/lua
SKYNET_DIR = ../skynet/skynet-src
3RDPATH = ../3rd
3RDFLAG = -I$(3RDPATH) -L$(3RDPATH) -Wl,-rpath,3rd:$(3RDPATH)
COMMON_FLAGS = -O2 -fPIC -shared -I$(LUA_DIR)

all : lfs.so lzstd.so lutil.so lkcp.so

lfs.so : lfs/lfs.c
	$(CC) -o $@ $^ $(COMMON_FLAGS) 

lzstd.so : lzstd/lzstd.c
	$(CC) -o $@ $^ $(COMMON_FLAGS) $(3RDFLAG) -lzstd

lutil.so : lutil/*.cc
	$(CXX) -o $@ $^ $(COMMON_FLAGS) $(CXXFLAGS)

lkcp.so: kcp/*.c kcp/*.cc
	$(CXX) -o $@ $^ $(COMMON_FLAGS) $(CXXFLAGS) -I$(SKYNET_DIR)

.PHONY : clean
clean:
	rm *.so