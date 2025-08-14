#ifndef __RANK_H__
#define __RANK_H__

#include <cstdint>
#include <set>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

using std::endl;
using std::ostringstream;
using std::set;
using std::string;
using std::unordered_map;
using std::vector;

struct Rank_base {
  string uid_;
  int64_t score_;
  int64_t time_;
};
struct Rank_base_cmp {
  bool operator()(const Rank_base &lhs, const Rank_base &rhs) const {
    if (lhs.score_ != rhs.score_) return lhs.score_ > rhs.score_;
    if (lhs.time_ != rhs.time_) return lhs.time_ < rhs.time_;
    return lhs.uid_ > rhs.uid_;
  }
};

using Rank_set = set<Rank_base, Rank_base_cmp>;
using Rank_set_it = Rank_set::iterator;
struct Rank {
  Rank_set ranks_;
  unordered_map<string, Rank_set_it> rank_info_;
  int max_num_;

  void add(const Rank_base &);
  void evict();
  string dump();
  Rank() : max_num_(999) {}
};

void Rank::evict() {
  if (rank_info_.size() > max_num_) {
    auto it = ranks_.rbegin();
    auto uid = it->uid_;
    rank_info_.erase(it->uid_);
    ranks_.erase(*it);
  }
}

void Rank::add(const Rank_base &base) {
  if (auto rank_info_it = rank_info_.find(base.uid_);
      rank_info_it != rank_info_.end()) {
    ranks_.erase(rank_info_it->second);
    rank_info_.erase(base.uid_);
  }
  auto [it, mark] = ranks_.insert(base);
  if (mark) rank_info_.insert({base.uid_, it});
  evict();
}

string Rank::dump() {
  ostringstream oss;
  oss << "rank_size : " << ranks_.size() << endl;
  oss << "it_size : " << rank_info_.size() << endl;
  oss << "max_size : " << max_num_ << endl;
  for (auto rank_base : ranks_) {
    oss << rank_base.uid_ << "," << rank_base.score_ << "," << rank_base.time_
        << "|";
  }
  oss << endl;
  return oss.str();
}

#endif