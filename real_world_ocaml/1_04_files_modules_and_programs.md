## 第四章 文件、模块和程序
目前为止我们主要是通过toplevel来体验OCaml。当你由练习转向实战时，你需要把toplevel放到一边,并开始从文件构建程序。文件不仅是存储代码的方便手段，在OCaml中，它们还充当了把程序分割成一些概念单元的边界。

本章中，我们会向你展示如何从一组文件来构建OCaml程序，同时还有模块和模块签名的基本使用。

### 单文件程序
我们从一个简单例子开始：一个统计`stdin`读入的行频率计数的工具，最后输出计数最大的前10行。我们先从一个简单实现开始，代码将保存到freq.ml中。

在这个实现中我们用了两个`List.Assoc`模块中的函数，该模块提供了操作关联列表的函数，关联列表即键/值对列表。这里，我们使用`List.Assoc.find`函数来在关联列表查找一个键值，用`List.Assoc.add`函数向关联列表中添加一对新的绑定，如下所示。
```ocaml
# let assoc = [("one", 1); ("two",2); ("three",3)] ;;
val assoc : (string * int) list = [("one", 1); ("two", 2); ("three", 3)]
# List.Assoc.find assoc "two" ;;
- : int option = Some 2
# List.Assoc.add assoc "four" 4 (* add a new key *) ;;
- : (string, int) List.Assoc.t = [("four", 4); ("one", 1); ("two", 2); ("three", 3)]
# List.Assoc.add assoc "two"  4 (* overwrite an existing key *) ;;
- : (string, int) List.Assoc.t = [("two", 4); ("one", 1); ("three", 3)]

(* OCaml Utop ∗ files-modules-and-programs/intro.topscript ∗ all code *)
```
注意`List.Assoc.add`不修改原列表，会分配一个包含所添加的键/值对的新列表。

现在我们可以写freq.ml了。
```ocaml
open Core.Std

let build_counts () =
  In_channel.fold_lines stdin ~init:[] ~f:(fun counts line ->
    let count =
      match List.Assoc.find counts line with
      | None -> 0
      | Some x -> x
    in
    List.Assoc.add counts line (count + 1)
  )

let () =
  build_counts ()
  |> List.sort ~cmp:(fun (_,x) (_,y) -> Int.descending x y)
  |> (fun l -> List.take l 10)
  |> List.iter ~f:(fun (line,count) -> printf "%3d: %s\n" count line)

(* OCaml ∗ files-modules-and-programs-freq/freq.ml ∗ all code *)
```
函数`build_counts`从`stdin`读入多行，并从这些行构建一个行和其出现频率计数的关联列表。调用了`In_channel.fold_lines`函数（类似[第三章列表和模式](#列表和模式)中描述的`List.fold`），它一行行读入，并对每一行调用给定的函数来更新累加器。累加器被初始化为空列表。

定义好`build_counts`，我们就可以调用它来构建关联列表，然后按频率计数降序排序，取前10个元素，最后遍历这10个元素把它们打印到屏幕上。这些操作用[第二章变量和函数](#变量和函数)中介绍的`|>`操作符串在一起。

> **`main`函数在哪里？**
>
> 和C语言不同，OCaml程序不需要一个唯一的`main`函数。当求值一个OCaml程序时，实现文件中的所有语句都会按顺序求值。这些实现文件可以包含任意表达式，而不仅限于函数定义。本例中，以`let () =`开始的声明充当了`main`函数的角色，是程序的开始。但其实整个文件都在启动时求值，所以某种程度上所有代码就是一个大`main`函数。
>
> `let () =`这种惯用法看起来可能有点怪异，但是有原因的。这里的`let`绑定是一个对`uint`类型值的模式匹配，这会保证右边的代码返回`uint`，这对于主要靠副作用的函数是常见的用法。

如果没有使用Core或其它外部库，我们可以像这样构建可执行程序：
```bash
$ ocamlc freq.ml -o freq.byte
File "freq.ml", line 1, characters 0-13:
Error: Unbound module Core

# Terminal ∗ files-modules-and-programs-freq/simple_build_fail.out ∗ all code 
```
但，如你所见，它会失败，因为找不到Core。我们需要一个稍微复杂的命令以链接Core：
```bash
 ocamlfind ocamlc -linkpkg -thread -package core freq.ml -o freq.byte

# Terminal ∗ files-modules-and-programs-freq/simple_build.out ∗ all code
```
这里用到了 **ocamlfind**，此工具会自己以合适的标志调用OCaml工具链中的其它组件（这里是 **ocamlc**），以链接特定的库和包。这里，`-package core`告诉ocamlfind要链接Core库，`-linkpkg`告诉ocamlfind构建可执行程序时把需要的库链入，`-thread`打开线程支持开关，Core需要。

对于只有一个文件的工程，这就够了，更复杂的工程需要工具来组织构建。一个很不错的工具就是 **ocamlbuild**，它是和OCaml编译器一起推出的。我们会在[第22章编译器前端：解析和类型检查](#编译器前端解析和类型检查)中进一步介绍ocamlbuild，现在，我们使用ocamlbuild的一个简单封装 **corebuild**，它可以针对Core及其相关的库正确设置构建参数。
```bash
$ corebuild freq.byte

 # Terminal ∗ files-modules-and-programs-freq-obuild/build.out ∗ all code
```
如果使用`freq.native`代替`freq.byte`作为目标调用corebuild，就会得到本地代码。

我们可以从命令行调用生成的可执行程序。下面的命令行提取了 **ocamlopt**二进制文件中字符串，然后报告了最常出现的。注意，结果随平台不同会有差异，因为这个二进制文件本身在不同平台上就是不同的。
```bash
$ strings `which ocamlopt` | ./freq.byte
6: +pci_expr =
6: -pci_params =
6: .pci_virt = %a
4: #lsr
4: #lsl
4: $lxor
4: #lor
4: $land
4: #mod
3: 6 .section .rdata,"dr"

 # Terminal ∗ files-modules-and-programs-freq-obuild/test.out ∗ all code
```

> **字节码 VS 本地代码**
>
> OCaml有两个编译器： 字节码编译器 **ocamlc**和本地代码编译器 **ocamlopt**。用ocamlc编译出的程序由一个虚拟机解释执行，而由ocamlopt编译出的程序被直接编译成可以在指定操作系统和处理器架构上运行的机器码。使用ocamlbuild，后缀为.byte的目标被编译成字节码，而.native后缀的目标则被编译为本地代码。
>
> 除了性能，这两个编译器产生的代码行为几乎完全一致。有几个问题需要注意一下。首先，字节码编译器可以在更多的架构上使用，并有一些本地码编译器没有的工具。如，OCaml调试器只能用在字节码上（尽管gbd，GNU Debugger，可以用在OCaml本地程序上）。字节码编译器也比本地代码编译器要快。另外，要运行字节码程序，你通常需要在系统上安装OCaml。这并不严格，因为你可以通过`-custom`标志把运行时嵌入到字节程序中。
>
> 一般情况下，生产程序都应该使用本地代码编译器构建，有时候字节码适合作为开发构建。还有，在本地代码编译器不支持的平台上也需要使用字节码。关于这两个编译器更多的细节会在[第23章编译器后端：字节码和本地代码](#编译器后端：字节码和本地代码)中讨论。

### 多文件程序和模块
OCaml中的源文件组成了模块系统，每个文件都编译成一个模块，该模块名继承自文件名。之前我们已经碰到过模块了，例如当你使用类似`List.Assoc`模块中的`find`和`add`函数时。最简单的，你可以把模块看作是一个在命名空间中的定义的集合。

现在让我们看一下如何使用模块来重构freq.ml。还记得吗，变量`counts`包含了一个代表行的频率计数的关联列表。更新关联列表的时间和其长度成线性关系，这就意味着整个处理的时间复杂度是文件行数的二次方。

我们可以用更高效的数据结构代替关联列表来解决这个问题。为此，我们首先将关键功能以显式的接口放到一个单独的模块中。一旦有了清晰的编程接口，我们就可以考虑一个替代实现（更高效）。

我们将从创建counter.ml文件开始，它包含了表示频率计数的关联列表的处理逻辑。主体函数是`touch`，将给定行的频率计数加一。
```ocaml
open Core.Std

let touch t s =
  let count =
    match List.Assoc.find t s with
    | None -> 0
    | Some x -> x
  in
  List.Assoc.add t s (count + 1)

(* OCaml ∗ files-modules-and-programs-freq-with-counter/counter.ml ∗ all code *)
```
counter.ml文件会被编译到`Counter`模块，模块名自动继承自文件名。即使文件名不是，模块名也是首字母大写的。实际上，模块名必须首字母大写。

我们现在可以用`Counter`重写freq.ml了。注意代码依然可以使用ocamlbuild编译，它会发现依赖关系并知道需要编译counter.ml。
```ocaml
open Core.Std

let build_counts () =
  In_channel.fold_lines stdin ~init:[] ~f:Counter.touch

let () =
  build_counts ()
  |> List.sort ~cmp:(fun (_,x) (_,y) -> Int.descending x y)
  |> (fun l -> List.take l 10)
  |> List.iter ~f:(fun (line,count) -> printf "%3d: %s\n" count line)

(* OCaml ∗ files-modules-and-programs-freq-with-counter/freq.ml ∗ all code *)
```

### 签名和抽象类型
即使我们已经把一些逻辑放到了`Counter`中，freq.ml的代码依然依赖于`Counter`的实现。实际上，看一下`build_counts`的定义就会知道它依赖这样一个事实：空的频率计数集合用空列表表示。想要去掉这个依赖，我们可以修改Counter的实现，而不必修改freq.ml中的客户代码。

一个模块的实现细节可以通过附加一个接口来隐藏。（注意在OCaml中，接口、签名、模块类型这些术语是一回事。）文件filename.ml中定义的模块，可以使用filename.mli中的签名来限定。

对于counter.mli，我们先不隐藏任何东西，只是写出描述counter.ml中当前内容的接口。`val`声明用以指定一个值的签名。`val`的语法如下所示：
```ocaml
val <identifier> : <type>

(* Syntax ∗ files-modules-and-programs/val.syntax ∗ all code *)
```
使用上述语法我们可以写出counter.ml的签名如下：
```ocaml
open Core.Std

(** Bump the frequency count for the given string. *)
val touch : (string * int) list -> string -> (string * int) list

(* OCaml ∗ files-modules-and-programs-freq-with-sig/counter.mli ∗ all code *)
```
注意，ocamlbuild会检查mli文件是否存在，并在构建中自动包含它。

> **自动生成mli文件**
>
> 如果不想整个mli文件都手写，你可以让OCaml为你从源代码自动生成一个，然后再调整成你想要的。下面是一个使用corebuild的例子。
> ```bash
> $ corebuild counter.inferred.mli
> $ cat _build/counter.inferred.mli
> val touch :
>   ('a, int) Core.Std.List.Assoc.t -> 'a -> ('a, int) Core.Std.List.Assoc.t
>
> #Terminal ∗ files-modules-and-programs-freq-with-counter/infer_mli.out ∗ all code
> ```
> 生成的代码和你之前手写的基本一样，但是更丑陋也更冗长，当然，还没有注释。通常，自动生成的mli文件只能作为一个起点。在OCaml中，mli文件是你表达和文档化你接口的关键位置，并且人类的编辑和组织能力是无法取代的。

为了隐藏频率计数由关联列表表示这个事实，我们需要把频率计数的类型变为 **抽象**的。一个只在接口中出现名字面而没有定义的类型就是一个抽象类型。下面是`Counter`的抽象接口：
```ocaml
open Core.Std

(** A collection of string frequency counts *)
type t

(** The empty set of frequency counts  *)
val empty : t

(** Bump the frequency count for the given string. *)
val touch : t -> string -> t

(** Converts the set of frequency counts to an association list.  A string shows
    up at most once, and the counts are >= 1. *)
val to_list : t -> (string * int) list

(* OCaml ∗ files-modules-and-programs-freq-with-sig-abstract/counter.mli ∗ all code *)
```
注意需要向`Counter`中增加`empty`和`to_list`，因为，我们无法创建一个`Counter.t`，也无法从其中获取数据。

我们也借机对模块进行了文档化。mli文件是你指定模块接口的地方，所以这是放置的文档的自然位置。我们使用两个星号来开始注释，这样ocamldoc工具就能在生成API文档时收集它们。我们会在[第23章编译器前端：解析和类型检查](#编译器前端解析和类型检查)中进一步讨论ocamldoc。

下面我们根据新的counter.mli来重写counter.ml。
```ocaml
open Core.Std

type t = (string * int) list

let empty = []

let to_list x = x

let touch t s =
  let count =
    match List.Assoc.find t s with
    | None -> 0
    | Some x -> x
  in
  List.Assoc.add t s (count + 1)

(* OCaml ∗ files-modules-and-programs-freq-with-sig-abstract/counter.ml ∗ all code *)
```
现在再编译freq.ml就会得到下面的错误。
```ocaml
$ corebuild freq.byte
File "freq.ml", line 4, characters 42-55:
Error: This expression has type Counter.t -> string -> Counter.t
       but an expression was expected of type 'a list -> string -> 'a list
       Type Counter.t is not compatible with type 'a list
Command exited with code 2.

(* Terminal ∗ files-modules-and-programs-freq-with-sig-abstract/build.out ∗ all code *)
```
这是因为freq.ml依赖频率计数由关联列表表示，而我们刚刚隐藏了这一点。我们需要修改`build_counts`，使用`Counter.empty`来代替`[]`，最后打印时使用`Counter.to_list`来获得关联列表。结果如下。
```ocaml
open Core.Std

let build_counts () =
  In_channel.fold_lines stdin ~init:Counter.empty ~f:Counter.touch

let () =
  build_counts ()
  |> Counter.to_list
  |> List.sort ~cmp:(fun (_,x) (_,y) -> Int.descending x y)
  |> (fun counts -> List.take counts 10)
  |> List.iter ~f:(fun (line,count) -> printf "%3d: %s\n" count line)

(* OCaml ∗ files-modules-and-programs-freq-with-sig-abstract-fixed/freq.ml ∗ all code *)
```
现在我们可以转向去优化`Counter`的实现。下面是一个替代实现，效率要高得多，使用了Core中的`Map`数据结构。
```ocaml
open Core.Std

type t = int String.Map.t

let empty = String.Map.empty

let to_list t = Map.to_alist t

let touch t s =
  let count =
    match Map.find t s with
    | None -> 0
    | Some x -> x
  in
  Map.add t ~key:s ~data:(count + 1)

(* OCaml ∗ files-modules-and-programs-freq-fast/counter.ml ∗ all code *)
```
注意上面我们有时用`String.Map`而有时只简单使用`Map`。这样做是因为对于有些操作，如创建一个`Map.t`，需要获得类型信息，其它的一些操作，如在一个`Map.t`中查找，则不需要。这在[第13章映射和哈希表](#映射和哈希表)中会进一步详述。

### 签名中的具体类型
在我们的频率计数例子中，`Counter`模块用一个抽象类型Counter.t来表示频率计数的集合。有时，你会希望你接口中的类型是 **具体**的，即在接口中包含类型定义。

例如，想象一下我们要向`Counter`中添加一个函数，返回频率计数处于中间的那一行。如果行数是偶数，就没有一个明确的中间值，函数会返回中间值前后的两行。我们使用一个自定义的类型来表示返回值的这两种情况。下面是一个可能的实现。
```ocaml
type median = | Median of string
              | Before_and_after of string * string

let median t =
  let sorted_strings = List.sort (Map.to_alist t)
                         ~cmp:(fun (_,x) (_,y) -> Int.descending x y)
  in
  let len = List.length sorted_strings in
  if len = 0 then failwith "median: empty frequency count";
  let nth n = fst (List.nth_exn sorted_strings n) in
  if len mod 2 = 1
  then Median (nth (len/2))
  else Before_and_after (nth (len/2 - 1), nth (len/2));;

(* OCaml ∗ files-modules-and-programs-freq-median/counter.ml , continued (part 1) ∗ all code *)
```
上面我们用`failwith`对空列表的情况抛出异常。[第7章错误处理](#错误处理)中会进一步讨论异常。同时注意`fst`函数用以简单返回一个二元组的第一个元素。

现在，要在接口中暴露这个功能，我们需要同时暴露函数`median`和类型`median`，包括类型`median`的定义。注意值（如函数就是一种值）和类型的命名空间不同，所以这里没有命名冲突。向counter.mli中添加下面两行就能达到这个目的。
```ocaml
(** Represents the median computed from a set of strings.  In the case where
    there is an even number of choices, the one before and after the median is
    returned.  *)
type median = | Median of string
              | Before_and_after of string * string

val median : t -> median

(* OCaml ∗ files-modules-and-programs-freq-median/counter.mli , continued (part 1) ∗ all code *)
```
决定一个类型是抽象的还是具体很重要。抽象类型在值的创建和访问上给你更多控制权，比起由靠类型自身，更容易强制使用不变量;具体类型使你可以轻松向客户代码暴露更多细节和结构。正确的选择依靠上下文确定。

### 嵌套模块
目前为止，我们只考虑了关联到文件的模块，如counter.ml。但模块（包括模块签名）也可以嵌套在其它模块中。举个简单例子，考虑一个处理类似用户名和主机名这样的多个标识符的程序。如果都用字符串表示，就容易将它们搞混。

更好的方法是为每种标识符创建一个新的抽象类型，这些类型底层用字符串实现。这样，类型系统就会阻止你混淆用户名和主机名，如果需要转换，你可以使用显式的转换器在这些类型和字符串之间转换。

下面展示了如何使用子模块实现这个抽象类型。
```ocaml
open Core.Std

module Username : sig
  type t
  val of_string : string -> t
  val to_string : t -> string
end = struct
  type t = string
  let of_string x = x
  let to_string x = x
end

(* OCaml ∗ files-modules-and-programs/abstract_username.ml ∗ all code *)
```
注意，`to_string`和`of_string`被实现为恒等函数（identity function），这意味着它们没有运行时开销。它们纯粹是通过类型系统作用于代码的一些规则。

模块声明的基本结构如下所示：
```ocaml
module <name> : <signature> = <implementation>

(* Syntax ∗ files-modules-and-programs/module.syntax ∗ all code *)
```
我们可以稍微变通一下，使用`module type`在顶层定义签名，这样就可以轻松用相同的底层实现来定义不同的类型。
```ocaml
open Core.Std

module type ID = sig
  type t
  val of_string : string -> t
  val to_string : t -> string
end

module String_id = struct
  type t = string
  let of_string x = x
  let to_string x = x
end

module Username : ID = String_id
module Hostname : ID = String_id

type session_info = { user: Username.t;
                      host: Hostname.t;
                      when_started: Time.t;
                    }

let sessions_have_same_user s1 s2 =
  s1.user = s2.host

(* OCaml ∗ files-modules-and-programs/session_info.ml ∗ all code *)
```
上面的代码有一个bug：你拿一个会话中的用户名和另一个会话中的主机名作比较，而实际上应该比较两个用户名。但因为定义了自己的类型，编译会为我们指出这个bug。
```bash
$ corebuild session_info.native
File "session_info.ml", line 24, characters 12-19:
Error: This expression has type Hostname.t
       but an expression was expected of type Username.t
Command exited with code 2.

 # Terminal ∗ files-modules-and-programs/build_session_info.out ∗ all code 
```
这个例子没有什么实际意义，但是混淆不同的标识符确实是滋生bug的温床，为不同类的标识符创建抽象类型的方法可以有效避免此类问题。

### 打开模块
通常，你可以选择使用模块名作为显式的限定符来引用其中的值和模块。如，可以用`List.map`引用`List`模块中的`map`函数。但有时，你想要不用显式的限定符来引用模块内容。这就要使用`open`语句。

我们之前已经见`open`了，特别是在我们用`open Core.Std`来获得Core库中的标准定义的访问权时。通常，打开一个模块会将其内容添加到编译器在其中查找标识符定义的环境中。下面是一个例子。
```ocaml
# module M = struct let foo = 3 end;;
module M : sig val foo : int end
# foo;;
Characters -1-3:
Error: Unbound value foo
# open M;;
# foo;;
- : int = 3

(* OCaml Utop ∗ files-modules-and-programs/main.topscript ∗ all code *)
```
当在环境中使用像Core这样的标准库时`open`非常重要，但是通常最小程度打开模块是更好的编程风格。打开模块基本上是简洁性和明确性之间的折衷--你打开的模块越多，所需的限定符就规越少，但查找一标识符及其出处也更困难。

下面是如何打开模块的一些建议。

- 在顶层打开一个模块要相当谨慎，通常，只有模块本身被特别设计成如此时才能打开，如`Core.Std`或`Option.Monad_infix`等。
- 如果非要打开，最好使用局部打开（local open）。局部打开有两种语法。如，你可以这样写：
 ```ocaml
 # let average x y =
    let open Int64 in
    x + y / of_int 2;;
  val average : int64 -> int64 -> int64 = <fun>

 (* OCaml Utop ∗ files-modules-and-programs/main.topscript , continued (part 1) ∗ all code *)
 ```
 上面，`of_int`和`infix`来自`Int64`模块。

 还有一种更轻量的语法，在短小表达式中特别有用：
 ```ocaml
 # let average x y =
    Int64.(x + y / of_int 2);;
 val average : int64 -> int64 -> int64 = <fun>

 (* OCaml Utop ∗ files-modules-and-programs/main.topscript , continued (part 2) ∗ all code *)
 ```
- 除了局部打开可以保持简洁性又不失明确性，还可以在局部重新绑定模块名。所以，使用`Counter.map`类型时，除了可以这样写：
 ```ocaml
 let print_median m =
   match m with
   | Counter.Median string -> printf "True median:\n   %s\n" string
   | Counter.Before_and_after (before, after) ->
     printf "Before and after median:\n   %s\n   %s\n" before after
 
 (* OCaml ∗ files-modules-and-programs-freq-median/use_median_1.ml , continued (part 1) ∗ all code *)
 ```
 你还可以这样：
 ```ocaml
 let print_median m =
   let module C = Counter in
   match m with
   | C.Median string -> printf "True median:\n   %s\n" string
   | C.Before_and_after (before, after) ->
     printf "Before and after median:\n   %s\n   %s\n" before after
 
 (* OCaml ∗ files-modules-and-programs-freq-median/use_median_2.ml , continued (part 1) ∗ all code *)
 ```
 因为模块名`C`的作用域很小，所以代码很容易阅读，也很容易指出`C`的含义。但通常，在顶层将模块重绑定到一个短名称上是个错误。
 
### 包含模块
打开模块影响查找标识符的环境，而包含一个模块则是一种向一个模块中添加新标识符的方法。下面是一个表示间隔范围的简单模块。
```ocaml
# module Interval = struct
    type t = | Interval of int * int
             | Empty

    let create low high =
      if high < low then Empty else Interval (low,high)
  end;;
module Interval :
  sig
    type t = Interval of int * int | Empty
    val create : int -> int -> t
  end

(* OCaml Utop ∗ files-modules-and-programs/main.topscript , continued (part 3) ∗ all code *)
```
我们可以使用`include`指令来创建一新的`Interval`模块的扩展版本。
```ocaml
# module Extended_interval = struct
    include Interval

    let contains t x =
      match t with
      | Empty -> false
      | Interval (low,high) -> x >= low && x <= high
  end;;
module Extended_interval :
  sig
    type t = Interval.t = Interval of int * int | Empty
    val create : int -> int -> t val
    contains : t -> int -> bool
  end
# Extended_interval.contains (Extended_interval.create 3 10) 4;;
- : bool = true

(* OCaml Utop ∗ files-modules-and-programs/main.topscript , continued (part 4) ∗ all code *)
```
`include`和`open`的不同在于，我们不只是修改了标识符如何搜索，我们还修改了模块的内容。如果上面使用`open`，结果会完全不同。
```ocaml
# module Extended_interval = struct
    open Interval

    let contains t x =
      match t with
      | Empty -> false
      | Interval (low,high) -> x >= low && x <= high
  end;;
module Extended_interval :
  sig
    val contains : Extended_interval.t -> int -> bool
  end
# Extended_interval.contains (Extended_interval.create 3 10) 4;;
Characters 28-52:
Error: Unbound value Extended_interval.create

(* OCaml Utop ∗ files-modules-and-programs/main.topscript , continued (part 5) ∗ all code *)
```
考虑一个更为实际的例子，想像一下你要构建`List`模块的扩展版本，以添加一些Core发布版中没有的功能。使用`include`就可以做到这一点。
```ocaml
open Core.Std

(* The new function we're going to add *)
let rec intersperse list el =
  match list with
  | [] | [ _ ]   -> list
  | x :: y :: tl -> x :: el :: intersperse (y::tl) el

(* The remainder of the list module *)
include List

(* OCaml ∗ files-modules-and-programs/ext_list.ml ∗ all code *)
```
现在，该如何给我们的新模块写接口呢？`include`是可以用在签名上的，所以我们可以用相同的技巧来写mli。唯一一个问题就是我们需要手动获得模块`List`的签名。这时可以使用`moudle type of`，它可以计算一个模块的签名。
```ocaml
open Core.Std

(* Include the interface of the list module from Core *)
include (module type of List)

(* Signature of function we're adding *)
val intersperse : 'a list -> 'a -> 'a list

(* OCaml ∗ files-modules-and-programs/ext_list.mli ∗ all code *)
```
注意mli中的声明顺序不一定要和ml中的一样。ml中的声明通常在影响值的遮蔽时才重要。如果我们想要用一个新函数来替换`List`的一个函数，ml中新函数的声明就要在`include List`后面。

现在我们可以使用`Ext_list`来代替`List`了。如果要在工程中优先使用`Ext_list`，我们可以创建一个通用定义：
```ocaml
module List = Ext_list

(* OCaml ∗ files-modules-and-programs/common.ml ∗ all code *)
```
这样如果我们在工程内的每个文件中都将`open Common`放到`open Core.Std`后面，那么`List`的引用会自动转向`Ext_list`。

### 与模块相关的常见错误
当OCaml从ml和mli编译程序时，检查到两者之间不匹配就会报错。下面是一些你会遇到的常见错误。

#### 类型不匹配
最简单的错误就是签名指定的类型和模块实现中的类型不匹配。举个例子，如果我们把`counter.mli`中的`val`声明的前两个参数交换：
```ocaml
(** Bump the frequency count for the given string. *)
val touch : string -> t -> t

(* OCaml ∗ files-modules-and-programs-freq-with-sig-mismatch/counter.mli , continued (part 1) ∗ all code *)
```
然后再试图编译时，我们就会得到下面的错误。
```bash
$ corebuild freq.byte
File "freq.ml", line 4, characters 53-66:
Error: This expression has type string -> Counter.t -> Counter.t
       but an expression was expected of type
         Counter.t -> string -> Counter.t
       Type string is not compatible with type Counter.t 
Command exited with code 2.

# Terminal ∗ files-modules-and-programs-freq-with-sig-mismatch/build.out ∗ all code
```

#### 缺少定义
我们可能会决定在`Counter`中要一个新的函数来提取一个给定字符串的频率计数。我们可以向mli添加下面的行。
```ocaml
val count : t -> string -> int

(* OCaml ∗ files-modules-and-programs-freq-with-missing-def/counter.mli , continued (part 1) ∗ all code *)
```
现在，如果不添加实现就试图编译，我们会得到这样的错误：
```bash
$ corebuild freq.byte
File "counter.ml", line 1:
Error: The implementation counter.ml
       does not match the interface counter.cmi:
       The field `count' is required but not provided
Command exited with code 2.

# Terminal ∗ files-modules-and-programs-freq-with-missing-def/build.out ∗ all code
```
缺少类型定义会导致类似的错误。

#### 类型定义不匹配
mli中的类型定义需要和ml中的相关定义匹配。再一次考虑类型`median`的例子。变体(variant)的声明顺序对OCaml编译器来说是有意义的，所以`median`定义和实现的`option`如果顺序不同：
```ocaml
(** Represents the median computed from a set of strings.  In the case where
    there is an even number of choices, the one before and after the median is
    returned.  *)
type median = | Before_and_after of string * string
              | Median of string

(* OCaml ∗ files-modules-and-programs-freq-with-type-mismatch/counter.mli , continued (part 1) ∗ all code *)
```
就会产生一个编译错误：
```bash
$ corebuild freq.byte
File "counter.ml", line 1:
Error: The implementation counter.ml
       does not match the interface counter.cmi:
       Type declarations do not match:
         type median = Median of string | Before_and_after of string * string
       is not included in
         type median = Before_and_after of string * string | Median of string
       File "counter.ml", line 18, characters 5-84: Actual declaration
       Fields number 1 have different names, Median and Before_and_after.
Command exited with code 2.

# Terminal ∗ files-modules-and-programs-freq-with-type-mismatch/build.out ∗ all code 
```
顺序对于其它类型也有类似的重要性，包括记录类型字段的声名顺序和函数参数（包括标签参数和可选参数）的顺序。

#### 循环依赖
多数情况下，OCaml都不允许循环依赖，即，一组全部互相依赖的定义。如果你要创建这种定义，就需要特别标记它们。例如，当定义一组相互递归的值（像[“递归函数”一节](#递归函数)中定义的`is_even`和`is_odd`）时，你需要使用`let rec`而不是普通的`let`。

在模块层面也是如此。模块间的相互依赖默认是不允许的，而文件之间的循环任何情况下都不允许。递归模块是可能的，但极少用，我们不在此讨论。

禁止循环引用最简单的例子就是引用它自己的模块名。因此，如果我们在counter.ml添加一个对`Counter`的引用
```ocaml
let singleton l = Counter.touch Counter.empty

(* OCaml ∗ files-modules-and-programs-freq-cyclic1/counter.ml , continued (part 1) ∗ all code *)
```
构建时我们就会得到这样的错误：
```bash
$ corebuild freq.byte
File "counter.ml", line 18, characters 18-31:
Error: Unbound module Counter
Command exited with code 2.

# Terminal ∗ files-modules-and-programs-freq-cyclic1/build.out ∗ all code
```
如果创建文件之间的循环引用，此问题会有不同的表现。通过在counter.ml中添加一个对`Freq`的引用我们就可以创造这种情况，如，添加下面这行代码。
```ocaml
let _build_counts = Freq.build_counts

(* OCaml ∗ files-modules-and-programs-freq-cyclic2/counter.ml , continued (part 1) ∗ all code *)
```
这种情况下，ocamlbuild（会由corebuild脚本调用）会发现错误并明确报告循环引用。
```bash
$ corebuild freq.byte
Circular dependencies: "freq.cmo" already seen in
  [ "counter.cmo"; "freq.cmo" ]
 
# Terminal ∗ files-modules-and-programs-freq-cyclic2/build.out ∗ all code
```
