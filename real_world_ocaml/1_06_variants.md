## 第六章 变体
>> Variants

变体类型是OCaml最有用的特性之一，也是最不寻常的特性之一。变体使你可以表达可能多种不同形态的数据，每种形式都用一个显式的标签标注。我们将会看到，结合模式匹配，变体给了你一种强大的方式来表达复杂数据以及组织在其上的案例分析。

变体类型声明的基本语法如下所示：
```ocaml
type <variant> =
  | <Tag> [ of <type> [* <type>]... ]
  | <Tag> [ of <type> [* <type>]... ]
  | ...

(* Syntax ∗ variants/variant.syntax ∗ all code *)
```
每一行实际上是表示变体的一个实例。每一个实例都有一个相关的标签，也可能有一系列可选的字段，每一个字段都有指定的类型。

让我们以一个具体的例子来说明变量的重要性。几乎所有的终端都支持一组基本颜色，我们可以使用变体表示它们。每种颜色声明成一个简单标签，使用管道符分隔不同的实例。注意变体标签必须是大写字母开头的：
```ocaml
# type basic_color =
   | Black | Red | Green | Yellow | Blue | Magenta | Cyan | White ;;
type basic_color =
    Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White
# Cyan ;;
- : basic_color = Cyan
# [Blue; Magenta; Red] ;;
- : basic_color list = [Blue; Magenta; Red]

(* OCaml Utop ∗ variants/main.topscript ∗ all code *)
```
下面的函数使用模式匹配把`basic_color`转换成相应的整数。模式匹配的完整性检查意味着当我们遗漏一个颜色时编译器会警告：
```ocaml
# let basic_color_to_int = function
  | Black -> 0 | Red     -> 1 | Green -> 2 | Yellow -> 3
  | Blue  -> 4 | Magenta -> 5 | Cyan  -> 6 | White  -> 7 ;;
val basic_color_to_int : basic_color -> int = <fun>
# List.map ~f:basic_color_to_int [Blue;Red];;
- : int list = [4; 1]

(* OCaml Utop ∗ variants/main.topscript , continued (part 1) ∗ all code *)
```
使用上面的函数，我们就可以生成转义代码来改变一个字符串在终端中的颜色：
```ocaml
# let color_by_number number text =
    sprintf "\027[38;5;%dm%s\027[0m" number text;;
val color_by_number : int -> string -> string = <fun>
# let blue = color_by_number (basic_color_to_int Blue) "Blue";;
val blue : string = "\027[38;5;4mBlue\027[0m"
# printf "Hello %s World!\n" blue;;
Hello Blue World!

(* OCaml Utop ∗ variants/main-2.rawscript ∗ all code *)
```
在多数终端里，"Blue"都会以蓝色呈现。

本例中，变体的实例是没有关联数据的简单标签。这本质上和C和Java等语言中的枚举类似。但我们会看到，变体的表达能力大大超过一个简单枚举。正好，枚举不足以有效表示一个现代终端可以显示的全部颜色了。许多终端，包括xterm，支持256种不同颜色，分为以下几组：
- 八种基本颜色，分为普通和粗体
- 一个6x6x6的RGB颜色立方体
- 一个24层灰度色谱

我们还是用变体来表示这个更复杂的颜色空间，但这次，不同的标签会带有参数用以描述每种实例的数据。注意变体可以有多个参数，用`*`分隔：
```ocaml
# type weight = Regular | Bold
  type color =
  | Basic of basic_color * weight (* basic colors, regular and bold *)
  | RGB   of int * int * int       (* 6x6x6 color cube *)
  | Gray  of int                   (* 24 grayscale levels *)
;;
type weight = Regular | Bold
type color =
    Basic of basic_color * weight
  | RGB of int * int * int
  | Gray of int
# [RGB (250,70,70); Basic (Green, Regular)];;
- : color list = [RGB (250, 70, 70); Basic (Green, Regular)]

(* OCaml Utop ∗ variants/main.topscript , continued (part 3) ∗ all code *)
```
我们再一次用模式匹配将颜色转换为对应的数字。但这回，模式匹配就不仅仅是用以分离不同实例了，它也允许我们提取标签关联的数据：
```ocaml
# let color_to_int = function
    | Basic (basic_color,weight) ->
      let base = match weight with Bold -> 8 | Regular -> 0 in
      base + basic_color_to_int basic_color
    | RGB (r,g,b) -> 16 + b + g * 6 + r * 36
    | Gray i -> 232 + i ;;
val color_to_int : color -> int = <fun>

(* OCaml Utop ∗ variants/main.topscript , continued (part 4) ∗ all code *)
```
现在我们就可以使用全部可用颜色来打印文本了：
```ocaml
# let color_print color s =
     printf "%s\n" (color_by_number (color_to_int color) s);;
val color_print : color -> string -> unit = <fun>
# color_print (Basic (Red,Bold)) "A bold red!";;
A bold red!
# color_print (Gray 4) "A muted gray...";;
A muted gray...

(* OCaml Utop ∗ variants/main-5.rawscript ∗ all code *)
```

### 笼统实例和重构
>> Catch-All Cases and Refactoring

OCaml类型系统可以作为重构工具使用，当你的代码需要更新以匹配接口的修改时会警告你。这在变体上下文中尤为重要。

考虑一下，如果我们像下面这样修改了`color`的定义会怎样：
```ocaml
# type color =
  | Basic of basic_color     (* basic colors *)
  | Bold  of basic_color     (* bold basic colors *)
  | RGB   of int * int * int (* 6x6x6 color cube *)
  | Gray  of int             (* 24 grayscale levels *)
;;
type color =
    Basic of basic_color
  | Bold of basic_color
  | RGB of int * int * int
  | Gray of int

(* OCaml Utop ∗ variants/catch_all.topscript , continued (part 1) ∗ all code *)
```
我们实际上把`Basic`实例分成了`Basic`和`Bold`两个，且`Basic`的参数从两个变为一个。`color_to_int`仍然期望一个旧的变体结构，如果我们试图编译这段代码，编译器会发现这种失配：
```ocaml
# let color_to_int = function
    | Basic (basic_color,weight) ->
      let base = match weight with Bold -> 8 | Regular -> 0 in
      base + basic_color_to_int basic_color
    | RGB (r,g,b) -> 16 + b + g * 6 + r * 36
    | Gray i -> 232 + i ;;
Characters 34-60:
Error: This pattern matches values of type 'a * 'b
       but a pattern was expected which matches values of type basic_color

(* OCaml Utop ∗ variants/catch_all.topscript , continued (part 2) ∗ all code *)
```
这里编译器报怨`Basic`标签参数个数错误。如果我们修复了这个问题，编译器又会给出第二个问题，那就是我们还没有处理新的`Bold`标签：
```ocaml
# let color_to_int = function
    | Basic basic_color -> basic_color_to_int basic_color
    | RGB (r,g,b) -> 16 + b + g * 6 + r * 36
    | Gray i -> 232 + i ;;


Characters 19-154:
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
Bold _val
color_to_int : color -> int = <fun>

(* OCaml Utop ∗ variants/catch_all.topscript , continued (part 3) ∗ all code *)
```
现在把这个改了，我们就获得了正确的实现：
```ocaml
# let color_to_int = function
    | Basic basic_color -> basic_color_to_int basic_color
    | Bold  basic_color -> 8 + basic_color_to_int basic_color
    | RGB (r,g,b) -> 16 + b + g * 6 + r * 36
    | Gray i -> 232 + i ;;
val color_to_int : color -> int = <fun>

(* OCaml Utop ∗ variants/catch_all.topscript , continued (part 4) ∗ all code *)
```
如你所见，类型错误指出了需要修正以完成代码重构的问题。这非常非常重要，但要使它可靠地工作，你的代码需要尽可能地让编译器有机会你发现bug。为此，有一个有用的经验法则，就是避免避免笼统地模式匹配。

这里有一个例子展示了笼统实例与完整性检查之间的交互。假设我们想要一个`color_to_int`，它作用在老终端上，前16个颜色（普通和粗体的八个`basic_colors`）正常转换，而其它的一切都转换成白色。我们可以把这个函数写成下面这样：
```ocaml
# let oldschool_color_to_int = function
    | Basic (basic_color,weight) ->
      let base = match weight with Bold -> 8 | Regular -> 0 in
      base + basic_color_to_int basic_color
    | _ -> basic_color_to_int White;;
Characters 44-70:
Error: This pattern matches values of type 'a * 'b
but a pattern was expected which matches values of type basic_color

(* OCaml Utop ∗ variants/catch_all.topscript , continued (part 5) ∗ all code *)
```
但是因为笼统实例包含了所有可能，当添加了`Bold`实例后，类型系统就不会再警告我们没有处理它了。我们可以避免笼统实例，使用显式的标签代替，这样就可以找回这种检查了。

### 结合记录和变体
*代数数据类型*这个术语经常用以描述包括变体、记录和元组这几个类型的集合。代数数据类型可以作为用以描述数据的有用且强大的语言。核心原因是它们结合了两种不同类型： *积类型（product type）*，像元组和记录，把不同类型组合在一起，数学上类似于笛卡儿积；以及 *和类型(sum type)*，像变体，它可以把不同的可能组合在一个类型中，数学上类似于不相交并集。

代数数据类型的大部分能力都来自于其构建分层的和或积组合的能力。我们可以重新实现一下[第5章，记录](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_05_records.md)中描述的日志服务器类型。先回顾一下`Log_entry.t`的定义：
```ocaml
# module Log_entry = struct
    type t =
      { session_id: string;
        time: Time.t;
        important: bool;
        message: string;
      }
  end
  ;;
module Log_entry :
  sig
    type t = {
      session_id : string;
      time : Time.t;
      important : bool;
      message : string;
    }
  end

(* OCaml Utop ∗ variants/logger.topscript , continued (part 1) ∗ all code *)
```
这个记录类型把多块数据组合在一个值中。就是单独一个`Log_entry`拥有一个`session_id`、一个`time`、一个`important`和一个`message`。更一般地，你可以把记录想成 *联合*。另一方面，变体是 *解析*，让你可以表示多个可能，如下所示：
```ocaml
# type client_message = | Logon of Logon.t
                        | Heartbeat of Heartbeat.t
                        | Log_entry of Log_entry.t
  ;;
type client_message =
    Logon of Logon.t
  | Heartbeat of Heartbeat.t
  | Log_entry of Log_entry.t

(* OCaml Utop ∗ variants/logger.topscript , continued (part 2) ∗ all code *)
```
一个`client_message`是一个`Logon`或`Heartbeat`或`Log_entry`。如果我们想要写出可以处理消息的通用代码，而不是只针对一个固定要类型，就需要像`client_message`这种包罗万象的的类型来代表不同的可能消息。然后我们可以匹配`client_message`来确定正在实际处理的消息类型。

使用变体表示不同类型间的差异可以增加你类型的精确性，用记录则可以表示共享结构。考虑下面这个函数，接收一个`client_message`列表，返回给定用户的所有消息。代码通过折叠（fold）消息列表实现，积加器是下面两个元素的序对：
- 已经处理过的该用户的会话标识集合
- 已处理过和该用户关联的消息集合

具体代码如下：
```ocaml
# let messages_for_user user messages =
    let (user_messages,_) =
      List.fold messages ~init:([],String.Set.empty)
        ~f:(fun ((messages,user_sessions) as acc) message ->
          match message with
          | Logon m ->
            if m.Logon.user = user then
              (message::messages, Set.add user_sessions m.Logon.session_id)
            else acc
          | Heartbeat _ | Log_entry _ ->
            let session_id = match message with
              | Logon     m -> m.Logon.session_id
              | Heartbeat m -> m.Heartbeat.session_id
              | Log_entry m -> m.Log_entry.session_id
            in
            if Set.mem user_sessions session_id then
              (message::messages,user_sessions)
            else acc
        )
    in
    List.rev user_messages
  ;;
val messages_for_user : string -> client_message list -> client_message list =
  <fun>
  
(* OCaml Utop ∗ variants/logger.topscript , continued (part 3) ∗ all code *)
```
上面的代码有一部分很难看，就是决定会话ID那部分逻辑。代码有点复杂，要关注每一种可能的消息类型（包括`Logon`实例，它是不可能出现在此处的）并在每个实例中提取会话ID。这种每个消息类型都处理的方式看起来是没有必要的，因为会话ID在所有的消息类型中的行为都一致。

我们可以重构我们的类型来改进，显式反映要在不同消息间共享的信息。第一步是减小每个消息记录的定义，使其只包含此记录独有的信息：
```ocaml
# module Log_entry = struct
    type t = { important: bool;
               message: string;
             }
  end
  module Heartbeat = struct
    type t = { status_message: string; }
  end
  module Logon = struct
    type t = { user: string;
               credentials: string;
             }
  end ;;
module Log_entry : sig type t = { important : bool; message : string; } end
module Heartbeat : sig type t = { status_message : string; } end
module Logon : sig type t = { user : string; credentials : string; } end

(* OCaml Utop ∗ variants/logger.topscript , continued (part 4) ∗ all code *)
```
然后定义一个变体类型来组合这些类型：
```ocaml
# type details =
    | Logon of Logon.t
    | Heartbeat of Heartbeat.t
    | Log_entry of Log_entry.t
 ;;
type details =
    Logon of Logon.t
  | Heartbeat of Heartbeat.t
  | Log_entry of Log_entry.t

(* OCaml Utop ∗ variants/logger.topscript , continued (part 5) ∗ all code *)
```
我们还需要一个单独的记录来包含所有消息共有的字段：
```ocaml
# module Common = struct
    type t = { session_id: string;
               time: Time.t;
             }
  end ;;
module Common : sig type t = { session_id : string; time : Time.t; } end

(* OCaml Utop ∗ variants/logger.topscript , continued (part 6) ∗ all code *)
```

一个完整的消息可以用`Common.t`和一个`details`的序对表示。这样，我们就可以像下面这样重写之前的例子：
```ocaml
# let messages_for_user user messages =
    let (user_messages,_) =
      List.fold messages ~init:([],String.Set.empty)
        ~f:(fun ((messages,user_sessions) as acc) ((common,details) as message) ->
          let session_id = common.Common.session_id in
          match details with
          | Logon m ->
            if m.Logon.user = user then
              (message::messages, Set.add user_sessions session_id)
            else acc
          | Heartbeat _ | Log_entry _ ->
            if Set.mem user_sessions session_id then
              (message::messages,user_sessions)
            else acc
        )
    in
    List.rev user_messages
  ;;
val messages_for_user :
  string -> (Common.t * details) list -> (Common.t * details) list = <fun>

(* OCaml Utop ∗ variants/logger.topscript , continued (part 7) ∗ all code *)
```

如你所见，提取会话ID的代码已被一个简单的表达式`common.Common.session_id`所代替。

另外，这样的设计允许我们一旦知道了类型是什么，就可以向下转换到特定的消息类型，并转向只处理此种消息类型的代码。我们使用`Commin.t * details`类型来代表任意类型，也可以使用`Common.t * Logon.t`来表示一条登录消息。因此，如果我们有了处理单独消息类型的函数，就可以写出如下的分发函数：

```ocaml
# let handle_message server_state (common,details) =
    match details with
    | Log_entry m -> handle_log_entry server_state (common,m)
    | Logon     m -> handle_logon     server_state (common,m)
    | Heartbeat m -> handle_heartbeat server_state (common,m)
  ;;
Characters 95-111:
Error: Unbound value handle_log_entry

(* OCaml Utop ∗ variants/logger.topscript , continued (part 8) ∗ all code *)
```
在类型层面很明显，`handle_log_entry`只处理`Log_entry`消息，而`handle_logon`只处理`Logon`消息，以此类推。

### 变体和递归数据结构
变体的另一个常见应用是表示树状数据结构。我们将通过走一遍一个简单布尔表达式语言的设计来展示如何做到这一点。这种语言在任何需要指定过滤器的地方都很有用，在从数据包分析器到邮件客户端的很多应用中，过滤器都有用处。

这种语言中的表达式由一个变体`expr`定义，其中对每一种支持的表达式都对应一个标签：
```ocaml
# type 'a expr =
    | Base  of 'a
    | Const of bool
    | And   of 'a expr list
    | Or    of 'a expr list
    | Not   of 'a expr
  ;;
type 'a expr =
    Base of 'a
  | Const of bool
  | And of 'a expr list
  | Or of 'a expr list
  | Not of 'a expr

(* OCaml Utop ∗ variants/blang.topscript ∗ all code *)
```
注意`expr`类型的定义是递归的，这意味着一个`expr`可以包含其它`expr`。同时，`expr`使用一个多态类型`'a`参数化，用以指定`Base`标签下值的类型。

每个标签的目的都很直接。`And`、`Or`和`Not`是构建布尔表达式的基本运算符，`Const`用以输入常量true和false。

`Base`标签允许你把`expr`和你的应用联系起来，让你指定一些基本谓词类型的元素，其真或假取决于你的应用。如果你在给一个邮件处理器写过滤语言，你的基本谓词可能指定了你要针对邮件做的测试，如下所示：
```ocaml
# type mail_field = To | From | CC | Date | Subject
  type mail_predicate = { field: mail_field;
                          contains: string }
  ;;
type mail_field = To | From | CC | Date | Subject
type mail_predicate = { field : mail_field; contains : string; }

(* OCaml Utop ∗ variants/blang.topscript , continued (part 1) ∗ all code *)
```
使用上面的代码，我们就能以`mail_predicate`为基本谓词创建一个简单表达式了：
```ocaml
# let test field contains = Base { field; contains };;
val test : mail_field -> string -> mail_predicate expr = <fun>
# And [ Or [ test To "doligez"; test CC "doligez" ];
        test Subject "runtime";
      ]
  ;;
- : mail_predicate expr =
And
 [Or
   [Base {field = To; contains = "doligez"};
    Base {field = CC; contains = "doligez"}];
  Base {field = Subject; contains = "runtime"}]

(* OCaml Utop ∗ variants/blang.topscript , continued (part 2) ∗ all code *)
```
只能构造表达式还不够，我们还需要能对其求值。下面即是一个求值函数：
```ocaml
# let rec eval expr base_eval =
    (* a shortcut, so we don't need to repeatedly pass [base_eval]
       explicitly to [eval] *)
    let eval' expr = eval expr base_eval in
    match expr with
    | Base  base   -> base_eval base
    | Const bool   -> bool
    | And   exprs -> List.for_all exprs ~f:eval'
    | Or    exprs -> List.exists  exprs ~f:eval'
    | Not   expr  -> not (eval' expr)
  ;;
val eval : 'a expr -> ('a -> bool) -> bool = <fun>

(* OCaml Utop ∗ variants/blang.topscript , continued (part 3) ∗ all code *)
```
代码结构很清晰--我们只是在数据结构上使用模式匹配，根据标签施加合适的计算。要在具体例子中使用这个求值器，我们只需要写一个`base_eval`函数，用以求值一个基本谓词。

表达式的另一个有用的操作符是简化。下面是一组简化构造函数，每一个对应于`expr`中的一个标签：
```ocaml
# let and_ l =
    if List.mem l (Const false) then Const false
    else
      match List.filter l ~f:((<>) (Const true)) with
      | [] -> Const true
      | [ x ] -> x
      | l -> And l

  let or_ l =
    if List.mem l (Const true) then Const true
    else
      match List.filter l ~f:((<>) (Const false)) with
      | [] -> Const false
      | [x] -> x
      | l -> Or l

  let not_ = function
    | Const b -> Const (not b)
    | e -> Not e
  ;;
val and_ : 'a expr list -> 'a expr = <fun>
val or_ : 'a expr list -> 'a expr = <fun>
val not_ : 'a expr -> 'a expr = <fun>

(* OCaml Utop ∗ variants/blang.topscript , continued (part 4) ∗ all code *)
```
基于以上函数我们可以写一个简化例程.
```ocaml
# let rec simplify = function
    | Base _ | Const _ as x -> x
    | And l -> and_ (List.map ~f:simplify l)
    | Or l  -> or_  (List.map ~f:simplify l)
    | Not e -> not_ (simplify e)
  ;;
val simplify : 'a expr -> 'a expr = <fun>

(* OCaml Utop ∗ variants/blang.topscript , continued (part 5) ∗ all code *)
```
我们可以将其作用于一个布尔表达式，看看简化得怎么样：
```ocaml
# simplify (Not (And [ Or [Base "it's snowing"; Const true];
                       Base "it's raining"]));;
- : string expr = Not (Base "it's raining")

(* OCaml Utop ∗ variants/blang.topscript , continued (part 6) ∗ all code *)
```
这里，它正确地将`Or`分支转换成`Const true`，然后完全消除了`And`，因为`And`只剩下一个有内容的元素了。

然而，有一些简化被忽略了。看一下如果我们添加一个双重否定会怎样：
```ocaml
# simplify (Not (And [ Or [Base "it's snowing"; Const true];
                       Not (Not (Base "it's raining"))]));;
- : string expr = Not (Not (Not (Base "it's raining")))

(* OCaml Utop ∗ variants/blang.topscript , continued (part 7) ∗ all code *)
```
它未能移除双重否定，原因显而易见。`not_`函数有一个笼统分支，所以除了它会显式处理的（即一个常量取反）以外，它会忽略一切。笼统分支通常都不是个好主意，代码写出的细节越多，双重否定处理的缺失就越明显：
```ocaml
# let not_ = function
    | Const b -> Const (not b)
    | (Base _ | And _ | Or _ | Not _) as e -> Not e
  ;;
val not_ : 'a expr -> 'a expr = <fun>

(* OCaml Utop ∗ variants/blang.topscript , continued (part 8) ∗ all code *)
```
当然我们可以简单添加一个处理双重否定的分支来解决此问题：
```ocaml
# let not_ = function
    | Const b -> Const (not b)
    | Not e -> e
    | (Base _ | And _ | Or _ ) as e -> Not e
  ;;
val not_ : 'a expr -> 'a expr = <fun>

(* OCaml Utop ∗ variants/blang.topscript , continued (part 9) ∗ all code *)
```
布尔达式的例子可不仅仅是个玩具。Core中有一个很类似的模块叫`Blang`（“Boolean language”的缩写），它在很多应用中都广泛使用。简化算法很有用，特别是在一些基本谓词已知的情况下，你想用其来研究表达式的求值时。

更一般地，用变体构建递归数据结构是一种常用技术，从设计小语言到构造复杂数据结构，到处都在使用。

### 多态变体
除了我们已经见到的普通变体，OCaml还支持多态变体。我们将会看到，多态变体更灵活，语法上也比普通变体强大，但额外的功能必然也有额外的代价。

语法上讲，多态变体以前导的撇号和普通变体相区别。且和普通变体不同，多态变体没有显式的类型声明也可以使用：
```ocaml
# let three = `Int 3;;
val three : [> `Int of int ] = `Int 3
# let four = `Float 4.;;
val four : [> `Float of float ] = `Float 4.
# let nan = `Not_a_number;;
val nan : [> `Not_a_number ] = `Not_a_number
# [three; four; nan];;
- : [> `Float of float | `Int of int | `Not_a_number ] list =
[`Int 3; `Float 4.; `Not_a_number]
(* OCaml Utop ∗ variants/main.topscript , continued (part 6) ∗ all code *)
```
如你所见，多态变体类型可以被自动推导，当我们把多个不同标签的变体组合在一起时，编译器会推导出一个新类型，这个类型可以知道所有这些标签。注意，在上面的例子中，标签名（如`` `Int``）和类型名(`int`)是匹配的。这在OCaml中是个常见的惯例。

同一个标签以不兼容的方式使用时，编译器会指出：
```ocaml
# let five = `Int "five";;
val five : [> `Int of string ] = `Int "five"
# [three; four; five];;
Characters 14-18:
Error: This expression has type [> `Int of string ]
       but an expression was expected of type
         [> `Float of float | `Int of int ]
       Types for tag `Int are incompatible

(* OCaml Utop ∗ variants/main.topscript , continued (part 7) ∗ all code *)
```
开头的`>`是必须是，因为它标明这个类型是开放的，可以和其它变体类型组合。我们可以将`` [> `Int of string | `Float of float]``这样解读：描述了一个标签为`` `Int of string``和`` `Float of float``的变体类型，但还可以包含更多的标签。换句话说，你可以简单地把`>`当作“这些或更多的标签”。

有些情况下OCaml会推导出带`<`的类型，表示“这些或更少的标签”，如下所示：
```ocaml
# let is_positive = function
     | `Int   x -> x > 0
     | `Float x -> x > 0.
  ;;
val is_positive : [< `Float of float | `Int of int ] -> bool = <fun>

(* OCaml Utop ∗ variants/main.topscript , continued (part 8) ∗ all code *)
```
有`<`是因为`is_positive`无法处理含有`` `Float of float`` 或`` `Int of int``以外标签的值。

我们可以把这些`<`和`>`标记看作已有标签的上下边界。如果标签集即是上边界又是下边界，我们就得到了一个确切的多态变体类型，什么标记都没有。例如：
```ocaml
# let exact = List.filter ~f:is_positive [three;four];;
val exact : [ `Float of float | `Int of int ] list = [`Int 3; `Float 4.]

(* OCaml Utop ∗ variants/main.topscript , continued (part 9) ∗ all code *)
```
这可能今人吃惊，我们也可以创建有不同上下边界的多态变体类型。注意下例中的`Ok`和`Error`来自Core中的`Result.t`类型：
```ocaml
# let is_positive = function
     | `Int   x -> Ok (x > 0)
     | `Float x -> Ok (x > 0.)
     | `Not_a_number -> Error "not a number";;
val is_positive :
  [< `Float of float | `Int of int | `Not_a_number ] ->
  (bool, string) Result.t = <fun>
# List.filter [three; four] ~f:(fun x ->
     match is_positive x with Error _ -> false | Ok b -> b);;
- : [< `Float of float | `Int of int | `Not_a_number > `Float `Int ] list =
[`Int 3; `Float 4.]

(* OCaml Utop ∗ variants/main.topscript , continued (part 10) ∗ all code *)
```
这里，推导出来类型表示标签不能多于`` `Float`` 、`` `Int``和`` `Not_a_number``，但又必须包含`` `Float``和`` `Int``。你已经看到了，多态变体可能会导致异常复杂的推导类型。

#### 例子：再看终端颜色
现在看一下实践中如何使用多态变体，我们回过头来看一下终端颜色的例子。假设我们有一个新的添加了更多颜色的终端颜色类型，添加alpha通道，使你可以指定颜色的透明度。我们可以使用普通变体像下面这样对这个颜色集建模：
```ocaml
# type extended_color =
    | Basic of basic_color * weight  (* basic colors, regular and bold *)
    | RGB   of int * int * int       (* 6x6x6 color space *)
    | Gray  of int                   (* 24 grayscale levels *)
    | RGBA  of int * int * int * int (* 6x6x6x6 color space *)
  ;;
type extended_color = 
    Basic of basic_color * weight 
  | RGB of int * int * int 
  | Gray of int 
  | RGBA of int * int * int * int

(* OCaml Utop ∗ variants/main.topscript , continued (part 11) ∗ all code *)
```
我们想要写一个`extended_color_to_int`函数，对老类型作用和`color_to_int`一样，只是添加了处理包含alpha通道颜色的新逻辑。有人可能会写出下面的代码：
```ocaml
# let extended_color_to_int = function
    | RGBA (r,g,b,a) -> 256 + a + b * 6 + g * 36 + r * 216
    | (Basic _ | RGB _ | Gray _) as color -> color_to_int color
  ;;
Characters 154-159: Error: This expression has type extended_color but an expression was expected of type color

(* OCaml Utop ∗ variants/main.topscript , continued (part 12) ∗ all code *)
```
代码看起来挺合理，但是它会引起类型错误，因为在编译器看来，`extended_color`和`color`是两个不同的没有关系的类型。编译器不会识别两个类型中相同的基本标签。

我们想要做的就是在两个不同变体类型之间共享标签，而多态变体正好可以以一种自然的方式做到这一点。首先，我们用多态变体重写`basic_color_to_int`和`color_to_int`。转换相当直接：
```ocaml
# let basic_color_to_int = function
    | `Black -> 0 | `Red     -> 1 | `Green -> 2 | `Yellow -> 3
    | `Blue  -> 4 | `Magenta -> 5 | `Cyan  -> 6 | `White  -> 7

  let color_to_int = function
    | `Basic (basic_color,weight) ->
      let base = match weight with `Bold -> 8 | `Regular -> 0 in
      base + basic_color_to_int basic_color
    | `RGB (r,g,b) -> 16 + b + g * 6 + r * 36
    | `Gray i -> 232 + i
 ;;
val basic_color_to_int : 
  [< `Black | `Blue | `Cyan | `Green | `Magenta | `Red | `White | `Yellow ] -> 
  int = <fun> 
val color_to_int : 
  [< `Basic of 
      [< `Black 
       | `Blue 
       | `Cyan 
       | `Green 
       | `Magenta 
       | `Red 
       | `White 
       | `Yellow ] * 
      [< `Bold | `Regular ] 
  | `Gray of int 
  | `RGB of int * int * int ] -> 
  int = <fun>

(* OCaml Utop ∗ variants/main.topscript , continued (part 13) ∗ all code *)
```
现在我们可以尝试写`extended_color_to_int`了。代码的关键是`extended_color_to_int`要以窄化的类型（即更少的标签）调用`color_to_int`。正常来讲，这种窄化可以使用模式匹配来完成。下面的代码中，`color`变量只包含`` `Basic``、`` `RGB``和`` `Gray``标签，而不包含`` `RGBA``标签：
```ocaml
# let extended_color_to_int = function
    | `RGBA (r,g,b,a) -> 256 + a + b * 6 + g * 36 + r * 216
    | (`Basic _ | `RGB _ | `Gray _) as color -> color_to_int color
  ;;
val extended_color_to_int :
  [< `Basic of 
       [< `Black 
        | `Blue 
        | `Cyan 
        | `Green 
        | `Magenta 
        | `Red 
        | `White 
        | `Yellow ] * 
       [< `Bold | `Regular ] 
  | `Gray of int 
  | `RGB of int * int * int 
  | `RGBA of int * int * int * int ] -> 
  int = <fun>

(* OCaml Utop ∗ variants/main.topscript , continued (part 14) ∗ all code *)
```
上面的代码比通常想像的都要平衡。实际上，如果我们用一个笼统的分支代替显式的枚举，那么类型就不会被窄化，编译就会失败：
```ocaml
# let extended_color_to_int = function
    | `RGBA (r,g,b,a) -> 256 + a + b * 6 + g * 36 + r * 216
    | color -> color_to_int color
  ;;
Characters 125-130: 
Error: This expression has type [> `RGBA of int * int * int * int ] 
       but an expression was expected of type 
         [< `Basic of 
              [< `Black 
               | `Blue 
               | `Cyan 
               | `Green 
               | `Magenta 
               | `Red 
               | `White 
               | `Yellow ] * 
               [< `Bold | `Regular ] 
         | `Gray of int 
         | `RGB of int * int * int ] 
       The second variant type does not allow tag(s) `RGBA

(* OCaml Utop ∗ variants/main.topscript , continued (part 15) ∗ all code *)
```

> **多态变体和笼统分支(catch-all cases)**
> 
> 之前见到的`is_positive`定义中，`match`语句导致推导出一个有上边界的变体类型，限制了匹配可以处理的标签。如果我们在`match`语句上添加一个笼统分支，就会得到一个有下边界的类型：
> ```ocaml
> # let is_positive_permissive = function
>     | `Int   x -> Ok (x > 0)
>     | `Float x -> Ok (x > 0.)
>     | _ -> Error "Unknown number type"
>  ;;
> val is_positive_permissive : [> `Float of float | `Int of int ] -> (bool, string)  Result.t = <fun>
> # is_positive_permissive (`Int 0);;
> - : (bool, string) Result.t = Ok false
> # is_positive_permissive (`Ratio (3,4));;
> - : (bool, string) Result.t = Error "Unknown number type"
>
> (* OCaml Utop ∗ variants/main.topscript , continued (part 16) ∗ all code *)
> ```
> 即使是使用普通变体，笼统分支也是滋生错误的温床，但是和多态变体一起使用时，这个问题尤为严重。因为你无法界定你的函数可以处理哪些标签。这种代码特别容易受输入错误的影响。举个例子，如果代码中传递给`is_positive_permissive`的`Float`误拼成了`Floot`，错误的代码也可以编译并不报错。
> ```ocaml
> # is_positive_permissive (`Floot 3.5);;
> - : (bool, string) Result.t = Error "Unknown number type"
> (* OCaml Utop ∗ variants/main.topscript , continued (part 17) ∗ all code *)
> ```
> 使用普通变体，这种输入错误会导致一个不识别的标签。通常，混合使用笼统分支和多态变体时都要格外小心。、

对在让我们来考虑一下如何把我们的代码装进一个合适的库，实现在ml文件中，接口在单独的mli文件中，就和[第四章，文件、模块和程序](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_04_files_modules_and_programs.md)中看到的那样。让我们从mli文件开始：
```ocaml
open Core.Std

type basic_color =
  [ `Black   | `Blue | `Cyan  | `Green
  | `Magenta | `Red  | `White | `Yellow ]

type color =
  [ `Basic of basic_color * [ `Bold | `Regular ]
  | `Gray of int
  | `RGB  of int * int * int ]

type extended_color =
  [ color
  | `RGBA of int * int * int * int ]

val color_to_int          : color -> int
val extended_color_to_int : extended_color -> int

(* OCaml ∗ variants-termcol/terminal_color.mli ∗ all code *)
```
这里， `extended_color`被显式地定义为`color`的一个扩展。同时，注意我们把所有类型都定义成了确切变体。我们可以像下面这样实现这个库：
```ocaml
open Core.Std

type basic_color =
  [ `Black   | `Blue | `Cyan  | `Green
  | `Magenta | `Red  | `White | `Yellow ]

type color =
  [ `Basic of basic_color * [ `Bold | `Regular ]
  | `Gray of int
  | `RGB  of int * int * int ]

type extended_color =
  [ color
  | `RGBA of int * int * int * int ]

let basic_color_to_int = function
  | `Black -> 0 | `Red     -> 1 | `Green -> 2 | `Yellow -> 3
  | `Blue  -> 4 | `Magenta -> 5 | `Cyan  -> 6 | `White  -> 7

let color_to_int = function
  | `Basic (basic_color,weight) ->
    let base = match weight with `Bold -> 8 | `Regular -> 0 in
    base + basic_color_to_int basic_color
  | `RGB (r,g,b) -> 16 + b + g * 6 + r * 36
  | `Gray i -> 232 + i

let extended_color_to_int = function
  | `RGBA (r,g,b,a) -> 256 + a + b * 6 + g * 36 + r * 216
  | `Grey x -> 2000 + x
  | (`Basic _ | `RGB _ | `Gray _) as color -> color_to_int color

(* OCaml ∗ variants-termcol/terminal_color.ml ∗ all code *)
```
在上面的代码中，定义`extended_color_to_int`时我们做了一些有趣的事来暴露多态变体的劣势。我们添加了一个特别的分支来处理灰色，而不是使用`color_to_int`。但不幸的是，我们把`Gray`误拼成了`Grey`。使用普通变体时编译器显然应该会捕捉到这个错误，但是使用多态变体，编译没有任何问题。所有的不同就是编译器为`extended_color_to_int`推导出了一个更宽的类型，它恰好与mli文件中列出的较窄的类型兼容。

如果我们给代码添加一个类型注释（不仅是在mli中），那么编译器就会有足够的信息来警告我们了：
```ocaml
let extended_color_to_int : extended_color -> int = function
  | `RGBA (r,g,b,a) -> 256 + a + b * 6 + g * 36 + r * 216
  | `Grey x -> 2000 + x
  | (`Basic _ | `RGB _ | `Gray _) as color -> color_to_int color
```
这样编译器就会报怨`` `Grey``分支没有使用：
```bash
$ corebuild terminal_color.native
File "terminal_color.ml", line 30, characters 4-11:
Error: This pattern matches values of type [? `Grey of 'a ]
       but a pattern was expected which matches values of type extended_color
       The second variant type does not allow tag(s) `Grey
Command exited with code 2.
Terminal ∗ variants-termcol-annotated/build.out ∗ all code
```
一旦定义了类型，我们就可以重新审视如何写出窄化类型的模式匹配这个问题。我们可以显式地使用类型名作为模式匹配的一部分，加一个`#`前缀：
```ocaml
let extended_color_to_int : extended_color -> int = function
  | `RGBA (r,g,b,a) -> 256 + a + b * 6 + g * 36 + r * 216
  | #color as color -> color_to_int color
```
当你想要窄化一个定义很长的类型时，这就有用了，你绝不想在匹配中啰唆地显式重写这些标签。

#### 何时使用多态变体
乍一看，多态变体绝对是普通变体的升级版。你可以做普通变体能做的任何事，还更灵活更简洁。还有什么理由不喜欢它呢？

实际上，多数时候普通变体才是更实际的选择。因为多态变体的灵活性是有代价的。下面是一些缺点：

- 复杂性
  
   正如我们所见，多态变体的类型规则比普通变体要复杂得多。这意味着重度使用多态会让你在查看为什么一段代码为什么能或不能编译时抓狂。也会使错误消息冗长并难以解读。实际上，值层面上的简洁往往是牺牲了类型层面的复杂性。
- 错误查找

  多态类型是类型安全的，但是需要小心输入，其灵活性使它不容易捕捉你程序中的bug。
- 效率

  这一点影响不是非常大，但多态变体会比普通变体重一些，OCaml不能给多态类型的模式匹配生成和普通变体那样就效的代码。

就是说，多态变体仍然是有用的强大的特性，但理解其局限性并搞清楚如何明智且慬慎地使用它们是值得的。

可能最安全也是最常见的多态变体使用场景是普通变体也足够但却太重量级时。比如，你经常想要创建一个变体类型来编码输入或输出，又不值得为这声明一个单独的类型。这时多态类型就非常有用了，和使用类型注释把它们限制到显式的、明确的类型上一样，都可以很好地工作。

变体最有问题的地方也是其最强大的地方；特别是当你使用多态变体支持标签重叠的功能时。这涉及OCaml对子类化的支持。正如我们将在[第11章，对象](https://github.com/zforget/translation/blob/master/real_world_ocaml/1_11_objects.md)中讨论的那样，子类化带来许多复杂性，多数时候，这种复杂性是应该避免的。
