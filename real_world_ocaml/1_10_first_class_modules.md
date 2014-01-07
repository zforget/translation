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

### Example: A Query-Handing Framework
#### Implementing a Query Handler
#### Dispatching to Multiple Query Handlers
#### Loading and Unloading Query Handlers

### Living Without First-Class Modules
