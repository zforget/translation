## 第七章 错误处理
没有人愿意处理错误。处理错误很乏味，还容易出出错，并且也没有计划程序如何正确运行有乐趣。但是，错误处理非常重要，无论你多么不喜欢，软件因为薄弱的错误处理而失败要更糟糕。

庆幸的是，OCaml提供了强大的工具来可靠地处理错误，且把痛处降至最低。本章我们会讨论OCaml中的几种处理错误的方法，并且给出了一些如何设计接口以简化错误处理的建议。

开始，我们先介绍OCaml中报告错误的两种基本方法：带错误的返回值和异常。
>> Error-Aware return types

### 带错误的返回值
OCaml中抛出一个错误最好的方法就是把这个错误包含到返回值中。考虑`List`模块中`find`函数的类型：
```ocaml
# List.find;;
- : 'a list -> f:('a -> bool) -> 'a option = <fun>
```
返回类型中的`option`表明此函数在查找一个相符的元表时可能会失败：
```ocaml
# List.find [1;2;3] ~f:(fun x -> x >= 2) ;;
- : int option = Some 2
# List.find [1;2;3] ~f:(fun x -> x >= 10) ;;
- : int option = None
```
在函数返回值中包含错误信息就要求调用者显式处理它，允许调用者来决定是从这个错误中恢复还是将其向前传播。

下面看一下`computer_bounds`函数。该函数接收一个列表和一个比较函数，通过查找最大和最小的列表元素返回列表的上下边界。提取列表中最大和最小元素用的是`List.hd`和`List.last`，它们在遇到空列表时会返回`None`：
```ocaml
# let compute_bounds ~cmp list =
let sorted = List.sort ~cmp list in
match List.hd sorted, List.last sorted with
| None,_ | _, None -> None
| Some x, Some y -> Some (x,y)
;;
val compute_bounds : cmp:('a -> 'a -> int) -> 'a list -> ('a * 'a) option =
<fun>
```
`match`语句用以处理错误分支，将`hd`或`last`返回的`None`传递给`computer_bounds`的返回值。

另一方面，下面的`find_mismatches`函数中，计算过程中碰到的错误不会传递给函数的返回值。`find_mismatches`接收两个哈希表作为参数，在一个表中查找与另一个表中对应的数据不同的键值。因此，在一个表中找不到一个键值不属于错误：
```ocaml
# let find_mismatches table1 table2 =
Hashtbl.fold table1 ~init:[] ~f:(fun ~key ~data mismatches ->
match Hashtbl.find table2 key with
| Some data' when data' <> data -> key :: mismatches
| _ -> mismatches
)
;;
val find_mismatches : ('a, 'b) Hashtbl.t -> ('a, 'b) Hashtbl.t -> 'a list =
<fun>
```
使用`option`编码错误凸显了这样一个事实：一个特定的结果，如在列表中没有找到某元素，是一个错误还是一个合理的结果，这一点并不明确。这依赖于你程序中更大的上下文，是一个通用库无法预知的。带错误的返回值的优势就在于两种情况它都适用。

#### 编码错误和结果
`option`在报告错误方面不总是有足够的表达力。特别是当你把一个错误编码成`None`时，就没有地方来说明错误的性质了。

`Result.t`就是为了解决此不足的。类型定义如下：
```ocaml
module Result : sig
   type ('a,'b) t = | Ok of 'a
                    | Error of 'b
end
```
`Result.t`本质上是一个参数化的`option`，给错误实例赋于存储其它信息的能力。像`Some`和`None`一样，构造器`Ok`和`Error`由`Core.Std`提升到顶层作用域。因此，我们可以这样写：
```ocaml
# [ Ok 3; Error "abject failure"; Ok 4 ];;
- : (int, string) Result.t list = [Ok 3; Error "abject failure"; Ok 4]
```
而不需要先打开`Result`模块。

#### `Error`和`Or_error`
`Result.t`给了你完全的自由来选择错误值的类型，但通常规范错误类型是有用的。别的不说，它会简化自动化通用错误处理模式的工具函数。

但选什么类型呢？把错误表示为字符串会更好呢？还是像XML这样更加结构化的表达？或者其它的什么？

`Core`的答案是`Error.t`类型，它试图在效率、方便性和对错误表达的控制力之间取得一个很好的平衡。

效率问题一开始并不明显。但生成错误消息是很昂贵的。一个值的ASCII表达可能相当耗时，特别是它包含不易转换的数值数据时。

`Error`使用惰性求值避开了这个问题，`Error.t`允许你推迟错误生成，除非你需要它，这就意味着很多时候你根本不需要去构造它。当然你也可以直接从一个字符串构造一个错误：
```ocaml
# Error.of_string "something went wrong";;
- : Error.t = something went wrong
```
但你也可以从一个形实转换程序（thunk）构造`Error.t`，即，一个接收单独一个`unit`类型参数的函数：
```ocaml
# Error.of_thunk (fun () ->
    sprintf "something went wrong: %f" 32.3343);;
- : Error.t = something went wrong: 32.334300
```
这时，我们就可以从`Error`的惰性求值获益，因为除非`Error.t`被转换为字符串，否则形实转换程序不会被调用。

创建`Error.t`最常用的方式是使用S-表达式。S-表达式是一个由小括号包围的表达式，表达式的叶子是字符串。这里有一个简单例子：
```scheme
(This (is an) (s expression))
```
`Core`中的S-表达式由`Sexplib`包支持，该包随`Core`发布，是`Core`最常用的序列化格式。实际上，`Core`中的多数类型都自带了内建的S-表达式转换器。下例中，使用时间的`sexp`转换器（`Time.sexp_of_t`）创建错误：
```ocaml
# Error.create "Something failed a long time ago" Time.epoch Time.sexp_of_t;;
- : Error.t =
Something failed a long time ago: (1970-01-01 01:00:00.000000+01:00)
```
注意，错误在被打印之前是不会真正序列化成S-表达式的。

这种错误报告并不只局限于内建类型。这会在[第17章](#第17章)讨论，但是`Sexplib`带了一个语言扩展，可以为新创建的类型自动生成`sexp`转换器：
```ocaml
# let custom_to_sexp = <:sexp_of<float * string list * int>>;;
val custom_to_sexp : float * string list * int -> Sexp.t = <fun>
# custom_to_sexp (3.5, ["a";"b";"c"], 6034);;
- : Sexp.t = (3.5 (a b c) 6034)
```
我们可以使用相同的惯用法创建错误：
```ocaml
# Error.create "Something went terribly wrong"
    (3.5, ["a";"b";"c"], 6034)
<:sexp_of<float * string list * int>> ;;
- : Error.t = Something went terribly wrong: (3.5(a b c)6034)
```
`Error`也支持错误转换操作。如，给错误一个带有上下文信息的参数或把多个错误组合在一起通常是很有用的。`Error.tag`和`Error.list`即可用于此：
```ocaml
# Error.tag
    (Error.of_list [ Error.of_string "Your tires were slashed";
                    Error.of_string "Your windshield was smashed" ])
    "over the weekend"
;;
- : Error.t =
over the weekend: Your tires were slashed; Your windshield was smashed
```
`'a Or_error.t`只是` ('a,Error.t) Result.t`的简写，它是`Core`中`option`之外最常用的返回错误方式。

#### `bind`和其它错误处理惯用法
随着用OCaml编写越来越多的错误处理代码，你会发现有几个特定的模式凸显出来。其中的一些通用模式已经被编进了`Option`和`Result`模块中的函数里。一个特别有用的模式是围绕`bind`函数构建的，`bind`既是普通函数又是中缀操作符`>>=`。下面是`option`的`bind`定义：
```ocaml
# let bind option f =
    match option with
    | None -> None
    | Some x -> f x
  ;;
val bind : 'a option -> ('a -> 'b option) -> 'b option = <fun>
```
如你所见，`bind None f`返回None而不调用`f`，而`bind (Some x) f`会返回`f x`。使用`bind`可以把生成错误的函数串连起来，这样第一个产生错误的函数就会终止计算。下面是使用嵌套的`bind`序列重写的`compute_bounds`：
```ocaml
# let compute_bounds ~cmp list =
    let sorted = List.sort ~cmp list in
    Option.bind (List.hd sorted) (fun first ->
      Option.bind (List.last sorted) (fun last ->
        Some (first,last)))
  ;;
val compute_bounds : cmp:('a -> 'a -> int) -> 'a list -> ('a * 'a) option =
<fun>
```
在语法层面上，上面的代码有点晦涩。我们可以通过使用`bind`的中缀操作符形式来去掉括号以使代码更易读，中缀操作符通过局部打开`Option.Monad_infix`访问。模块名叫`Monad_infix`是因为`bind`操作符是`Monad`子接口的一部分，我们会在[第18章](#第18章)再次讨论:
```ocaml
# let compute_bounds ~cmp list =
    let open Option.Monad_infix in
    let sorted = List.sort ~cmp list in
    List.hd sorted  >>= fun first ->
    List.last sorted >>= fun last  ->
    Some (first,last)
  ;;
val compute_bounds : cmp:('a -> 'a -> int) -> 'a list -> ('a * 'a) option =
<fun>
```
这里使用`bind`本质上确实不比开始时那个版本好，实际上，像这样的小例子，直接使用`option`通常比使用`bind`好。但是对于巨大的、复杂的、有许多层错误处理的例子，`bind`惯用法更清晰也更容易管理。

`Option`的函数中还有其它有用的惯用法。`Option.both`是其中之一，它接收两个`option`值，生成一个新的`option`序对，如果参数中有一个是`None`，那么就返回None。使用`Option.both`可以使`compute_bounds`更简短：
```ocaml
# let compute_bounds ~cmp list =
    let sorted = List.sort ~cmp list in
    Option.both (List.hd sorted) (List.last sorted)
;;
val compute_bounds : cmp:('a -> 'a -> int) -> 'a list -> ('a * 'a) option =
<fun>
```
这些错误处理函数的价值在于它们可以使你的显式并且简洁地表达错误处理。我们只讨论了`Option`模块上下文中的函数，但是在`Result`和`Or_error`模块中有更多这种功能的函数。

### 异常
OCaml中的异常和其它语言，如Java、C#和Python，中的没有什么大的不同。如果提供了机制来捕获和处理（也可能恢复）子例程中触发的异常，异常就可以用以终止计算并报告错误。

举个例子，你可以通过整数除零来触发一个异常：
```ocaml
# 3 / 0;;
Exception: Division_by_zero.
```
即使是发生在深度的嵌套中，异常也可以终止计算：
```ocaml
# List.map ~f:(fun x -> 100 / x) [1;3;0;4];;
Exception: Division_by_zero.
```
如果在计算中间放置一个`printf`，就会看到`List.map`在执行中间被打断了，而没有到达列表末尾：
```ocaml
# List.map ~f:(fun x -> printf "%d\n%!" x; 100 / x) [1;3;0;4];;
1
3
0
Exception: Division_by_zero.
```
除了像`Divide_by_zero`这样的内建异常，OCaml也允许你定义自己的异常：
```ocaml
# exception Key_not_found of string;;
exception Key_not_found of string
# raise (Key_not_found "a");;
Exception: Key_not_found("a").
```
异常只是普通的值，可以像操作其它OCaml值一样操作：
```ocaml
# let exceptions = [ Not_found; Division_by_zero; Key_not_found "b" ];;
val exceptions : exn list = [Not_found; Division_by_zero; Key_not_found("b")]
# List.filter exceptions  ~f:(function
    | Key_not_found _ | Not_found -> true
    | _ -> false);;
- : exn list = [Not_found; Key_not_found("b")]
```

#### Helper Functions for Throwing Exceptions
#### Exception Handlers
#### Cleaning Up in the Presence of Exceptions
#### Catching Specific Exceptions
#### Backtraces
#### From Exceptions to Error-Aware Types and Back Again

### Choosing an Error-Handling Strategy