## 第三章 列表和模式
本章会聚焦于OCaml中两个常用编程元素：列表和模式匹配。在[第一章导览](#导览)中对它们都有过介绍，但这里我们会更深入，把这两个概念放在一起，并用一个来帮助诠释另一个。

### 列表基础
OCaml的列表中不可变的、有限的同类型元素序列。如我们所见，OCaml列表可以使用方括号和分号来创建。
```ocaml
# [1;2;3];;
- : int list = [1; 2; 3]

(* OCaml Utop ∗ lists-and-patterns/main.topscript ∗ all code *)
```
它们也可以使用等价的`::`记号来创建。
```ocaml
# 1 :: (2 :: (3 :: [])) ;;
- : int list = [1; 2; 3]
# 1 :: 2 :: 3 :: [] ;;
- : int list = [1; 2; 3]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 1) ∗ all code *)
```
你可以看到`::`操作符是右结合的，就是说你可以不用括号来构建列表。空列表`[]`用以来结束一个列表。注意空列表是多态的，它可以和任何类型的元素一起用，如下所示：
```ocaml
# let empty = [];;
val empty : 'a list = []
# 3 :: empty;;
- : int list = [3]
# "three" :: empty;;
- : string list = ["three"]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 2) ∗ all code *)
```
`::`操作符可以把一个元素附加到一个列表前面，这反映了OCaml列表实际上是一个单向链表。下面是一个表示列表`1 :: 2 :: 3 :: []`数据结构布局的概图。最后一个箭头（从包含`3`的盒子起始的那个）指向一个空列表。
```ocaml
+---+---+   +---+---+   +---+---+
| 1 | *---->| 2 | *---->| 3 | *---->||
+---+---+   +---+---+   +---+---+

(* Diagram ∗ lists-and-patterns/lists_layout.ascii ∗ all code *)
```
每一个`::`实质上是向上图添加一个块。这个块包含两样东西：一个列表元素数据的引用，和一个列表剩余部分的引用。这就说说明了为什么`::`不需修改就能扩展一个列表，扩展是创建了一个新的列表元素但却不需要修改任何已存在的元素，如下所示：
```ocaml
# let l = 1 :: 2 :: 3 :: [];;
val l : int list = [1; 2; 3]
# let m = 0 :: l;;
val m : int list = [0; 1; 2; 3]
# l;;
- : int list = [1; 2; 3]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 3) ∗ all code *)
```

### 使用模式从列表中提取数据。
我们可以使用模式匹配读出列表中的数据。下面是一个递归函数的简单例子，用以计算列表中所有元素的和。
```ocaml
# let rec sum l =
    match l with
    | [] -> 0
    | hd :: tl -> hd + sum tl
  ;;
val sum : int list -> int = <fun>
# sum [1;2;3];;
- : int = 6
# sum [];;
- : int = 0

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 4) ∗ all code *)
```
这段代码遵循了使用`hd`表示列表第一个元素（或者说头），`tl`表示剩下的列表（或者说尾）的惯用法。

`sum`中的`match`语句实际上做了两件事：首先，作为分支分析工具，把可能的情况分解到以模式为索引的分支列表中。其次，让你可以使用匹配的数据结构来命名子结构。这种情况下，变量`hd`和`tl`由定义第二个`match`分支语句的模式绑定。这样绑定的变量可以在当前模式箭头右边的表达式中使用。

`match`语句可以用来绑定新变量可能会引起困惑。为了说明这一点，想像一下我们要定义一个函数来过滤出列表中与特定值相等的元素。你可能会写出下面的代码，但如果这样，编译器会立即给出警告。
```ocaml
# let rec drop_value l to_drop =
    match l with
    | [] -> []
    | to_drop :: tl -> drop_value tl to_drop
    | hd :: tl -> hd :: drop_value tl to_drop
  ;;

Characters 114-122:
Warning 11: this match case is unused.val drop_value : 'a list -> 'a -> 'a list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 5) ∗ all code *)
```
并且，函数行为也明显是错误的，它过滤掉了列表的所有元素，而非只是和给定值相等的那些，如下所示。
```ocaml
# drop_value [1;2;3] 2;;
- : int list = []

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 6) ∗ all code *)
```
那么这到底是怎么回事呢？

关键就是第二种情况中`to_drop`的名并不意味着会检查它是否与`drop_value`输入参数里的`to_drop`相等。相反，它只会引入一个名为`to_drop`的新变量，并绑定绑定到列表的第个元素，无论是什么，并遮蔽了之前的定义的`to_drop`。第三个分支没有使用，因为它和第二个完全是相同的模式。

一种更好的做法是不使用模式匹配来判断第一个元素是否等于`to_drop`，而是使用普通的`if`语句。
```ocaml
# let rec drop_value l to_drop =
    match l with
    | [] -> []
    | hd :: tl ->
      let new_tl = drop_value tl to_drop in
      if hd = to_drop then new_tl else hd :: new_tl
  ;;
val drop_value : 'a list -> 'a -> 'a list = <fun>
# drop_value [1;2;3] 2;;
- : int list = [1; 3]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 7) ∗ all code *)
```
注意如果只要想去掉一个特定字面值（而不是一个传入的值），我们可以使用类似原先的那个`drop_value`实现。
```ocaml
# let rec drop_zero l =
    match l with
    | [] -> []
    | 0  :: tl -> drop_zero tl
    | hd :: tl -> hd :: drop_zero tl
  ;;
val drop_zero : int list -> int list = <fun>
# drop_zero [1;2;0;3];;
- : int list = [1; 2; 3]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 8) ∗ all code *)
```

### 模式匹配的限制（也是福利）
上面的例子说明了一个很重要的事实，就是用模式匹配不能表示所有条件。模式可以描述数据结构的布局，甚至可以像` drop_zero`示例中那包含字面值，但也仅仅如此了。一个模式可以检查一个列表是否有两个相等的元素，但却无法检查其前两个元素是否相等。

你可以把模式看成一种特殊的子语言，可以表示有限的（但依然是非常丰富的）条件。模式语言受限是件很好的事，这样就可以在编译器中构建更好的模式支持。特别是在匹配效率方面，还有编译器依靠模式天然受限的特征在匹配中发现错误的能力方面。

#### 性能
你会很自然地认为需要依次检查`match`中的每个分支来确定匹配了哪个。如果分支是任意代码保护的，确实需要如此。但是依靠一组高效的运行时检查，OCaml通常可以生成直接跳到匹配的分支机器码。

举个例子，考虑下面这两个傻瓜函数，用以把一个整数加一。第一个使用模式匹配，第二个使用一系列`if`语句。
```ocaml
# let plus_one_match x =
    match x with
    | 0 -> 1
    | 1 -> 2
    | 2 -> 3
    | _ -> x + 1

  let plus_one_if x =
    if      x = 0 then 1
    else if x = 1 then 2
    else if x = 2 then 3
    else x + 1
  ;;
val plus_one_match : int -> int = <fun>
val plus_one_if : int -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 9) ∗ all code *)
```
注意上面匹配中使用的`_`，是一个可以匹配任意值的通配模式，但不会绑定一个变量到这个值。

如果你做一些基准测试就会发现`plus_one_if`比`plus_one_match`慢得多，并且随着分支的增加会慢得更多。这里我们使用`core_bench`库来做基准测试，你可以在命令行使用`opam install core_bench`来安装它。
```ocaml
# #require "core_bench";;
# open Core_bench.Std;;
# let run_bench tests =
  Bench.bench
    ~ascii_table:true
    ~display:Textutils.Ascii_table.Display.column_titles
    tests
;;
val run_bench : Bench.Test.t list -> unit = <fun>
# [ Bench.Test.create ~name:"plus_one_match" (fun () ->
      ignore (plus_one_match 10))
  ; Bench.Test.create ~name:"plus_one_if" (fun () ->
      ignore (plus_one_if 10)) ]
  |> run_bench
  ;;

Estimated testing time 20s (change using -quota SECS).
  Name            Time (ns)   % of max
---------------- ----------- ----------
  plus_one_match  46.81       68.21
  plus_one_if     68.63       100.00

- : unit = ()

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 10) ∗ all code *)
```
这里还有另外一个不那么刻意的例子。我们可以重写前面章节中定义的`sum`函数，这次使用`if`语句而不是模式匹配。我们可以使用`List`模块中的`is_empty`、`hd_exn`以及`tl_exn`来析构列表，以此实现整个不使用模式匹配的函数。
```ocaml
# let rec sum_if l =
    if List.is_empty l then 0
    else List.hd_exn l + sum_if (List.tl_exn l)
  ;;
val sum_if : int list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 11) ∗ all code *)
```
再一次我们使用基准测试来看有什么不同。
```ocaml
# let numbers = List.range 0 1000 in
  [ Bench.Test.create ~name:"sum_if" (fun () -> ignore (sum_if numbers))
  ; Bench.Test.create ~name:"sum"    (fun () -> ignore (sum numbers)) ]
  |> run_bench
  ;;

Estimated testing time 20s (change using -quota SECS). 
  Name      Time (ns)  % of max
 -------- ----------- ----------
  sum_if    110_535    100.00
  sum       22_361     20.23

- : unit = ()

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 12) ∗ all code *)
```
这次，基于模式匹配的实现比基于`if`的实现足足快了几倍。差异主要是因为我们需要多次高效完成相同的工作，因为我们调用的每个函数都要重复检查列表的第一个元素以确定其是否是空的。使用模式匹配，这个工作对每个列表元素只发生一次。
>> 是指`is_empty`、`hd_exn`以及`tl_exn`中都要检查？

模式匹配通常都比你手动写的版本更高效。一个例外是字符串匹配，这时实际上顺序测试的，所以有许多字符串需要匹配时使用哈希表会更好。但大多数情况下，模式匹配都是明显的性能赢家。

#### 检测错误
如果模式匹配还有什么比其性能更重要的，那就是其错误检测能力。我们已经见过一个关于在模式匹配中OCaml的查错能力的例子：在我们错误的`drop_value`定义中，OCaml警告我们最后种情况是多余的。没有任何算法可以确定一个用通用语言写的谓词是多余的，但在模式匹配上下文中却可以可靠地解决此问题。

OCaml也可以检查`match`语句的完整性。考虑一下如果我们通过删除一个分支来修改`drop_zero`会发生什么。如你所见，编译器会产生一个警告，告诉我们落了一个分支，并带着一个不能匹配的模式的示例。
```ocaml
# let rec drop_zero l =
    match l with
    | [] -> []
    | 0  :: tl -> drop_zero tl
  ;;

Characters 26-84:
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
1::_val drop_zero : int list -> 'a list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 13) ∗ all code *)
```
即使在这么简单的例子中，不完整检查也是非常有用的。但是在[第6章变量](#变量)中，碰到更复杂的例子时，它们会变得更有价值，特别是涉及用户自定义类型时。除了捕捉直接错误，它们还可以作为一种重构工具，指导你找到需要调整的位置，以使你的代码可以应对类型的变化。

### 高效使用`List`模块
现在我们已经使用模式匹配和递归函数写了大量列表处理代码。但在现实中，你通常最好应该使用`List`模块，它里面有许多可重用的函数，它们抽象出一些列表计算的通用模式。

让我们通过一个具体例子来看看实际应用。我们将要写一个`render_table`函数，给定一个列标题列表和一个行列表，把它们打印到一个有良好格式化的文本表中，如下所示。
```ocaml
# printf "%s\n"
   (render_table
     ["language";"architect";"first release"]
     [ ["Lisp" ;"John McCarthy" ;"1958"] ;
       ["C"    ;"Dennis Ritchie";"1969"] ;
       ["ML"   ;"Robin Milner"  ;"1973"] ;
       ["OCaml";"Xavier Leroy"  ;"1996"] ;
     ]);;

| language | architect      | first release |
|----------+----------------+---------------|
| Lisp     | John McCarthy  | 1958          |
| C        | Dennis Ritchie | 1969          |
| ML       | Robin Milner   | 1973          |
| OCaml    | Xavier Leroy   | 1996          |
- : unit = ()

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 69) ∗ all code *)
```
第一步是要写一个计算最大列宽的函数。我们可以把标题以及每行数据的列表转换成一个表示长度的整数列表，然后取这些列表的最大元素即可。直接写这些代码很繁杂，但是使用`List`模块中的`map`、`map2_exn`和`fold`这三个函数我们可以非常简捷地完成任务。

`List.map`解释起来最简单。它接收一个列表和一个函数参数，用函数转换列表的每个元素，并返回一个由转换后的值构成新列表。因此我们可以这样写：
```ocaml
# List.map ~f:String.length ["Hello"; "World!"];;
- : int list = [5; 6]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 14) ∗ all code *)
```
`List.map2_exn`和`List.map`类似，但它接收两个列表和一个函数来组合它们。因此，代码可以这样：
```ocaml
# List.map2_exn ~f:Int.max [1;2;3] [3;2;1];;
- : int list = [3; 2; 3]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 15) ∗ all code *)
```
有一个`_exn`后缀是因为这个函数会在两个列表长度不同时抛出异常。
```ocaml
# List.map2_exn ~f:Int.max [1;2;3] [3;2;1;0];;
Exception: (Invalid_argument "length mismatch in rev_map2_exn: 3 <> 4 ").

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 16) ∗ all code *)
```
`List.fold`是这三中最复杂的，有三个参数：一个要处理的列表，一个累加器初始值和一个根据列表元素来更新累加器的函数。`List.fold`从左至右遍历列表，在每一步时更新累加器并在结束时返回累加器最终的值。看此函数的类型签名你就可以略知一二了。
```ocaml
# List.fold;;
- : 'a list -> init:'accum -> f:('accum -> 'a -> 'accum) -> 'accum = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 17) ∗ all code *)
```
我们可以用`List.fold`来完成简单如累加一个列表这样的工作。
```ocaml
# List.fold ~init:0 ~f:(+) [1;2;3;4];;
- : int = 10

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 18) ∗ all code *)
```
我个例子特别简单是因为累加器和列表元素是相同的。但`fold`中并没有个限制。例如我们可以使用`fold`来反转一个列表，这种情况下累加器本身就是一个列表。
```ocaml
# List.fold ~init:[] ~f:(fun list x -> x :: list) [1;2;3;4];;
- : int list = [4; 3; 2; 1]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 19) ∗ all code *)
```
现在让我们用这三个函数一起来计算最大行宽。
```ocaml
# let max_widths header rows =
    let lengths l = List.map ~f:String.length l in
    List.fold rows
      ~init:(lengths header)
      ~f:(fun acc row ->
        List.map2_exn ~f:Int.max acc (lengths row))
  ;;
val max_widths : string list -> string list list -> int list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 20) ∗ all code *)
```
我们使用`List.map`定义了一个`lengths`函数，用以把一个字符串列表转换成一个对应元素长度的整数列表。然后用`List.fold`来迭代`rows`，使用`map2_exn`来取累加器和每一行字符串长度的最大值，累加器初始值是标题行的长度。

现在我们知道了如何计算列宽，我们就可以之代码来生成分隔标题行和文本表中其余行的分隔符。我们会使用根据列长`String.make`来生成合适长度的破折号字符串。然后使用`String.concat`把它们组合起来，此函数用一个可选的分隔字符串来拼接字符串，还有`^`，是一个两两拼接字符串的函数，用以在外面添加分隔符。
```ocaml
# let render_separator widths =
    let pieces = List.map widths
      ~f:(fun w -> String.make (w + 2) '-')
    in
    "|" ^ String.concat ~sep:"+" pieces ^ "|"
  ;;
val render_separator : int list -> string = <fun>
# render_separator [3;6;2];;
- : string = "|-----+--------+----|"

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 21) ∗ all code *)
```
注意破折号行比给定的宽度多两个字符，以在表中每一项周围提供一些空格。

> **`String.concat`和`^`的性能**
>
> 上面我们使用了两种不同的字符串拼接方法，作用于字符串列表的`String.concat`，和两两拼接的`^`操作符。拼接许多字符串时应该尽量避免使用`^`，因为每一次调用它都会分配一个新的字符串。因此，下面的代码会分配长度分别为2、3、4、5、6和7的字符串
> ```ocaml
> # let s = "." ^ "."  ^ "."  ^ "."  ^ "."  ^ "."  ^ ".";;
> val s : string = "......."
>
> (* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 22) ∗ all code *)
> ```
> 但下面的代码只会分配一个长度为7的字符串和一个有7个元素的列表。
> ```ocaml
> # let s = String.concat [".";".";".";".";".";".";"."];;
> val s : string = "......."
> 
> (* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 23) ∗ all code *)
> ```
>这么小字符串不会产生多大影响，但是组合巨大的字符串时，这会产生严重的性能问题。

#### More useful list functions
##### Combining list elements with List.reduce
##### Filtering with List.filter and List.filter_map
##### Partitioning with List.partition_tf
##### Combining lists

### Tail recursion

### Terser and faster patterns
