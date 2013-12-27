## 第八章 命令式编程
到目前为止，本书所示的大部分代码，实际上，应该是一般的OCaml代码，都是*纯函数式*的。纯函数式代码不会修改程序内部状态，没有I/O操作，不去读时钟，也不会以其它方式与外部的可变部分交互。因此一个纯函数行为类似一个数学方程式，对给定的输入总是会返回相同的结果，除了返回值之外对外部没有任何影响。另一方面，*命令式*代码通过副作用运作，修改程序内部状态或与外部交互。命令式函数有新的作用，并潜在每次调用返回不同的值的可能。

OCaml中默认的是函数式代码，原因是容易推导、错误更少且可组合性更好。但对于实用的编程语言来说，命令式代码有根本的重要性，因为现实世界的任务要求你与外部交互，这是其本性。命令式编程在性能方面也很重要。尽管OCaml中的纯函数代码很高效，但有许多算法只能用命令式技术高效实现。

在这方面OCaml提供了今人满意的折衷，使纯函数式编程容易且自然的同时，也对命令式编程提供了良好的支持。本章会带你领略OCaml的命令式特性，帮助你更好地使用他们。

### 例子：命令式字典
我们以一个简单的命令式字典开始，即，一个键和值都可变的映射。这仅仅是用于展示，Core和标准库都提供了命令式字典，在现实的任务中，你应该使用那些实现。[第13章](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_13_maps_and_hash_tables.md)有更多使用Core实现的建议。

我们现在描述的字典，和Core及标准库中的一样，将使用哈希表实现。我们将使用*开放哈希*，一个哈希表是一个存储单元(bucket)的数组，每个存储单元包含一个键/值序对的列表。

下面是以mli文件形式提供的接口。类型`('a, 'b) t`表示一个键类型为`'a`，值类型为`'b`的字典：
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
mli文件中还包含一组辅助函数，其目的和行为可以从名字和类型签名中猜个八九不离十。注意有多个函数，像添加和修改字典的函数，都返回`unit`。这些是典型地通过副作用发挥作用的函数。

现在我们一块块地过一下实现（包含在ml文件中），解释遇到各种命令式构造。

第一步是把字典类型定义成一个有两个字段的记录：
```ocaml
(* file: dictionary.ml *)
open Core.Std

type ('a, 'b) t = { mutable length: int;
                    buckets: ('a * 'b) list array;
                  }
```
第一个字段`length`被声明成可变的。在OCaml中，记录默认是不可变的，但是单独的字段可以标记成可变的。第二个字段`buckets`是不可变的，但是包含了一个数组，这个数组本身就是个可变数据结构。

现在我们开始组建操作字典的基本函数：
```ocaml
let num_buckets = 17

let hash_bucket key = (Hashtbl.hash key) mod num_buckets

let create () =
  { length = 0;
    buckets = Array.create ~len:num_buckets [];
  }

let length t = t.length

let find t key =
  List.find_map t.buckets.(hash_bucket key)
    ~f:(fun (key',data) -> if key' = key then Some data else None)
```
注意`num_buckets`是个常数，意味着我们桶数组是定长的。一个实际的实现需要随着字典元素的增加而增长这个数组，但此处为了简化我们忽略这一点。

`hash_bucket`函数在模块的其余部分都要使用，用以选择一个给定的键在数组中的存储位置。基于`Hashtbl.hash`实现，这是一个OCaml运行时提供的函数，可以用在任何类型上。因此其自身的类型是多态的：`'a -> int`。

上面定义的其它函数就相当明了了：

- `create`  
    创建一个空字典。
- `length`  
  从相应的记录字段中提取长度，返回保存在字典中的元素数。
- `find`  
  在表中查找一个键，如果找到就以`option`类型返回相关的值。

`find`中展示了另一个重要的命令式语法：我们用`array.(index)`来提取数组的值。`find`也用到了`List.find_map`，你可以在toplevel中查看其类型:
```ocaml
# List.find_map;;
- : 'a list -> f:('a -> 'b option) -> 'b option = <fun>
```
`List.find_map`迭代一个列表的元素，对每一个条目调用`f`直到`f`返回`Some`，然后返回这个值。如果对所有的值`f`都返回`None`，那么就返回`None`。

现在我们来看看`iter`的实现：
```ocaml
let iter t ~f =
  for i = 0 to Array.length t.buckets - 1 do
    List.iter t.buckets.(i) ~f:(fun (key, data) -> f ~key ~data)
done
```
`iter`被设计为遍历字典中的所有条目。`iter t ~f`会对字典中的每个键/值对调用`f`。注意`f`必须返回`unit`，因为它以副作用而不是返回值起作用，且整个`iter`也返回`unit`。

`iter`代码用到了两种迭代：用`for`循环遍历数组元素；里面还有一个循环调用`List.iter`遍历给定的数组元素。你可以使用递归函数来代替外层的`for`循环，但`for`循环在语法上更方便，且在命令式编程中更熟悉也更常用。

下面代码是从一个字典添加和删除映射：
```ocaml
let bucket_has_key t i key =
  List.exists t.buckets.(i) ~f:(fun (key',_) -> key' = key)

let add t ~key ~data =
  let i = hash_bucket key in
  let replace = bucket_has_key t i key in
  let filtered_bucket =
    if replace then
      List.filter t.buckets.(i) ~f:(fun (key',_) -> key' <> key)
    else
      t.buckets.(i)
  in
  t.buckets.(i) <- (key, data) :: filtered_bucket;
  if not replace then t.length <- t.length + 1

let remove t key =
  let i = hash_bucket key in
  if bucket_has_key t i key then (
    let filtered_bucket =
      List.filter t.buckets.(i) ~f:(fun (key',_) -> key' <> key)
    in
    t.buckets.(i) <- filtered_bucket;
    t.length <- t.length - 1
  )
```
上面的代码更复杂一些，因为我们需要检查是不是在重写或删除已存在的绑定，以确定是否需要修改`t.length`。辅助函数`bucket_has_key`即用于此。

`add`和`remove`都展示了一个语法：使用`<-`操作符更新数组元素（`arrray.(i) <- expr`）以及更新一个记录字段(`record.field <- expression`)。

我们也用到了`;`，顺序操作符，用以表达命令式操作序列。我们可以使用`let`达到同样的目的：
```ocaml
let () = t.buckets.(i) <- (key, data) :: filtered_bucket in
  if not replace then t.length <- t.length + 1
```
但`;`更简洁也更符合习惯。更一般地,
```ocaml
<expr1>;
<expr2>;
...
<exprN>
```
等价于
```ocaml
let () = <expr1> in
let () = <expr2> in
...
<exprN>
```
当表达式序列`expr1; expr2`被求值时，`expr1`先求值，然后是`expr2`。表达式`expr1`类型应该是`unit`（尽管这只是个警告，而不是强制的。编译标志`-strict-sequence`会把这一点变为硬性要求，这通常是个好注意），`expr2`的返回的类型即是整个序列的类型。如，序列`print_string "hello world"; 1 + 2`先打印"hello world"，然后返回整数3。

注意我们把所有副作用操作都放到每个函数的末尾执行。这是一个好的实践，因为这样最小化了这些操作被异常打断从而使数据结构状态不一致的机会。

### 原生的可变数据
现在我们已经看过了一个完整例子，让我们更系统地看一个OCaml中的命令式编程。上面我们碰到了两种不同形式的可变数据：有可变字段的记录和数组。我们现在和其它OCaml中其它原生可变数据一起更深入讨论一下。
#### 类数组数据
OCaml支持好几种类数组数据结构，也就是以整数为索引的容器，提供了常数时间的元素访问操作。本节我们讨论其中几种：
##### 普通数组
`array`类型用以通用目的的多态数组。`Array`模块有大量和数组交互的工具函数，包括一些修改操作。这其中包括`Array.set`，用以设置一个单独元素，以及`Array.blit`，用以高效地在两个索引范围间拷贝数据。

`Array`也有特殊的语法用以从一个数组中提取元素：
```ocaml
<array_expr>.(<index_expr>)
```
也可以设置数组中的一个元素：
```ocaml
<array_expr>.(<index_expr>) <- <value_expr>
```
越界访问数组（实际上对所有类数组数据结构都一样）会抛出异常。

数组字面写法使用`[|`和`|]`作为分隔符。因此，`[| 1; 2; 3 |]`是一个字面整数数组。

##### 字符串
字符串本质上是字节数组，通常用在文本数据上。使用`string`而不是`Char.t array`（一个`Char.t`是一个8比特字符）的主要优势在于空间效率上；数组使用一个字--在64位系统上有8字节--来存储一个元素，而字符串每个字符只要一个字节。

字符串也有其自己的存取语法：
```ocaml
<string_expr>.[<index_expr>]
<string_expr>.[<index_expr>] <- <char_expr>
```
字符串字面值是用双引号包围的。同样也存在一个`String`模块，里面你可以找到字符串相关的有用函数。

##### Bigarrays
`Bigarray.t`是一个OCaml堆之外的内存块句柄。主要用以和C或Fortran交互，[第20章](https://github.com/zforget/translation/blob/master/real_world_ocaml/3_20_memory_representation_of_values.md)会讨论。Bigarray也有自己的存取语法：
```ocaml
<bigarray_expr>.{<index_expr>}
<bigarray_expr>.{<index_expr>} <- <value_expr>
```
#### 可变记录和对象字段以及引用单元(Ref Cells)
如我们所见，记录类型默认是不可变的，但是单独的记录字段却可以声明为可变的。这些可变字段可以用`<-`设置，即，`record.field <- expr`。

在[11章](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_11_objects.md)我们会看到，一个对象的字段也可以类似地声明成可变的，也可以用与修改记录字段相同的方法进行修改。

##### 引用单元
OCaml中的变量是永不可变的--它们可以引用可变数据，但变量指向的东西是不可以改变的。但有时，你确实想要和其它语言中一样的可变变量：定义一个单独的、可变的值。在OCaml中，通常可以通过使用`ref`来做到这一点，一个`ref`本质上是一个包含单独一个可变的多态字段的容器。

`ref`类型定义如下所示：
```ocaml
# type 'a ref = { mutable contents : 'a };;
type 'a ref = { mutable contents : 'a; }
```
标准库中定义了以下`ref`相关的操作符。

- `ref expr`  
    构造一个引用单元，包含一个由`expr`表达式定义的值。
- `!refcell`  
    返回引用单元的内容。
- `refcell := expr`  
    替换引用单元的内容。

你可以看一下如何使用：
```ocaml
# let x = ref 1;;
val x : int ref = {contents = 1}
#   !x;;
- : int = 1
#   x := !x + 1;;
- : unit = ()
#   !x;;
- : int = 2
```
上面都是普通的OCaml函数，可以像下面这样定义：
```ocaml
# let ref x = { contents = x };;
val ref : 'a -> 'a ref = <fun>
# let (!) r = r.contents;;
val ( ! ) : 'a ref -> 'a = <fun>
# let (:=) r x = r.contents <- x;;
val ( := ) : 'a ref -> 'a -> unit = <fun>
```
#### 外部函数
OCaml中另一部分命令式操作来自通过OCaml的外部函数接口（FFI）与外部库的交互。FFI使OCaml可以处理由系统调用或其它外部库导出的命令式结构。其中许多都是内建的，如访问`write`系统调用或访问时钟，而其它的则是来自用户库，像`LAPACK`绑定。OCaml的FFI会在[第19章](https://github.com/zforget/translation/blob/master/real_world_ocaml/3_19_foreign_function_interface.md)详细讨论。 

### `for`和`while`循环
OCaml支持传统的命令式循环结构，即`for`和`while`循环。它们都不是必须的，因为可以用递归函数模拟。然而，显式的`for`和`while`循环更简洁且在命令式编程中也更常用。

两者中`for`循环要简单些。实际上，我们已经用过`for`了--`Dictionary`中的`iter`函数中就是使用它创建的。这里有一个`for`的简单例子：
```ocaml
# for i = 0 to 3 do printf "i = %d\n" i done;;
i = 0
i = 1
i = 2
i = 3
- : unit = ()
```
可以看到，上下边界都是包含的。我们也可以使用`downto`来反向迭代：
```ocaml
# for i = 3 downto 0 do printf "i = %d\n" i done;;
i = 3
i = 2
i = 1
i = 0
- : unit = ()
```
注意`for`循环的循环变量，本例中即为`i`，在循环作用域中是不可变的，也是循环局部拥有的，即，不能在循环之外引用。

OCaml也支持`while`循环，它包含一个条件和一个主体。循环先求值条件，然后，如果求值结果为真，就求值主体并再次启动循环。下面是一个简单例子，就地反转一个数组：
```ocaml
# let rev_inplace ar =
    let i = ref 0 in
    let j = ref (Array.length ar - 1) in
    (* terminate when the upper and lower indices meet *)
    while !i < !j do
      (* swap the two elements *)
      let tmp = ar.(!i) in
      ar.(!i) <- ar.(!j);
      ar.(!j) <- tmp;
      (* bump the indices *)
      incr i;
      decr j
    done
  ;;
val rev_inplace : 'a array -> unit = <fun>
# let nums = [|1;2;3;4;5|];;
val nums : int array = [|1; 2; 3; 4; 5|]
# rev_inplace nums;;
- : unit = ()
# nums;;
- : int array = [|5; 4; 3; 2; 1|]
```
上例中，我们使用了`incr`和`decr`，它们是内建的函数，分别将一个`int ref`加一或减一。
### 例子：双向链表
另一个常见的命令式数据结构是双向链表。双向链表可以从两个方向遍历，元素的添加和删除是常数时间。Core定义了一个双向列表（模式名`Doubly_linked`），但我们为了演示还是要定义自己的双向链表。

这是模块的mli文件:
```ocaml
(* file: dlist.mli *)
open Core.Std

type 'a t
type 'a element

(** Basic list operations *)
val create  : unit -> 'a t
val is_empty : 'a t -> bool

(** Navigation using [element]s *)
val first : 'a t -> 'a element option
val next  : 'a element -> 'a element option
val prev  : 'a element -> 'a element option
val value : 'a element -> 'a

(** Whole-data-structure iteration *)
val iter  : 'a t -> f:('a -> unit) -> unit
val find_el : 'a t -> f:('a -> bool) -> 'a element option

(** Mutation *)
val insert_first : 'a t -> 'a -> 'a element
val insert_after : 'a element -> 'a -> 'a element
val remove : 'a t -> 'a element -> unit
```
注意这里有两个类型定义：`'a t`，列表类型；和`'a element`，元素类型。元素充当了列表的内部指针，允许你操作列表并给了你可以施加修改操作的地方。

现在让我们看一下实现。我们从定义`'a element`和`'a t`开始：
```ocaml
(* file: dlist.ml *)
open Core.Std

type 'a element =
  { value : 'a;
    mutable next : 'a element option;
    mutable prev : 'a element option
  }
  
type 'a t = 'a element option ref
```
`'a element`是一个记录，包含一个该节点存储的值，还有指向前一个和后一个元素的`option`（同时也是可变的）字段。在列表头，前导元素是`None`，在列表尾，后续元素是`None`。

列表自身的类型是一个`option`元素的可变引用。列表为空时这个引用是`None`，否则是`Some`。

现在我们可以定义操作列表和元素的基本函数了：
```ocaml
let create () = ref None
let is_empty t = !t = None

let value elt = elt.value

let first t = !t
let next elt = elt.next
let prev elt = elt.prev
```
我些都是从我们的类型定义中直接得出的。
> **循环数据结构**
> 
> 双向链表是循环数据结构，就是说可能沿着一个非平凡的指针序列可以接近自身。通常构建循环数据结构都要求副作用。先构建数据元素，然后使用向后赋值添加循环。
>
> 但有一个例外：你可以使用`let rec`构建固定长度的循环数据结构：
> ```ocaml
> # let rec endless_loop = 1 :: 2 :: 3 :: endless_loop;;
> val endless_loop : int list =
>   [1; 2; 3; 1; 2; 3; 1; 2; 3;
>    1; 2; 3; 1; 2; 3; 1; 2; 3;
>    1; 2; 3; 1; 2; 3; 1; 2; 3;
>    ...]
> ```
> 然而这种方法作用很有限。通用目的的循环数据结构需要能修改。

#### 修改列表
现在我们开始考虑修改列表的操作，从`insert_first`开始，它用以在列表头部插入一个元素：
```ocaml
let insert_first t value =
  let new_elt = { prev = None; next = !t; value } in
  begin match !t with
  | Some old_first -> old_first.prev <- Some new_elt
  | None -> ()
  end;
  t := Some new_elt;
  new_elt
```
`insert_first`首先定义了一个新元素`new_elt`，然后将其连到列表上，最后把列表本身指向`new_elt`。注意`match`语句的优先级是非常低的，为了和后面的赋值语句（`t := Some new_elt`）分开，我们使用`begin ... end`将其包围。我们也可以使用小括号达到同样的目的。如果没有某种括号，最后的赋值会错误地成为`None`分支的一部分。

我们可以使用`insert_after`在列表的元素后插入元素。`insert_after`以一个要在其后插入新节点的元素和一个要插入的值为参数：
```ocaml
let insert_after elt value =
  let new_elt = { value; prev = Some elt; next = elt.next } in
  begin match elt.next with
  | Some old_next -> old_next.prev <- Some new_elt
  | None -> ()
  end;
  elt.next <- Some new_elt;
new_elt
```
最后我们需要一个`remove`函数：
```ocaml
let remove t elt =
  let { prev; next; _ } = elt in
  begin match prev with
  | Some prev -> prev.next <- next
  | None -> t := next
  end;
  begin match next with
  | Some next -> next.prev <- prev;
  | None -> ()
  end;
  elt.prev <- None;
  elt.next <- None
```
上面的代码在前后元素存在时，小心地修改了后面元素的`prev`指针和前面元素的`next`指针。如果没有前导元素，要更新列表自身的指针。任何情况下，都要把被删除元素前导和后续元素指针设置为`None`。

这些函数比看起来要脆弱得多。错误使用接口可能导致毁坏的数据。如，重复删除一个元素会导致列表的主引用被置了`None`，这会清空列表。删除一个列表中不存在的列表也会导致类似的问题。

也并不意外。复杂的数据结构肯定更难处理，比其纯函数式的替代需要更多技巧。前面说的问题可以通过更小心的错误检查处理，且这样的错误在Core的`Doubly_linked`模块中都得到了小心处理。你应该尽可能地使用设计良好的库中的命令式数据结构。如果不行，你应该确保在错误上加倍小心。

#### 迭代函数
当定义列表、字典和树这样的容器时，你通常需要定义一组迭代函数，如`iter`、`map`和`fold`，使用它们来简洁地表达通用迭代模式。

`Dlist`有两个这种迭代器：`iter`，目标是按顺序在列表的每一个元素上调用一个产生`unit`的函数；还有`find_el`，在列表的每一个元素

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
