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
> 本地抽象类型的一个关键属性就是它们在函数内部被作为抽象类型处理，但在外部看来却是多态的。看下面的例子：
> ```ocaml
> # let wrap_in_list (type a) (x : a) = [x];;
> val wrap_in_list : 'a -> 'a list = <fun>
> ```
> 这会编译成功，因为类型`a`以抽象方式使用。但推导出的函数类型却是多态的。
>
> 另一方面，如果我们尝试把`a`用作一个具体类型的等价，比如，`int`，那么编译会失败：
> ```ocaml
> # let double_int (type a) (x : a) = x + x;;
> Characters 38-39:
> Error: This expression has type a but and expression was expected of type int
> ```
> 本地抽象类型的一个最常见应用是创建一个新类型，用以构造一个模块。这里有一个例子，就是这样创建一个第一类模块：
> ```ocaml
> # module type Comparable = sig
>     type t
>     val compare : t -> t -> int
>   end ;;
> module type Comparable = sig type t val compare : t -> t -> int end
> # let create_comparable (type a) compare =
>     (module struct
>       type t = a
>       let compare = compare
>     end : Comparable with type t = a)
>   ;;
> val create_comparable :
> ('a -> 'a -> int) -> (module Comparable with type t = 'a) = <fun>
> # create_comparable Int.compare;;
> - : (module Comparable with type t = int) = <module>
> # create_comparable Float.compare;;
> - : (module Comparable with type t = float) = <module>
> ```
> 这里，我们事实上是捕捉了一个多态类型并在一个模块中将其导出成具体类型。
>
> 这种技术在第一类模块以外也有用。如，我们可以用相同的方法构造一个本地模块传给一个函子。

### 例：一个查询处理框架
现在说我们在一个更完整更现实的例子中看一下第一类模块。考虑下面的模块签名，此模块实现了一个响应用户查询的系统。
```ocaml
# module type Query_handler = sig
    (** Configuration for a query handler. Note that this can be
         converted to and from an s-expression *)
    type config with sexp

    (** The name of the query-handling service *)
    val name : string

    (** The state of the query handler *)
    type t

    (** Creates a new query handler from a config *)
    val create : config -> t

    (** Evaluate a given query, where both input and output are
         s-expressions *)
    val eval : t -> Sexp.t -> Sexp.t Or_error.t
  end;;

module type Query_handler =
  sig
    type config
    val name : string
    type t
    val create : config -> t
    val eval : t -> Sexp.t -> Sexp.t Or_error.t
    val config_of_sexp : Sexp.t -> config
    val sexp_of_config : config -> Sexp.t
  end
```
这里我们用S表达式作为查询和响应格式，也作为查询处理器的配置。S表达式是一种简单、灵活并可读的序列化格式，在Core中很常用。现在，将其看成括号围起的表达式，原子值是字符串就足够了，即，`(this (is an) (s expression))`。

另外，我们使用了`Sexplib`语法扩展，它用`with sexp`声明扩展了OCaml。把`with sexp`附加到一个签名中的类型上，就添加了S表达式转换器，如：
```ocaml
# module type M = sig type t with sexp end;;
module type M =
  sig type t val t_of_sexp : Sexp.t -> t val sexp_of_t : t -> Sexp.t end
```
在模块中，`with sexp`会添加这些函数的实现。因此，我们可以这样写：
```ocaml
# type u = { a: int; b: float } with sexp;;
type u = { a : int; b : float; }
val u_of_sexp : Sexp.t -> u = <fun>
val sexp_of_u : u -> Sexp.t = <fun>
# sexp_of_u {a=3;b=7.};;
- : Sexp.t = ((a 3) (b 7))
# u_of_sexp (Sexp.of_string "((a 43) (b 3.4))");;
- : u = {a = 43; b = 3.4}
```
这些在[第17章]()都会详述。

#### 实现一个查询处理器
说我们看一些满足`Query_handler`接口的查询处理器。第一个例子是一个产生唯一整数ID的处理器。它通过内部保持一个整数计数器工作，每次产生一个新值那会变化。这种情况下查询的输入只是一个无意义的S表达式`()`，或称为`Sexp.unit`：
```ocaml
# module Unique = struct
    type config = int with sexp
    type t = { mutable next_id: int }

    let name = "unique"
    let create start_at = { next_id = start_at }

    let eval t sexp =
      match Or_error.try_with (fun () -> unit_of_sexp sexp) with
      | Error _ as err -> err
      | Ok () ->
        let response = Ok (Int.sexp_of_t t.next_id) in
        t.next_id <- t.next_id + 1;
        response
  end;;
module Unique :
  sig
    type config = int
    val config_of_sexp : Sexp.t -> config
    val sexp_of_config : config -> Sexp.t
    type t = { mutable next_id : config; }
    val name : string
    val create : config -> t
    val eval : t -> Sexp.t -> (Sexp.t, Error.t) Result.t
  end
```
我们可以使用这个模块创建一个`Unique`查询处理器的实例并直接与之交互：
```ocaml
# let unique = Unique.create 0;;
val unique : Unique.t = {Unique.next_id = 0}
# Unique.eval unique Sexp.unit;;
- : (Sexp.t, Error.t) Result.t = Ok 0
# Unique.eval unique Sexp.unit;;
- : (Sexp.t, Error.t) Result.t = Ok 1
```
下面是另一个例子：一个列举目录的查询处理器。这里，`config`是默认目录，被视为相对路径：
```ocaml
# module List_dir = struct
    type config = string with sexp
    type t = { cwd: string }

    (** [is_abs p] Returns true if [p] is an absolute path *)
    let is_abs p =
      String.length p > 0 && p.[0] = '/'

    let name = "ls"
    let create cwd = { cwd }

    let eval t sexp =
      match Or_error.try_with (fun () -> string_of_sexp sexp) with
      | Error _ as err -> err
      | Ok dir ->
        let dir =
          if is_abs dir then dir
          else Filename.concat t.cwd dir
        in
        Ok (Array.sexp_of_t String.sexp_of_t (Sys.readdir dir))
  end;;
module List_dir :
  sig
    type config = string
    val config_of_sexp : Sexp.t -> config
    val sexp_of_config : config -> Sexp.t
    type t = { cwd : config; }
    val is_abs : config -> bool
    val name : config
    val create : config -> t
    val eval : t -> Sexp.t -> (Sexp.t, Error.t) Result.t
  end
```
我们可以创建一个此查询处理器的实例并直接与之交互：
```ocaml
# let list_dir = List_dir.create "/var";;
val list_dir : List_dir.t = {List_dir.cwd = "/var"}
# List_dir.eval list_dir (sexp_of_string ".");;
- : (Sexp.t, Error.t) Result.t =
Ok (lib mail cache www spool run log lock opt local backups tmp)
# List_dir.eval list_dir (sexp_of_string "yp");;
Exception: (Sys_error "/var/yp: No such file or directory").
```

#### 调度多个查询处理器
现在，如果我们要把查询分发给任意一个处理器集合中的一个该怎么办？理想情况下，我们只要把这处理器以像列表这种简单数据结构传入。单用模块和函子这是很难的，但用 第一类模块就相当自然。首先要做的是创建一个签名，把`Query_handler`模块和一个实例化的查询处理器组合地一起：
```ocaml
# module type Query_handler_instance = sig
    module Query_handler : Query_handler
    val this : Query_handler.t
  end;;
module type Query_handler_instance =
  sig module Query_handler : Query_handler val this : Query_handler.t end
```
使用这个签名，我们就可以创建一个第一类模块，封装一个查询实例和此查询上匹配的操作：
```ocaml
# let unique_instance =
    (module struct
       module Query_handler = Unique
       let this = Unique.create 0
     end : Query_handler_instance);;
val unique_instance : (module Query_handler_instance) = <module>
```
这样构建实例有一点冗长，但我们可以之一个函数来消除大部分样板。注意我们再一次用到了本地抽象类型：
```ocaml
# let build_instance
        (type a)
        (module Q : Query_handler with type config = a)
        config
    =
    (module struct
      module Query_handler = Q
      let this = Q.create config
     end : Query_handler_instance)
  ;;
val build_instance :
  (module Query_handler with type config = 'a) ->
  'a -> (module Query_handler_instance) = <fun>
```
使用`build_instance`，一行就可以构建一个新的实例：
```ocaml
# let unique_instance = build_instance (module Unique) 0;;
val unique_instance : (module Query_handler_instance) = <module>
# let list_dir_instance = build_instance (module List_dir)  "/var";;
val list_dir_instance : (module Query_handler_instance) = <module>
```
现在我们可以写代码把查询分发到一个查询处理器实例列表了。我们假设查询格式如下：
```
(query-name query)
```
其中`query-name`是用以确定使用哪个查询处理器的名字，`query`是查询的内容。

我们要做的第一件事是需要一个函数，接收一个处理器列表并个中构建一个分发表：
```ocaml
# let build_dispatch_table handlers =
    let table = String.Table.create () in
    List.iter handlers
      ~f:(fun ((module I : Query_handler_instance) as instance) ->
        Hashtbl.replace table ~key:I.Query_handler.name ~data:instance);
    table
  ;;
val build_dispatch_table :
  (module Query_handler_instance) list ->
  (module Query_handler_instance) String.Table.t = <fun>
```
现在我们需要一个函数，用分发表的分发到一个处理器：
```ocaml
# let dispatch dispatch_table name_and_query =
    match name_and_query with
    | Sexp.List [Sexp.Atom name; query] ->
      begin match Hashtbl.find dispatch_table name with
      | None ->
        Or_error.error "Could not find matching handler"
          name String.sexp_of_t
      | Some (module I : Query_handler_instance) ->
        I.Query_handler.eval I.this query
      end
    | _ ->
      Or_error.error_string "malformed query"
  ;;
val dispatch :
  (string, (module Query_handler_instance)) Hashtbl.t ->
  Sexp.t -> Sexp.t Or_error.t = <fun>
```
此函数通过把一个实例解包成模块`I`与之交互，然后使用查询处理器实例（`I.this`）和相关模块（`I.Query_handler`）协作。

模块和值的绑定在许多方面使用联想到面向对象编程语言。一个重要的不同是第一第模块允许你打包比函数或方法更多的东西。如我们所见，你也可以包含类型甚至是模块。这里我们只用到了一小部分，还有额外的功能允许构建更复杂的组件，包含多个相互依赖的类型和值。

对我，让我们回来添加一个命令行接口，以完成一个可运行的例子：
```ocaml
# let rec cli dispatch_table =
    printf ">>> %!";
    let result =
      match In_channel.input_line stdin with
      | None -> `Stop
      | Some line ->
        match Or_error.try_with (fun () -> Sexp.of_string line) with
        | Error e -> `Continue (Error.to_string_hum e)
        | Ok (Sexp.Atom "quit") -> `Stop
        | Ok query ->
          begin match dispatch dispatch_table query with
          | Error e -> `Continue (Error.to_string_hum e)
          | Ok s  -> `Continue (Sexp.to_string_hum s)
          end;
    in
    match result with
    | `Stop -> ()
    | `Continue msg ->
      printf "%s\n%!" msg;
      cli dispatch_table
  ;;
val cli : (string, (module Query_handler_instance)) Hashtbl.t -> unit = <fun>
```
我们实际上可以从一个独立程序中运行此命令行接口，我们可以把上面的代码放到一个函数中，然后使用下面的命令来启动接口：
```ocaml
let () =
  cli (build_dispatch_table [unique_instance; list_dir_instance])
```
下例是此程序的一个会话：
```bash
$ ./query_handler.byte 
>>> (unique ())
0
>>> (unique ())
1
>>> (ls .)
(agentx at audit backups db empty folders jabberd lib log mail msgs named netboot pgsql_socket_alt root rpc run rwho spool tmp vm yp)
>>> (ls vm)
(sleepimage swapfile0 swapfile1 swapfile2 swapfile3 swapfile4 swapfile5 swapfile6)
```
    
#### 加载和卸载查询处理器
第一类模块的一个优势就是它们提供了强大的动态性和灵活性。如，修改我们设计来允许运行时加载和卸载查询处理器相当容易。

我们先创建一个查询处理器，其工作就是控制活动查询处理器的集合。此模块叫作`Loader`，其配置是一个已知`Query_handler`模块的列表。下面是基本类型：
```ocaml
module Loader = struct
  type config = (module Query_handler) list sexp_opaque with sexp

  type t = { known  : (module Query_handler)  String.Table.t
           ; active : (module Query_handler_instance) String.Table.t
           }
           
  let name = "loader"
```
注意`Loader.t`有两个表：一个包含已知的查询处理器模块，一个包含活动的查询处理器实例。`Loader.t`负责创建新的实例并将其添加到这个表中，同时也根据用户查询来删除实例。

下面，我们需要一个函数来创建`Loader.t`。这个函数需要一个已知查询处理器模块的列表。注意活动模块表开始是空的：
```ocaml
let create known_list =
  let active = String.Table.create () in
  let known  = String.Table.create () in
  List.iter known_list
    ~f:(fun ((module Q : Query_handler) as q) ->
      Hashtbl.replace known ~key:Q.name ~data:q);
  { known; active }
```
现在我们写维护活动查询处理器表的函数。我们先从加载实例函数开始。注意它把查询处理器名和S表达式形式的实例化配置作为参数。这些用以创建一个类型为`(module Query_handler_instance)`第一类模块，然后将其添加到活动表中：
```ocaml
let load t handler_name config =
  if Hashtbl.mem t.active handler_name then
    Or_error.error "Can't re-register an active handler"
      handler_name String.sexp_of_t
  else
    match Hashtbl.find t.known handler_name with
    | None ->
      Or_error.error "Unknown handler" handler_name String.sexp_of_t
    | Some (module Q : Query_handler) ->
      let instance =
        (module struct
          module Query_handler = Q
          let this = Q.create (Q.config_of_sexp config)
        end : Query_handler_instance)
      in
      Hashtbl.replace t.active ~key:handler_name ~data:instance;
      Ok Sexp.unit
```
因为加密函数会复用来加载一个已经活动的处理器，我们还需要能卸载一个处理器。注意处理器会显示拒绝卸载自身：
```ocaml
let unload t handler_name =
  if not (Hashtbl.mem t.active handler_name) then
    Or_error.error "Handler not active" handler_name String.sexp_of_t
  else if handler_name = name then
Or_error.error_string "It's unwise to unload yourself"
  else (
    Hashtbl.remove t.active handler_name;
    Ok Sexp.unit
  )
```
最后我们需要实现`eval`函数，确定用户的拉查询接口。我们创建一个变体类型来做这件事，使用对此类型生成的S表达式转换器来解析用户查询：
```ocaml
type request =
    | Load of string * Sexp.t
    | Unload of string
    | Known_services
    | Active_services
  with sexp
```
`eval`函数本身很简单，把每种查询分发到合适的函数即可。注意我们用`<:sexp_of<string list>>`来自动生成一个将字符串列表转换成一个S表达式的函数，[第17章](https://github.com/zforget/translation/blob/master/real_world_ocaml/2_17_data_serialization_with_s_expressions.md)会介绍。

此函数结束了`Loader`模块的定义：
```ocaml
let eval t sexp =
  match Or_error.try_with (fun () -> request_of_sexp sexp) with
  | Error _ as err -> err
  | Ok resp ->
    match resp with
    | Load (name,config) -> load  t name config
    | Unload name  -> unload t name
    | Known_services ->
      Ok (<:sexp_of<string list>> (Hashtbl.keys t.known))
    | Active_services ->
      Ok (<:sexp_of<string list>> (Hashtbl.keys t.active))
end
```
最后我们可以把这些都放一起放到命令行接口中。我们先创建一个加载器查询处理器实例，然后将其添加到活动表。然后我们启动命令行接口即可，将活动表传给它：
```ocaml
let () =
  let loader = Loader.create [(module Unique); (module List_dir)] in
  let loader_instance =
    (module struct
      module Query_handler = Loader
      let this = loader
    end : Query_handler_instance)
  in
  Hashtbl.replace loader.Loader.active
    ~key:Loader.name ~data:loader_instance;
  cli loader.Loader.active
```
现在构建这个命令行来体验一下：
```bash
 $ corebuild query_handler_loader.byte
 ```
 结果和你期望的大致相同，开始时没有可用的查询处理器，但你可以加载和卸载它们。下面是一个运行的例子。如你所见，我们开始时只有`loader`自身是活动的处理器：
 ```bash
 $ ./query_handler_loader.byte
>>> (loader known_services)
(ls unique)
>>> (loader active_services)
(loader)
 ```
 任何使用非活动查询处理器的尝试都会失败：
 ```bash
 >>> (ls .)
Could not find matching handler: ls
 ```
但是我们用一个我们自己选择的配置加载`ls`处理器，然后就可以使用了。然后当我们卸载它以后，就又不可用了，又可以用不同的配置加载：
```bash
>>> (loader (load ls /var))
()
>>> (ls /var)
(agentx at audit backups db empty folders jabberd lib log mail msgs named netboot pgsql_socket_alt root rpc run rwho spool tmp vm yp)
>>> (loader (unload ls))
()
>>> (ls /var)
Could not find matching handler: ls
```
注意`loader`不能被加载（因为它不在已知处理器列表中），也不能被卸载：
```bash
>>> (loader (unload loader))
It's unwise to unload yourself
```
尽管我们这里不会描述细节，使用OCaml的动态链接设施我们更进一步使用这种动态性，动态链接允许你在运行时编译和链接新的代码。这可以使用像`ocaml_plugin`这样的库自动完成，`ocaml_plugin`可以通过OPAM安装，会自动化大量设置动态链接的工作流。

### 不使用第一类模块工作

