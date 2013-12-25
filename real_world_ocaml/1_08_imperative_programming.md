## 第八章 命令式编程
到目前为止，本书所示的大部分代码，实际上，应该是一般的OCaml代码，都是*纯函数式*的。纯函数式代码不会修改程序内部状态，没有I/O操作，不去读时钟，也不会以其它方式与外部的可变部分交互。因此一个纯函数行为类似一个数学方程式，对给定的输入总是会返回相同的结果，除了返回值之外对外部没有任何影响。另一方面，*命令式*代码通过副作用运作，修改程序内部状态或与外部交互。命令式函数有新的作用，并潜在每次调用返回不同的值的可能。

OCaml中默认的是函数式代码，原因是容易推导、错误更少且可组合性更好。但对于实用的编程语言来说，命令式代码有根本的重要性，因为现实世界的任务要求你与外部交互，这是其本性。命令式编程在性能方面也很重要。尽管OCaml中的纯函数代码很高效，但有许多算法只能用命令式技术高效实现。

在这方面OCaml提供了今人满意的折衷，使纯函数式编程容易且自然的同时，也对命令式编程提供了良好的支持。本章会带你领略OCaml的命令式特性，帮助你更好地使用他们。

### 例子：命令式字典
我们以一个简单的命令式字典开始，即，一个键和值都可变的映射。这仅仅是用于展示，Core和标准库都提供了命令式字典，在现实的任务中，你应该使用那些实现。[第13章](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_13_maps_and_hash_tables.md)有更多使用Core实现的建议。

我们现在描述的字典，和Core及标准库中的一样，将使用哈希表实现。我们将使用*开放哈希*，一个哈希表是一个存储单元(bucket)的数组，每个存储单元包含一个键/值序对的列表。

下面是以mli文件形式提供的接口。类型`('a, 'b) t`表示一个字典键类型为`'a`，值类型为`'b`：
```ocaml
(* file: dictionary.mli *)
open Core.Std

type ('a, 'b) t

val create : unit -> ('a, 'b) t
val length : ('a, 'b) t -> int
val add  : ('a, 'b) t -> key:'a -> data:'b -> unit
val find  : ('a, 'b) t -> 'a -> 'b option
val iter  : ('a, 'b) t -> f:(key:'a -> data:'b -> unit) -> unit
val remove : ('a, 'b) t -> 'a -> unit
```

### Primitive Mutable Data
#### Array-Like Data
#### Mutable Record and Object Fields and Ref Cells
#### Foreign Functions

### for and while Loops

### Example: Doubly Linked Lists
#### Modifying the List
#### Iteration Functions

### Laziness and Other Benign Effects
#### Memoization and Other Dynamic Programming

### Input and Output
#### Terminal I/O
#### Formatted Output with printf
#### File I/O

### Side Effects and Weak Polymorphism
#### The Value Restriction
#### Partial Application and the Value Restriction
#### Relaxing the value Restriction

### Summary
