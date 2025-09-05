#include "jps.hpp"

#include <algorithm>
#include <iomanip>
#include <set>
#include <sstream>

using namespace std;

static const int16_t sweigh = 100;
static const int16_t dweigh = 141;

struct Pos_direct_cmp {
  bool operator()(const Pos &lhs, const Pos &rhs) {
    int dx = end_.x_ - start_.x_;
    int dy = end_.y_ - start_.y_;
    if (dx) dx = dx > 0 ? 1 : -1;
    if (dy) dy = dy > 0 ? 1 : -1;
    int l = abs(lhs.x_ - dx) + abs(lhs.y_ - dy);
    int r = abs(rhs.x_ - dx) + abs(rhs.y_ - dy);
    return l < r;
  }
  Pos start_;
  Pos end_;
};

static vector<Pos> dirs = {{0, 1}, {0, -1}, {1, 0},  {-1, 0},
                           {1, 1}, {-1, 1}, {1, -1}, {-1, -1}};
static map<Pos, int8_t> dir_idx = {
    {{0, 1}, 0}, {{0, -1}, 1}, {{1, 0}, 2}, {{-1, 0}, 3}};

bool Jps::add_force_neighbor(State s, Pos dir) {
  bool b = false;
  Pos ps = {s.x_, s.y_};

  force_neighbor(ps, dir, [&](Pos p, Pos dir) {
    auto &pres = *ppres_;
    if (auto it = pres.find(p); it != pres.end()) return false;
    State news = {p.x_, p.y_, s.cost_ + dweigh, 0, dir.x_, dir.y_};
    cal_weigh(news);
    add_jp(news, ps);
    b = true;
  });
  return b;
}

bool Jps::add_jp_to_openlist(State p, Pos dir) {
  if (dir.x_ && dir.y_) return false;
  State s = p;
  Pos ps = {s.x_, s.y_};
  int len = search_jp_cache(ps, dir);
  if (len <= 0) return false;

  s.x_ += dir.x_ * len;
  s.y_ += dir.y_ * len;
  s.cost_ += sweigh * len;

  bool b = add_force_neighbor(s, dir);
  auto &pres = *ppres_;
  if (b) {
    if (pres.find({s.x_, s.y_}) == pres.end()) {
      s.dx_ = dir.x_;
      s.dy_ = dir.y_;
      cal_weigh(s);
      add_jp(s, ps);
    }
  }
  return b;
}

void Jps::add_jp(State s, Pos pre) {
  Pos ps = {s.x_, s.y_};
  if (ps == pre) return;
  auto &open_list = *popen_list_;
  auto &pres = *ppres_;
  if (pres.find(ps) != pres.end()) return;
  // cout << "addjp " << s.x_ << "," << s.y_ << " " << (int)(s.dx_) << ","
  //      << (int)(s.dy_) << " " << s.cost_ << " " << s.weigh_ << " " << pre.x_
  //      << "," << pre.y_ << endl;
  open_list.push(s);
  pres[ps] = pre;
}

bool Jps::find_end(Pos p, Pos dir) {
  if (dir.x_ && dir.y_) return false;
  if (p == end_) return true;

  int dx = end_.x_ - p.x_;
  int dy = end_.y_ - p.y_;
  if (dx) dx = dx > 0 ? 1 : -1;
  if (dy) dy = dy > 0 ? 1 : -1;
  if (dx != dir.x_ || dy != dir.y_) return false;

  int16_t len = search_jp_cache(p, dir);
  if (len <= 0) return false;
  Pos newp = {p.x_ + dx * len, p.y_ + dy * len};
  if (p.x_ <= end_.x_ && p.y_ <= end_.y_ && end_.x_ <= newp.x_ and
      end_.y_ <= newp.y_)
    return true;
  if (p.x_ >= end_.x_ && p.y_ >= end_.y_ && end_.x_ >= newp.x_ &&
      end_.y_ >= newp.y_)
    return true;
  return false;
}

void Jps::cal_weigh(State &s) {
  Pos p{s.x_, s.y_};
  if (p == end_) {
    s.weigh_ = 0;
    return;
  }
  int distance = dis(p, end_);
  if (!quick_) {
    s.weigh_ = distance + s.cost_;
  } else {
    s.weigh_ = distance;
  }
}

void Jps::force_neighbor(Pos p, Pos dir, function<void(Pos, Pos)> cb) {
  if (dir.x_ && dir.y_) return;
  Pos p1 = {p.x_ + dir.y_, p.y_ + dir.x_};
  Pos p11 = {p1.x_ + dir.x_, p1.y_ + dir.y_};
  if (side_check(p1) && side_check(p11)) {
    if (!walkable(p1) && walkable(p11)) {
      cb(p11, {dir.x_ + dir.y_, dir.y_ + dir.x_});
    }
  }

  Pos p2 = {p.x_ - dir.y_, p.y_ - dir.x_};
  Pos p21 = {p2.x_ + dir.x_, p2.y_ + dir.y_};
  if (side_check(p2) && side_check(p21)) {
    if (!walkable(p2) && walkable(p21)) {
      cb(p21, {dir.x_ - dir.y_, dir.y_ - dir.x_});
    }
  }
}

string Jps::dump_jp_cache(Pos dir) {
  ostringstream oss;
  for (int j = world_.wid_ - 1; j >= 0; --j) {
    for (int i = 0; i < world_.len_; ++i) {
      int val = search_jp_cache({i, j}, dir);
      oss << setw(3) << val;
    }
    oss << endl;
  }
  return oss.str();
}

int Jps::search_jp_cache(Pos p, Pos dir) {
  auto &arr = jp_cache_[p.x_][p.y_];
  return arr[dir_idx[dir]];
}

void Jps::add_jp_cache(Pos p, Pos dir, int16_t len) {
  jp_cache_[p.x_][p.y_][dir_idx[dir]] = len;
}

void Jps::line_jp_cache(Pos p, Pos dir) {
  if (dir.x_ && dir.y_) return;
  Pos q = p;
  while (side_check(q) && !walkable(q)) {
    add_jp_cache(q, dir, 0);
    q.x_ += dir.x_;
    q.y_ += dir.y_;
  }
  if (!side_check(q)) return;

  Pos t = q;
  int i = 0;
  while (1) {
    bool fneig = false;
    force_neighbor(t, dir, [&](Pos p1, Pos p2) { fneig = true; });
    if (!walkable(t) || (fneig && i)) {
      if (!walkable(t)) --i;
      for (int16_t j = 0; j <= i; ++j) {
        Pos t2{q.x_ + dir.x_ * j, q.y_ + dir.y_ * j};
        add_jp_cache(t2, dir, i - j);
      }
      line_jp_cache(t, dir);
      return;
    }

    t.x_ += dir.x_;
    t.y_ += dir.y_;
    ++i;
  }
}

void Jps::block_jp_cache(int16_t minx, int16_t miny, int16_t maxx,
                         int16_t maxy) {
  if (minx > maxx || miny > maxy) return;
  if (!side_check({minx, miny}) || !side_check({maxx, maxy})) return;
  for (int16_t i = minx - 1; i <= maxx + 1; ++i) {
    if (i < 0 || i > world_.len_ - 1) continue;
    line_jp_cache({i, 0}, {0, 1});
    line_jp_cache({i, world_.wid_ - 1}, {0, -1});
  }
  for (int16_t j = miny - 1; j <= maxy + 1; ++j) {
    if (j < 0 || j > world_.wid_ - 1) continue;
    line_jp_cache({0, j}, {1, 0});
    line_jp_cache({world_.len_ - 1, j}, {-1, 0});
  }
}

void Jps::init_jp_cache() {
  jp_cache_ = vector<vector<array<int16_t, 4>>>(
      world_.wid_, vector<array<int16_t, 4>>(world_.len_));
  for (int16_t i = 0; i < world_.len_; ++i) {
    line_jp_cache({i, 0}, {0, 1});
    line_jp_cache({i, world_.wid_ - 1}, {0, -1});
  }

  for (int16_t j = 0; j < world_.wid_; ++j) {
    line_jp_cache({0, j}, {1, 0});
    line_jp_cache({world_.len_ - 1, j}, {-1, 0});
  }
}

int Jps::dis(Pos p1, Pos p2) {
  double d = pow((p2.x_ - p1.x_), 2) + pow((p2.y_ - p1.y_), 2);
  return sqrt(d) * 100;
}

bool Jps::step(State start, Pos dir) {
  // cout << "step" << start.x_ << start.y_ << " " << (int)(dir.x_)
  //      << (int)(dir.y_) << " " << endl;
  start.dx_ = dir.x_;
  start.dy_ = dir.y_;
  State s = start;

  while (1) {
    if (!dir.x_ || !dir.y_) {
      Pos ps = {s.x_, s.y_};
      if (!walkable(ps)) return false;
      if (find_end(ps, dir)) {
        over_ = true;
        add_jp({end_.x_, end_.y_, 0, 0, 0, 0}, ps);
        return true;
      }
      if (add_jp_to_openlist(s, dir)) return true;
      return false;
    } else if (dir.x_ && dir.y_) {
      Pos pstart = {start.x_, start.y_};
      Pos ps = {s.x_, s.y_};
      // cout << "===" << s.x_ << s.y_ << " " << (int)(dir.x_) << (int)(dir.y_)
      //      << endl;
      bool b = false;
      auto &pres = *ppres_;
      b = add_force_neighbor(s, {dir.x_, 0}) || b;
      b = add_force_neighbor(s, {0, dir.y_}) || b;
      if (b) {
        if (!(ps == pstart) && pres.end() == pres.find(ps)) {
          pres[ps] = pstart;
        }
        int x = s.x_;
        int y = s.y_;
        int dx = dir.x_;
        int dy = dir.y_;
        bool b1 = side_check({x + dx, y}) && !walkable({x + dx, y});
        bool b2 = side_check({x, y + dy}) && !walkable({x, y + dy});
        bool b3 = side_check({x + dx, y + dy}) && walkable({x + dx, y + dy});
        // cout << x << y << " " << dx << dy << endl;
        // cout << "check:" << b1 << b2 << b3 << endl;
        if ((b1 || b2) && b3) return true;
      }

      s.x_ += dir.x_;
      s.y_ += dir.y_;
      s.cost_ += dweigh;
      ps = {s.x_, s.y_};
      if (!walkable(ps)) return false;
      if (ps == end_) {
        over_ = true;
        s.weigh_ = 0;
        add_jp(s, pstart);
        return true;
      }
      // cout << s.x_ << "  " << s.y_ << endl;

      bool r = false;
      r = step(s, {dir.x_, 0}) || r;
      r = step(s, {0, dir.y_}) || r;
      if (r) {
        if (pres.end() == pres.find(ps)) {
          pres[ps] = pstart;
          s.x_ += dir.x_;
          s.y_ += dir.y_;
          s.cost_ += dweigh;
          cal_weigh(s);
          ps = {s.x_, s.y_};
          if (walkable(ps) && pres.end() == pres.find(ps)) {
            add_jp(s, pstart);
          }
          return true;
        }
      }
    }
  }
}

void Jps::pathfind(Pos s, Pos e, vector<Pos> &ret) {
  over_ = false;
  start_ = s;
  end_ = e;
  if (!walkable(start_)) return;
  if (!walkable(end_)) return;
  if (s == e) return;

  set<Pos> close_list;
  map<Pos, Pos> pres;
  priority_queue<State> open_list;
  ppres_ = &pres;
  popen_list_ = &open_list;

  int weigh = dis(s, e);
  open_list.push({s.x_, s.y_, 0, weigh, 0, 0});

  while (!open_list.empty()) {
    State st = open_list.top();
    open_list.pop();
    Pos pt = {.x_ = st.x_, .y_ = st.y_};
    if (close_list.find(pt) != close_list.end()) continue;
    close_list.insert(pt);

    if (end_ == pt) {
      ret.push_back(end_);
      Pos p = end_;
      while (pres.end() != pres.find(p)) {
        p = pres[p];
        ret.push_back(p);
      }
      return;
    }

    int8_t dx = st.dx_;
    int8_t dy = st.dy_;
    vector<Pos> dirs_;
    if (!dx && !dy) {
      Pos_direct_cmp p = {.start_ = s, .end_ = e};
      dirs_ = dirs;
      sort(dirs_.begin(), dirs_.end(), p);
    } else if (dx && dy) {
      dirs_.push_back({dx, 0});
      dirs_.push_back({0, dy});
      dirs_.push_back({dx, dy});
    } else {
      dirs_.push_back({dx, dy});
    }
    for (auto dir : dirs_) {
      step(st, dir);
      if (over_) break;
    }
  }
  popen_list_ = nullptr;
  ppres_ = nullptr;
}
