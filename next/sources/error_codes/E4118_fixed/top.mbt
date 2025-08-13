pub fn MyMap::op_get[K: Eq + Hash, V](self : MyMap[K, V], key : K) -> V? {
  self._[key]
}