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

### Nested modules

### Opening modules

### Including modules

### Common errors with modules
#### Type mismatches
#### Missing definitions
#### Type definition mismatches
#### Cyclic dependencies

