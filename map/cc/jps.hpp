#ifndef __JPS_HPP__
#define __JPS_HPP__

#include <array>
#include <cmath>
#include <functional>
#include <iostream>
#include <map>
#include <queue>
#include <string>
#include <unordered_map>
#include <vector>

using std::array;
using std::cout;
using std::endl;
using std::function;
using std::map;
using std::priority_queue;
using std::string;
using std::vector;

struct Pos {
  int16_t x_, y_;
  bool operator<(const Pos &rhs) const {
    if (x_ != rhs.x_) return x_ < rhs.x_;
    return y_ < rhs.y_;
  }
  bool operator==(const Pos &rhs) const { return x_ == rhs.x_ && y_ == rhs.y_; }
};

struct State {
  int16_t x_, y_;
  int32_t cost_, weigh_;
  int8_t dx_, dy_;
  bool operator<(const State &rhs) const { return weigh_ > rhs.weigh_; }
};

struct World {
  vector<vector<int8_t>> map_;
  int16_t len_, wid_;

  void init_world(int16_t len, int16_t wid) {
    len_ = len;
    wid_ = wid;
    map_ = vector<vector<int8_t>>(wid, vector<int8_t>(len));
  }

  bool side_check(Pos p) {
    auto x = p.x_;
    auto y = p.y_;
    if (x < 0 || x >= len_) return false;
    if (y < 0 || y >= wid_) return false;
    return true;
  }

  bool walkable(Pos p) {
    if (!side_check(p)) return false;
    if (block(p)) return false;
    return true;
  }

  void set_block(int16_t minx, int16_t miny, int16_t maxx, int16_t maxy, int8_t v) {
    if (!side_check({minx, miny}) || !side_check({maxx, maxy})) return;
    if (minx > maxx || miny > maxy) return;
    for (int x = minx; x <= maxx; ++x) {
      for (int y = miny; y <= maxy; ++y) {
        map_[x][y] = v;
      }
    }
  }

  bool block(Pos p) {
    if (!side_check(p)) return false;
    return map_[p.x_][p.y_];
  }
};

struct Jps {
  World world_;
  vector<vector<array<int16_t, 4>>> jp_cache_;

  bool over_;
  int8_t quick_;
  Pos start_, end_;
  map<Pos, Pos> *ppres_;
  priority_queue<State> *popen_list_;

  int dis(Pos p1, Pos p2);
  string dump_jp_cache(Pos dir);
  int search_jp_cache(Pos p, Pos dir);
  void add_jp_cache(Pos p, Pos dir, int16_t len);
  void line_jp_cache(Pos p, Pos dir);
  void block_jp_cache(int16_t minx, int16_t miny, int16_t maxx, int16_t maxy);
  void init_jp_cache();
  bool side_check(Pos p) { return world_.side_check(p); }
  bool walkable(Pos p) { return world_.walkable(p); }

  void cal_weigh(State &state);
  bool find_end(Pos p, Pos dir);

  void add_jp(State s, Pos pre);
  bool add_force_neighbor(State s, Pos dir);
  bool add_jp_to_openlist(State s, Pos dir);
  bool step(State s, Pos dir);
  void force_neighbor(Pos p, Pos dir, function<void(Pos, Pos)> cb);
  void pathfind(Pos s, Pos e, vector<Pos> &ret);
};

#endif