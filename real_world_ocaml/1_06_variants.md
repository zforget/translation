## 第六章 变体
>> Variants

变体类型是OCaml最有用的特性之一，也是最不寻常的特性之一。变体使你可以表达可能多种不同形态的数据，每种形式都用一个显式的标签标注。我们将会看到，结合模式匹配，变体给了你一种强大的方式来表达复杂数据以及组织在其上的案例分析。

变体类型声明的基本语法如下所示：
```ocaml
type <variant> =
  | <Tag> [ of <type> [* <type>]... ]
  | <Tag> [ of <type> [* <type>]... ]
  | ...

(* Syntax ∗ variants/variant.syntax ∗ all code *)
```
每一行实际上是表示变体的一个实例。每一个实例都有一个相关的标签，也可能有一系列可选的字段，每一个字段都有指定的类型。

让我们以一个具体的例子来说明变量的重要性。几乎所有的终端都支持一组基本颜色，我们可以使用变体表示它们。每种颜色声明成一个简单标签，使用管道符分隔不同的实例。注意变体标签必须是大写字母开头的：
```ocaml
# type basic_color =
   | Black | Red | Green | Yellow | Blue | Magenta | Cyan | White ;;
type basic_color =
    Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White
# Cyan ;;
- : basic_color = Cyan
# [Blue; Magenta; Red] ;;
- : basic_color list = [Blue; Magenta; Red]

(* OCaml Utop ∗ variants/main.topscript ∗ all code *)
```
下面的函数使用模式匹配把`basic_color`转换成相应的整数。模式匹配的完整性检查意味着当我们遗漏一个颜色时编译器会警告：
```ocaml
# let basic_color_to_int = function
  | Black -> 0 | Red     -> 1 | Green -> 2 | Yellow -> 3
  | Blue  -> 4 | Magenta -> 5 | Cyan  -> 6 | White  -> 7 ;;
val basic_color_to_int : basic_color -> int = <fun>
# List.map ~f:basic_color_to_int [Blue;Red];;
- : int list = [4; 1]

(* OCaml Utop ∗ variants/main.topscript , continued (part 1) ∗ all code *)
```
使用上面的函数，我们就可以生成转义代码来改变一个字符串在终端中的颜色：
```ocaml
# let color_by_number number text =
    sprintf "\027[38;5;%dm%s\027[0m" number text;;
val color_by_number : int -> string -> string = <fun>
# let blue = color_by_number (basic_color_to_int Blue) "Blue";;
val blue : string = "\027[38;5;4mBlue\027[0m"
# printf "Hello %s World!\n" blue;;
Hello Blue World!

(* OCaml Utop ∗ variants/main-2.rawscript ∗ all code *)
```
在多数终端里，”Blue“都会以蓝色呈现。

### Catch-All Cases and Refactoring
### Variants and Recursive Data Structures
### Polymorphic Variants
#### Example: Terminal Colors Redux
#### When to Use Polymorphic Variants
