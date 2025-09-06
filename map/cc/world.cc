#include "world.h"

#include <cmath>
#include <iostream>
#include <random>
#include <sstream>
using namespace std;

void World::init_world(int16_t len, int16_t wid) {
  len_ = len;
  wid_ = wid;
  entities_ = vector<vector<int32_t>>(len, vector<int32_t>(wid));
  watch_grids_ = vector<vector<set<Watch>>>(
      len / WATCH_LEN + 1, vector<set<Watch>>(wid / WATCH_LEN + 1));
}

int16_t World::correct_x(int16_t x) {
  if (x < 0) return 0;
  if (x >= len_) return len_ - 1;
  return x;
}

int16_t World::correct_y(int16_t y) {
  if (y < 0) return 0;
  if (y >= wid_) return wid_ - 1;
  return y;
}

bool World::check_pos(int16_t cx, int16_t cy, int16_t len) {
  int16_t blx = cx - (len - 1);
  int16_t bly = cy - (len - 1);
  int16_t trx = cx + len - 1;
  int16_t try_ = cy + len - 1;

  if (blx < 0 || blx >= len_) return false;
  if (trx < 0 || trx >= len_) return false;
  if (bly < 0 || bly >= wid_) return false;
  if (try_ < 0 || try_ >= wid_) return false;
  return true;
}

void World::dump_troops() {
  ostringstream oss;
  for (auto [id, troop] : troops_) {
    oss << "id:" << troop.id_;
    oss << " speed:" << troop.speed_;
    oss << " tm:" << troop.tm_;
    oss << " nowx,nowy:" << troop.nowx_ << "," << troop.nowy_;
    oss << " nowpos:" << troop.nowpos_;
    oss << "path: ";
    for (auto v : troop.path_) {
      oss << v << " ";
    }
    oss << endl;
  }
  cout << oss.str() << endl;
}

void World::dump_entites() {
  cout << "dump entities:" << endl;
  ostringstream oss;
  for (int x = 0; x < entities_.size(); ++x) {
    for (int y = 0; y < entities_[x].size(); ++y) {
      auto id = entities_[x][y];
      if (id == 0) continue;
      oss << "(" << x << "," << y << ":" << id << ")" << endl;
    }
  }
  cout << oss.str() << endl;
}

void World::area_entities(int16_t cx, int16_t cy, int16_t len,
                          unordered_set<int32_t> &ret) {
  int16_t blx = correct_x(cx - (len - 1));
  int16_t bly = correct_y(cy - (len - 1));
  int16_t trx = correct_x(cx + len - 1);
  int16_t try_ = correct_y(cy + len - 1);

  for (int16_t x = blx; x <= trx; ++x) {
    for (int16_t y = bly; y <= try_; ++y) {
      auto id = entities_[x][y];
      if (id != 0) ret.insert(id);
    }
  }
}

void World::add_entity(int16_t cx, int16_t cy, int16_t len, int32_t id,
                       vector<int32_t> &watches) {
  if (id <= 0) return;
  if (!check_pos(cx, cy, len)) return;
  unordered_set<int32_t> ret;
  area_entities(cx, cy, len, ret);
  if (ret.size() > 0) return;

  int16_t blx = cx - (len - 1);
  int16_t bly = cy - (len - 1);
  int16_t trx = cx + len - 1;
  int16_t try_ = cy + len - 1;
  for (int16_t x = blx; x <= trx; ++x) {
    for (int16_t y = bly; y <= try_; ++y) {
      entities_[x][y] = id;
    }
  }
  search_watches(cx, cy, len + WATCH_LEN, watches);
}

void World::del_entity(int16_t cx, int16_t cy, int16_t len,
                       vector<int32_t> &watches) {
  if (!check_pos(cx, cy, len)) return;
  int16_t blx = cx - (len - 1);
  int16_t bly = cy - (len - 1);
  int16_t trx = cx + len - 1;
  int16_t try_ = cy + len - 1;
  for (int16_t x = cx; x <= trx; ++x) {
    for (int16_t y = cy; y <= try_; ++y) {
      entities_[x][y] = 0;
    }
  }
  search_watches(cx, cy, len + WATCH_LEN, watches);
}

bool World::troop_arrive(Troop &troop) {
  if (troop.nowpos_ * 2 + 2 >= troop.path_.size()) return true;
  return false;
}

void World::troop_move_dis(Troop &troop, double dis) {
  if (dis <= 0) return;
  if (troop_arrive(troop)) return;

  int16_t nowpos = troop.nowpos_;
  auto &path = troop.path_;
  int16_t nextx = path[nowpos * 2 + 2];
  int16_t nexty = path[nowpos * 2 + 3];
  double nowx = troop.nowx_;
  double nowy = troop.nowy_;

  double dx = nextx - nowx;
  double dy = nexty - nowy;
  double ddis = sqrt(pow(dx, 2) + pow(dy, 2));

  if (dis >= ddis) {
    troop.nowx_ = nextx;
    troop.nowy_ = nexty;
    troop.nowpos_++;
    troop_move_dis(troop, dis - ddis);
  } else {
    troop.nowx_ += dx / ddis * dis;
    troop.nowy_ += dy / ddis * dis;
  }
}

void World::dump_troop_grids() {
  cout << "dump_troop_grids:" << endl;
  ostringstream oss;
  for (int x = 0; x < troop_grids_.size(); ++x) {
    for (int y = 0; y < troop_grids_[x].size(); ++y) {
      auto &set_ = troop_grids_[x][y];
      if (set_.size() == 0) continue;
      oss << x << "," << y << ":";
      for (auto id : set_) {
        oss << id << " ";
      }
      oss << endl;
    }
  }
  cout << oss.str() << endl;
}

void World::gen_one_troop_grid(int32_t id, double sx, double sy, double ex,
                               double ey, int max) {
  if (max <= 0) return;

  double dx = ex - sx;
  double dy = ey - sy;
  double dis = sqrt(pow(dx, 2) + pow(dy, 2));
  double x = sx;
  double y = sy;
  while (true) {
    double x1 = x - ex;
    double y1 = y - ey;
    if (x1 * dx + y1 * dy >= 0) {
      // cout << "end:" << ex << " " << ey << endl;
      auto &vec = troop_grids_[ex / WATCH_LEN][ey / WATCH_LEN];
      if (vec.empty() || vec.back() != id) {
        vec.push_back(id);
      }
      break;
    }

    int16_t gx = x / WATCH_LEN;
    int16_t gy = y / WATCH_LEN;
    // cout << x / WATCH_LEN << " " << y / WATCH_LEN << endl;
    auto &vec = troop_grids_[x / WATCH_LEN][y / WATCH_LEN];
    if (vec.empty() || vec.back() != id) {
      vec.push_back(id);
      if (--max <= 0) break;
    }
    x += WATCH_LEN * dx / dis;
    y += WATCH_LEN * dy / dis;
  }
}

void World::gen_troop_grids() {
  troop_grids_ = vector<vector<vector<int32_t>>>(
      len_ / WATCH_LEN + 1, vector<vector<int32_t>>(wid_ / WATCH_LEN + 1));

  for (auto &[id, troop] : troops_) {
    int PERMAX = 200000 / troops_.size();
    if (troop_arrive(troop)) continue;
    double ex = troop.nowx_;
    double ey = troop.nowy_;
    const auto &path = troop.path_;
    double sx = path[path.size() - 2];
    double sy = path[path.size() - 1];

    gen_one_troop_grid(id, sx, sy, ex, ey, PERMAX / 2);
    gen_one_troop_grid(id, ex, ey, sx, sy, PERMAX / 2);
  }
}

void World::troops_move(int64_t tm, vector<int32_t> &arrive) {
  for (auto &[id, troop] : troops_) {
    int64_t timediff = tm - troop.tm_;
    if (timediff <= 300) continue;
    troop.tm_ = tm;
    double dis = timediff / 1000 * troop.speed_;
    troop_move_dis(troop, dis);
    if (troop_arrive(troop)) arrive.push_back(id);
  }

  for (auto id : arrive) troops_.erase(id);
}

void World::add_troop(int32_t id, int64_t tm, double speed,
                      vector<int16_t> &path) {
  size_t path_size = path.size();
  if (path_size < 4) return;
  if (path_size % 2 == 1) return;
  if (speed <= 0) return;

  int16_t sx = path[0];
  int16_t sy = path[1];
  int16_t ex = path[path_size - 2];
  int16_t ey = path[path_size - 1];
  if (!check_pos(sx, sy, 1)) return;
  if (!check_pos(ex, ey, 1)) return;

  Troop t;
  t.id_ = id;
  t.path_ = path;
  t.nowpos_ = 0;
  t.nowx_ = sx;
  t.nowy_ = sy;
  t.tm_ = tm;
  t.speed_ = speed;
  troops_[id] = t;
  // dump_troops();
}

void World::del_troop(int32_t id) {
  if (auto it = troops_.find(id); it != troops_.end()) {
    auto &troop = it->second;
  }
  troops_.erase(id);
}

void World::search_watches(int16_t cx, int16_t cy, int16_t len,
                           vector<int32_t> &ids) {
  if (!check_pos(cx, cy, 1)) return;
  int16_t blx = correct_x(cx - (len - 1));
  int16_t bly = correct_y(cy - (len - 1));
  int16_t trx = correct_x(cx + len - 1);
  int16_t try_ = correct_y(cy + len - 1);

  int mingx = cx / WATCH_LEN;
  int maxgx = trx / WATCH_LEN;
  int mingy = cy / WATCH_LEN;
  int maxgy = try_ / WATCH_LEN;

  int grids_num = (maxgx - mingx + 1) * (maxgy - mingy + 1);
  int NOTIFY_MAX = 300;

  int all_num = 0;
  for (int i = mingx; i <= maxgx; ++i) {
    for (int j = mingy; j <= maxgy; ++j) {
      const auto &set_ = watch_grids_[i][j];
      all_num += set_.size();
    }
  }

  if (all_num <= 0) return;
  for (int i = mingx; i <= maxgx; ++i) {
    for (int j = mingy; j <= maxgy; ++j) {
      const auto &set_ = watch_grids_[i][j];
      int num = set_.size() / all_num * NOTIFY_MAX;
      for (const auto &w : set_) {
        ids.push_back(w.id_);
        if (--num <= 0) break;
      }
    }
  }
}

void World::troop_watches(unordered_map<int32_t, vector<int32_t>> &ret) {
  gen_troop_grids();
  vector<int16_t> dirs = {0,  0, -1, 1, -1, -1, 1, 1,  1,
                          -1, 0, 1,  0, -1, 1,  0, -1, 0};
  int MAX = 300000;
  for (auto [watchid, wit] : watches_) {
    int PER_MAX = MAX / watches_.size();
    int16_t gcx = wit->cx_ / WATCH_LEN;
    int16_t gcy = wit->cy_ / WATCH_LEN;
    for (int i = 0; i < 9; ++i) {
      int16_t gx = gcx + dirs[i * 2];
      int16_t gy = gcy + dirs[i * 2 + 1];

      if (gx < 0 || gx >= troop_grids_.size()) continue;
      if (gy < 0 || gy >= troop_grids_[gx].size()) continue;

      auto &set_ = ret[watchid];
      auto &troop_grid = troop_grids_[gx][gy];
      for (auto troopid : troop_grid) {
        set_.push_back(troopid);
        if (set_.size() >= PER_MAX) break;
      }
      if (set_.size() >= PER_MAX) break;
    }
    if (ret[watchid].size() == 0) ret.erase(watchid);
  }
}

void World::del_watch(int32_t id) {
  if (auto it = watches_.find(id); it != watches_.end()) {
    auto git = it->second;
    int16_t cx = git->cx_;
    int16_t cy = git->cy_;
    auto &set_ = watch_grids_[cx / WATCH_LEN][cy / WATCH_LEN];
    set_.erase(git);
    watches_.erase(it);
  }
}

void World::add_watch(int32_t id, int32_t weigh, int16_t cx, int16_t cy) {
  if (!check_pos(cx, cy, 1)) return;
  del_watch(id);
  Watch w = {.id_ = id, .weigh_ = weigh, .cx_ = cx, .cy_ = cy};
  auto &set_ = watch_grids_[cx / WATCH_LEN][cy / WATCH_LEN];
  auto [it, ok] = set_.insert(w);
  if (ok) {
    watches_[id] = it;
  }
}

void World::dump_watches() {
  ostringstream oss;
  oss << "watches:" << endl;
  for (auto [id, it] : watches_) {
    oss << id << " " << it->weigh_;
    oss << " " << it->cx_ << "," << it->cy_ << "|";
  }
  oss << endl;
  oss << "grid watches:" << endl;
  for (int x = 0; x <= len_ / WATCH_LEN; ++x) {
    for (int y = 0; y <= wid_ / WATCH_LEN; ++y) {
      auto &set_ = watch_grids_[x][y];
      if (set_.size() > 0) {
        oss << x << "," << y << ":";
        for (auto &w : set_) {
          oss << "(" << w.id_ << " " << w.weigh_ << " " << w.cx_ << "," << w.cy_
              << " )";
        }
        oss << endl;
      }
    }
  }
  cout << oss.str() << endl;
}
