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

### Signatures and abstract types

### Concrete types in signatures

### Nested modules

### Opening modules

### Including modules

### Common errors with modules
#### Type mismatches
#### Missing definitions
#### Type definition mismatches
#### Cyclic dependencies

