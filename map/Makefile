COMMON_FLAGS = -O2 -fPIC -I../skynet/3rd/lua -std=c++17

srcs = $(wildcard cc/*.cc)

srcso = $(srcs:%.cc=%.o)

lworld.so : $(srcso)
	$(CXX) -o $@ $^ $(COMMON_FLAGS) -shared && mv lworld.so ../luaclib

%.o:%.cc
	$(CXX) -o $@ -c $< $(COMMON_FLAGS) 

clean:
	rm cc/*.o