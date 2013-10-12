open Core.Std

(** 字符串频率计数集合 *)
type t

(** 频率计数空集值 *)
val empty : t

(** 修改给定字符串的频率计数 *)
val touch : t -> string -> t

(** 将频率计数集合转换成关联列表。一个字符串至少出现一次，所以counts >= 1。 *)
val to_list : t -> (string * int) list

(** 表示一字符串的中间值，当偶数时，取中间值前后的那两个返回。 *)
type median = | Median of string 
              | Before_and_after of string * string 
val median : t -> median
