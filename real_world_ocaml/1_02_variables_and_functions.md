## 第二章 变量和函数
变量和函数是几乎所有编程语言的基本概念。OCaml 中概念与你碰到过的可能有所不同，所以本章会覆盖 OCaml 中变量和函数的细节，从基本的如何定义一个变量开始，最后会介绍使用了可选参数和标签参数的复杂函数。

当被一些细节打击时不要气馁，特别是在接近本章结尾时。本章的概念非常重要，如果首次阅读时没有领会，在你对 OCaml 有了更多了解后回过头来重读本章以补上对这些概念的理解。

### 变量
简单来说，变量是一个标识符，其含义绑定到一个特定的值上。在 OCaml 中，这些绑定通常用`let`关键字引入。我们可以用下面的语法写出一个所谓的*顶层绑定*。注意变量名必须以小写字母或下划线开头：

```ocaml
let <variable> = <expr>

(* Syntax ∗ variables-and-functions/let.syntax ∗ all code *)
```
在[第4章文件、模块和程序](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_04_files_modules_and_programs.md)中接触模块时我们会看到，模块的顶层`let`绑定也使用了相同的语法。

每一个变量绑定都有一个*作用域*，就是代码中可以引用它的部分。使用  **utop** 时，顶层`let`绑定的作用域是本次会话中其后面所有的东西。当在模块中时，作用域就是那个模块剩下的部分。

下面是一个例子：

```ocaml
# let x = 3;;
val x : int = 3
# let y = 4;;
val y : int = 4
# let z = x + y;;
val z : int = 7

(* OCaml Utop ∗ variables-and-functions/main.topscript ∗ all code *)
```
使用下面的语法，`let`也可以用以创建一个作用域仅限于特定表达式的变量：

```ocaml
let <variable> = <expr1> in <expr2>

(* Syntax ∗ variables-and-functions/let_in.syntax ∗ all code *)
```
先求值`<expr1>`，再把`<variable>>`绑定到`<expr1>`的值上来求值`<expr2>`。下面是一个实际应用的例子：

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
这一次，内层作用域中我们用`languages`来代替`language_list`作为字符串列表名，因此隐藏了`languages`的原始定义。但是一但`dashed_languages`执行完，内层作用域就会关闭，`languages`的原始定义就又回来了：

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
注意不要把一系列`let`绑定和修改可变变量混淆。例如，如果故意写点混淆代码，考虑一下`area_of_ring`会如何工作：

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
这里,我们在`area_of_ring`之后又把`pi`重定义成 0。你可能会以为计算结果是 0，但实际上函数的行为没有改变。这是因为原先的`pi`定义没有改变，只是被隐藏了而已，就是说接下来对`pi`的引用才会看到`pi`的新定义 0，先前的引用是不会改变的。但是后面没有对`pi`的引用了，所以把`0.`绑定到`pi`其实没有任何作用。这就解释了为什么 toplevel 会警告我们有未使用的`pi`定义。

在 OCaml中，`let`绑定是不可变的。OCaml 中有许多可变的值，我们会在[第8章命令式编程](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_08_imperative_programming.md)中讨论，但是却没有可变的变量。
> **为什么变量不能变化**
>
> OCaml 初学者的一个困惑就是变量是不可变的。这在语言学上也很奇怪，难道变量不是就可以变化的意思吗?
>
> 答案是，OCaml（通常还有其它函数式编程语言）中的变量更像是方程式中的变量，而非命令式语言中的变量。如果你考虑数学方程式`x(y+z)=xy+xz`，那么变量`x`、`y`和`z`就没有可变的意思。可变的意思是你可以给变量不同的值来实例化这个方程式，但是方程式依然是成立的。
>
> 在函数式语言中也是这样的。一个函数可以作用于不同的输入，因此其变量即使不能改变也会具有不同的值。

#### 模式匹配和`let`
`let`绑定的另一个有用特性是支持在左边使用 **模式**。考虑下面的代码，其中使用了`List.unzip`，这个函数可以将一个序对（pair）列表转变成两个列表的序对：

```ocaml
# let (ints,strings) = List.unzip [(1,"one"); (2,"two"); (3,"three")];;
val ints : int list = [1; 2; 3]
val strings : string list = ["one"; "two"; "three"]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 7) ∗ all code *)
```
其中`(ints,strings)`是一个模式，`let`绑定会赋值模式中出现的标识符。模式本质上是一个数据结构形状的描述，其中有一些组件是需要需要绑定的标识符。在[“元组、列表、option和模式匹配”](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_01_a_guide_tour.md#元组列表option-和模式匹配)一节中我们已经看到了，OCaml 在许多不同数据类型上都有模式。

在`let`绑定中使用模式对于 **确凿的（irrefutable）**模式更有意义，即，此类型的任何值都能保证匹配这个模式。元组和记录模式是确凿的，但列表模式不是。考虑虑下面的代码，其实现了一个函数，将一个逗号分割的列表的第一个元素变成大写：

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
这种情况实际上永远不会发生，因为`String.split`总是会返回一个至少有一个元素的列表。但是编译器不知道这一点，所以它给出了警告。通常，使用`match`语句显式处理这种情况会更好：

```ocaml
# let upcase_first_entry line =
     match String.split ~on:',' line with
     | [] -> assert false (* String.split returns at least one element *)
     | first :: rest -> String.concat ~sep:"," (String.uppercase first :: rest)
  ;;
val upcase_first_entry : string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 9) ∗ all code *)
```
这是我们首次使用`assert`，它在标注不可能出现的情况时很有用。我们会在[第7章错误处理](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_07_error_handling.md)中详细讨论。

### 函数
考虑到 OCaml 是一种函数式语言，也就不奇怪函数是如此重要且如此普遍，我们目前的每个例子中几乎都有函数的身影。这一节我们更进一步，解释 OCaml 中的函数是如何工作的。你会看到，OCaml 中的函数与你在主流语言中见到的函数有很大的不同。

#### 匿名函数
我们从 OCaml 中最基本的函数声明方式开始： *匿名函数*。匿名函数是一个不带名称声明的函数值。它们可以使用`fun`关键字声明，如下所示：

```ocaml
# (fun x -> x + 1);;
- : int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 10) ∗ all code *)
```
匿名函数和命名函数的行为大致相同。如，我们可以把匿名函数应用在一个参数上：

```ocaml
# (fun x -> x + 1) 7;;
- : int = 8

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 11) ∗ all code *)
```
或者将其传递给其它函数。将函数传递给`List.map`这类迭代函数可能是匿名函数最常见的使用场景：

```ocaml
# List.map ~f:(fun x -> x + 1) [1;2;3];;
- : int list = [2; 3; 4]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 12) ∗ all code *)
```
我们甚至可以把它们塞进一个数据结构中：

```ocaml
# let increments = [ (fun x -> x + 1); (fun x -> x + 2) ] ;;
val increments : (int -> int) list = [<fun>; <fun>]
# List.map ~f:(fun g -> g 5) increments;;
- : int list = [6; 7]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 13) ∗ all code *)
```
现在有必要停下来搞清楚这个例子，因为函数的这种高阶用法开始可能显得比较晦涩。首先，`(fun g -> g 5)`是一个函数，它接收一个函数作为参数并将其应用到数字`5`上。调用`List.map`是将`(fun g -> g 5)`函数应用到`increments`列表的每一个元素（也是函数）上，并返回结果构成的新列表。

关键点就是，OCaml 的函数只是普通值，所以你可以用普通值做的事都可以用于函数，如作为函数参数或返回值，以及保存到数据结构中。使用`let`绑定，我们甚至可以像命名其它值一样命名函数：

```ocaml
# let plusone = (fun x -> x + 1);;
val plusone : int -> int = <fun>
# plusone 3;;
- : int = 4

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 14) ∗ all code *)
```
命名函数的定义实在是太常用了，所以提供了一些语法糖。下面`plusone`的定义和上面是等价的：

```ocaml
# let plusone x = x + 1;;
val plusone : int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 15) ∗ all code *)
```
这是声明函数更常用也更方便的方法，不过抛开语法细节不说，这两种定义函数的方式是完全等价的。
> **`let`和`fun`**
>
> 函数和`let`绑定有许多互通性。在某种意义上，你可以把函数参数看成是一个由调用者绑定了输入值的变量。实际上，下面两个表达式几乎是一样的：
> 
> ```ocaml
> # (fun x -> x + 1) 7;;
> - : int = 8
> # let x = 7 in x + 1;;
> - : int = 8
> 
> (* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 16) ∗ all code *)
> ```
> 这种联系很重要，这在单子(monadic)风格编程中更明显，详见[第18章使用Async 并行编程](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_18_concurrent_programming_with_async.md)。

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

这种风格的函数称为 **柯里化（curried）**函数。(Currying是以 Haskell Curry 命名的，一位对编程语言设计和理论都有重大影响的逻辑学家。)解释柯里化函数签名的关键是`->`是右结合的。因此`abs_diff`的类型签名可以像下面这样加上括号：

```ocaml
val abs_diff : int -> (int -> int)

(* OCaml ∗ variables-and-functions/abs_diff.mli ∗ all code *)
```
括号并没有改变签名的含意，但是可以更清楚地看到柯里化。

柯里化也不仅仅是理论玩具。应用柯里化，你可以只提供一部分参数来特化一个函数。下面的例子中，我们创建了一个`abs_diff`的特化版本，来求给定的数到`3`的距离：

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

注意`fun`关键字本身的语法就支持柯里化，所以下面的`abs_diff`定义和上面的是等价的：

```ocaml
# let abs_diff = (fun x y -> abs (x - y));;
val abs_diff : int -> int -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 20) ∗ all code *)
```
你也许会担心调用柯里化函数会有严重的性能问题，但完全没有这个必要。在 OCaml 中，以完整参数调用一个柯里化的函数没有任何额外开销。（当然，偏特化函数会产生一点点额外的开销。）

柯里化不是 OCaml 中写多参数函数的唯一方法。使用元组不同字段作为不同参数也是可以的。所以我们可以这样写：

```ocaml
# let abs_diff (x,y) = abs (x - y);;
val abs_diff : int * int -> int = <fun>
# abs_diff (3,4);;
- : int = 1

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 21) ∗ all code *)
```
OCaml处理这种调用约定也非常高效。特别是，通常都不必为了传递元组形式的参数而分配一个元组。当然，这时你就不能使用偏特化应用了。

这两种方法差异很小，但是大多数时候你都应该使用柯里化形式，因为它是 OCaml 中默认的风格。

#### 递归函数
定义中又调用了自己的函数就是*递归*的。递归在任何编程语言中都很重要，但对函数式语言尤为如此，因为递归是函数式语言实现循环结构的手段。（[第8章命令式编程](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_08_imperative_programming.md)中我们会详细介绍，OCaml 也支持像`for`和`while`这样的命令式循环结构，但是它们只在使用 OCaml 的命令式编程特性时才有用。）

要定义递归函数，你需要使用`rec`关键字将`let`绑定标记成递归的，下面是一个例子，是一个查找列表第一个重复元素序列的函数：

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
模式`[] | [_]`是一个 *或模式*，是两个模式的组合，只要任何一个模式匹配即可。这里`[]`匹配空列表，`[_]`匹配只有一个元素的列表。使用`_`我们就不用为这个单独的元素指定显式名称了。

使用`let rec`和`and`配合我们也能定义多个交互递归的值。下面是一个（天生低效的）例子：

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
OCaml 需要区分非递归定义（用`let`）和递归定义（用`let rec`）主要是技术原因：类型推导算法需要知道何时一组函数定义是交互递归的，并且出于一些像 Haskell 这样的纯函数式语言中没有原因，这需要程序员自己显式标注。
> 到底是啥原因呢?:( Lisp 也不纯啊！ by clark。

但这个决策也有一些好处。一个原因是，递归（特别是交互递归）定义比非递归更难推理。所以如果在没有显式`rec`的地方，你就可以认为这个`let`绑定一定只能是基于之前的绑定，这一点是有意义的。

另外，有一个单独的非递归形式也使得通过遮蔽来创建一个新的定义以替代一个已存在的定义更为容易。

#### 前缀和中缀操作符
目前，在例子中前缀和中缀形式的函数我们都用过了：

```ocaml
# Int.max 3 4  (* prefix *);;
- : int = 4
# 3 + 4        (* infix  *);;
- : int = 7

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 24) ∗ all code *)
```
你也许会认为第二个例子不是一个普通函数，但它还真的是。像`+`这样的中缀操作符仅仅在语法上和其它函数有点不同。实际上，如果给中缀操作符加上括号，就可以像普通前缀函数一样使用了：

```ocaml
# (+) 3 4;;
- : int = 7
# List.map ~f:((+) 3) [4;5;6];;
- : int list = [7; 8; 9]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 25) ∗ all code *)
```
第二个表达式中，我们通用偏特化`(+)`创建了一个将参数加3的函数。

如果函数名是下面的标识符，就会被当成操作符，也包括完全由多个下面字符组成的标识符：

```ocaml
! $ % & * + - . / : < = > ? @ ^ | ~

(* Syntax ∗ variables-and-functions/operators.syntax ∗ all code *)
```
还有几个预先确定的字符串也是操作符，包括`mod`，取模操作符，和`lsl`，表示“逻辑左移（logical shift left）”，一个位移操作符。

我们可以定义（或重定义）一个操作符的含义。下面例子中是一个作用于`int`序对的向量加法操作符：

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
上面的错误是因为`(***)`没有被解析成操作符，而是被看成了注释！要正确工作，我们需要在`*`前面或后面加上括号：

```ocaml
# let ( *** ) x y = (x ** y) ** y;;
val ( *** ) : float -> float -> float = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 28) ∗ all code *)
```
操作符的语法角色主要是前一到两个字符决定的，鲜有例外。下表将不同的操作符和其它语法形式按优先级从高到低分组，并分别解释了其语法行为。我们用`!...`来表示以`!`开头的这类操作符。

| Prefix                                           |Usage |
| ------------------------------------------------ | ---- |
|`!..., ?..., ~...` 	                           |前缀  |
|`., .(, .[`                                       |   -   |
|`function application, constructor, assert, lazy` |左结合|
|`-, -.` 	                                       |前缀  |
|`**..., lsl, lsr, asr` 	                       |右结合|
|`*..., /..., %..., mod, land, lor, lxor` 	       |左结合|
|`+..., -...` 	                                       |左结合|
|`::` 	                                           |右结合|
|`@..., ^...` 	                                   |右结合|
|`=..., <..., >...,` &#124;..., `&..., $...` 	   |左结合|
|`&, &&` 	                                       |右结合|
|`or`, &#124;&#124;                                |右结合|
|`,` 	                                           | -     |
|`<-, :=` 	                                       |右结合|
|`if` 	                                           | -     |
|`;` 	                                           |右结合|

有一个很重要的特殊情况：`-`和`-.`，整数和浮点数减法运算符，可以即当前缀操作符（负数）也当中缀操作符（减法），因此`-x`和`x - y`都是正确的表达式。还有一点要注意的就是负数操作的优先比函数调用低，就是说你需要括号来传递一个负数，如下所示:

```ocaml
# Int.max 3 (-4);;
- : int = 3
# Int.max 3 -4;;
Characters -1-9:
Error: This expression has type int -> int but an expression was expected of type int

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 29) ∗ all code *)
```
这里，OCaml 会把第二个表达式解释成：

```ocaml
# (Int.max 3) - 4;;
Characters 1-10:
Error: This expression has type int -> int but an expression was expected of type int

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 30) ∗ all code *)
```
这显然是错误的。

下面的例子中是一个非常有用的操作符，来自标准库，其行为严格依赖上面提到的优先级规则：

```ocaml
# let (|>) x f = f x ;;
val ( |> ) : 'a -> ('a -> 'b) -> 'b = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 31) ∗ all code *)
```
乍一看其作用并不明显：它只是接收一个值和一个函数，然后把函数应用到值上。尽管这个描述听起来平淡无奇，它却在顺序操作时扮演重要角色，这和 UNIX 管道神似。例如，考虑下面的代码，可以无重复地打印出你`PATH`中的元素。下面的`List.dedup`通过使用给定的比较函数排序来从一个列表中消除重复：

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
注意我们不用`|>`也能做到这一点，但是会有一些冗长：

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
这里有一个很重要的方面就是偏特化应用。如，`List.iter`正常会接收两个参数：一个是对列表的每一个元素都调用的函数，还有一个用以迭代的列表。我们可以用完整的参数调用`List.iter`：

```ocaml
# List.iter ~f:print_endline ["Two"; "lines"];;

Two
lines
- : unit = ()

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 34) ∗ all code *)
```
或者。我们可以只传给它函数参数，这样就会得到一个打印字符串列表的函数：

```ocaml
# List.iter ~f:print_endline;;
- : string list -> unit = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 35) ∗ all code *)
```
后面这个形式就是我们在上面`|>`管道中使用的。

注意`|>`能以预定的方式工作，因为它是左结合的。让我们看看如果使用右结合操作符会发生什么，比如`(^>)`：

```ocaml
# let (^>) x f = f x;;
val ( ^> ) : 'a -> ('a -> 'b) -> 'b = <fun>
# Sys.getenv_exn "PATH"
  ^> String.split ~on:':' path
  ^> List.dedup ~compare:String.compare
  ^> List.iter ~f:print_endline
  ;;
Characters 98-124:
Error: This expression has type string list -> unit
       but an expression was expected of type
         (string list -> string list) -> 'a
       Type string list is not compatible with type
         string list -> string list 

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 36) ∗ all code *)
```
上面的类型错误乍一看挺迷惑人的。 事情是这样的，由于`^>`是右结合的，所以会试图把`List.dedup ~compare:String.compare`传给`List.iter ~f:print_endline`。但是`List.iter ~f:print_endline`需要一个字符串列表作为输入，而不是一个函数。

除了类型错误，这个例子还强调了小心选择操作符的重要性，特别是结合性方面。

#### 使用`function`声明函数
定义函数还有一个方法就是使用`function`关键字。和支持声明多参数（柯里化的）函数语法不同，`function`内建了模式匹配。例如：

```ocaml
# let some_or_zero = function
     | Some x -> x
     | None -> 0
  ;;
val some_or_zero : int option -> int = <fun>
# List.map ~f:some_or_zero [Some 3; None; Some 4];;
- : int list = [3; 0; 4]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 37) ∗ all code *)
```
这和使用`match`定义的普通函数是等价的：

```ocaml
# let some_or_zero num_opt =
    match num_opt with
    | Some x -> x
    | None -> 0
  ;;
val some_or_zero : int option -> int = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 38) ∗ all code *)
```
我们也可以把不同的函数声明风格组合在一起，下面的例子中，我们声明了一个有两个参数（柯里化）的函数，第二个参数使用模式匹配：

```ocaml
# let some_or_default default = function
     | Some x -> x
     | None -> default
  ;;
val some_or_default : 'a -> 'a option -> 'a = <fun>
# some_or_default 3 (Some 5);;
- : int = 5
# List.map ~f:(some_or_default 100) [Some 3; None; Some 4];;
- : int list = [3; 100; 4]

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 39) ∗ all code *)
```
再一次注意使用偏特化创建了一个函数传给`List.map`这种用法。换句话说，`some_or_default 100`是通过只给`some_or_default`第一个参数来创建的函数。

#### 标签参数
到目前为止，我们定义的函数都是通过位置，即，参数传给函数的顺序，来区分参数的。OCaml 也支持标签参数，允许你可以使用名称来标识参数。实际上，我们已经碰到过 Core 中一些使用标签参数的函数，如`List.map`。标签参数用一个波浪号前缀标注，并在需要标签的变量前使用一个标签（后面跟着一个分号）。下面是一个例子：

```ocaml
# let ratio ~num ~denom = float num /. float denom;;
val ratio : num:int -> denom:int -> float = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 40) ∗ all code *)
```
我们可以使用类似的约定提供一个标签化的实参，如你所见，这些参数顺序可以是任意的：

```ocaml
# ratio ~num:3 ~denom:10;;
- : float = 0.3
# ratio ~denom:10 ~num:3;;
- : float = 0.3

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 41) ∗ all code *)
```
OCaml 也支持 *标签双关（label punning）*，如果标签和和变量名同名，那么你就可以不用`:`及后面的部分了。实际上，上面在定义`ratio`时我们已经使用了标签双关。下面展示了如何在函数调用中使用双关：

```ocaml
# let num = 3 in
let denom = 4 in
ratio ~num ~denom;;
- : float = 0.75

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 42) ∗ all code *)
```
标签参数在几种不同场景下有用：

- 定义一个有许多参数的函数时。超出一定数量后，按名称记参数比按位置更容易。
- 一个特定的参数只看类型意义不明确时。考虑一个创建哈希表的函数，其第一个参数是底层数组的初始大小，第二参数是一个布尔标志，表明当移除元素时数组是否会收缩：

  ```ocaml
  val create_hashtable : int -> bool -> ('a,'b) Hashtable.t

  (* OCaml ∗ variables-and-functions/htable_sig1.ml ∗ all code *)
  ```
  用上面的签名难以预测这两个参数的含义，但如果使用标签参数，立刻就清楚了：
  
  ```ocaml
  val create_hashtable :
    init_size:int -> allow_shrinking:bool -> ('a,'b) Hashtable.t
  
  (* OCaml ∗ variables-and-functions/htable_sig2.ml ∗ all code *)
  ```
  给布尔值选一个合适的标签名尤为重要，因为当值为真时到底是打开还是禁止一个特性经常会引起混淆。
- 函数有多个可能互相混淆的参数时。通常都是在这些参数类型相同时才可能有这样的问题。例如，考虑这个提取子字符串的函数：

  ```ocaml
  val substring: string -> int -> int -> string
  
  (* OCaml ∗ variables-and-functions/substring_sig1.ml ∗ all code *)
  ```
  这里的两个`int`分别是要提取的子串的开始位置和长度。我们可以使用标签来使签名更明确：
  
  ```ocaml
  val substring: string -> pos:int -> len:int -> string
  
  (* OCaml ∗ variables-and-functions/substring_sig2.ml ∗ all code *)
  ```
  这使得函数签名和使用`substring`的客户代码都更易读，并且不容易无意间弄反位置和长度。
- 当你需要函数参数传入时位置灵活时。考虑`List.iter`这样的函数，接收两个参数：一个函数，还有一个列表，在列表的每一个元素上调用该函数。一个常见的模式中只用一个函数参数来偏特化`List.iter`，就和下面这个本章之前的例子一样：

  ```ocaml
  #   String.split ~on:':' path
    |> List.dedup ~compare:String.compare
    |> List.iter ~f:print_endline
    ;;
  
  /bin
  /sbin
  /usr/bin
  /usr/local/bin
  - : unit = ()
  
  (* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 43) ∗ all code *)
  ```
  这就要求我们把函数参数放在首位。在其它情况下，通常是为了代码更可读，你又想把函数参数放在后面。特别是，把一个多行函数作为参数传给另一个函数时，把它放在最后可读性是最好的。

##### 高阶函数和标签
关于标签参数，有一点会出乎你的意料，就是尽管调用使用标签参数的函数时参数顺序没有影响，但是在高阶上下文中顺序却是有影响的，如，当把一个使用标签参数的函数传给另一个函数时。下面是一个例子：

```ocaml
# let apply_to_tuple f (first,second) = f ~first ~second;;
val apply_to_tuple : (first:'a -> second:'b -> 'c) -> 'a * 'b -> 'c = <fun>
(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 44) ∗ all code *)
```
这里`apply_to_tuple`的定义期待其第一个参数是一个有标签参数的函数，`first`和`second`，并且就是按这个顺序的。我们还可以另定义`apply_to_tuple`以改变标签参数的顺序：

```ocaml
# let apply_to_tuple_2 f (first,second) = f ~second ~first;;
val apply_to_tuple_2 : (second:'a -> first:'b -> 'c) -> 'b * 'a -> 'c = <fun>
(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 45) ∗ all code *)
```
这说明顺序是有影响的。特别是，如果我们定义一个不同顺序的函数：

```ocaml
# let divide ~first ~second = first / second;;
val divide : first:int -> second:int -> int = <fun>
(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 46) ∗ all code *)
```
就会发现我们不能将其传给`apply_to_tuple_2`。

```ocaml
# apply_to_tuple_2 divide (3,4);;
Characters 17-23:
Error: This expression has type first:int -> second:int -> int
       but an expression was expected of type second:'a -> first:'b -> 'c
(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 47) ∗ all code *)
```
但是它和之前的`apply_to_tuple`一起用却没有问题：

```ocaml
# let apply_to_tuple f (first,second) = f ~first ~second;;
val apply_to_tuple : (first:'a -> second:'b -> 'c) -> 'a * 'b -> 'c = <fun>
# apply_to_tuple divide (3,4);;
- : int = 0
(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 48) ∗ all code *)
```
结论就是，当作为参数传递一个标签化的函数时，你需要注意保持标签参数顺序的一致性。

#### 可选参数
可选参数就像一个调用者可提供也可不提供的标签参数。可选参数使用和标签参数一样的语法进行传递，并且，和标签参数一样，顺序可任意。

下面的例子是一个字符串拼接函数，使用了一个可选的分隔符。此函数使用`^`操作符拼接一对字符串：

```ocaml
# let concat ?sep x y =
     let sep = match sep with None -> "" | Some x -> x in
     x ^ sep ^ y
  ;;
val concat : ?sep:string -> string -> string -> string = <fun>
# concat "foo" "bar"             (* without the optional argument *);;
- : string = "foobar"
# concat ~sep:":" "foo" "bar"    (* with the optional argument    *);;
- : string = "foo:bar"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 49) ∗ all code *)
```
这里，在函数定义中使用`?`来把`sep`标记成可选的。调用者可以给`sep`传递一个``string`型的值，在函数内部，`sep`被看成一个`string option`，当调用者没有提供`sep`时值为`None`。

上在的例子中，当什么都没有提供时，还需要一些代码来选择默认分隔符。这种情况足够通用，以致于有一种专门提供默认值的语法，使我们可以把代码写得更简捷：

```ocaml
# let concat ?(sep="") x y = x ^ sep ^ y ;;
val concat : ?sep:string -> string -> string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 50) ∗ all code *)
```
可选参数非常有用，但也容易被滥用。可选参数的优点在于允许你写出有多个参数的函数，而这些参数使用者大数时候可以忽略，只在特别需要使用这些选项时才会去关心它们。它们也允许你可以在无需改变已有代码的情况下扩展一个 API。

缺点是调用者可能意识不到还有另外的选择，所以可能不知不觉地（并且是错误地）使用默认行为。只有在省略参数带来的简捷性大于明确性相关的损失时，可选参数才有意义。

这意味着极少用到的函数不应该使用可选参数。一个好的经验法则是避免在模块内部函数（即没有包含在模块接口或 mli 文件中的函数）中使用可选参数。我们会在[第4章文件、模块和程序](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_04_files_modules_and_programs.md)中学习 mli 文件。

##### 显式传递一个可选参数
在后台，当调用者没有提供此参数时，一个使用可选参数的函数会接收到一个`None`，否则会接收到`Some`。但是`Some`和`None`都不是调用者显式传递的。

但有时候你确实想传递`Some`或`None`。OCaml 允许你这样做，只要使用`?`代替`~`来标注参数即可。因此，下面两种给`concat`传递`sep`参数的方法是等价的：

```ocaml
# concat ~sep:":" "foo" "bar" (* provide the optional argument *);;
- : string = "foo:bar"
# concat ?sep:(Some ":") "foo" "bar" (* pass an explicit [Some] *);;
- : string = "foo:bar"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 51) ∗ all code *)
```
下面两种不指定`sep`调用`concat`的方法也是等价的：

```ocaml
# concat "foo" "bar" (* don't provide the optional argument *);;
- : string = "foobar"
# concat ?sep:None "foo" "bar" (* explicitly pass `None` *);;
- : string = "foobar"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 52) ∗ all code *)
```
这种方式的一个使用场景是，你要定义一个包装函数，这个函数需要模拟被包装的函数的可选参数。例如，想象一下我们要创建一个名为`uppercase_concat`的函数，它和`concat`功能一样只是把第一个字符串变成大写字母。我们可以像这样写：

```ocaml
# let uppercase_concat ?(sep="") a b = concat ~sep (String.uppercase a) b ;;
val uppercase_concat : ?sep:string -> string -> string -> string = <fun>
# uppercase_concat "foo" "bar";;
- : string = "FOObar"
# uppercase_concat "foo" "bar" ~sep:":";;
- : string = "FOO:bar"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 53) ∗ all code *)
```
按这种写法，我们又强制指定了默认分隔。所以，之后再改变`concat`默认值的时候，需要记着同时修改`uppercase_concat`来与之匹配。

实际上，我们可以使用`?`语法直接把`uppercase_concat`的可选参数传给`concat`：

```ocaml
# let uppercase_concat ?sep a b = concat ?sep (String.uppercase a) b ;;
val uppercase_concat : ?sep:string -> string -> string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 54) ∗ all code *)
```
现在，如果有人不指定`sep`调用`uppercase_concat`时，这时显式的`None`会传递给`concat`，从而由`concat`来决定默认值。

##### 标签参数和可选参数的类型推导
关于标签和可选参数有一个微妙的方面就是类型系统是如何推导它们的。考虑下面这个例子，用以计算一个有两个实数参数的函数的数值导数。它接收一个`delta`参数来确定计算导数的窗口大小，值`x`和`y`用以给出计算导数的点，还有一个要计算导数的函数`f`。函数`f`本身接收两个标签参数`x`和`y`。注意你可以在变量名中使用撇号，所以`x'`和`y'`只是普通变量：

```ocaml
# let numeric_deriv ~delta ~x ~y ~f =
    let x' = x +. delta in
    let y' = y +. delta in
    let base = f ~x ~y in
    let dx = (f ~x:x' ~y -. base) /. delta in
    let dy = (f ~x ~y:y' -. base) /. delta in
    (dx,dy)
  ;;
val numeric_deriv : delta:float -> x:float -> y:float -> f:(x:float -> y:float -> float) -> float * float = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 55) ∗ all code *)
```
理论上，应该如何选择`f`的函数顺序并不明显。因为标签参数可以以任意顺序传递，看起来其类型除了可以是`x:float -> y:float -> float`，也可以是`y:float -> x:float -> float`。

更糟的是，如果`f`有可选参数而非标签参数也可以保持完美的一致，这可以使`numeric_deriv`的类型签名变成下面这样：

```ocaml
val numeric_deriv :
  delta:float ->
  x:float -> y:float -> f:(?x:float -> y:float -> float) -> float * float

(* OCaml ∗ variables-and-functions/numerical_deriv_alt_sig.mli ∗ all code *)
```
由于存在多种可能，OCaml 需要一些启示来做选择。编译器使用的启示是：标签参数比可选参数优先，参数顺序遵从源代码中出现的顺序。

注意这些启发方法在源代码的不同位置可能会建议不同的类型。下面这个版本的`numeric_deriv`，以不同的参数顺序调用`f`：

```ocaml
# let numeric_deriv ~delta ~x ~y ~f =
    let x' = x +. delta in
    let y' = y +. delta in
    let base = f ~x ~y in
    let dx = (f ~y ~x:x' -. base) /. delta in
    let dy = (f ~x ~y:y' -. base) /. delta in
    (dx,dy)
  ;;
Characters 130-131:
Error: This function is applied to arguments in an order different from other calls. This is only allowed when the real type is known.

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 56) ∗ all code *)
```
就像错误信息中提示的那样，我们可以提供明确的类型信息，以使OCaml 可以接受`f`以不同的参数顺序调用。因此，下面的代码会编译无误，因为给出了`f`的类型注解：

```ocaml
# let numeric_deriv ~delta ~x ~y ~(f: x:float -> y:float -> float) =
    let x' = x +. delta in
    let y' = y +. delta in
    let base = f ~x ~y in
    let dx = (f ~y ~x:x' -. base) /. delta in
    let dy = (f ~x ~y:y' -. base) /. delta in
    (dx,dy)
  ;;
val numeric_deriv : delta:float -> x:float -> y:float -> f:(x:float -> y:float -> float) -> float * float = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 57) ∗ all code *)
```
##### 可选参数和偏特化
可选参数在遇上偏特化应用时比较麻烦。我当然可以只提供可选参数来做偏特化：

```ocaml
# let colon_concat = concat ~sep:":";;
val colon_concat : string -> string -> string = <fun>
# colon_concat "a" "b";;
- : string = "a:b"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 58) ∗ all code *)
```
但当我们只提供第一个参数时会发生什么呢？

```ocaml
# let prepend_pound = concat "# ";;
val prepend_pound : string -> string = <fun>
# prepend_pound "a BASH comment";;
- : string = "# a BASH comment"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 59) ∗ all code *)
```
可选参数`?sep`现在已经消失了，或者说是被 *消除（erased）*了。实际上，现在你再试图传递一个可选参数会被拒绝：

```ocaml
# prepend_pound "a BASH comment" ~sep:":";;
Characters -1-13:
Error: This function has type string -> string
       It is applied to too many arguments; maybe you forgot a `;'.

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 60) ∗ all code *)
```
那么 OCaml 什么时候会去掉一个可选参数呢？

规则是：一旦可选参数*后面*的第一个位置参数（就是除标签和可选参数以外的参数）传入，这个可选参数就被消除了。这就解释了上面`prepend_pound`的行为。但是如果我们把可选参数作为`concat`的第二个参数：

```ocaml
# let concat x ?(sep="") y = x ^ sep ^ y ;;
val concat : string -> ?sep:string -> string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 61) ∗ all code *)
```
那么第一个参数的偏特化应用就不会导致可选参数被消除了：

```ocaml
# let prepend_pound = concat "# ";;
val prepend_pound : ?sep:string -> string -> string = <fun>
# prepend_pound "a BASH comment";;
- : string = "# a BASH comment"
# prepend_pound "a BASH comment" ~sep:"--- ";;
- : string = "# --- a BASH comment"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 62) ∗ all code *)
```
然而，如果所有的参数都一次给定，那么在所有参数都传入之后才会消除可选参数。这就为我们保留了可以在任何位置传入可选参数的能力。因此，我们才可以这样写：

```ocaml
# concat "a" "b" ~sep:"=";;
- : string = "a=b"

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 63) ∗ all code *)
```
后面没有任何位置参数的可选参数是无法消除的，这时编译器会给出警告：

```ocaml
# let concat x y ?(sep="") = x ^ sep ^ y ;;
Characters 15-38:
Warning 16: this optional argument cannot be erased.val concat : string -> string -> ?sep:string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 64) ∗ all code *)
```
实际上，当我们只提供两个位置参数时，`sep`参数并没有被消除，所以会返回一个参数为`sep`的函数：

```ocaml
# concat "a" "b";;
- : ?sep:string -> string = <fun>

(* OCaml Utop ∗ variables-and-functions/main.topscript , continued (part 65) ∗ all code *)
```
可以看到，OCaml 中的标签参数和可选参数并不是没有复杂性代价的。但不要让这些复杂性掩盖了这些特性的实用性。标签参数和可选参数是非常有效的工具，可以让你的 API 更方便使用并且更安全，付出努力学习有效使用它们是非常值得的。
