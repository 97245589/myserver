#ifndef __WORLD_H__
#define __WORLD_H__

#include <cstdint>
#include <set>
#include <unordered_map>
#include <unordered_set>
#include <vector>
using std::hash;
using std::set;
using std::unordered_map;
using std::unordered_set;
using std::vector;

struct Watch
{
  int32_t id_;
  int32_t weigh_;
  int16_t cx_, cy_;
  bool operator<(const Watch &rhs) const
  {
    if (weigh_ != rhs.weigh_)
      return weigh_ > rhs.weigh_;
    return id_ < rhs.id_;
  }
};

struct Troop
{
  int32_t id_;
  vector<int16_t> path_;
  int16_t nowpos_;
  double nowx_, nowy_;
  int64_t tm_;
  double speed_;
};

struct World
{
  int16_t len_, wid_;
  vector<vector<int32_t>> entities_;
  unordered_map<int32_t, Troop> troops_;

  vector<vector<set<Watch>>> watch_grids_;
  unordered_map<int32_t, set<Watch>::iterator> watches_;

  vector<vector<vector<int32_t>>> troop_grids_;

  static const int16_t WATCH_LEN = 5;

  void init_world(int16_t len, int16_t wid);
  int16_t correct_x(int16_t x);
  int16_t correct_y(int16_t y);
  bool check_pos(int16_t cx, int16_t cy, int16_t len);

  void watch_troops(unordered_map<int32_t, vector<int32_t>> &ret);
  void search_watches(int16_t cx, int16_t cy, int16_t len,
                      vector<int32_t> &ids);
  void dump_watches();
  void add_watch(int32_t id, int32_t weigh, int16_t cx, int16_t cy);
  void del_watch(int32_t id);

  void dump_troops();
  void dump_troop_grids();
  void gen_one_troop_grid(int32_t id, double sx, double sy, double ex,
                          double ey, int max);
  void gen_troop_grids();

  void troops_move(int64_t tm, vector<int32_t> &arrive);
  bool troop_arrive(Troop &troop);
  void troop_move_dis(Troop &troop, double dis);
  void add_troop(int32_t id, int64_t tm, double speed, vector<int16_t> &path);
  void del_troop(int32_t id);

  void dump_entites();
  void area_entities(int16_t cx, int16_t cy, int16_t len,
                     unordered_set<int32_t> &ret);
  void add_entity(int16_t cx, int16_t cy, int16_t len, int32_t id,
                  vector<int32_t> &watches);
  void del_entity(int16_t cx, int16_t cy, int16_t len,
                  vector<int32_t> &watches);
};

#endif