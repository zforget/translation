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
在多数终端里，”Blue“都会以蓝色呈现。

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

OCaml类型系统可以作为重构工具使用，当你的代码需要更新以匹配接口的修改时会警告你。这个变体上下文中尤为重要。

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
但是因为笼统实例包含了所有可能，当添加了`Bold`实例后，类型系统就不会再警告我们没有处理它了。我们可以避免笼统实例，使用显式的标签代替，这样就可以找回这样检查了。

### 结合记录和变体
*代数数据类型*这个术语经常用以描述包括变体、记录和元组这几个类型的集合。代数数据类型可以作为用以描述数据的有用且强大的语言。核心原因是它们结合了两种不同类型：*积类型（product type）*，像元组和记录，把不同类型组合在一起，数学上类似于笛卡儿积；以及*和类型(sum type)*，像变体，它使用可以把不同的可能组合在一个类型中，数学上类似于不相交并集。

代数数据类型的大部分能力都来自于其构建分层的和或积组合的能力。我们可以重新实现一下[第5章，记录](#记录)中描述的日志服务器类型。先回顾一下`Log_entry.t`的定义：
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
这个记录类型把多块数据组合在一个值中。就是单独一个`Log_entry`拥有一个`session_id`、一个`time`、一个`important`和一个`message`。更一般地，你可以把记录想成连合。另一方面，变体是解析，让你可以表示多个可能，如下所示：
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

使用变体表示不同类型间的差异可以增加你类型的精确性，用记录来表示共享结构。考虑下面这个函数，接收一个`client_message`列表，返回给定用户的所有消息。代码通过折叠消息列表实现，积加器是下面两个元素的序对：
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
上面的代码有一部分很难看，就是决定会话ID那部分逻辑。代码有点复杂，关注每一种可能的消息类型（包括`Logon`实例，它是不可能出现在此处的）并在每个实例中提取会话ID。这种每个消息类型都处理的方式看起来是没有必要的，因为会话ID在所有的消息类型中的行为都一致。

我们可以重构我们的类型来改进，显式反映要在不同消息间共享的信息。第一步是减小每个消息记录的定义，使其只包含此记录才有的信息：
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
我们还需要一个单独的记录来包含所有消息都有的字段：
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
变体的另一个常见应用是表示树状数据结构。我们将通过走一遍一个简单布尔表达式语言的设计来展示如何做到这一点。这种语言在任何需要指定过滤器的地方都很有用，过滤器在从数据包分析器到邮件客户端都有用。

### Polymorphic Variants
#### Example: Terminal Colors Redux
#### When to Use Polymorphic Variants
