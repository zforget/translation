## 第三章 列表和模式
本章会聚焦于 OCaml 中两个常用编程元素：列表和模式匹配。在[第一章导览](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_01_a_guide_tour.md)中对它们都有过介绍，但这里我们会更深入，把这两个概念放在一起，并互相诠释。

### 列表基础
OCaml 的列表是一个不可变的、有限的同类型元素序列。如我们所见，OCaml 列表可以使用方括号和分号来创建：

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
`::`操作符可以把一个元素附加到一个列表前面，这反映了 OCaml 列表实际上是一个单向链表。下面是一个表示列表`1 :: 2 :: 3 :: []`数据结构布局的概图。最后一个箭头（从包含`3`的盒子起始的那个）指向一个空列表：

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
我们可以使用`match`语句读出列表中的数据。下面是一个递归函数的简单例子，用以计算列表中所有元素的和：

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

`match`语句可以用来绑定新变量可能会引起困惑。为了说明这一点，想像一下我们要定义一个函数来过滤出列表中与特定值相等的元素。你可能会写出下面的代码，但如果这样，编译器会立即给出警告：

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
并且，函数行为也明显是错误的，它过滤掉了列表的所有元素，而非只是和给定值相等的那些，如下所示：

```ocaml
# drop_value [1;2;3] 2;;
- : int list = []

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 6) ∗ all code *)
```
那么这到底是怎么回事呢？

关键就是第二种情况中`to_drop`的名并不意味着会检查它是否与`drop_value`输入参数里的`to_drop`相等。相反，它只会引入一个名为`to_drop`的新变量，并绑定绑定到列表的第一个元素，无论它是什么，并遮蔽了之前的定义的`to_drop`。第三个分支没有使用，因为它和第二个完全是相同的模式。

一种更好的做法是不使用模式匹配来判断第一个元素是否等于`to_drop`，而是使用普通的`if`语句：

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
注意如果只要想去掉一个特定字面值（而不是一个传入的值），我们可以使用类似原先的那个`drop_value`实现：

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

你可以把模式看成一种特殊的子语言，可以表示有限的（但依然是非常丰富的）条件。模式语言受限是件很好的事，这样就可以在编译器中构建更好的模式支持。特别是在匹配效率方面，还有就是依靠模式的受限性，编译器发现错误的能力。

#### 性能
你会很自然地认为需要依次检查`match`中的每个分支来确定匹配了哪个。如果分支是任意的代码，确实需要如此。但是依靠一组高效的运行时检查，OCaml 通常可以生成直接跳到匹配分支的机器码。

举个例子，考虑下面这两个傻瓜函数，用以把一个整数加一。第一个使用模式匹配，第二个使用一系列`if`语句：

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
注意上面匹配中使用的`_`，是一个可以匹配任意值的通配模式，但不会给匹配的值绑定一个变量名。

如果你做一些基准测试就会发现`plus_one_if`比`plus_one_match`慢得多，并且随着分支的增加会慢得更多。这里我们使用`core_bench`库来做基准测试，你可以在命令行使用`opam install core_bench`来安装它：

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
> 注意由于`Core_bench`接口变化，上面的代码已经跑不通了，可以修改成这样：
> 
> ```ocaml
> let run_bench tests =
>	 Bench.bench
>	 ~display_config:(Bench.Display_config.create 
>	     ~ascii_table:true 
>	     ~display:Textutils.Ascii_table.Display.column_titles
>	 	  ())
>	 tests;;
> ```
> by clark 2017.3.14
 
这里还有另外一个不那么刻意的例子。我们可以重写前面章节中定义的`sum`函数，这次使用`if`语句而不是模式匹配。我们可以使用`List`模块中的`is_empty`、`hd_exn`以及`tl_exn`来析构列表，以此实现整个不使用模式匹配的函数:

```ocaml
# let rec sum_if l =
    if List.is_empty l then 0
    else List.hd_exn l + sum_if (List.tl_exn l)
  ;;
val sum_if : int list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 11) ∗ all code *)
```
再一次我们使用基准测试来看有什么不同:

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
这次，基于模式匹配的实现比基于`if`的实现足足快了几倍。差异主要是因为我们需要多次完成相同的工作，因为我们调用的每个函数都要重复检查列表的第一个元素以确定其是否是空的。使用模式匹配，这个工作对每个列表元素只发生一次。
> 是指`is_empty`、`hd_exn`以及`tl_exn`中都要检查？by clark

模式匹配通常都比你手动写的代码更高效。一个例外是字符串匹配，这实际上是顺序测试的，所以有许多字符串需要匹配时，使用哈希表效率会更高。但大多数情况下，模式匹配都是明显的性能赢家。

#### 检测错误
如果还有什么比模式匹配的性能更重要的，那就是其错误检测能力。我们已经见过一个关于在模式匹配中 OCaml 的查错能力的例子：在我们错误的`drop_value`定义中，OCaml 警告我们最后一个分支是多余的。没有任何算法可以确定一个用通用语言写的谓词是多余的，但在模式匹配上下文中却可以可靠地解决此问题。

OCaml 也可以检查`match`语句的完整性。考虑一下如果我们通过删除一个分支来修改`drop_zero`会发生什么。如你所见，编译器会产生一个警告，告诉我们落了一个分支，并带着一个不能匹配的模式的示例：

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
即使在这么简单的例子中，穷尽检查也是非常有用的。但是在[第6章变体](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_06_variants.md)中，碰到更复杂的例子时，它们会变得更有价值，特别是涉及用户自定义类型时。除了捕捉直接错误，它们还可以作为一种重构工具，指导你找到需要调整的位置，以使你的代码可以应对类型的变化。

### 高效使用`List`模块
现在我们已经使用模式匹配和递归函数写了大量列表处理代码。但在现实中，你通常最好应该使用`List`模块，它里面有许多可重用的函数，它们抽象出一些列表计算的通用模式。

让我们通过一个具体例子来看看实际应用。我们将要写一个`render_table`函数，给定一个列标题列表和一个行列表，把它们打印到一个有良好格式化的文本表中，如下所示：

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
有一个`_exn`后缀是因为这个函数会在两个列表长度不同时抛出异常：

```ocaml
# List.map2_exn ~f:Int.max [1;2;3] [3;2;1;0];;
Exception: (Invalid_argument "length mismatch in rev_map2_exn: 3 <> 4 ").

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 16) ∗ all code *)
```
`List.fold`是这三中最复杂的，有三个参数：一个要处理的列表，一个累加器初始值和一个根据列表元素来更新累加器的函数。`List.fold`从左至右遍历列表，在每一步时更新累加器并在结束时返回累加器最终的值。看此函数的类型签名你就可以略知一二了：

```ocaml
# List.fold;;
- : 'a list -> init:'accum -> f:('accum -> 'a -> 'accum) -> 'accum = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 17) ∗ all code *)
```
我们可以用`List.fold`来完成简单如累加一个列表这样的工作：

```ocaml
# List.fold ~init:0 ~f:(+) [1;2;3;4];;
- : int = 10

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 18) ∗ all code *)
```
这个例子特别简单是因为累加器和列表元素是相同类型的。但`fold`中并没有个限制。例如我们可以使用`fold`来反转一个列表，这种情况下累加器本身就是一个列表：

```ocaml
# List.fold ~init:[] ~f:(fun list x -> x :: list) [1;2;3;4];;
- : int list = [4; 3; 2; 1]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 19) ∗ all code *)
```
现在让我们用这三个函数一起来计算最大行宽：

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

现在我们知道了如何计算列宽，我们就可以写代码来生成分隔标题行和文本表中其余行的分隔符。我们会在列长上使用`String.make`来生成合适长度的破折号字符串。然后使用`String.concat`把它们组合起来，此函数用一个可选的分隔字符串来拼接字符串，还有`^`，是一个两两拼接字符串的函数，用以在两头添加分隔符：

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
> 上面我们使用了两种不同的字符串拼接方法，作用于字符串列表的`String.concat`，和两两拼接的`^`操作符。拼接许多字符串时应该尽量避免使用`^`，因为每一次调用它都会分配一个新的字符串。因此，下面的代码会分配长度分别为2、3、4、5、6 和 7 的字符串：
> 
> ```ocaml
> # let s = "." ^ "."  ^ "."  ^ "."  ^ "."  ^ "."  ^ ".";;
> val s : string = "......."
>
> (* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 22) ∗ all code *)
> ```
> 
> 但下面的代码只会分配一个长度为 7 的字符串和一个有 7 个元素的列表：
> 
> ```ocaml
> # let s = String.concat [".";".";".";".";".";".";"."];;
> val s : string = "......."
> 
> (* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 23) ∗ all code *)
> ```
>这么小字符串不会产生多大影响，但是组合巨大的字符串时，这会产生严重的性能问题。

现在我需要写代码来呈现一行数据。我们先写一个`pad`函数来把一个字符串拉长到指定长度，包括两边各加一个空格：

```ocaml
# let pad s length =
    " " ^ s ^ String.make (length - String.length s + 1) ' '
  ;;
val pad : string -> int -> string = <fun>
# pad "hello" 10;;
- : string = " Hello      "

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 24) ∗ all code *)
```
我们可以把填充后的字符串合并起来呈现一行数据。我们再一次使用了`List.map2_exn`来结合一行数据的列表和其对应宽度的列表：

```ocaml
# let render_row row widths =
    let padded = List.map2_exn row widths ~f:pad in
    "|" ^ String.concat ~sep:"|" padded ^ "|"
  ;;
val render_row : string list -> int list -> string = <fun>
# render_row ["Hello";"World"] [10;15];;
- : string = "| Hello      | World           |"

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 25) ∗ all code *)
```
现在我可以把所有这些都用在一个函数中来呈现一个表：

```ocaml
# let render_table header rows =
    let widths = max_widths header rows in
    String.concat ~sep:"\n"
      (render_row header widths
       :: render_separator widths
       :: List.map rows ~f:(fun row -> render_row row widths)
      )
  ;;
val render_table : string list -> string list list -> string = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 26) ∗ all code *)
```
#### 更多有用的列表函数
上面的例子只涉及了`List`中的三个函数。我们不能覆盖所有接口（你可以去查看[在线文档](http://realworldocaml.org/doc)），但还有几个函数很重要，值得在这里提一下。

##### 用`List.reduce`合并列表元素
我们上面描述的`List.fold`是一个非常通用也非常强大的函数。然而有时，你会想要更简单也更容易使用的接口。`List.reduce`就是其中之一，它本质上是一个特殊版本的`List.fold`，不需要显式的初始值，其累加器要消费并生产和列表元素相同类型的值。

这是其类型签名：

```ocaml
# List.reduce;;
- : 'a list -> f:('a -> 'a -> 'a) -> 'a option = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 27) ∗ all code *)
```
`reduce`返回一个`option`值，当输入列表为空时返回`None`。

现在我们可以看看`reduce`的应用：

```ocaml
# List.reduce ~f:(+) [1;2;3;4;5];;
- : int option = Some 15
# List.reduce ~f:(+) [];;
- : int option = None

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 28) ∗ all code *)
```
##### 使用`List.filter`和`List.filter_map`过滤列表
处理列表时，通常需要将注意力限定在列表特定的子集上。`List.filter`就一种方法：

```ocaml
# List.filter ~f:(fun x -> x mod 2 = 0) [1;2;3;4;5];;
- : int list = [2; 4]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 29) ∗ all code *)
```
注意上面的`mod`是一个中缀操作符，在[第2章变量和函数](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_02_variables_and_functions.md)中有描述。

有时，你会想在一个操作中同时进行遍历和过滤操作。此时，你需要`List.filter_map`。传给`List.filter_map`的函数返回一个`option`值，`List.filter_map`会丢弃所有返回`None`的元素。

这里有一个例子。下面的表达式用以处理一个当前目录中文件扩展名的列表，并将其传给`List.dedup`来去重。注意此例中也使用了其它模块的函数，包括`Sys.ls_dir`，用以取目录列表，以及`String.rsplit2`以最右边出现的给定字符来分割字符串：

```ocaml
# List.filter_map (Sys.ls_dir ".") ~f:(fun fname ->
    match String.rsplit2 ~on:'.' fname with
    | None  | Some ("",_) -> None
    | Some (_,ext) ->
      Some ext)
  |> List.dedup
  ;;
- : string list = ["ascii"; "ml"; "mli"; "topscript"]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 30) ∗ all code *)
```
上面也是一个**或**模式的例子，或模式允许在一个大模式中使用多个子模式。这里，`None | Some ("",_)`就是一个或模式。后面我们会看到，或模式可以在一个更大的模式中任意嵌套。

##### 使用`List.partition_tf`分割列表元素
另一个和过滤很像的有用操作符是分割。函数`List.partition_tf`以一个列表和一个函数为参数，函数对每一个列表元素计算出一个布尔值，`List.partition_tf`返回两个列表。名字中的`tf`提示用户，`true`的元素在返回的第一个列表中，`false`的元素在第二个中。下面是一个例子：

```ocaml
# let is_ocaml_source s =
    match String.rsplit2 s ~on:'.' with
    | Some (_,("ml"|"mli")) -> true
    | _ -> false
  ;;
val is_ocaml_source : string -> bool = <fun>
# let (ml_files,other_files) =
    List.partition_tf (Sys.ls_dir ".")  ~f:is_ocaml_source;;
val ml_files : string list = ["example.mli"; "example.ml"]
val other_files : string list = ["main.topscript"; "lists_layout.ascii"]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 31) ∗ all code *)
```

##### 组合列表
另一个很常见的操作就是列表的拼接。`List`模块提供了几种不的方式在拼接列表。首先是`List.append`，用以拼接一对列表：

```ocaml
# List.append [1;2;3] [4;5;6];;
- : int list = [1; 2; 3; 4; 5; 6]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 32) ∗ all code *)
```

还有`@`，一个和`List.append`等价的事件符：

```ocaml
# [1;2;3] @ [4;5;6];;
- : int list = [1; 2; 3; 4; 5; 6]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 33) ∗ all code *)
```
此外还有`List.concat`，用以拼接一个列表中的所有列表：

```ocaml
# List.concat [[1;2];[3;4;5];[6];[]];;
- : int list = [1; 2; 3; 4; 5; 6]

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 34) ∗ all code *)
```
下面的例子使用`List.concat`和`List.map`来递归列举一个目录树：

```ocaml
# let rec ls_rec s =
    if Sys.is_file_exn ~follow_symlinks:true s
    then [s]
    else
      Sys.ls_dir s
      |> List.map ~f:(fun sub -> ls_rec (s ^/ sub))
      |> List.concat
  ;;
val ls_rec : string -> string list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 35) ∗ all code *)
```
注意`^/`是`Core`提供的一个中缀操作符，用以向一个表示路径的字符串上添加一个新元素。和`Core`的`Filename.concat`等价。

上面`List.map`和`List.concat`的组合使用非常常用，以至于专门有一个`List.concat_map`函数把这两个函数合二为一，形成是一个更高效的操作：

```ocmal
# let rec ls_rec s =
    if Sys.is_file_exn ~follow_symlinks:true s
    then [s]
    else
      Sys.ls_dir s
      |> List.concat_map ~f:(fun sub -> ls_rec (s ^/ sub))
  ;;
val ls_rec : string -> string list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 36) ∗ all code *)
```

### 尾递归
计算一个 OCaml 列表长度的唯一方法是从头数到尾。所以，计算一个列表长度的时间和列表的大小成线性关系。下面就是一个求列表长度的简单函数：

```ocaml
# let rec length = function
    | [] -> 0
    | _ :: tl -> 1 + length tl
  ;;
val length : 'a list -> int = <fun>
# length [1;2;3];;
- : int = 3

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 37) ∗ all code *)
```
看起来很简单，但我们会发现这个实现在巨大的列表上会有问题，如下所示：

```ocaml
# let make_list n = List.init n ~f:(fun x -> x);;
val make_list : int -> int list = <fun>
# length (make_list 10);;
- : int = 10
# length (make_list 10_000_000);;
Stack overflow during evaluation (looping recursion?).

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 38) ∗ all code *)
```
上面的例子使用`List.init`来创建列表，以一个整数`n`和一个函数`f`为参数，创建一个长度为`n`的列表，每个元素的数据就是在索引值上调用`f`的结果。

要弄清楚上面的例子错在哪里，你还需要知道多一点函数调用的工作原理。典型的一个函数调用需要一些空间来保存相关的信息，如传给函数的参数，或是函数完成时需要继续执行的位置。为了允许嵌套函数，这些信息通常都组织在栈上，每个嵌套函数调用都会分配一个新的*栈结构（stack frame）*，在函数结束时会释放这个结构。

这就是我们调用`length`的问题所在：试图分配一千万个栈结构，这耗尽了栈空间。幸运的是，这个问题有解。看下面的另一个实现：

```ocaml
# let rec length_plus_n l n =
    match l with
    | [] -> n
    | _ :: tl -> length_plus_n tl (n + 1)
  ;;
val length_plus_n : 'a list -> int -> int = <fun>
# let length l = length_plus_n l 0 ;;
val length : 'a list -> int = <fun>
# length [1;2;3;4];;
- : int = 4

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 39) ∗ all code *)
```
这个实现依赖一个帮助函数`length_plus_n`，它计算一个给定列表的长度加上给定的`n`。实际上，`n`起到了累加器的作用，一步步构造最终结果。因此，我们就可以顺着做加法，而不必像`length`的第一个实现那样去展开嵌套函数的调用。

这种方法的优点是`length_plus_n`中的递归调用是一个*尾调用*。稍后我们会更准确地解释什么是尾调用，但一个非常重要的原因是尾调用不需要分配新的栈结构，因为使用了一种称为*尾调用优化*的技术。如果一个函数的所有递归调用都是尾调用，它就是*尾递归*的。`length_plus_n`是尾递归的，因此，`length`可以接收输入一个长列表而不会撑爆栈：

```ocaml
# length (make_list 10_000_000);;
- : int = 10000000

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 40) ∗ all code *)
```
那么尾调用到底是什么呢？让我们思考一下一个函数（调用者）对另一个函数（被调用者）的调用。对于被调用者的返回值，如果调用者除了将其直接返回没有其它任何操作，这个调用就是一个尾调用。尾调用优化之所以可行，是因为当调用者执行一个尾调用时，调用者栈结构就不会再使用了，所以你也就没有必要保存它了。因此，编译器可以复用调用者的栈结构，而不必为被调用者分配一个新的。

尾递归在许多情况下都很重要，而不仅限于列表。在处理像二叉树这样树的深度是你数据大小的对数时，使用普通递归（非尾递归）是很合理的。但是当嵌套调用的深度和你的数据大小相当时，应该使用尾递归。

### 更简洁、更快的模式
现在我们已经知道了列表和模式是如何工作的，让我们考虑一下我们可以如何改进[“递归列表函数”一节](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_01_a_guide_tour.md#递归列表函数)中的一个例子：函数`destutter`，用以消除一个列表中的连续重复。下面是之前的实现：

```ocaml
# let rec destutter list =
    match list with
    | [] -> []
    | [hd] -> [hd]
    | hd :: hd' :: tl ->
      if hd = hd' then destutter (hd' :: tl)
      else hd :: destutter (hd' :: tl)
  ;;
val destutter : 'a list -> 'a list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 41) ∗ all code *)
```
下面我们想一些办法使这段代码更简捷同时也更高效。

首先让我们考虑效率。上面`destutter`的一个问题是在有些情况下会在箭头右边重复创建左边已经存在的值。因此，模式`[hd] -> [hd]`分配了一个新的列表元素，但实际上，它应该仅返回匹配的列表即可。使用`as`模式我们可以减少这种分配，`as`让我们可以给和一个模式或子模式匹配的东西命名。同时我们使用`function`关键字来替代显式的`match`：

```ocaml
# let rec destutter = function
    | [] as l -> l
    | [_] as l -> l
    | hd :: (hd' :: _ as tl) ->
      if hd = hd' then destutter tl
      else hd :: destutter tl
  ;;
val destutter : 'a list -> 'a list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 42) ∗ all code *)
```
我们可以使用或模式组合前两个分支来进一步压缩：

```ocaml
# let rec destutter = function
    | [] | [_] as l -> l
    | hd :: (hd' :: _ as tl) ->
      if hd = hd' then destutter tl
      else hd :: destutter tl
  ;;
val destutter : 'a list -> 'a list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 43) ∗ all code *)
```
使用`when`子句我们可以使代码更简洁。`when`子句允许在一个模式上以任意 OCaml 表达式的形式添加额外的先决条件。现在，我们使用它来包含前两个元素是否相等的检查。
```ocaml
# let rec destutter = function
    | [] | [_] as l -> l
    | hd :: (hd' :: _ as tl) when hd = hd' -> destutter tl
    | hd :: tl -> hd :: destutter tl
  ;;
val destutter : 'a list -> 'a list = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 44) ∗ all code *)
```
#### 多态比较
上面`destutter`的例子中，我们使用了 OCaml 的一个特性，使我们可以用`=`操作符来测试任意类型的两个值是否相等。因此，我们可以这样写：

```ocaml
# 3 = 4;;
- : bool = false
# [3;4;5] = [3;4;5];;
- : bool = true
# [Some 3; None] = [None; Some 3];;
- : bool = false

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 45) ∗ all code *)
```
实际上，当我们查看等于操作符的类型时，就可以看到它是多态的：

```ocaml
# (=);;
- : 'a -> 'a -> bool = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 46) ∗ all code *)
```
OCaml 自带了一整族的多态操作符，包括标准的中缀操作符`<`、`>=`等，还有`compare`函数，在第一个操作数小于、相等、大于第二个操作数时分别返回`-1`、`0`或`1`。

你可能想知道如果 OCaml 没有自带时，你如何才能自己创建这样的函数。结论是你*不能*自己创建这样的函数。OCaml 的多态比较函数实际上是在运行时底层内建的。这些比较的多态性是建立在几乎忽略所有被比较值的类型信息的基础之上的，只关注值在内存中分布的结构。

多态比较是有一些限制的。比如，碰到函数值就会失败：

```ocaml
# (fun x -> x + 1) = (fun x -> x + 1);;
Exception: (Invalid_argument "equal: functional value").

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 47) ∗ all code *)
```
类似的，在作用于 OCaml 堆以外的值时也会失败，如来自 C 语言绑定的值。但对于其它值，其都能很好地工作。

对于简单的原子类型，多态比较的语义是可以预期的：对于浮点数和整数，多态比较就是相关的数值比较函数。对于字符串，就是字典比较。

然而，多态比较的这种类型无关有时会成为问题，特别是当你想使用自己的相等或顺序概念时。在[第13章映射和哈希表](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_13_maps_and_hash_tables.md)中，我们还会进一步讨论这个话题，以及多态比较的其它缺点。

注意`when`子句也是有负面作用的。模式匹配相关的静态检查依赖于其模式在表达方面是受限的。一旦给模式加入了可以附带任意表达式的能力，就会同时丢失某些特性。特别是编译器检查匹配是否完整或分支是否多余的能力会受影响。

来看下面这个函数，接收一个`option`值的列表，返回其中值为`Some`的元素数。因为这个实现使用了`when`子句，所以编译器无法确定代码的匹配是完整的：

```ocaml
# let rec count_some list =
    match list with
    | [] -> 0
    | x :: tl when Option.is_none x -> count_some tl
    | x :: tl when Option.is_some x -> 1 + count_some tl
  ;;

Characters 30-169:
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
_::_
(However, some guarded clause may match this value.)val count_some : 'a option list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 48) ∗ all code *)
```
尽管有警告，函数依然可以正常工作：

```ocaml
# count_some [Some 3; None; Some 4];;
- : int = 2

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 49) ∗ all code *)
```
如果我们加一个不使用`when`子句的分支，编译器就不会报怨了，也不会警告有冗余：

```ocaml
# let rec count_some list =
    match list with
    | [] -> 0
    | x :: tl when Option.is_none x -> count_some tl
    | x :: tl when Option.is_some x -> 1 + count_some tl
    | x :: tl -> -1 (* unreachable *)
  ;;
val count_some : 'a option list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 50) ∗ all code *)
```
可能更好的方法是简单把第二个`when`子句去掉即可：

```ocaml
# let rec count_some list =
    match list with
    | [] -> 0
    | x :: tl when Option.is_none x -> count_some tl
    | _ :: tl -> 1 + count_some tl
  ;;
val count_some : 'a option list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 51) ∗ all code *)
```
这样不如直接使用模式匹配来得清楚，直接使用模式匹配时，每一个模式本身的含义更清楚：

```ocaml
# let rec count_some list =
    match list with
    | [] -> 0
    | None   :: tl -> count_some tl
    | Some _ :: tl -> 1 + count_some tl
  ;;
val count_some : 'a option list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 52) ∗ all code *)
```
结论就是：尽管`when`子句很有用，但是无论何处只要模式够用，就应该优先使用模式。

另外，上面的这个`count_some`实现没必要这么长，更糟的也不是尾递归的。实际应用中，只要使用 Core 中的`List.count`函数就行了：

```ocaml
# let count_some l = List.count ~f:Option.is_some l;;
val count_some : 'a option list -> int = <fun>

(* OCaml Utop ∗ lists-and-patterns/main.topscript , continued (part 53) ∗ all code *)
```





