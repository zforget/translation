## 第八章 命令式编程 ##

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
`insert_first`首先定义了一个新元素`new_elt`，然后将其连到列表上，最后把列表本身指向`new_elt`。注意`match`语句的优先级是非常低的，为了和后面的赋值语句（`t := Some new_elt`）分开，我们使用`begin ... end`将其包围。我们也可以使用小括号达到同样的目的。如果没有某种形式的括号，最后的赋值会错误地成为`None`分支的一部分。

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

上面的函数比看起来要脆弱得多。错误使用接口可能导致毁坏的数据。如，重复删除一个元素会导致列表的主引用被置为`None`，这会清空列表。删除一个列表中不存在的列表也会导致类似的问题。

也并不意外。复杂的数据结构肯定更难处理，比其纯函数式的替代需要更多技巧。前面说的问题可以通过更小心的错误检查来处理，且这样的错误在Core的`Doubly_linked`模块中都得到了小心处理。你应该尽可能地使用设计良好的库中的命令式数据结构。如果不行，你应该确保在错误处理上加倍小心。

#### 迭代函数
当定义列表、字典和树这样的容器时，你通常需要定义一组迭代函数，如`iter`、`map`和`fold`，使用它们来简洁地表达通用迭代模式。

`Dlist`有两个这种迭代器：`iter`，目标是按顺序在列表的每一个元素上调用一个产生`unit`的函数；还有`find_el`，在列表的每一个元素这运行一个测试函数，返回第一个通过测试的元素。`iter`和`find_el`都是用简单递归循环实现的，使用`next`从一个元素转到另一个元素，使用`value`提取给定节点的值：
```ocaml
let iter t ~f =
  let rec loop = function
	| None -> ()
	| Some el -> f (value el); loop (next el)
  in
  loop !t

let find_el t ~f =
  let rec loop = function
	| None -> None
	| Some elt ->
	  if f (value elt) then Some elt
	  else loop (next elt)
  in
  loop !t
```
这样我们的实现就完成了，但是要得到一个真正实用的双向链表还有相当多的工作要做。如前所述，你最好使用像Core的`Doubly_link`这样的模块，它们更完整，也处理了更多棘手问题。尽管如此，本例还是展示了OCaml中你可以用来构建重要命令式数据结构的技术，同时还有陷阱。


### 惰性和温和影响
>> Laziness and Benign Effects

很多时候，你都想基本上用纯函数式风格编程，只有限地使用副作用来提高代码效率。这种副作用有时称为 *温和影响*，这是一种既能使用命令式特性又能保留纯函数式好处的很有用的方法。

最简单的温和影响就是 *惰性*。一个惰性值就是一个不真正使用不计算的值。在OCaml中，惰性值使用`lazy`关键字创建，它可以把一个类型为`s`的表达式转换成类型为`s Lazy.t`的惰性值。表达式的求值被推迟，直到强制调用`Lazy.force`：
```ocaml
# let v = lazy (print_string "performing lazy computation\n"; sqrt 16.);;
val v : float lazy_t = <lazy>
# Lazy.force v;;
performing lazy computation
- : float = 4.
# Lazy.force v;;
- : float = 4.
```
从`print`语句可以看出，实际的计算只运行了一次，在调用`force`之后。

为了更好地理解惰性的工作原理，我们一起来实现自己的惰性类型。我们首先声明一个类型来表示惰性值：
```ocaml
# type 'a lazy_state =
	| Delayed of (unit -> 'a)
	| Value of 'a
	| Exn of exn
  ;;
type 'a lazy_state = Delayed of (unit -> 'a) | Value of 'a | Exn of exn
```
`lazy_state`表示一个惰性值的可能状态。运行之前惰性值是`Delayed`，`Delayed`持有一个用于计算的函数。计算被强制执行完成并正常结束后惰性值是`Value`。当计算被强制执行，但抛出了异常时使用`Exn`实例。一个惰性值就是一个简单的`lazy_state`引用。`ref`使得可以从`Delayed`状态转换到`Value`或`Exn`。

我们可以从一个代码块创建一个惰性值，即，一个接收一个`unit`参数的函数。把表达式包装在一个代码块中是另一种暂停计算表达式的方式：
```ocaml
# let create_lazy f = ref (Delayed f);;
val create_lazy : (unit -> 'a) -> 'a lazy_state ref = <fun>
# let v = create_lazy
(fun () -> print_string "performing lazy computation\n"; sqrt 16.);;
val v : float lazy_state ref = {contents = Delayed <fun>}
```
现在我们只要一个强制执行惰性值的方法。下面代码即可做到：
```ocaml
# let force v =
	match !v with
	| Value x -> x
	| Exn e -> raise e
	| Delayed f ->
	try
	  let x = f () in
	  v := Value x;
	  x
	with exn ->
	  v := Exn exn;
	  raise exn
;;
val force : 'a lazy_state ref -> 'a = <fun>
```
我们可以使用`Lazy.force`一样来使用它：
```ocaml
# force v;;
performing lazy computation
- : float = 4.
# force v;;
- : float = 4.
```
我们实现的和内建惰性之间用户能看到的不同就是语法。相对于`create_lazy (fun () -> sqrt 16.)`，我们（使用内建的`lazy`）只写`lazy (sqrt 16.)`就可以了。	

#### 记忆和动态编程
>> Memoization and Other Dynamic Programming

另一个温和影响是 *记忆*。一个记忆函数可以记住之前调用的结果，因此之前调用的参数再次出现时，就可以直接返回而不用继续计算。

这里有一个函数接收任意一个单参数函数为参数，返回其记忆版本。这里我们使用了Core的`Hashtbl`模块，而没有使用我们自己的玩具`Dictionary`：
```ocaml
# let memoize f =
    let table = Hashtbl.Poly.create () in
    (fun x ->
      match Hashtbl.find table x with
      | Some y -> y
      | None ->
        let y = f x in
        Hashtbl.add_exn table ~key:x ~data:y;
        y
    );;
val memoize : ('a -> 'b) -> 'a -> 'b = <fun>
```
上面的代码有点技巧。`memoize`接收一个函数`f`作为参数，然后分配一个哈希表（叫`table`）并返回一个新的函数作为`f`的记忆版本。当新函数被调用时，先查表，查找失败才会调用`f`并把结果存到`table`中。只要`memoize`返回的函数在作用域内，`table`就有效。

当函数重新计算很昂贵且你不介意无限缓存旧结果时，记忆非常有用。重要警告：记忆函数天生就是内存泄漏。只要你使用记忆函数，你就持有了其到目前为止的每一个返回结果。

记忆也用于高效实现一些递归算法。计算两个字符串的编辑距离（也称Levenshtein距离）是一个很好的例子。编辑距离是把一个字符串转换为另一个字符串所需要的单字节修改（包括字母变化、插入和删除）次数。这种距离度量可用于各种近似字符串匹配问题，如拼写检查。

考虑下面计算编辑距离的代码。这里了解算法不是重点，但你要注意递归调用结构：
```ocaml
# let rec edit_distance s t =
    match String.length s, String.length t with
    | (0,x) | (x,0) -> x
    | (len_s,len_t) ->
      let s' = String.drop_suffix s 1 in
      let t' = String.drop_suffix t 1 in
      let cost_to_drop_both =
        if s.[len_s - 1] = t.[len_t - 1] then 0 else 1
      in
      List.reduce_exn ~f:Int.min
        [ edit_distance s' t  + 1
        ; edit_distance s  t' + 1
        ; edit_distance s' t' + cost_to_drop_both
        ]
  ;;
val edit_distance : string -> string -> int = <fun>
# edit_distance "OCaml" "ocaml";;
- : int = 2
```
注意当调用`edit_distance "OCaml" "ocaml"`时，会按顺序分配下面的调用：
```ocaml
edit_distance "OCam" "ocaml"
edit_distance "OCaml" "ocam"
edit_distance "OCam" "ocam"
```
这样又会按顺序分配其它的调用：
```ocaml
edit_distance "OCam" "ocaml"
   edit_distance "OCa" "ocaml"
   edit_distance "OCam" "ocam"
   edit_distance "OCa" "ocam"
edit_distance "OCaml" "ocam"
   edit_distance "OCam" "ocam"
   edit_distance "OCaml" "oca"
   edit_distance "OCam" "oca"
edit_distance "OCam" "ocam"
   edit_distance "OCa" "ocam"
   edit_distance "OCam" "oca"
   edit_distance "OCa" "oca"
```
如你所见，这些调用中有一些是重复的。如有两个不同的`edit_distance "OCam" "oca"`调用。随着字符串大小的增长冗余数以指数级增加，这意味着我们的`edit_distance`在处理大字符串时非常非常慢。我们可以通过写一个简单计时函数来看一下：
```ocaml
# let time f =
    let start = Time.now () in
    let x = f () in
    let stop = Time.now () in
    printf "Time: %s\n" (Time.Span.to_string (Time.diff stop start));
    x ;;
val time : (unit -> 'a) -> 'a = <fun>
```
我们现在可以用这个函数来试验一些例子：
```ocaml
# time (fun () -> edit_distance "OCaml" "ocaml");;
Time: 1.40405ms
- : int = 2
# time (fun () -> edit_distance "OCaml 4.01" "ocaml 4.01");;
Time: 6.79065s
- : int = 2
```
几个额外字符就能导致慢几千倍。

这里记忆就可以帮上大忙了，但要修复这个问题，我们要记住`edit_distance`对其自己的调用。这种技术有时被称作动态编程。为了弄明白如何做，我们把`edit_distance`放一边，先考虑一个简单得多的例子：计算斐波纳契数列的第`n`个元素。斐波纳契数列定义为，以两个`1`开始，后续元素是前面两个的和。经典的递归计算如下：
```ocaml
# let rec fib i =
    if i <= 1 then 1 else fib (i - 2) + fib (i - 1);;
```
但是这个实现指数级地慢，和`edit_distance`慢的原因相同：我们对`fib`做了很多重复调用。性能方面相当有明显：
```ocaml
# time (fun () -> fib 20);;
Time: 0.844955ms
- : int = 10946
# time (fun () -> fib 40);;
Time: 12.7751s
- : int = 165580141
```
如你所见，`fib 40`比`fib 20`慢了几千倍。

那么，我们如何使用记忆来加速呢？技巧就是我们需要在fib中的递归调用前插入记忆。我们不能以普通方式定义`fib`然后再记忆它以期待`fib`的第一个调用被提升：
```ocaml
# let fib = memoize fib;;
val fib : int -> int = <fun>
# time (fun () -> fib 40);;
Time: 12.774s
- : int = 165580141
# time (fun () -> fib 40);;
Time: 0.00309944ms
- : int = 165580141
```
为了加速`fib`，第一步我们将展开递归来重写`fib`。下面的版本需要其第一参数是一个函数（叫作`fib`），用它来替换每一个递归调用：
```ocaml
# let fib_norec fib i =
    if i <= 1 then i
    else fib (i - 1) + fib (i - 2) ;;
val fib_norec : (int -> int) -> int -> int = <fun>
```
现在我们可以连接递归节点(recursive knot)来把它转成一个普通的斐波纳契函数：
```ocaml
# let rec fib i = fib_norec fib i;;
val fib : int -> int = <fun>
# fib 20;;
- : int = 6765
```
我们甚至可以定义一个叫`make_rec`的多态函数以这种形式来连接任何函数的递归节点：
```ocaml
# let make_rec f_norec =
    let rec f x = f_norec f x in
    f
;;
val make_rec : (('a -> 'b) -> 'a -> 'b) -> 'a -> 'b = <fun>
# let fib = make_rec fib_norec;;
val fib : int -> int = <fun>
# fib 20;;
- : int = 6765
```
这是一段奇怪的代码，要弄清楚需要多考虑一会儿。像`fib_norec`一样，传递给`make_rec`的函数`f_norec`不是递归的，但是接收并调用一个函数参数。`make_rec`的本质是把`f_norec`喂给它自己，从面形成了一个真正的递归函数。

这种做法挺聪明的，但我们真正要做的是要找到一种方法来实现之前的很慢的斐波纳契函数。要使它更快，我们需要一个`make_rec`的变体，可以在绑定递归节点时插入记忆。我们称之为`memo_rec`：
```ocaml
# let memo_rec f_norec x =
    let fref = ref (fun _ -> assert false) in (* 下面这几句是创建递归的一种方法，此函数是占位用的。 zhaock *)
    let f = memoize (fun x -> f_norec !fref x) in
    fref := f;
    f x
  ;;
val memo_rec : (('a -> 'b) -> 'a -> 'b) -> 'a -> 'b = <fun
```
注意`memo_rec`和`make_rec`签名相同。

这里我们用引用来连接递归节点，而不是`let rec`，原因我们稍后讨论。

使用`memo_rec`，现在我们可以构建`fib`的高效版本了：
```ocaml
# let fib = memo_rec fib_norec;;
val fib : int -> int = <fun>
# time (fun () -> fib 40);;
Time: 0.0591278ms
- : int = 102334155
```
可以看到，指数级的时间复杂度消失了。

记忆行为在这里很重要。如果回头看一下`memo_rec`的定义，你会看到调用`memo_rec lib_norec`没有触发`memoize`调用。只有`fib`被调用从而`memo_rec`最终的参数确定时，`memoize`才会被调用。调用结果在`fib`返回时就超出作用域了，所以调用`memo_rec`不会有内存泄漏--记忆表在计算结束时被回收了。

我们可以把`memo_rec`作用一个单独声明的一部分，这让它看起来更像是`let rec`的一种特殊形式：
```ocaml
# let fib = memo_rec (fun fib i ->
    if i <= 1 then 1 else fib (i - 1) + fib (i - 2));;
val fib : int -> int = <fun>
```
用记忆来实现斐波纳契有点小题大作了，实际上，上面的`fib`也不是特别高效，需要按传给`fib`的数线性分配空间。写一个只用常数空间的斐波纳契函数是很容易的。

但是对于`edit_distance`，记忆却是一个好方法，我们可以使用和`fib`一样的方法。我们需要修改一下`edit_distance`使它把一对字符串接收为一个参数，因为`memo_rec`只能作用于单参数函数上。（我们总是可以使用封装函数来覆盖原始接口。）这样的修改加上`memo_rec`的调用，我们就得到了一个有记忆版的`edit_distance`:
```ocaml
# let edit_distance = memo_rec (fun edit_distance (s,t) ->
    match String.length s, String.length t with
    | (0,x) | (x,0) -> x
    | (len_s,len_t) ->
      let s' = String.drop_suffix s 1 in
      let t' = String.drop_suffix t 1 in
      let cost_to_drop_both =
        if s.[len_s - 1] = t.[len_t - 1] then 0 else 1
      in
      List.reduce_exn ~f:Int.min
        [ edit_distance (s',t ) + 1
        ; edit_distance (s ,t') + 1
        ; edit_distance (s',t') + cost_to_drop_both
        ]) ;;
val edit_distance : string * string -> int = <fun>
```
新版的`edit_distance`比之前的要高效得多；下面的调用比没有记忆的版本快了几千倍：
```ocaml
# time (fun () -> edit_distance ("OCaml 4.01","ocaml 4.01"));;
Time: 0.500917ms
- : int = 2
```

> **`let rec`的局限性**
>
> 你可能想知道，在`memo_rec`中连接递归节点时为什么不像先前`make_rec`中那样使用`let rec`。代码如下：
> ```ocaml
> # let memo_rec f_norec =
>     let rec f = memoize (fun x -> f_norec f x) in
>     f
>  ;;
> Characters 39-69:
> Error: This kind of expression is not allowed as right-hand side of `let rec'
> ```
> OCaml拒绝了这个定义，因为OCaml是一种强类型语言，对可以放在`let rec`右边的东西有限制。想像下面的代码会如何编译：
> ```ocaml
> let rec x = x + 1
> ```
> 注意`x`是一个普通值，不是函数。因此编译器会如何处理这个定义并不清楚。你可能以为它会被编译成一个无限循环，但`x`是`int`型的，又不存在一个和无限循环相对应的`int`。因此，这个结构是绝对无法编译的。
>
> 要避免这种不可能的情况，编译器在`let rec`右边只允许三种结构：一个函数定义，一个构造函数，或一个惰性值。这排除了一些合理的东西，如我们的`memo_rec`定义，但它同样也挡住了不合理的东西，像我们对`x`的定义。
>
> 值得一提的是在一种像Haskell这样的惰性语言中不会有这个问题。实际上，我们可以使用OCaml的惰性特性使类似上面`x`的定义可行：
> ```ocaml
> # let rec x = lazy (Lazy.force x + 1);;
> val x : int lazy_t = <lazy>
> ```
> 当前，真的试图计算会失败。Ocaml的`lazy`在一个惰性值试图把强制求值自己作用计算的一部分时会抛异常.
> ```ocaml
> # Lazy.force x;;
> Exception: Lazy.Undefined.
> ```
> 但我们还是可以用`lazy`创建有用的递归定义。实际上，我们可以用惰性来定义我们的`memo_rec`，而不是显式修改：
> ```ocaml
> # let lazy_memo_rec f_norec x =
>     let rec f = lazy (memoize (fun x -> f_norec (Lazy.force f) x)) in
>     (Lazy.force f) x
>   ;;
> val lazy_memo_rec : (('a -> 'b) -> 'a -> 'b) -> 'a -> 'b = <fun>
> # time (fun () -> lazy_memo_rec fib_norec 40);;
> Time: 0.0650883ms
> - : int = 102334155
> ```
> 惰性比显式修改有更多的约束，所以有时会使代码更易懂。


### 输入输出
命令式编程可不只修改内存数据这么些。任何参数和返回值没有确实转换关系的函数本质都是命令式的。这不仅包括修改你的程序数据，还有和程序外部世界交互的操作。其中一个重要例子就是I/O，即从文件、终端输入输出和网络套接字读写数据的操作。

OCaml中有好几个I/O库。本节我们要讨论OCaml带缓存的I/O库，可以通过Core的`In_channel`和`Out_channel`模块使用。其它I/O原语可以通过Core的`Unix`模块和`Async`获得，异步I/O库在[18章](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_18_concurrent_programming_with_async.md)介绍。Core的`In_channel`和`Out_channel`模块（包括`Unix`模块）的多数功能都源于标准库，但此处我们会使用Core的接口。

#### 终端I/O
OCaml的带缓存I/O库围绕两个类型组织：`in_channel`，用以读取的通道，和`out_channel`，用以写入的通道。`In_channel`和`Out_channel`模块只直接支持文件和终端相关的通道，其它类型的通道可以通过`Unix`模块创建。

我们对I/O的讨论先聚焦于终端。沿用Unix模型，和终端的通信组织成三个通道，分别对应于Unix中的三个标准文件描述符：
- In_channel.stdin
  标准输入通道。默认是来自终端的输入，处理键盘输入。
- Out_channel.stdout
  标准输出通道。默认向用户终端的`stdout`的输出。
- Out_channel.stderr
  标准错误通道。和`stdout`类似，但是目标为了错误消息。

`stdin`、`stdout`和`stderr`非常有用，以至于它们可以在全局作用域中直接使用，不需要通过`In_channel`和`Out_channel`模块。

让我们看一下它们在一个简单命令式程序中的应用。下面的程序，`time_converter`，提示用户输入一个时区，然后打印那个时区的当前时间。这里，我们使用了Core的`Zone`模块地查询时区，用`Time`模块来计算当前时间并以相应的时区打印出来：
```ocaml
(* 本例中Zone似乎要使用Core.Zone *)
open Core.Std

let () =
  Out_channel.output_string stdout "Pick a timezone: ";
  Out_channel.flush stdout;
  match In_channel.input_line stdin with
  | None -> failwith "No timezone provided"
  | Some zone_string ->
    let zone = Zone.find_exn zone_string in
    let time_string = Time.to_string_abs (Time.now ()) ~zone in
    Out_channel.output_string stdout
      (String.concat
        ["The time in ";Zone.to_string zone;" is ";time_string;".\n"]);
    Out_channel.flush stdout
```
我们可以使用corebuild构建程序并运行之。你会看到它提示你输入，如下所示：
```bash
$ corebuild time_converter.byte
$ ./time_converter.byte
Pick a timezone:
```
然后你可以输入一个时区名按回车，它就会打印出那个时区的当前时间：
```bash
Pick a timezone: Europe/London
The time in Europe/London is 2013-08-15 00:03:10.666220+01:00.
```
我们在`stdout`上调用`Out_channel.flush`，因为`out_channel`是带缓存的，就是说OCaml不会每次调用`outpt_string`后立即执行一个写操作。而是将写操作缓存，直到写了足够多从而触发了缓存刷新，或是显式请求了一个刷新操作。通过减少系统调用次数极大增加了写处理的效率。

注意`In_channel.input_line`返回一个字符串`option`，`None`表示输入流结束（即，一个文件结束条件）。`Out_channel.output_string`用以打印最后的输出，并调用`Out_channel.flush`把输出刷新到屏幕上。最后的那个刷新技术上说是不需要的，因为程序接着就结束了，此时所有剩余的输出都会被刷新，但显式的刷新仍不失为一个好实践。

#### 使用`printf`格式化输出
像`Out_channel.output_string`这样的生成输出的函数很简单且容易理解，但是有点冗长。OCaml也支持使用`printf`函数格式化输出，它仿照了C语言标准库中的`printf`。`printf`接收一个描述打印内容和格式的格式化字符串，还有要打印的参数，由格式化字符串中的格式化指令确定。然后，我们就可以写出以下例子：
```ocaml
# printf "%i is an integer, %F is a float, \"%s\" is a string\n"
    3 4.5 "five";;
3 is an integer, 4.5 is a float, "five" is a string
- : unit = ()
```
和C语言的`printf`不同，OCaml中的`printf`是类型安全的。如果我们提供一个和格式化字符串中的类型不匹配的参数，会得到一个类型错误：
```ocaml
# printf "An integer: %i\n" 4.5;;
Characters 26-29:
Error: This expression has type float but an expression was expected of type
int
```
-----
##### 理解格式化字符串
`printf`中使用的格式化字符串和普通的字符串有很大的不同。这种不同是因为OCaml中的格式化字符串，不像C语言中的，是类型安全的。编译器会检查格式化字符中引用的类型和`printf`其余参数类型的匹配。

为了检查这一点，OCaml需要在编译期分析格式化字符串的内容，这意味着格式化字符串需要在编译期就是一个可获得的字符串常量。实际上，如果你试图传递一个普通字符串给`printf`，编译器会报错：
```ocaml
# let fmt = "%i is an integer, %F is a float, \"%s\" is a string\n";;
val fmt : string = "%i is an integer, %F is a float, \"%s\" is a string\n"
# printf fmt 3 4.5 "five";;
Characters 9-12:
Error: This expression has type string but an expression was expected of type
         ('a -> 'b -> 'c -> 'd, out_channel, unit) format =
           ('a -> 'b -> 'c -> 'd, out_channel, unit, unit, unit, unit)
           format6
```
如果OCaml推导出一个给定的字符串是一个格式化字符串，它就会在编译期解析它，根据找到的格式化指令选择其类型。因此，如果我们添加一个类型注释表明我们定义的字符串实际上是一个格式化字符串，它就会被像下面这样解释：
```ocaml
# let fmt : ('a, 'b, 'c) format =
    "%i is an integer, %F is a float, \"%s\" is a string\n";;
val fmt : (int -> float -> string -> 'c, 'b, 'c) format = <abstr>
```
于是我们可以把它传给`printf`：
```ocaml
# printf fmt 3 4.5 "five";;
3 is an integer, 4.5 is a float, "five" is a string
- : unit = ()
```
如果这看起来和你之前看到的不一同样，那是因为它确实不一样。这确实是类型系统的特例。大多数时候，你不需要关心这种对格式化字符串的特殊处理--你可以使用`printf`而无需关心细节。但脑子里对这一点有一个大体印象还是有用的。

-----

现在看看可以如何使用`printf`重写时间转换程序，使它更简洁一点：
```ocaml
open Core.Std

let () =
  printf "Pick a timezone: %!";
  match In_channel.input_line stdin with
  | None -> failwith "No timezone provided"
  | Some zone_string ->
    let zone = Zone.find_exn zone_string in
    let time_string = Time.to_string_abs (Time.now ()) ~zone in
    printf "The time in %s is %s.\n%!" (Zone.to_string zone) time_string
```
上例中，我们只使用两个格式化指令：`%s`，用以包含一个字符串，和`%!`，使`printf`刷新通道。

`printf`的格式化指令提供了很多控制，让你可以指定下面的内容：
- 对齐和填充
- 字符串转义规则
- 数字应该格式化为十进制、十六进制还是二进制
- 浮点转换精度

还有一些类`printf`的函数，输出目标不是`stdout`，包括：
- `eprintf`，打印到`stderr`
- `fprintf`，打印到任意通道
- `sprintf`，返回一个格式化的字符串

这些，还有更多的内容，在OCaml手册的`Printf`模块API文档中都有描述。

#### 文件I/O
`in_channel`和`out_channel`另一个常见应用是和文件一起使用。这里有几个函数--一个创建一个全是数字的文件，另一个从这个文件中读取并返回这些数字的和：
```ocaml
# let create_number_file filename numbers =
    let outc = Out_channel.create filename in
    List.iter numbers ~f:(fun x -> fprintf outc "%d\n" x);
    Out_channel.close outc
  ;;
val create_number_file : string -> int list -> unit = <fun>
# let sum_file filename =
    let file = In_channel.create filename in
    let numbers = List.map ~f:Int.of_string (In_channel.input_lines file) in
    let sum = List.fold ~init:0 ~f:(+) numbers in
    In_channel.close file;
    sum
  ;;
val sum_file : string -> int = <fun>
# create_number_file "numbers.txt" [1;2;3;4;5];;
- : unit = ()
# sum_file "numbers.txt";;
- : int = 15
```
这两个函数都使用相同的基本流程：先创建通道，然后使用通道，最后关闭通道。关闭通道很重要，要不然，就不会释放文件背后相关的操作系统资源。

上面代码的问题是如果中间抛出异常，通道就不会关闭。如果读一个实际上不包含数字的文件，就会得到一个错误：
```ocaml
# sum_file "/etc/hosts";;
Exception: (Failure "Int.of_string: \"127.0.0.1 localhost\"").
```
如果我们在一个循环里一遍一遍这样做，最终会耗尽文件描述符：
```ocaml
# for i = 1 to 10000 do try ignore (sum_file "/etc/hosts") with _ -> () done;;
- : unit = ()
# sum_file "numbers.txt";;
Exception: (Sys_error "numbers.txt: Too many open files").
```
现在，要打开更多文件你就必须要重启toplevel。

要避免这种情况，你就要保证你的代码在调用后会完成清理工作。我们可以用[第七章](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_07_error_handling.md)中描述的`protect`函数来做到这一点，如下所示：
```ocaml
# let sum_file filename =
    let file = In_channel.create filename in
    protect ~f:(fun () ->
        let numbers = List.map ~f:Int.of_string (In_channel.input_lines file) in
        List.fold ~init:0 ~f:(+) numbers)
    ~finally:(fun () -> In_channel.close file)
  ;;
val sum_file : string -> int = <fun>
```
现在文件描述符就不会泄漏了。
```ocaml
# for i = 1 to 10000 do try ignore (sum_file "/etc/hosts") with _ -> () done;;
- : unit = ()
# sum_file "numbers.txt";;
- : int = 15
```
这这例子是命令式编程中的一个普遍问题。使用命令式编程时，你需要特别小心，不要让异常破坏程序的状态。

`In_channel`有一些函数可以自动处理其中的一些细节。如，`In_channel.with_file`接收一个文件名和一个处理`in_channel`中数据的函数，会小心处理相关的打开和关闭操作。我们可以使用它重写`sum_file`，如下所示：
```ocaml
# let sum_file filename =
    In_channel.withfile filename ~f:(fun file ->
      let numbers = List.map ~f:Int.of_string (In_channel.input_lines file) in
      List.fold ~init:0 ~f:(+) numbers)
  ;;
```
我们的`sum_file`实现的另一个不足是我们在处理之前就把整个文件读入内存。对于巨大的文件，一次处理一行更高效。你可以使用`In_channel.fold_lines`函数来做到一点：
```ocaml
# let sum_file filename =
    In_channel.with_file filename ~f:(fun file ->
      In_channel.fold_lines file ~init:0 ~f:(fun sum line ->
        sum + Int.of_string line))
  ;;
val sum_file : string -> int = <fun>
```
这里只是小试了一下`In_channel`和`Out_channel`。要有更完整的理解，你应该去看这些模块的API文档。

### 求值顺序

### Side Effects and Weak Polymorphism
#### The Value Restriction
#### Partial Application and the Value Restriction
#### Relaxing the value Restriction

### Summary
