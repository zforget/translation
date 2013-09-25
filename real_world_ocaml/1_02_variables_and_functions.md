## 第二章 变量和函数
变量和函数几乎是所有编程语言的基本概念。OCaml中概念与你碰到过的可能有所不同，所以本章会覆盖OCaml中变量和函数的细节，从基本的如何定义一个变量开始，最后会介绍使用了可选参数和标签参数的复杂函数。

当被一些细节打击时不要气馁，特别是在接近本章结尾时。本章的概念非常重要，如果首次阅读时没有领会，在你对OCaml有了更多了解后回过头来重读本章以补上对这些概念的理解。

### 变量
简单来说，变量是一个标识符，其含义绑定到一个特定的值上。在OCaml中，这些绑定通常用`let`关键字引入。我们可以用下面的语法写出一个所谓的顶层绑定。注意变量必须以小写字母或下划线开头。
```ocaml
let <variable> = <expr>

(* Syntax ∗ variables-and-functions/let.syntax ∗ all code *)
```
在[第4章文件、模块和程序](#文件模块和程序)中接触模块时我们会看到，模块的顶层`let`绑定也使用了相同的语法。

每一个变量绑定都有一个作用域，就是代码中可以引用它的部分。使用 **utop**时，作用域是本次会话后面所有的东西。当在模块中时，作用域就是那个模块剩下的部分。

下面是一个例子。
```ocaml
# let x = 3;;
val x : int = 3
# let y = 4;;
val y : int = 4
# let z = x + y;;
val z : int = 7

(* OCaml Utop ∗ variables-and-functions/main.topscript ∗ all code *)
```
使用下面的语法，`let`也可以用以创建一个作用域仅限于特定表达式的变量。
```ocaml
let <variable> = <expr1> in <expr2>

(* Syntax ∗ variables-and-functions/let_in.syntax ∗ all code *)
```
先求值`<expr1>`，再把`<variable>>`绑定到`<expr1>`的值上来求值`<expr2>`。下面是一个实际应用的例子。
```ocaml
# let languages = "OCaml,Perl,C++,C";;
val languages : string = "OCaml,Perl,C++,C"
# let dashed_languages =
    let language_list = String.split languages ~on:',' in
    String.concat ~sep:"-" language_list
  ;;
val dashed_languages : string = "OCaml-Perl-C++-C"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 1) ∗ all code *)
```
注意`language_list`的作用域仅限于表达式`String.concat ~sep:"-" language_list`，在顶层是不能访问的，就比如现在我们尝试访问它：
```ocaml
# language_list;;
Characters -1-13:
Error: Unbound value language_list

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 2) ∗ all code *)
```
内层作用域的绑定会遮蔽，或者说隐藏外层作用域中的定义。所以，我们可以像下面这样写`dashed_languages`这个例子：
```ocaml
# let languages = "OCaml,Perl,C++,C";;
val languages : string = "OCaml,Perl,C++,C"
# let dashed_languages =
     let languages = String.split languages ~on:',' in
     String.concat ~sep:"-" languages
  ;;
val dashed_languages : string = "OCaml-Perl-C++-C"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 3) ∗ all code *)
```
这一次，内层作用域中我们用`languages`来代替`language_list`作为字符串列表名，因此隐藏了`languages`的原始定义。但是一但`dashed_languages`执行完，内层作用域就会关闭，`languages`的原始定义就又回来了。
```ocaml
# languages;;
- : string = "OCaml,Perl,C++,C"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 4) ∗ all code *)
```
有一个惯用法就是使用一系列的`let/in`表达式来构建一个大型计算的各个组件。因此，我们可以这样写：
```ocaml
# let area_of_ring inner_radius outer_radius =
     let pi = acos (-1.) in
     let area_of_circle r = pi *. r *. r in
     area_of_circle outer_radius -. area_of_circle inner_radius
  ;;
val area_of_ring : float -> float -> float = <fun>
# area_of_ring 1. 3.;;
- : float = 25.1327412287

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 5) ∗ all code *)
```
注意不要修改可变变量，这会使这一系列`let`绑定变得混乱。例如，如果这不是故意写来混淆代码的，那么下面会如何计算环形的面积：
```ocaml
# let area_of_ring inner_radius outer_radius =
     let pi = acos (-1.) in
     let area_of_circle r = pi *. r *. r in
     let pi = 0. in
     area_of_circle outer_radius -. area_of_circle inner_radius
  ;;

Characters 126-128:
Warning 26: unused variable pi.val area_of_ring : float -> float -> float = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 6) ∗ all code *)
```
这里,我们在`area_of_ring`之后又把`pi`重定义成0。你可能会以为计算结果是0，但实际上函数的行为没有改变。这是因为原先的`pi`定义没有改变，只是被隐藏了而已，就是说接下来新的定义中对`pi`的引用才会看到`pi`的值为0，先前的引用是不会改变的。但是后面没有对`pi`的引用了，所以把`0.`绑定到`pi`其实没有任何作用。这就解释了为什么toplevel会警告我们有未使用的`pi`定义。

在OCaml中，`let`绑定是不可变的。OCaml中有许多不可变的值，我们会在第8章命令式编译中讨论，但是却没有可变的变量。
> **为什么变量不能变化**
>
> OCaml初学者的一个困惑就是变量是不可变的。这在语言学上也很奇怪，难道变量不是就可以变化的意思吗?
>
> 答案是，OCaml（通常还有其它函数式编程语言）中的变量更像是方程式中的变量，而非命令式语言中的变量。如果你考虑数学方程式`x(y+z)=xy+xz`，那么变量`x`、`y`和`z`就没有可变的意思。可变的意思是你可以给变量不同的值来实例化这个方程式，但是变量仍然是不变的。
>
> 在函数式语言中也是这样的。一个函数可以作用于不同的输入，因此其变量即使不能改变也会具有不同的值。

#### 模式匹配和`let`
`let`绑定的另一个有用特性是支持在左边使用 **模式**。考虑下面的代码，其中使用了`List.unzip`，这个函数可以将一个序对（pair）列表转变成两个列表的序对。
```ocaml
# let (ints,strings) = List.unzip [(1,"one"); (2,"two"); (3,"three")];;
val ints : int list = [1; 2; 3]
val strings : string list = ["one"; "two"; "three"]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 7) ∗ all code *)
```
其中`(ints,strings)`是一个模式，`let`绑定会赋值模式中出现的标识符。模式本质上是一个数据结构形状的描述，其中有一些组件是需要需要绑定的标识符。在[“元组、列表、option和模式匹配”](#元组列表option和模式匹配)一节中我们已经看到了，OCaml在许多不同数据类型上都要有模式。

在`let`绑定中使用模式对于 **确凿的（irrefutable）**模式更有意义，即，此类型的任何值都能保证匹配这个模式。元组和记录模式是确凿的，但列表模式不是。考虑虑下面的代码，其实现了一个函数，将一个逗号分割的列表的第一个元素变成大写。
```ocaml
# let upcase_first_entry line =
     let (first :: rest) = String.split ~on:',' line in
     String.concat ~sep:"," (String.uppercase first :: rest)
  ;;

Characters 40-53:
Warning 8: this pattern-matching is not exhaustive. Here is an example of a value that is not matched:
[]val upcase_first_entry : string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 8) ∗ all code *)
```
这种情况实际上永远不会发生，因为`String.split`总是会返回一个至少有一个元素的列表。但是编译器不知道这一点，所以它给出了警告。通常，使用`match`语句显式处理这种情况会更好。
```ocaml
# let upcase_first_entry line =
     match String.split ~on:',' line with
     | [] -> assert false (* String.split returns at least one element *)
     | first :: rest -> String.concat ~sep:"," (String.uppercase first :: rest)
  ;;
val upcase_first_entry : string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 9) ∗ all code *)
```
这是我们首次使用`assert`，它在标注不可能的情况时很有用。我们会在[第7章错误处理](#错误处理)中详细讨论。

### 函数
考虑到OCaml是一种函数式语言，也就不奇怪函数是如此重要且如此普通，我们目前的每个例子中几乎都有函数的身影。这一节我们更进一步，解释OCaml中的函数是如何工作的。你会看到，OCaml中的函数与你在主流语言中见到的函数有很大的不同。

#### 匿名函数
我们从OCaml中最基本的函数声明方式开始： **匿名函数**。匿名函数是一个不带名称声明的函数值。它们可以使用`fun`关键字声明，如下所示。
```ocaml
# (fun x -> x + 1);;
- : int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 10) ∗ all code *)
```
匿名函数和命名函数的行为大致相同。如，我们可以在匿名函数上应用参数。
```ocaml
# (fun x -> x + 1) 7;;
- : int = 8

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 11) ∗ all code *)
```
或者将其传递给其它函数。将函数传递给`List.map`这类迭代函数可能是匿名函数最常见的使用场景。
```ocaml
# List.map ~f:(fun x -> x + 1) [1;2;3];;
- : int list = [2; 3; 4]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 12) ∗ all code *)
```
我们甚至可以把它们塞进一个数据结构中。
```ocaml
# let increments = [ (fun x -> x + 1); (fun x -> x + 2) ] ;;
val increments : (int -> int) list = [<fun>; <fun>]
# List.map ~f:(fun g -> g 5) increments;;
- : int list = [6; 7]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 13) ∗ all code *)
```
现在有必要停下来搞清楚这个例子，因为函数的这种高阶用法开始可能显得比较晦涩。首先，`(fun g -> g 5)`是一个函数，它接收一个函数作为参数并将其应用到数字`5`上。调用`List.map`是将`(fun g -> g 5)`函数应用到`increments`列表的每一个元素（也是函数）上，并返回结果构成的新列表。

关键点就是，OCaml的函数只是普通值，所以你可以用普通值做的事都可以用于函数，如作为函数参数或返回值，以及保存到数据结构中。使用`let`绑定，我们可以像命名其它值一样命名函数。
```ocaml
# let plusone = (fun x -> x + 1);;
val plusone : int -> int = <fun>
# plusone 3;;
- : int = 4

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 14) ∗ all code *)
```
函数定义太常用了，所以提供了一些语法糖。下面`plusone`的定义和上面是等价的。
```ocaml
# let plusone x = x + 1;;
val plusone : int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 15) ∗ all code *)
```
这是声明函数更常用也更方便的方法，不过抛开语法细节不说，这两种定义函数的方式是完全等价的。
> **`let`和`fun`**
>
> 函数和`let`绑定有许多互通性。在某种意义上，你可以把函数参数看成是一个由调用者绑定了输入值的变量。实际上，下面两个表达式几乎是一样的：
> ```ocaml
> # (fun x -> x + 1) 7;;
> - : int = 8
> # let x = 7 in x + 1;;
> - : int = 8
> 
> (* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 16) ∗ all code *)
> ```
> 这种联系很重要，这在单子(monadic)风格中更明显，详见[第18章使用Async并行编程](#使用Async并行编程)。

#### 多参数函数
OCaml当然支持多参数函数，如：
```ocaml
# let abs_diff x y = abs (x - y);;
val abs_diff : int -> int -> int = <fun>
# abs_diff 3 4;;
- : int = 1

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 17) ∗ all code *)
```
你会发现`abs_diff`的类型签名中有许多不好解析的箭头。为了理解这一点，我们以一种等价的方式，用`fun`关键字重写`abs_diff`函数：
```ocaml
# let abs_diff =
    (fun x -> (fun y -> abs (x - y)));;
val abs_diff : int -> int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 18) ∗ all code *)
```
这次真的把`abs_diff`显式写成了一个接收一个参数的函数，返回另一个也接收一个参数函数，返回的函数的返回值即是最后的结果。因为函数的嵌套的，所以内层表达式`abs (x - y)`即可以访问外层函数绑定的`x`，也可以访问内层函数绑定的`y`。

这种风格的函数称为 **柯里化（curried）**函数。(Currying是以Haskell Curry命名的，一位对编程语言设计和理论都有重大影响的逻辑学家。)解释柯里化函数签名的关键是`->`是右结合的。因此`abs_diff`的类型签名可以像下面这样加上括号。
```ocaml
val abs_diff : int -> (int -> int)

(* OCaml ∗ variables-and-functions/abs_diff.mli ∗ all code *)
```
括号并没有改变签名的含意，但是可以更清楚地看到柯里化。

柯里化也不仅仅是理论玩具。应用柯里化，你可以只提供一部分参数来特化一个函数。下面的例子中，我们创建了一个`abs_diff`的特化版本，来求给定的数到`3`的距离。
```ocaml
# let dist_from_3 = abs_diff 3;;
val dist_from_3 : int -> int = <fun>
# dist_from_3 8;;
- : int = 5
# dist_from_3 (-1);;
- : int = 4

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 19) ∗ all code *)
```
这种在柯里化函数上应用部分参数得到一个新函数的实践叫 **偏特化应用（partial application）**。

注意`fun`关键字本身的语法就支持柯里化，所以下面的`abs_diff`定义和上面的是等价的。
```ocaml
# let abs_diff = (fun x y -> abs (x - y));;
val abs_diff : int -> int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 20) ∗ all code *)
```
你也许会担心调用柯里化函数会有严重的性能问题，但完全没有这个必要。在OCaml中，以完整参数调用一个柯里化的函数没有任何额外开销。（当然，偏特化函数会产生一点点额外的开销。）

柯里化不是OCaml中写多参数函数的唯一方法。使用元组不同字段作为不同参数也是可以的。所以我们可以这样写：
```ocaml
# let abs_diff (x,y) = abs (x - y);;
val abs_diff : int * int -> int = <fun>
# abs_diff (3,4);;
- : int = 1

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 21) ∗ all code *)
```
OCaml处理这种调用约定也非常高效。特别是，通常都不必为了传递元组形式的参数而分配一个元组。当然，这时你就不能使用偏特化应用了。

这两种方法差异很小，但是大多数时候你都应该使用柯里化形式，因为它是OCaml中默认的。

#### 递归函数
定义中又调用了自己的函数就是 **递归**的。递归在任何编程语言中都很重要，但对函数式语言尤为如此，因为递归是函数式语言实现循环结构的手段。（第8章命令式编程中我们会详细介绍，OCaml也支持`for`循环和`while`循环，但是它们只是在使用OCaml的命令式编程特性时才有用。）

要定义递归函数，你需要使用`rec`关键将`let`绑定标记成递归的，下面是一个例子，是一个查找列表第一个重复元素序列的函数。
```ocaml
# let rec find_first_stutter list =
    match list with
    | [] | [_] ->
      (* only zero or one elements, so no repeats *)
      None
    | x :: y :: tl ->
      if x = y then Some x else find_first_stutter (y::tl)
   ;;
val find_first_stutter : 'a list -> 'a option = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 22) ∗ all code *)
```
模式`[] | [_]`是一个 **或模式**，是两个模式的组合，只要任何一个模式匹配即可。这里`[]`匹配空列表，`[_]`匹配只有一个元素的列表。使用`_`我们为这个单独的元素指定显式名称了。

使用`let rec`和`and`配合我们也能定义多个互相递归的值。下面是一个例子（天生低效）。
```ocaml
# let rec is_even x =
    if x = 0 then true else is_odd (x - 1)
  and is_odd x =
    if x = 0 then false else is_even (x - 1)
 ;;
val is_even : int -> bool = <fun> val is_odd : int -> bool = <fun>
# List.map ~f:is_even [0;1;2;3;4;5];;
- : bool list = [true; false; true; false; true; false]
# List.map ~f:is_odd [0;1;2;3;4;5];;
- : bool list = [false; true; false; true; false; true]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 23) ∗ all code *)
```
OCaml需要区分非递归定义（用`let`）和递归定义（用`let rec`）主要是技术原因：类型推导算法需要知道何时一组函数定义是相互递归的，并且出于一些纯函数式语言中没有原因，如Haskell，这需要程序员自己显式标注。

但这个决策也有好处。一个原因是，递归（特别是交互递归）定义比非递归更难推理。所以如果在没有显式`rec`的地方，你就可以认为这个`let`绑定一定只能是基于之前的绑定，这一点是有意义的。

另外，有一个单独的非递归形式也使得创建一个新的定义通过遮蔽来替代一个已存在的定义更为容易。

#### 前缀和中缀操作符
目前。在例子中我们前缀和中缀形式的函数都用过了：
```ocaml
# Int.max 3 4  (* prefix *);;
- : int = 4
# 3 + 4        (* infix  *);;
- : int = 7

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 24) ∗ all code *)
```
你也许会认为第二个例子不是一个普通函数，但它还真的是。像`+`这样的中缀操作符仅仅在语法上和其它函数有点不同。实际上，如果给中缀操作符加上括号，就可以像普通前缀函数一样使用了。
```ocaml
# (+) 3 4;;
- : int = 7
# List.map ~f:((+) 3) [4;5;6];;
- : int list = [7; 8; 9]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 25) ∗ all code *)
```
第二个表达式中，我们通用偏特化`(+)`创建了一个将参数加3的函数。

如果函数名中下面的标识符，就会被当成操作符，也包括完全由下面字符组成的标识符。
```ocaml
! $ % & * + - . / : < = > ? @ ^ | ~

(* Syntax ∗ variables-and-functions/operators.syntax ∗ all code *)
```
还有几个预先确定的字符串也是操作符，包括`mod`，取模操作符，和`lsl`，表示“逻辑左移（logical shift left）”，一个位操作符。

我们可以定义（或重定义）一个操作符的含义。下面例子中是一个作用于`int`序对的向量加法操作符。
```ocaml
# let (+!) (x1,y1) (x2,y2) = (x1 + x2, y1 + y2);;
val ( +! ) : int * int -> int * int -> int * int = <fun>
# (3,2) +! (-2,4);;
- : int * int = (1, 6)

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 26) ∗ all code *)
```
处理包含`*`的操作符要小心。看下面的例子：
```ocaml
# let (***) x y = (x ** y) ** y;;
Characters 17-18:
Error: This expression has type int but an expression was expected of type float

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 27) ∗ all code *)
```
上面的错误是因为`(***)`没有被解析成操作符，而是被看成了注释！要正确工作，我们需要在`*`前面或后面加上括号。
```ocaml
# let ( *** ) x y = (x ** y) ** y;;
val ( *** ) : float -> float -> float = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 28) ∗ all code *)
```
操作符的语法角色主是前一到两个字符决定的，鲜有例外。下表将不同的操作符和其它语法形式按优先级从高到低分组，并分别解释了其语法行为。我们用`!...`来表示以`～`开头的这类操作符。

| Prefix                                           |Usage |
| ------------------------------------------------ | ---- |
|`!..., ?..., ~...` 	                           |前缀  |
|`., .(, .[`                                       |      |
|`function application, constructor, assert, lazy` |左结合|
|`-, -.` 	                                       |前缀  |
|`**..., lsl, lsr, asr` 	                       |右结合|
|`*..., /..., %..., mod, land, lor, lxor` 	       |左结合|
|`+, -` 	                                       |左结合|
|`::` 	                                           |右结合|
|`@..., ^...` 	                                   |右结合|
|`=..., <..., >...,` &#124;..., `&..., $...` 	   |左结合|
|`&, &&` 	                                       |右结合|
|`or`, &#124;&#124;                                |右结合|
|`,` 	                                           |      |
|`<-, :=` 	                                       |右结合|
|`if` 	                                           |      |
|`;` 	                                           |右结合|

有一个很重要的特殊情况：`-`和`-.`，整数和浮点数减法运算符，可以即当前缀操作符（负数）也当中缀操作符（减法），因此`-x`和`x - y`都是正确的表达式。还有一点要注意的就是负数操作的优先比函数调用低，就是说你需要括号来传递一个负数，如下所示。
```ocaml
# Int.max 3 (-4);;
- : int = 3
# Int.max 3 -4;;
Characters -1-9:
Error: This expression has type int -> int but an expression was expected of type int

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 29) ∗ all code *)
```
OCaml会把第二个表达式解释成：
```ocaml
# (Int.max 3) - 4;;
Characters 1-10:
Error: This expression has type int -> int but an expression was expected of type int

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 30) ∗ all code *)
```
这显然是错误的。

下面的例子中是一个非常有用的操作符，来自标准库，其行为严格依赖上面提到的优先级规则。代码如下。
```ocaml
# let (|>) x f = f x ;;
val ( |> ) : 'a -> ('a -> 'b) -> 'b = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 31) ∗ all code *)
```
其作用开始并不明显：它只是接收一个值和一个函数，然后把函数应用到值上。尽管这个描述听起来平淡无奇，它却在序列化操作符时扮演重要角色，和UNIX管道神似。例如，考虑下面的代码，可以无重复地打印出你`PATH`中的元素。下面的`List.dedup`通过使用给定的比较函数排序来从一个列表中消除重复。
```ocaml
# let path = "/usr/bin:/usr/local/bin:/bin:/sbin";;
val path : string = "/usr/bin:/usr/local/bin:/bin:/sbin"
#   String.split ~on:':' path
  |> List.dedup ~compare:String.compare
  |> List.iter ~f:print_endline
  ;;

/bin
/sbin
/usr/bin
/usr/local/bin
- : unit = ()

(*s OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 32) ∗ all code *)
```
注意我们不用`|>`也能做到这一点，但是会有一些冗长。
```ocaml
#   let split_path = String.split ~on:':' path in
  let deduped_path = List.dedup ~compare:String.compare split_path in
  List.iter ~f:print_endline deduped_path
  ;;

/bin
/sbin
/usr/bin
/usr/local/bin
- : unit = ()

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 33) ∗ all code *)
```
这里有一个很重要的方面就是偏特化应用。如，`List.iter`正常会接收两个参数：一个对列表的每一个元素都调用的函数
#### Declaring functions with function

#### Labeled arguments
##### Higher-order functions and labels

#### Optional arguments
##### Explicit passing of an optional argument
##### Inference of labeled and optional arguments
##### Optional arguments and partial application
