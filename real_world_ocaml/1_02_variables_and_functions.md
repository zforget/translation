## 第二章 变量和函数
变量和函数几乎是所有编程语言的基本概念。OCaml中的这概念与你碰到过的可能有所不同，所以本章会覆盖OCaml中变量和函数的细节，从基本的如何定义一个变量开始，最后会介绍使用了可选参数和标签参数的复杂函数。

当被一些细节打击时不要气馁，特别是在接近本章结尾时。本章的概念非常重要，如果首次阅读时没有领会，在你对OCaml有了更多了解后回过头来重读本章以补上对这些概念的理解。

### 变量
简单来说，变量是一个标识符，其含义绑定到一个特定的值上。在OCaml中，这些绑定通常用`let`关键字引入。我们可以用下面的语法写出一个所谓的顶层绑定。注意变量必须以小写字母或下划线开头。
```ocaml
let <variable> = <expr>

(* Syntax ∗ variables-and-functions/let.syntax ∗ all code *)
```
在[第4章文件、模块和程序](#文件模块和程序)中接触模块时我们会看到，模块是顶层`let`绑定也使用了相同的语法。

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
注意`language_list`的作用域仅限于表达式`String.concat ~sep:"-" language_list`，在顶层不能访问，就比如现在我们尝试访问它：
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
这是我们首次使用`assert`，它在标注不可能的情况是很有用。我们会在[第7章错误处理](#错误处理)中详细讨论。

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
#### Multi-argument functions

#### Recursive functions

#### Prefix and infix operators

#### Declaring functions with function

#### Labeled arguments
##### Higher-order functions and labels

#### Optional arguments
##### Explicit passing of an optional argument
##### Inference of labeled and optional arguments
##### Optional arguments and partial application
