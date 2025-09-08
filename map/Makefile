COMMON_FLAGS = -O2 -fPIC -I../skynet/3rd/lua -std=c++17 -w

srcs = $(wildcard cc/*.cc)

srcso = $(srcs:%.cc=%.o)

lworld.so : $(srcso)
	g++ -o $@ $^ $(COMMON_FLAGS) -shared && mv lworld.so ../luaclib

%.o:%.cc
	g++ -o $@ -c $< $(COMMON_FLAGS) 

clean:
	rm cc/*.o