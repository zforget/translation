open Core.Std

(** 字符串频率计数集合 *)
type t

(** 频率计数空集值 *)
val empty : t

(** 修改给定字符串的频率计数 *)
val touch : t -> string -> t

(** 将频率计数集合转换成关联列表。一个字符串至少出现一次，所以counts >= 1。 *)
val to_list : t -> (string * int) list
