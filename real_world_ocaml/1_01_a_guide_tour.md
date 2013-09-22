# I. 语言概念

## 第一章 导览
本章通过一系列覆盖了大部分主要语言特性的小例子给出了OCaml的概观。这提供了OCaml语言能做什么的直观印象，但对每一个话题都不深入讨论。

贯穿本书会一直使用Core，一个全功能的OCaml标准库的兼容替代。我们也会使用 **utop**，一个shell，允许你键入表达式并交互式求值。 **utop**是OCaml标准顶层（toplevel，你可以从命令行输入`ocaml`启动）的一个更易用的版本。这些教程会特别假设你使用 **utop**。

开始之前，确保你完成了OCaml的安装，这样就可以试验读到的例子。查看[附录A（安装）](#附录A)以获得更多细节。

### OCaml作为计算器
使用Core要做的第一件事就是打开`Core.Std`。
```ocaml
# open Core.Std;;

(* OCaml Utop * guided-tour/main.topscript * all code *)
```
这使得Core中的定义可以使用，在本书的大部分例子中都需要。

现在我们可以尝试一些简单的数值运算。
```ocaml
# 3 + 4;;
- : int = 7
# 8 / 3;;
- : int = 2
# 3.5 +. 6.;;
- : float = 9.5
# 30_000_000 / 300_000;;
- : int = 100
# sqrt 9.;;
- : float = 3.

(* OCaml Utop * guided-tour/main.topscript , continued (part 1) * all code *)
```
总的来说，这和其它编程语言很相似，但还是有几件事要注意。

- 我们需要键入`;;`以告诉tolevel它应该求值一个表达式。这是toplevel独有的，在独立的程序中并不需要（尽管有时包含`;;`会使顶层声明的结束更明显，从而改善OCaml的错误报告）。
- 对表达式求值之后，toplevel先打印出结果，然后是结果的类型。
- 函数参数以空格分隔而不是括号和逗号，这更像UNIX的shell而不是C或Java这样的传统语言。
- OCaml允许你在数字字面值中间加下划线来增加可读性。注意下划线可以放在数字的任何位置，而不限于每三个数字一组。
- OCaml严格区分`float`（浮点数类型）和`int`（整数类型）。不同类型的字面值不同（`6.`和`6`），中缀操作符也不同（`+.`和`+`），而且OCaml不会在这些类型之间自动转换。这可能有点麻烦，但是也有其好处，因为可以阻止其它语言因为`int`和`float`行为不同而引发的bug。比如，在许多语言中`1 / 3`等于`0`，而`1 / 3.0`却等于三分之一。OCaml要求你必须明确要执行什么操作。

我们也可以使用`let`关键字创建一个变量来命名给定表达式的值。这就是`let`绑定。
```ocaml
# let x = 3 + 4;;
val x : int = 7
# let y = x + x;;
val y : int = 14

(* OCaml Utop * guided-tour/main.topscript , continued (part 2) * all code *)
```
创建新的变量后，除了变量类型（`int`）和值（`7`或`14`），toplevel还告诉我们变量名（`x`或`y`）。

注意能用在变量名里的标识符是有限制的。标点符号只允许使用`_`和`'`，并且变量名只能以小写字母或下划线开头。因此，下面的变量名都是合法的：
```ocaml
# let x7 = 3 + 4;;
val x7 : int = 7
# let x_plus_y = x + y;;
val x_plus_y : int = 21
# let x' = x + 1;;
val x' : int = 8
# let _x' = x' + x';;
 
# _x';;
- : int = 16
(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 3) ∗ all code *)
```
注意默认情况下， **utop**不会打印下划线开头的变量。
  
下面的例子是不合法的。
```ocaml
# let Seven = 3 + 4;;
Characters 4-9:
Error: Unbound constructor Seven
# let 7x = 7;;
Characters 5-10:
Error: This expression should not be a function, the expected type is
int
# let x-plus-y = x + y;;

Characters 4-5:
Error: Parse error: [fun_binding] expected after [ipatt] (in [let_binding]) 

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 4) ∗ all code *)
```
错误信息有点诡异，但当你对OCaml了解更多时就会明白了。

### 函数和类型推导
`let`语法也可以用以定义函数。
```ocaml
# let square x = x * x ;;
val square : int -> int = <fun>
# square 2;;
- : int = 4
# square (square 2);;
- : int = 16

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 5) ∗ all code *)
```
OCaml中的函数和其它值是一样的，这就是为什么我们使用`let`关键字来把函数绑定到一个变量名，就和绑定一个整数这样的简单值到变量名一样。当使用`let`定义函数时，`let`后的第一个标识符是函数名，后面跟着参数列表。综上所述，上面的`square`就是一个只有一个参数的函数。

现在我们创建了如函数这样更有趣的值，其类型也变得更有趣。`int -> int`是一个函数类型，表示一个接收一个`int`型参数并返回`int`型结果的参数。我们也可以写出接收多个参数的函数。（注意下面的例子只有打开`Core.Std`时才能工作。）
```ocaml
# let ratio x y =
     Float.of_int x /. Float.of_int y
  ;;
val ratio : int -> int -> float = <fun>
# ratio 4 7;;
- : float = 0.571428571429

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 6) ∗ all code *)
```
上面恰好也是我们第一次使用模块。这里，`Float.of_int`引用了`Float`模块中的`of_int`函数。这与你在面向对象语言中的经验不同，在那里点号通常被用来访问对象的方法。注意模块名必须以大写字母开头。

多参数函数类型签名的记法开始看着会有点不适应，这一点我们在[“多参数函数”一节](#多参数函数)讲函数柯里化时会解释。现在只要记住，箭头作为函数参数的分隔符，最后一个箭头后面跟着返回值类型。因此，`int -> int -> float`描述了一个接收两个`int`参数返回一个`float`的函数。

函数也可以以其它函数作为参数。下面的例子是一个接收3个参数的函数：一个测试函数和两个整数参数。这个函数返回可以通过测试函数的两个整数参数之和。
```ocaml
# let sum_if_true test first second =
    (if test first then first else 0)
    + (if test second then second else 0)
  ;;
val sum_if_true : (int -> bool) -> int -> int -> int = <fun>

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 7) ∗ all code *)
```
仔细观察推导出的类型签名，我们会看到第一个参数是一个函数，它接收一个整数参数并返回一个布尔值，剩下的两个参数是整型的。下面是如何使用该函数的例子。
```ocaml
# let even x =
    x mod 2 = 0 ;;
val even : int -> bool = <fun>
# sum_if_true even 3 4;;
- : int = 4
# sum_if_true even 2 4;;
- : int = 6

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 8) ∗ all code *)
```
注意在`even`的定义中，`=`有两种不同的使用方式：一是在`let`绑定中分隔内容和其定义;一是在相等测试中，用于比较`x mod 2`和`0`。尽管形式一样，但却是非常不同的操作。

#### 类型推导
当类型越来越复杂时，你可能会问OCaml在是如何在我们没有给出显式类型信息的情况推导出类型的。

OCaml使用一种叫作类型推导的技术来确定表达式的类型，使用这种技术，可以从变量类型以及在表达式结构中隐含的约束中推导出表达式的类型。

作为例子，我们过一遍推导`sum_if_true`的类型的过程。
- OCaml要求`if`语句的两个分支有相同的类型，所以表达式`if test first then first else 0`要求`first`必须和`0`类型相同，所以`first`必须是`int`型。同样从`if test second then second else 0`我们也能推导出`second`是`int`型的。
- `test`以`first`为参数。因为`first`是`int`型的，所以`test`的输入也必须是`int`型的。
- `test first`被用做`if`语句的条件，所以`test`的返回值必须是`bool`型的。
- `+`返回`int`意味着`sum_if_true`的返回值必须是`int`。

综上所述，就确定了所有变量的类型，这也确定了`sum_if_true`的整体类型。

随着时间推移，你会建立一个关于OCaml类型推导引擎工作原理的粗略直觉，这有助于使你的程序保持合理。你可以通过添加显式的类型标注来使表达式类型更易理解。这些类型标注不会影响OCaml程序的行为，但它们可以作为很好的文档，同时也能检查到无意的类型改变。它们也有助于指出为什么一段代码不能通过编译。

这是带类型标注版本的`sum_if_true`：
```ocaml
# let sum_if_true (test : int -> bool) (x : int) (y : int) : int =
     (if test x then x else 0)
     + (if test y then y else 0)
  ;;
val sum_if_true : (int -> bool) -> int -> int -> int = <fun>

(* OCaml Utop * guided-tour/main.topscript , continued (part 9) * all code *)
```
上面，我们用其类型标注了函数的每个参数，最后还指出了返回值类型。这样的标注可以用在OCaml程序的任何表达式上。

#### 泛型类型推导
有时没有足够的信息来完全推导出一个值的具体类型。看下面这个函数。
```ocaml
# let first_if_true test x y =
    if test x then x else y
  ;;
val first_if_true : ('a -> bool) -> 'a -> 'a -> 'a = <fun>

(* OCaml Utop * guided-tour/main.topscript , continued (part 10) * all code *)
```
`first_if_true`以一个`test`函数和`x`、`y`两个值作为参数，如果`test x`为真则返回`x`，否则返回`y`。那么`first_if_true`是什么类型呢？没有像算术运算符或字面值这样明显的线索可以告诉你`x`和`y`的类型。这使得`first_if_true`似乎可以用在任何类型的值上。

事实上，如果查看toplevel返回的类型，我们就会看到OCaml没有选择一个单独的具体类型，而是引入了一个类型变量`'a`来表示此类型是一个泛型。（你可以把单引号开头的都称为类型变量。）特别是`test`参数的类型是`('a -> bool)`，表示`test`是一个单参数函数，返回值是`bool`型，参数可以任何类型`'a`。但是，无论`'a`是什么类型,都要和其它两个参数以及`first_if_true`返回值类型相同。这种泛化叫作参数多态，和C#以及Java中的泛型很相似。

`first_if_true`的泛型类型允许我们写出这样的代码：
```ocaml
# let long_string s = String.length s > 6;;
val long_string : string -> bool = <fun>
# first_if_true long_string "short" "loooooong";;
- : string = "loooooong"

(* OCaml Utop * guided-tour/main.topscript , continued (part 11) * all code *)
```
也可以这样：
```ocaml
# let big_number x = x > 3;;
val big_number : int -> bool = <fun>
# first_if_true big_number 4 3;;
- : int = 4

(* OCaml Utop * guided-tour/main.topscript , continued (part 12) * all code *)
```
`long_string`和`big_number`都是函数，都可以和其它两个类型一致的参数一起传给`first_if_true`（第一个例子中是字符串，第二个例子中是整数）。但同一次`fist_if_true`调用中我们不能混合使用不同具体类型的'a。
```ocaml
# first_if_true big_number "short" "loooooong";;
Characters 25-32:
Error: This expression has type string but an expression was expected of type int

(* OCaml Utop * guided-tour/main.topscript , continued (part 13) * all code *)
```
上面的例子中`big_number`需要把`'a`实例化为`int`，但是"short"和"loooooong"却要将`'a`实例化为`string`，这不可能同时成立。

> **类型错误**
>
> OCaml（实际上是任何编译型语言）中编译期和运行时捕获的错误是非常不同的。开发过程中越早捕获错误越好，编译期是最好的。
>
> 在toplevel上工作有时编译期错误和运行时错误之间的差异并不明显，但依然存在，通常，下面这样的类型错误是编译期错误（因为`+`要求其两个参数都是`int`型），
> ```ocaml
> # let add_potato x =
>      x + "potato";;
> Characters 28-36:
> Error: This expression has type string but an expression was expected of type int
> 
> (* OCaml Utop * guided-tour/main.topscript , continued (part 14) * all code *)
> ```
> 反之那些不能被类型系统捕获的错误，如除0错误，会引发运行时异常。
> ```ocaml
> # let is_a_multiple x y =
>      x mod y = 0 ;;
> val is_a_multiple : int -> int -> bool = <fun>
> # is_a_multiple 8 2;;
> - : bool = true
> # is_a_multiple 8 0;;
> Exception: Division_by_zero.
> 
> (* OCaml Utop ∗ guided-tour/main.topscript , continued (part 15) ∗ all code *)
> ```
> 这里的区别就是类型错误无论你是否运行那会阻止出错的代码。仅定义`add_potato`就会出错，而`is_a_multiple`只有在被调用且输入触发异常时才会失败。

### 元组，列表，option和模式匹配
#### 元组
目前为止我们已经见过了几个基本类型，如`int`、`float`和`string`，还有函数类型，如`string -> int`。但是还没有讨论数据结构。我们从一个特别简单的数据结构--元组开始。元组是值的有序集合，值的类型可以不同。你可以用逗号把值拼接起来创建元组。
```ocaml
# let a_tuple = (3,"three");;
val a_tuple : int * string = (3, "three")
# let another_tuple = (3,"four",5.);;
val another_tuple : int * string * float = (3, "four", 5.)

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 16) ∗ all code *)
```
（出于数学上的倾向，使用`*`是因为所有的`t * s`对的集合对应于`t`类型元素集合和`s`类型元素的笛卡尔积）

你可以使用OCaml的模式匹配语法提取元组的元素，就像下面这样：
```ocaml
# let (x,y) = a_tuple;;
 val x : int = 3
 val y : string = "three"

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 17) ∗ all code *)
```
其中`let`绑定左边的`(x, y)`是模式。这个模式让我们创建新的变量`x`和`y`，并且分别绑定到匹配的值的不同部分。在接下来的代码就可以使用这两个变量了。
```ocaml
# x + String.length y;;
- : int = 8

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 18) ∗ all code *)
```
注意元组的构建和模式匹配使用相同的语法。

模式匹配也可以出现在函数参数中。下面是一函数，用以计算两个点之间的距离，每个点用一对`float`表示。模式匹配语法可以让我们轻松获得需要的值。
```ocaml
# let distance (x1,y1) (x2,y2) =
    sqrt ((x1 -. x2) ** 2. +. (y1 -. y2) ** 2.)
  ;;
val distance : float * float -> float * float -> float = <fun>

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 19) ∗ all code *)
```
上面的`**`用以计算浮点数的乘方。

这只是与模式匹配的首次接触。模式匹配是OCaml中的普遍工具，你将会看到，它异常强大。

#### 列表
元组让你可以组合固定数量，通常类型不同的值，而使用列表你可以保存任意数量类型相同的元素。看下面的例子。
```ocaml
# let languages = ["OCaml";"Perl";"C"];;
val languages : string list = ["OCaml"; "Perl"; "C"]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 20) ∗ all code *)
```
注意，和元组不同，同一个列表中不能混合类型不同的值。
```ocaml
# let numbers = [3;"four";5];;
Characters 17-23:
Error: This expression has type string but an expression was expected of type int

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 21) ∗ all code *)
```
##### `List`模块
`Core`有一个`List`模块，里面有丰富的列表操作函数。我们用点号访问模块中的值。如，下面演示如何计算列表的长度。
```ocaml
# List.length languages;;
- : int = 3

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 22) ∗ all code *)
```
下面是一个更复杂的例子。我们可以计算`languages`中每一项的长度。
```ocaml
# List.map languages ~f:String.length;;
- : int list = [5; 4; 1]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 23) ∗ all code *)
```
`List.map`接收两个参数：一个列表和一个用以变换列表元素的函数。它返回转换后的元素组成的新列表，并不改变原列表。

注意，`List.map`的函数参数是在 **标签参数**`~f`下传入的。标签参数以名称标识而非位置，因此允许你改变它们在函数参数中出现的位置而不影响函数行为，如下所示：
```ocaml
# List.map ~f:String.length languages;;
- : int list = [5; 4; 1]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 24) ∗ all code *)
```
我们会在[第二章，变量和函数](#变量和函数)中学习更多关于标签参数的内容，并了解它们的重要性。
##### 用`::`构造列表
除了使用方括号构造列表，你也可以使用`::`操作符向一个列表前面添加元素。
```ocaml
# "French" :: "Spanish" :: languages;;
- : string list = ["French"; "Spanish"; "OCaml"; "Perl"; "C"]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 25) ∗ all code *)
```
这里我们创建了一个新的扩展列表，并没有改变开始的列表，如下所示：
```ocaml
# languages;;
- : string list = ["OCaml"; "Perl"; "C"]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 26) ∗ all code *)
```

> **分号 VS 逗号**
>
> 和其它语言不同，OCaml使用分号而不是逗号来分隔列表中的元素，逗号被用来分隔元组中的元素。如果你在列表中使用了逗号，代码也可以编译过，但和你的预期会大不相同。
> ```ocaml
> # ["OCaml", "Perl", "C"];;
> - : (string * string * string) list = [("OCaml", "Perl", "C")]
> 
> (* OCaml Utop ∗ guided-tour/main.topscript , continued (part 27) ∗ all code *)
> ```
>
> 你不会得到含有三个元素的列表，而会得到一个只有一个元素的列表，这个元素是一个三元组。
>
> 这个例子也说明即使没有括号包围，逗号也能创建元组。因此我们可以这样分配一个整数元组。
> ```ocaml
> # 1,2,3;;
> - : int * int * int = (1, 2, 3)
> 
> (* OCaml Utop ∗ guided-tour/main.topscript , continued (part 28) ∗ all code *)
> ```
> 但这通常被认为是不好的风格，应该避免。

方括号实际上是`::`的语法糖。因此下面的声明是等价的。注意`[]`用以表示空列表，`::`是右结合的。
```ocaml
# [1; 2; 3];;
- : int list = [1; 2; 3]
# 1 :: (2 :: (3 :: []));;
- : int list = [1; 2; 3]
# 1 :: 2 :: 3 :: [];;
- : int list = [1; 2; 3]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 29) ∗ all code *)
```
`::`操作符只能用以在列表前面添加元素，所以最后要有一个`[]`，即空列表。`@`操作符可以用以连接两个列表。
```ocaml
# [1;2;3] @ [4;5;6];;
- : int list = [1; 2; 3; 4; 5; 6]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 30) ∗ all code *)
```
有一点必须记住，和`::`不同，`@`的时间复杂度不是常数级的，拼接两个列表的时间和第一个列表的长度成正比。

##### 使用`match`的列表模式
列表元素可以用模式匹配访问。列表模式基于这两个列表构造器：`::`和`[]`。下面是简单例子：
```ocaml
# let my_favorite_language (my_favorite :: the_rest) =
     my_favorite
  ;;

Characters 25-69:
Warning 8: this pattern-matching is not exhaustive. Here is an example of a value that is not matched:
[]
val my_favorite_language : 'a list -> 'a = <fun>

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 31) ∗ all code *)
```
使用`::`进行的模式匹配，我们分离并命名了列表的第一个元素（`my_favorite`）和剩下的元素（`the_rest`）。如果你熟悉Lisp或Scheme，那么我们现在做的和使用`car`以及`cdr`函数来分离列表的第一个元素和剩下的部分是等价的。

正如你看到的，toplevel不满意这个定义，它会给出一个警告说这个模式不完整。这意味着其中的类型有一些值不能被模式捕获。警告中甚至给出了不能和给定模式匹配的示例值，即`[]`，空列表。如果执行`my_favorite_language`就会发现，在非空列表上正常，但对空列表会失败。
```ocaml
# my_favorite_language ["English";"Spanish";"French"];;
- : string = "English"
# my_favorite_language [];;
Exception: (Match_failure //toplevel// 0 25).

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 32) ∗ all code *)
```
你可以避免这些警告，更重要的是，应该使用`match`语句来确保你的代码会处理所有的情况。

`match`语句是C或Java中`switch`的加强版。它本质上是允许你列出一组模式（用`|`分隔，第一个分支前的可以省略），编译器会分配至第一个匹配的模式。如前所示，模式可以创建和匹配值子结构关联的新变量。

下面是新版的`my_favorite_language`，使用了`match`，不会触发编译器警告。
```ocaml
# let my_favorite_language languages =
    match languages with
    | first :: the_rest -> first
    | [] -> "OCaml" (* A good default! *)
 ;;
val my_favorite_language : string list -> string = <fun>
# my_favorite_language ["English";"Spanish";"French"];;
- : string = "English"
# my_favorite_language [];;
- : string = "OCaml"

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 33) ∗ all code *)
```
上面也包含了我们第一个OCaml注释。OCaml注释用`(*`和`*)`包围，可以任意嵌套，可以跨多行。OCaml中没有类似C++风格的以`//`开头的单行注释。

第一个模式，`fist :: the_rest`，涵盖了`languages`有至少一元素的情况，因为除了空列表，每一个列表都能写成使用一个或多个`::`的形式。第三个模式，`[]`，只匹配空列表。这样模式就完整了，因为列表或是空的，或是至少有一个元素，这是编译器保证的。

##### 递归列表函数
递归函数，就是调用自身的函数，是OCaml以及所有函数式语言的重要技术。设计递归函数的典型方法是把逻辑分割成一些可以直接解决的 **基本分支**，和一些 **归纳分支**，归纳分支中把函数分割成更小的块，然后再调用自身来解决它们。

写递归列表的函数时，基本分支和归纳分支通常用模式匹配来分隔。下面是一个简单例子，一个求列表元素之和的函数。
```ocaml
# let rec sum l =
    match l with
    | [] -> 0                   (* base case *)
    | hd :: tl -> hd + sum tl   (* inductive case *)
  ;;
val sum : int list -> int = <fun>
# sum [1;2;3];;
- : int = 6

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 34) ∗ all code *)
```
按照OCaml惯用法，我们使用`hd`引用列表头，用`tl`引用列表尾。注意要必须使用`rec`才能使`sum`可以调用自身。如你所见，基本分支和归纳分支就是`match`的两个分支。

逻辑上，你可以的把`sum`这种简单递归函数的求值想成一个数学方程式，其含意你可以一步步展开。
```ocaml
sum [1;2;3]
= 1 + sum [2;3]
= 1 + (2 + sum [3])
= 1 + (2 + (3 + sum []))
= 1 + (2 + (3 + 0))
= 1 + (2 + 3)
= 1 + 5
= 6

(* OCaml ∗ guided-tour/recursion.ml ∗ all code *)
```
这建立了一个OCaml求值递归函数实际操作的合理的心理模型。

我们可以提出更复杂的列表模式。下面是一个消除列表中连续重复的函数。
```ocaml
# let rec destutter list =
    match list with
    | [] -> []
    | hd1 :: hd2 :: tl ->
      if hd1 = hd2 then destutter (hd2 :: tl)
      else hd1 :: destutter (hd2 :: tl)
  ;;

Characters 29-171:
Warning 8: this pattern-matching is not exhaustive. Here is an example of a value that is not matched:
_::[]val destutter : 'a list -> 'a list = <fun>

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 35) ∗ all code *)
```
和上面一样，`match`的第一项是基本分支，第二项是归纳分支。但是，如警告信息所言，这段代码是有问题的。我们没有处理只有一个元素的列表。可以给`match`添加一个分支来解决这个问题。
```ocaml
# let rec destutter list =
    match list with
    | [] -> []
    | [hd] -> [hd]
    | hd1 :: hd2 :: tl ->
      if hd1 = hd2 then destutter (hd2 :: tl)
      else hd1 :: destutter (hd2 :: tl)
  ;;
val destutter : 'a list -> 'a list = <fun>
# destutter ["hey";"hey";"hey";"man!"];;
- : string list = ["hey"; "man!"]

(* OCaml Utop ∗ guided-tour/main.topscript , continued (part 36) ∗ all code *)
```
注意上面的代码中使用了列表模式的又一个变体`[hd]`来匹配只有一个元素的列表。我们可以用这种方法匹配任何有固定数量元素的列表，如`[x;y;z]`会匹配所有有三个元素的列表，并会把元素分别绑定到变量`x`、`y`和`z`上。

最近的几个例子中，我们的列表处理函数包含了许多递归函数。实际中，这通常都是不必要的。大多数情况下，你会更乐于使用List模块中的迭代函数。但知道如何使用递归是有好处的，以防你要用它做点新的事情。

#### Options
### Records and variants
### Imperative programming
#### Arrays
#### Mutable record fields
#### Refs
#### For and while loops
### A complete program
#### Compiling and running
### Where to go from here

