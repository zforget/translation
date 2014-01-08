## 第十章 第一类模块
>> First-Class Modules

你可以认为OCaml分成了两部分：一个是核心语言，聚焦于值和类型，一个是模块语言，聚焦于模块和模块签名。这些子语言是分层的，模块中可以包含类型和值，但是普通的值不能包含模块或模块类型。这意味着你不能定义一个值为模块的变量，或一个接收一个模块作为参数的函数。

围绕这种层次，OCaml以 *第一类模块*的形式提供一种方法。第一类模块是普通的值，可以从普通模块创建，也可以转回普通模块。

第一类模块是一种复杂的技术，要有效地使用它们你需要适应一些高级语言特性。但这是值得学习的，因为把模块引入核心语言是很强大的，扩展了你的表达能力并使构建灵活且模块化的系统更容易。

### 使用第一类的模块
我们通过一些无用的小例子来讲解第一类模块的基本机制。下一节会有更多实用的例子。

基于这一点，考虑下面这个只有一个整数变量的模块的签名：
```ocaml
# module type X_int = sig val x : int end;;
module type X_int = sig val x : int end
```
我们再创建一个匹配此类型的模块：
```ocaml
# module Three : X_int = struct let x = 3 end;;
module Three : X_int
# Three.x;;
- : int = 3
```
一个第一类模块通过包装一个模块和其匹配的签名来创建。使用`module`关键字，语法如下：
```ocaml
(module <Module> : <Module_type>)
```
所以我们可以像下面这样把`Three`转化成第一类模块：
```ocaml
# let three = (module Three : X_int);;
val three : (module X_int) = <module>
```
如果可以推导出，那么模块类型在构造时就不是必须的。因此，我们可以这样写：
```ocaml
# module Four = struct let x = 4 end;;
module Four : sig val x : int end
# let numbers = [ three; (module Four) ];;
val numbers : (module X_int) list = [<module>; <module>]
```
我们也可以从匿名模块创建第一类模块：
```ocaml
# let numbers = [three; (module struct let x = 4 end)];;
val numbers : (module X_int) list = [<module>; <module>]
```
为了能够访问第一类模块的内容，你需要将其解包成一个普通模块。可以使用val关键字，语法如下：
```ocaml
(val <first_class_module> : <Module_type>)
```
下面是一个例子:
```ocaml
# module New_three = (val three : X_int) ;;
module New_three : X_int
# New_three.x;;
- : int = 3
```
-----
**第一类模块类型的相等**

第一类模块的类型，如`(module X_int)`，完全基于构建它的签名的名字。一个基于名字不同的签名的第一类模块，即使实际上是相同的签名，也会得到一个不同的类型：
```ocaml
# module type Y_int = X_int;;
module type Y_int = X_int
# let five = (module struct let x = 5 end : Y_int);;
val five : (module Y_int) = <module>
# [three; five];;
Characters 8-12:
Error: This expression has type (module Y_int)
but an expression was expected of type (module X_int)
```
但即使作为第一类模块它们的类型不同，底层的模块类型却是兼容的（显而易见），所以我们可以通过解包再打包来统一类型：
```ocaml
# [three; (module (val five))];;
- : (module X_int) list = [<module>; <module>]
```
第一类模块的相等判断方式可能难以理解。一个常见的问题就是在其它地方创建一个模块类型的别名。在显式声明一个模块类型或隐式的`include`声明中，都可以用来提高可读性。这两种情况下，从别名创建的和从原始模块类型创建的第一类模块的不兼容会产生意想不到的副作用。为了解决这个问题，创建第一类模块时，我们对引用的签名应该格外严格。

-----

我们也可以写消费和生产第一类模块的普通函数。下面展示了两个函数的定义：`to_int`，把一个`(module X_int)`转换成`int`；以及`plus`，返回两个`(module X_int)`的和：
```ocaml
# let to_int m =
    let module M = (val m : X_int) in
    M.x
  ;;
val to_int : (module X_int) -> int = <fun>
# let plus m1 m2 =
    (module struct
      let x = to_int m1 + to_int m2
     end : X_int)
  ;;
val plus : (module X_int) -> (module X_int) -> (module X_int) = <fun>
```
有这些函数在手，我们现在就可以更自然地使用`(module X_int)`类型的值了，可以享受核心语言的简洁性：
```ocaml
# let six = plus three three;;
val six : (module X_int) = <module>
# to_int (List.fold ~init:six ~f:plus [three;three]);;
- : int = 12
```
处理第一类模块时有一些有用的简化语法。其中一个值得注意的就是可以使用模式匹配转换成一个普通模块。因此，我们可以像下面这样重写`to_int`函数：
```ocaml
# let to_int (module M : X_int) = M.x ;;
val to_int : (module X_int) -> int = <fun>
```
除了`int`这样的简单类型，第一类模块还可以包含类型和函数。下面是一个包含一个类型和一个相关操作`bump`的接口，`bump`接收一个此类型的值并产生一个新的：
```ocaml
# module type Bumpable = sig
    type t
    val bump : t -> t
  end;;
module type Bumpable = sig type t val bump : t -> t end
```
我们可以使用不同底层类型创建这个模块的多个实例：
```ocaml
# module Int_bumper = struct
    type t = int
    let bump n = n + 1
  end;;
module Int_bumper : sig type t = int val bump : t -> t end
# module Float_bumper = struct
    type t = float
    let bump n = n +. 1.
  end;;
module Float_bumper : sig type t = float val bump : t -> t end
```
且我们可以把它们转换成第一类模块：
```ocaml
# let int_bumper = (module Int_bumper : Bumpable);;
val int_bumper : (module Bumpable) = <module>
```
但你不能再对`int_bumper`做什么了，因为`int_bumper`是完全抽象的，因此我们无法再找回其中的类型是`int`这个信息了：
```ocaml
# let (module Bumpable) = int_bumper in Bumpable.bump 3;;
Characters 52-53:
Error: This expression has type int but an expression was expected of type
         Bumpable.t
```
要使用`int_bumper`可用，我们需要暴露类型，可以这样做：
```ocaml
# let int_bumper = (module Int_bumper : Bumpable with type t = int);;
val int_bumper : (module Bumpable with type t = int) = <module>
# let float_bumper = (module Float_bumper : Bumpable with type t = float);;
val float_bumper : (module Bumpable with type t = float) = <module>
```
上面添加的共享约束使第一类模块在类型`t`上多态。这样，我们就能把这些值用于匹配类型了：
```ocaml
# let (module Bumpable) = int_bumper in Bumpable.bump 3;;
- : int = 4
# let (module Bumpable) = float_bumper in Bumpable.bump 3.5;;
- : float = 4.5
```
我们也可以写出多态使用这种第一类模块的函数。下面的函数接收两个参数：一个`Bumpable`模块和一个元素与此模式中的`t`类型相同的列表：
```ocaml
# let bump_list
      (type a)
      (module B : Bumpable with type t = a)
      (l: a list)
    =
    List.map ~f:B.bump l
;;
val bump_list : (module Bumpable with type t = 'a) -> 'a list -> 'a list =
<fun>
```
这里我们用到了一个前面没碰到过的OCaml特性：一个 *本地抽象类型*。对任何函数，你都可以用`(type a)`的形式声明一个伪参数，类型名`a`任意，会引入一个新类型。这个类型作为一个此函数上下文中的抽象类型。在上例中，本地抽象类型作为共享约束的一部分来把类型`B.t`和传入的列表元素的类型绑定在一起。

结果就是此函数在列表元素类型和类型`Bumpable.t`上都是多态的。我们可以看一下函数的使用：
```ocaml
# bump_list int_bumper [1;2;3];;
- : int list = [2; 3; 4]
# bump_list float_bumper [1.5;2.5;3.5];;
- : float list = [2.5; 3.5; 4.5]
```
多态第一类模块很重要，因为它们允许你可以将第一类模块中的类型和其它值的模块连系起来。

> **更多关于本地抽象类型**
>

### Example: A Query-Handing Framework
#### Implementing a Query Handler
#### Dispatching to Multiple Query Handlers
#### Loading and Unloading Query Handlers

### Living Without First-Class Modules
