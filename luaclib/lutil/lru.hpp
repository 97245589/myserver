#ifndef __LRU_HPP__
#define __LRU_HPP__

#include <cstdint>
#include <iostream>
#include <list>
#include <sstream>
#include <string>
#include <unordered_map>

using std::endl;
using std::list;
using std::ostringstream;
using std::string;
using std::unordered_map;

using Lru_type = string;

struct Lru {
  list<Lru_type> ids_;
  unordered_map<Lru_type, list<Lru_type>::iterator> list_it_;
  int cache_size_;

  static const int default_cache_size = 1000;
  Lru() : cache_size_(default_cache_size) {}

  bool update(const Lru_type &id, Lru_type &evict);
  void dump(string &out);
};

bool Lru::update(const Lru_type &id, Lru_type &evict) {
  if (auto it = list_it_.find(id); it != list_it_.end()) ids_.erase(it->second);
  ids_.push_front(id);
  list_it_[id] = ids_.begin();

  if (list_it_.size() > cache_size_) {
    auto it = ids_.rbegin();
    evict = *it;
    list_it_.erase(*it);
    ids_.pop_back();
    return true;
  }
  return false;
}

void Lru::dump(string &out) {
  ostringstream oss;
  oss << "itsize:" << list_it_.size() << endl;
  oss << "cachesize:" << cache_size_ << endl;
  oss << "idssize:" << ids_.size() << endl;
  for (auto id : ids_) {
    oss << id << " ";
  }
  oss << endl;
  out = oss.str();
}

#endif