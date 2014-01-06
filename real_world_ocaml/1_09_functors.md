## 第九章 函子
到目前为止，我们已经看到OCaml的模块扮演了重要但受限的角色。实际上，我们已经知道它们可以作为一种机制，用以把代码组织到一些拥有自己接口的单元。但OCaml模块系统的作用远不止于此，它是构建通用代码和构造大型系统的强大工具。

笼统地说，函子是模块到模块的函数，它们可以用以解决大量的代码结构问题，包括：
- *依赖注入*  
  使系统的一些组件实现可替换。当你要为测试或模拟而制作系统中某部分的模型时，这一点特别有用。
- *自动扩展模块*  
  函子给了你一个用新功能扩展已有模块的标准方法。如，你可能想要基于一个基本比较函数来添加大量的比较运算符。手动做的话需要在每个类型上有大量重复代码，但函子让你可以只写一次就能应用到许多不同类型上。
- *带状态实例化模块*  
  模块可以包含可变状态，就是说你可能偶尔需要同一个模块的多个实例，每一个实例都有其独立的可变状态。函子使你可以将这种模块的构造自动化。
  
这仅仅是函子用途的一部分。此处我们不会试图提供函子所有用途的示例。相反，本章会尝试提供示例来展示为了更好地使用函子你需要掌握的语言特性和设计模式。

### 一个小例子
让我们创建一个函子，接收一个包含一个单独整数变量`x`的模块，返回一个新模块，其中的`x`加一。这样做的目的只是为了过一下函子的基本机制，在实际中你不会想要这种东西。

首先，我们给模块定义一个签名，包含一个单独的类型为`int`的值：
```ocaml
# module type X_int = sig val x : int end;;
module type X_int = sig val x : int end
```
现在可以定义我们的函子了。我们既使用`X_int`来约束函子的参数也用其来限制返回的模块：
```ocaml
# module Increment (M : X_int) : X_int = struct
    let x = M.x + 1
  end;;
module Increment : functor (M : X_int) -> X_int
```
立即就能发现函子在语法上比普通函数更重量级。一件事，就是函子要求显式的（模块）类型声明，而普通函数不需要。技术上说，只有输入类型是强制的，但在实践中，你也应该限制函子的返回值，就和mli文件一样，尽管这不是强制的。

下面代码展示了如果忽略函子的输出类型会如何：
```ocaml
# module Increment (M : X_int) = struct
    let x = M.x + 1
  end;;
module Increment : functor (M : X_int) -> sig val x : int end
```
可以看到推导出的输出模块类型现在显式写出了，而不是一个名为`X_int`签名。

我们可以使用`Increment`来定义新模块：
```ocaml
# module Three = struct let x = 3 end;;
module Three : sig val x : int end
# module Four = Increment(Three);;
module Four : sig val x : int end
# Four.x - Three.x;;
- : int = 1
```
这里，我们把`Increment`应用到一个签名和`X_int`完全相同的模块上。但就和ml内容必须满足mli一样，我们也可以把`Increment`应用到任何接口满足`X_int`的模块上。就是说模块类型可以忽略模块中的一个些信息，或是丢弃一些字段或是把某些字段保持为抽象的。示例如下：
```ocaml
# module Three_and_more = struct
    let x = 3
    let y = "three"
  end;;
module Three_and_more : sig val x : int val y : string end
# module Four = Increment(Three_and_more);;
module Four : sig val x : int end
```
判断一个模块是否匹配一个给定签名的规则，和面向对象语言中如何判断一个对象是否满足一个给定接口类似。和面向对象编程一样，不匹配签名的多余的信息（上例中即是变量`y`）只是被简单忽略了。

### 一个大点的例子：计算区间
让我们来考虑一个如何使用函子的更为实际的例子：一个用以计算区间的库。区间是一个通用的计算对象，对不同的类型有不同的内容。你可能需要计算浮点数或字符串或时间等的区间，每种情况下，你都需要类似的操作：空值测试、包含检查、相交区间等等。

让我们看一下如何使用函子来构建一个通用区间库，可以用于支持你想创建区间的基本集合的任意类型。

首先，我们定义一个模块类型来捕捉区间的端点信息。这个接口，我们称为`Comarable`，只包含两点：一个比较函数和一个被比较的值的类型：
```ocaml
# module type Comparable = sig
    type t
    val compare : t -> t -> int
  end ;;
module type Comparable = sig type t val compare : t -> t -> int end
```
比较函数遵循OCaml在此类函数上的标准惯用法，如果两个元素相等返回`0`，如果第一个元素大于第二个返回`1`，如果第一个元素小于第二个返回`-1`。因此，我们可以在`compare`的基础上重写标准的比较函数。
```ocaml
compare x y < 0  (* x < y *)
compare x y = 0  (* x = y *)
compare x y > 0  (* x > y *)
```
（这个惯用法一定程度上说是一个历史错误。如果`compare`针对小于、大于和等于这三种情况返回一个变体会更好。但此处这足够了，不需要改变它。）

接下来就是创建区间模块的函子。我们用一个变体表示区间，这个变体是`Empty`或`Interval (x,y)`，其中`x`和`y`是区间的边界。除了类型，函子还包含了一些与区间交互的有用原语的实现：
```ocaml
# module Make_interval(Endpoint : Comparable) = struct

    type t = | Interval of Endpoint.t * Endpoint.t
             | Empty
    (** [create low high] creates a new interval from [low] to
        [high].  If [low > high], then the interval is empty *)
    let create low high =
      if Endpoint.compare low high > 0 then Empty
      else Interval (low,high)

    (** Returns true iff the interval is empty *)
    let is_empty = function
      | Empty -> true
      | Interval _ -> false

    (** [contains t x] returns true iff [x] is contained in the
        interval [t] *)
    let contains t x =
      match t with
      | Empty -> false
      | Interval (l,h) ->
        Endpoint.compare x l >= 0 && Endpoint.compare x h <= 0

    (** [intersect t1 t2] returns the intersection of the two input
        intervals *)
    let intersect t1 t2 =
      let min x y = if Endpoint.compare x y <= 0 then x else y in
      let max x y = if Endpoint.compare x y >= 0 then x else y in
      match t1,t2 with
      | Empty, _ | _, Empty -> Empty
      | Interval (l1,h1), Interval (l2,h2) ->
        create (max l1 l2) (min h1 h2)
  end ;;
  
module Make_interval :
  functor (Endpoint : Comparable) ->
   sig
     type t = Interval of Endpoint.t * Endpoint.t | Empty
     val create : Endpoint.t -> Endpoint.t -> t
     val is_empty : t -> bool
     val contains : t -> Endpoint.t -> bool
     val intersect : t -> t -> t
   end
```
我们可以通过将函子应用到拥有正确类型的模块上来将其实例化。下面的代码中，我们没有先命名一个模块再调用函子，而是以匿名模块作为函子的输入：
```ocmal
# module Int_interval =
    Make_interval(struct
      type t = int
      let compare = Int.compare
    end);;
module Int_interval :
  sig
    type t = Interval of int * int | Empty
    val create : int -> int -> t
    val is_empty : t -> bool
    val contains : t -> int -> bool
    val intersect : t -> t -> t
  end
```
如果函子输入的接口和标准库对应，那你不需要构建一个自定义模块再将其传给函子。这种情况下，我们可以直接使用Core中提供的`Int`或`String`模块：
```ocaml
# module Int_interval = Make_interval(Int) ;;
module Int_interval :
  sig
   type t = Make_interval(Core.Std.Int).t = Interval of int * int | Empty
   val create : int -> int -> t
   val is_empty : t -> bool
   val contains : t -> int -> bool
   val intersect : t -> t -> t
  end
# module String_interval = Make_interval(String) ;;
module String_interval :
  sig
    type t =
    Make_interval(Core.Std.String).t =
      Interval of string * string
      | Empty
    val create : string -> string -> t
    val is_empty : t -> bool
    val contains : t -> string -> bool
    val intersect : t -> t -> t
  end
```
这可以工作是因为Core中的许多模块，包括`Int`和`String`，都满足上述`Comparable`签名的一个扩展版本。这种标准化的签名是一个好实践，因为它们使函子更易用，还因为它们鼓励标准化，这使你的代码更可读。

我们可以像使用普通模块一样使用新定义的`Int_interval`模块：
```ocaml
# let i1 = Int_interval.create 3 8;;
val i1 : Int_interval.t = Int_interval.Interval (3, 8)
# let i2 = Int_interval.create 4 10;;
val i2 : Int_interval.t = Int_interval.Interval (4, 10)
# Int_interval.intersect i1 i2;;
- : Int_interval.t = Int_interval.Interval (4, 8)
```
这种设计使我们可以自由选择端点的比较函数。如，我们可以把比较反转来创建一个整数区间，如下所示：
```ocaml
# module Rev_int_interval =
    Make_interval(struct
      type t = int
      let compare x y = Int.compare y x
    end);;
module Rev_int_interval :
  sig
    type t = Interval of int * int | Empty
    val create : int -> int -> t
    val is_empty : t -> bool
    val contains : t -> int -> bool
    val intersect : t -> t -> t
  end
```
`Rev_int_interval`和`Int_interval`的行为当然是不同的：
```ocaml
# let interval = Int_interval.create 4 3;;
val interval : Int_interval.t = Int_interval.Empty
# let rev_interval = Rev_int_interval.create 4 3;;
val rev_interval : Rev_int_interval.t = Rev_int_interval.Interval (4, 3)
```
重要的是，`Rev_int_interval.t`和`Int_interval.t`类型不同，尽管它们的物理表示是一样的。实际上，类型系统会阻止我们混淆它们。
```ocaml
# Int_interval.contains rev_interval 3;;
Characters 22-34:
Error: This expression has type Rev_int_interval.t
       but an expression was expected of type Int_interval.t
```
这很重要，因为混淆两种区间在语义上是错误的，这是个很容易犯的错误。函子创建新类型的能力是一个有用的技巧，有多用途。

#### 抽象化函子
`Make_interval`有一个问题。我们写代码依赖于上边界的变量大于下边界的变量，但这些变量可能违反这一点。变量由`create`函数限制的，但是由于`Interval.t`不是抽象的，我们可以绕开它：
```ocaml
# Int_interval.is_empty (* going through create *)
(Int_interval.create 4 3) ;;
- : bool = true
# Int_interval.is_empty (* bypassing create *)
(Int_interval.Interval (4,3)) ;;
- : bool = false
```
为了抽象化`Interval.t`，我们需要使用一个接口限制`Make_interval`的输出。下面即是一个可用于此的接口：
```ocaml
# module type Interval_intf = sig
    type t
    type endpoint
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
  end;;
module type Interval_intf =
  sig
    type t
    type endpoint
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
  end
```
此接口包含了一个`endpoint`类型，使我们可以引用端点的类型。有了这个接口，我们可以重新定义`Make_interval`。注意，在模块实现中也加入了`endpoint`类型以和`Interval_intf`相匹配:
```ocaml
# module Make_interval(Endpoint : Comparable) : Interval_intf = struct
    type endpoint = Endpoint.t
    type t = | Interval of Endpoint.t * Endpoint.t
             | Empty

    ...

  end ;;
module Make_interval : functor (Endpoint : Comparable) -> Interval_intf
```

#### 共享约束
这样返回的模块是抽象了，但不幸的是太抽象了。实际上，我们没有暴露类型`endpoint`，这意味着我们甚至都不能构建任何区间了：
```ocaml
# module Int_interval = Make_interval(Int);;
module Int_interval :
  sig
    type t = Make_interval(Core.Std.Int).t
    type endpoint = Make_interval(Core.Std.Int).endpoint
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
  end
# Int_interval.create 3 4;;
Characters 20-21:
Error: This expression has type int but an expression was expected of type
         Int_interval.endpoint
```
要修复这个问题，我们需要暴露一个事实，就是`endpoint`等价于`Int.t`（或更一般的，等价于`Endpoint.t`，其中`Endpoint`是传给函子的参数）。其中一个方法是通过 *共享约束*，允许你告诉编译器将给定的类型和其它某类型等价这个事实暴露出来。简单的语法如下所示：
```ocaml
<Module_type> with type <type> = <type'>
```
这个表达式的结果就是一个新的签名，所做的修改暴露了`Module_type`模块中定义的`type`和外面定义的`type'`等价。可以对一个签名应用多个共享约束：
```ocaml
Module_type> with type <type1> = <type1'> and <type2> = <type2'>
```
我们可以使用共享约束针对整数区间创建一个`Interval_intf`的特殊版本：
```ocaml
# module type Int_interval_intf =
    Interval_intf with type endpoint = int;;
module type Int_interval_intf =
  sig
    type t
    type endpoint = int
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
  end
```
我们也可以在函子上下文中使用共享约束。最常见是使用场景是你想暴露生成的模块中的某些类型和输入模块中的某些类型相关。

这时，我们会暴露一个新模块中的类型`endpoint`和函子参数模块`Endpoint`中的`Endpoint.t`之间的等价关系。如下所示：
```ocaml
# module Make_interval(Endpoint : Comparable)
      : (Interval_intf with type endpoint = Endpoint.t)
  = struct
    type endpoint = Endpoint.t
    type t = | Interval of Endpoint.t * Endpoint.t
             | Empty

    ...

  end ;;
module Make_interval :
  functor (Endpoint : Comparable) ->
    sig
      type t
      type endpoint = Endpoint.t
      val create : endpoint -> endpoint -> t
      val is_empty : t -> bool
      val contains : t -> endpoint -> bool
      val intersect : t -> t -> t
    end
```
现在，正如接口显示的那样，`endpoint`等价于`Endpoint.t`。这种等价的结果就是，我们对可以做一些需要暴露`endpoint`的操作了，如构造区间：
```ocaml
# module Int_interval = Make_interval(Int);;
module Int_interval :
  sig
    type t = Make_interval(Core.Std.Int).t
    type endpoint = int
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
  end
# let i = Int_interval.create 3 4;;
val i : Int_interval.t = <abstr>
# Int_interval.contains i 5;;
- : bool = false
```

#### 破坏式替换
共享约束基本上能解决问题，但是有一些缺点。我们现在可能就被接口和实现里那乱七八糟的无用`endpoint`声明给烦到了。更好的解决方案是修改`Interval_intf`签名，使用`Endpoint.t`替换`endpoint`，并从签名中删除`endpoint`的定义。我们可以使用 *破坏式替换*来实现。下面是基本语法：
```ocaml
<Module_type> with type <type> := <type'>
```
下面展示了如何在`Make_interval`上使用：
```ocaml
# module type Int_interval_intf =
    Interval_intf with type endpoint := int;;
module type Int_interval_intf =
  sig
    type t
    val create : int -> int -> t
    val is_empty : t -> bool
    val contains : t -> int -> bool
    val intersect : t -> t -> t
  end
```
现在`endpoint`类型没有了：所有出现的地方也都换成了`int`。和共享约束一样，它也可以用在函子上下文上：
```ocaml
# module Make_interval(Endpoint : Comparable)
    : Interval_intf with type endpoint := Endpoint.t =
  struct
    type t = | Interval of Endpoint.t * Endpoint.t
             | Empty

    ...

  end ;;
module Make_interval :
  functor (Endpoint : Comparable) ->
  sig
    type t
    val create : Endpoint.t -> Endpoint.t -> t
    val is_empty : t -> bool
    val contains : t -> Endpoint.t -> bool
    val intersect : t -> t -> t
  end
```
这个接口恰恰就是我们想要的：类型`t`是抽象的，且类型`endpoint`被暴露；因此我们可以通过`create`函数来创建`Int_interval`类型的值，但不能直接使用构造器，也就不能顺便破坏模块规则了：
```ocaml
# module Int_interval = Make_interval(Int);;
module Int_interval :
  sig
    type t = Make_interval(Core.Std.Int).t
    val create : int -> int -> t
    val is_empty : t -> bool
    val contains : t -> int -> bool
    val intersect : t -> t -> t
  end
# Int_interval.is_empty
    (Int_interval.create 3 4);;
- : bool = false
# Int_interval.is_empty
    (Int_interval.Interval (4,3));;
Characters 40-48:
Error: Unbound constructor Int_interval.Interval
```
还有，`endpoint`从接口中消失了，就是说我们再也不用在模块体中定义`endpoint`类型的别名了。

值得注意的是这个名字有点误导，在破坏性替换中没有任何破坏性；它只是一种从一个已存在的签名创建一个新签名的方法。

#### 使用多重接口
另一个我们想要加到区间模块上的特性是序列化能力，即，可以以字节流读写区间。本例中，我们会使用S表达式，在[第七章](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_07_error_handling.md)已经介绍过了。回顾一下，S表达式本质上是一个括号表达式，其原子是字符串，是一种在Core中常用的序列化格式。下面是一个例子：
```ocaml
# Sexp.of_string "(This is (an s-expression))";;
- : Sexp.t = (This is (an s-expression))
```
Core带有一个叫作`Sexplib`的语法扩展，可以从一个类型声明自动生成S表达式转换函数。附加`with sexp`到一个类型定义上会触发这个扩展来创建这个转换器。因此，我们可以这样写：
```ocaml
# type some_type = int * string list with sexp;;
type some_type = int * string list
val some_type_of_sexp : Sexp.t -> int * string list = <fun>
val sexp_of_some_type : int * string list -> Sexp.t = <fun>
# sexp_of_some_type (33, ["one"; "two"]);;
- : Sexp.t = (33 (one two))
# Sexp.of_string "(44 (five six))" |> some_type_of_sexp;;
- : int * string list = (44, ["five"; "six"])
```
我们会在[第十七章](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_17_data_serialization_with_s_expressions.md)讨论更多类型S表达式和`Sexlib`的细节，但现在，让我们看看如果我们把`with sexp`附加到函子的`t`定义上会怎样：
```ocaml
# module Make_interval(Endpoint : Comparable)
    : (Interval_intf with type endpoint := Endpoint.t) = struct
    type t = | Interval of Endpoint.t * Endpoint.t
             | Empty
    with sexp

    ...

  end ;;
Characters 136-146:
Error: Unbound value Endpoint.t_of_sexp
```
问题在于`with sexp`会添加代码来定义S表达式转换器，且代码会假设`Endpoint`对`Endpoint.t`已经有了合适的S表达式转换函数。但对于`Endpoint`我们所知的只有它会满足`Comparable`接口，没有关于S表达式的任何信息。

庆幸的是，Core内建了用于此目的的接口，叫`Sexpable`，定义如下:
```ocaml
module type Sexpable = sig
  type t
  val sexp_of_t : t -> Sexp.t
  val t_of_sexp : Sexp.t -> t
end
```
我们可以在`Make_interval`的输入输出上都使用`Sexpable`接口。首先，我们创建一个`Interval_intf`的扩展版本，让其包含`Sexable`的接口中的函数。为了避免有多个不同的类型`t`的互相冲突，我们可以在`Sexable`接口上使用破坏式替换做到这一点：
```ocaml
# module type Interval_intf_with_sexp = sig
    include Interval_intf
    include Sexpable with type t := t
  end;;
module type Interval_intf_with_sexp =
  sig
    type t
    type endpoint
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
```
等价地，我们可以在新模块中定义一个类型`t`，然后在所有被包含的接口上应用破坏式替换，包括`Interval_intf`，如下例所示。这在组合多个接口时或多或少要清楚一些，因为它正确地反映了所有的签名都是被同等对待的：
```ocaml
# module type Interval_intf_with_sexp = sig
    type t
    include Interval_intf with type t := t
    include Sexpable  with type t := t
  end;;
module type Interval_intf_with_sexp =
  sig
    type t
    type endpoint
    val create : endpoint -> endpoint -> t
    val is_empty : t -> bool
    val contains : t -> endpoint -> bool
    val intersect : t -> t -> t
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
```
现在我们可以写出函子本身了。这里我们小地重写了`sexp`转换器，以确保数据结构的不变式在从S表达式中读取时仍会得到维护：
```ocaml
# module Make_interval(Endpoint : sig
                         type t
                         include Comparable with type t := t
                         include Sexpable  with type t := t
                       end)
    : (Interval_intf_with_sexp with type endpoint := Endpoint.t)
  = struct
  
    type t = | Interval of Endpoint.t * Endpoint.t
             | Empty
    with sexp
    
    (** [create low high] creates a new interval from [low] to
        [high].  If [low > high], then the interval is empty *)
    let create low high =
      if Endpoint.compare low high > 0 then Empty
      else Interval (low,high)

    (* put a wrapper around the autogenerated [t_of_sexp] to enforce
       the invariants of the data structure *)
    let t_of_sexp sexp =
      match t_of_sexp sexp with
      | Empty -> Empty
      | Interval (x,y) -> create x y
      
    (** Returns true iff the interval is empty *)
    let is_empty = function
      | Empty -> true
      | Interval _ -> false

    (** [contains t x] returns true iff [x] is contained in the
        interval [t] *)
    let contains t x =
      match t with
      | Empty -> false
      | Interval (l,h) ->
        Endpoint.compare x l >= 0 && Endpoint.compare x h <= 0

    (** [intersect t1 t2] returns the intersection of the two input
        intervals *)
    let intersect t1 t2 =
      let min x y = if Endpoint.compare x y <= 0 then x else y in
      let max x y = if Endpoint.compare x y >= 0 then x else y in
      match t1,t2 with
      | Empty, _ | _, Empty -> Empty
      | Interval (l1,h1), Interval (l2,h2) ->
        create (max l1 l2) (min h1 h2)
  end;;
module Make_interval :
  functor
    (Endpoint : sig
                  type t
                  val compare : t -> t -> int
                  val t_of_sexp : Sexp.t -> t
                  val sexp_of_t : t -> Sexp.t
                end) ->
    sig
      type t
      val create : Endpoint.t -> Endpoint.t -> t
      val is_empty : t -> bool
      val contains : t -> Endpoint.t -> bool
      val intersect : t -> t -> t
      val t_of_sexp : Sexp.t -> t
      val sexp_of_t : t -> Sexp.t
    end
```
现在我们正常使用`sexp`转换器了：
```ocaml
# module Int_interval = Make_interval(Int) ;;
module Int_interval :
  sig
    type t = Make_interval(Core.Std.Int).t
    val create : int -> int -> t
    val is_empty : t -> bool
    val contains : t -> int -> bool
    val intersect : t -> t -> t
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
# Int_interval.sexp_of_t (Int_interval.create 3 4);;
- : Sexp.t = (Interval 3 4)
# Int_interval.sexp_of_t (Int_interval.create 4 3);;
- : Sexp.t = Empty
```

### 扩展模块
函子的另一个常用功能就是以标准方法为给定的模块生成类型相关的功能。让我们看一下在一个函数式队列上下文中是如何使用的，函数式队列就是FIFO（先入先出）队列的函数式版本。函数式，即队列操作会返回新的队列，而不是修改传入的队列。

下面是这个模块的一个合理的mli：
```ocaml
type 'a t

val empty : 'a t

(** [enqueue q el] adds [el] to the back of [q] *)
val enqueue : 'a t -> 'a -> 'a t

(** [dequeue q] returns None if the [q] is empty, otherwise returns
    the first element of the queue and the remainder of the queue *)
val dequeue : 'a t -> ('a * 'a t) option

(** Folds over the queue, from front to back *)
val fold : 'a t -> init:'acc -> f:('acc -> 'a -> 'acc) -> 'acc
```
上面的`Fqueue.fold`需要再解释一下。它和[高效使用`List`模块](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_03_lists_and_patterns.md#%E9%AB%98%E6%95%88%E4%BD%BF%E7%94%A8list%E6%A8%A1%E5%9D%97)中描述的`List.fold`函数模式相同。本质上，`Fqueue.fold q ~init ~f`从前向后遍历`q`中的元素，从一个值为`init`的累加器开始，遍历过程中使用`f`更新累加器，在计算结束时返回累加器最终的值。我们会看到，`fold`是一个功能相当强大的操作。

我们会以一个常见的维护输入输出列表的技巧实现`Fqueue`，这样就能高效在输入列表上入队，从输出列表上出队了。如果你试图在输出列表为空时出队，输入列表会反转并变为新的输出列表。下面是实现：
```ocaml
open Core.Std

type 'a t = 'a list * 'a list

let empty = ([],[])

let enqueue (in_list, out_list) x =
  (x :: in_list,out_list)

let dequeue (in_list, out_list) =
  match out_list with
  | hd :: tl -> Some (hd, (in_list, tl))
  | [] ->
    match List.rev in_list with
    | [] -> None
    | hd :: tl -> Some (hd, ([], tl))

let fold (in_list, out_list) ~init ~f =
  let after_out = List.fold ~init ~f out_list in
  List.fold_right ~init:after_out ~f:(fun x acc -> f acc x) in_list
```
`Fqueue`的一个问题就是接口太少了。大量有用的辅助函数都没有。反观`List`模块，有类似`List.iter`的函数，在每个元素上执行一个函数；还有`List.for_all`，当且仅当给定的谓词在列表所有元素上求值都为`true`时返回真。这样的辅助函数几乎每个容器类型都支持，反复实现它们是一件枯燥重复的事。

巧的是，许多这些辅助函数都能从我们已经实现的`fold`函数机械地衍生出来。相较于为每个新容器手写所有这些函数，我们可以使用一个函子给拥有`fold`函数的容器加上这些功能。

我们创建一个新模块，`Foldable`，它给一个支持`fold`的容器自动添加辅助函数。如你所见，`Foldable`包含一个模块签名S，S定义了需要支持`fold`的签名；还有一个函子`Extend`，允许你扩展任何匹配`Foldable.S`的模块：
```ocaml
open Core.Std

module type S = sig
  type 'a t
  val fold : 'a t -> init:'acc -> f:('acc -> 'a -> 'acc) -> 'acc
end

module type Extension = sig
  type 'a t
  val iter  : 'a t -> f:('a -> unit) -> unit
  val length  : 'a t -> int
  val count  : 'a t -> f:('a -> bool) -> int
  val for_all : 'a t -> f:('a -> bool) -> bool
  val exists  : 'a t -> f:('a -> bool) -> bool
end

(* For extending a Foldable module *)
module Extend(Arg : S)
  : (Extension with type 'a t := 'a Arg.t) =
struct
  open Arg

  let iter t ~f =
    fold t ~init:() ~f:(fun () a -> f a)

  let length t =
    fold t ~init:0  ~f:(fun acc _ -> acc + 1)

  let count t ~f =
    fold t ~init:0  ~f:(fun count x -> count + if f x then 1 else 0)

  exception Short_circuit

  let for_all c ~f =
    try iter c ~f:(fun x -> if not (f x) then raise Short_circuit); true
    with Short_circuit -> false

  let exists c ~f =
    try iter c ~f:(fun x -> if f x then raise Short_circuit); false
    with Short_circuit -> true
end
```
现在我们可以将其应用到`Fqueue`上。我们可以创建一个扩展版`Fqueue`的接口：
```ocaml
type 'a t
include (module type of Fqueue) with type 'a t := 'a t
include Foldable.Extension with type 'a t := 'a t
```
为了应用这个函子，我们把`Fqueue`的定义放在一个叫`T`的子模块中，然后在`T`上调用`Foldable.Extend`：
```ocaml
include Fqueue
include Foldable.Extend(Fqueue)
```
以这种基本模式，Core自带了一些用于扩展模块的函子，包括：
- `Container.Make`  
  和`Foldable.Extend`很类似
- `Comparable.Make`  
  添加依赖比较函数的功能，包含对像映射和集合这样的容器的支持。
- `Hashable.Make`  
  给包含哈希表、哈希集合和哈希堆等基于哈希的数据结构添加支持
- `Monad.Make`  
  用于所谓的单子库，像第七章和第十八章讨论那些。这里，此函子用于提供一组基于`bind`和`return`操作符的辅助函数。

当你想要给你自己的类型添加Core中常见的功能时，函子就派上用场了。

我们只介绍了函子的几种可能应用。函子是组织代码的利器。代价是相对于该语言的其它部分，函子的语法比较重量级，且要高效使用它你需要理解一些技巧，其中最为重要的是共享约束和破坏式替换。

所有这些意味着对于简单的小程序，大量使用函子可能是个错误。但随着你的程序越来越复杂，你需要更有效的模块化架构，函子此时就是一个极有价值的工具。
