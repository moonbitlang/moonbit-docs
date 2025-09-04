let programs : @hashmap.HashMap[String, String] = {
  let programs = @hashmap.new(capacity=40)
  programs["square"] = (
    #| (defn square[x] (mul x x))
  )
  programs["fix"] = (
    #| (defn fix[f] (letrec ([x (f x)]) x))
  )
  programs["isNil"] = (
    #| (defn isNil[x]
    #|   (case x [(Nil) 1] [(Cons n m) 0]))
  )
  programs["tail"] = (
    #| (defn tail[l] (case l [(Cons x xs) xs]))
  )
  programs["fibs"] = (
    // fibs = 0 : 1 : zipWith (+) fibs (tail fibs)
    #| (defn fibs[] (Cons 0 (Cons 1 (zipWith add fibs (tail fibs)))))
  )
  programs["take"] = (
    #| (defn take[n l]
    #|   (case l
    #|     [(Nil) Nil]
    #|     [(Cons x xs)
    #|        (if (le n 0) Nil (Cons x (take (sub n 1) xs)))]))
  )
  programs["zipWith"] = (
    #| (defn zipWith[op l1 l2]
    #|   (case l1
    #|     [(Nil) Nil]
    #|     [(Cons x xs)
    #|       (case l2
    #|         [(Nil) Nil]
    #|         [(Cons y ys) (Cons (op x y) (zipWith op xs ys))])]))
  )
  programs["factorial"] = (
    #| (defn factorial[n]
    #|   (if (eq n 0) 1 (mul n (factorial (sub n 1)))))
  )
  programs["abs"] = (
    #| (defn abs[n]
    #|   (if (lt n 0) (negate n) n))
  )
  programs["length"] = (
    #| (defn length[l]
    #|   (case l
    #|     [(Nil) 0]
    #|     [(Cons x xs) (add 1 (length xs))]))
  )
  programs
}
