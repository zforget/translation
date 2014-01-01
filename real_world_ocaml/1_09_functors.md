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

首先，说我们给模块定义一个签名，包含一个单独的类型为`int`的值：
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
这里，我们把`Increment`应用到一个签名和`X_int`完全相同的模式上。但就和ml内容必须满足mli一样，我们也可以吧`Increment`应用到任何接口满足`X_int`的模块上。就是说模块类型可以忽略模块中的一个些信息，或是丢弃一些字段或是把某些字段保持为抽象的。示例如下：
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
让我们来考虑一个如何使用函子的更为实际的例子：一个用以计算区间的库。区间是一个通用的计算对象，对不同的类型有不同的内容。你可以需要计算浮点数或字符串或时间等的区间，每种情况下，你都需要类似的操作：空值测试、包含检查、相交区间等等。

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
（）

#### Making the Functor Abstract
#### Sharing Constraints
#### Destructive Substitution
#### Using Multiple Interface

### Extending Modules
