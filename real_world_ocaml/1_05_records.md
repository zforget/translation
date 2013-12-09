## 第五章 记录
OCaml最好的特性之一就是其简捷且富有表达力的用以声明新数据类型的系统，记录是这个系统的一个关键要素。在[第一章导览](#导览)中我们简要讨论了一下记录，但本章会更深入，覆盖记录类型的工作原理，以及如何在软件设计中有效使用它们的建议。

记录表示一组存储在一起的值，每个组件由一个不同的字段名标识。记录类型的基本语法如下所示。
```ocaml
type <record-name> =
  { <field> : <type> ;
    <field> : <type> ;
    ...
  }

(* Syntax ∗ records/record.syntax ∗ all code *)
```
注意记录的字段名必须以小写字母开头。

这里有一个简单例子，记录`host_info`是一个计算机信息的摘要。
```ocaml
# type host_info =
    { hostname   : string;
      os_name    : string;
      cpu_arch   : string;
      timestamp  : Time.t;
    };;
type host_info = {
  hostname : string;
  os_name : string;
  cpu_arch : string;
  timestamp : Time.t;
}

(* OCaml Utop ∗ records/main.topscript ∗ all code *)
```
我们可以很容易地构建一个`host_info`。下面的代码中使用了Core_extended中的`Shell`模块，用以将命令转发给shell以提取所需的当前系统信息。也使用了Core中`Time`模块的`Time.now`。
```ocaml
# #require "core_extended";;
 
# open Core_extended.Std;;
 
# let my_host =
    let sh = Shell.sh_one_exn in
    { hostname   = sh "hostname";
      os_name    = sh "uname -s";
      cpu_arch   = sh "uname -p";
      timestamp  = Time.now ();
    };;
val my_host : host_info =
  {hostname = "ocaml-www1"; os_name = "Linux"; cpu_arch = "unknown";
   timestamp = 2013-08-18 14:50:48.986085+01:00}

(* OCaml Utop ∗ records/main.topscript , continued (part 1) ∗ all code *)
```
你可能会问编译器是如何知道`my_host`是`host_info`类型的。这里编译器用以推断类型的方法就是根据记录的字段名。本章稍后我们会讨论当一个作用域中出现多个有相同字段名的记录类型时会如何。

一旦有了记录值，我们就可以使用点号`.`来从中提取字段。
```ocaml
# my_host.cpu_arch;;
- : string = "unknown"

(* OCaml Utop ∗ records/main.topscript , continued (part 2) ∗ all code *)
```
当声明一个OCaml类型时，你总是可以用一个多态类型将其参数化。记录在这方面并无二致。所以，下面的例子中是一个类型，可以给任意物品加时间戳。
```ocaml
# type 'a timestamped = { item: 'a; time: Time.t };;
type 'a timestamped = { item : 'a; time : Time.t; }

(* OCaml Utop ∗ records/main.topscript , continued (part 3) ∗ all code *)
```
然后我们就可以写出操作这个参数化类型的多态函数了。
```ocaml
# let first_timestamped list =
    List.reduce list ~f:(fun a b -> if a.time < b.time then a else b)
  ;;
val first_timestamped : 'a timestamped list -> 'a timestamped option = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 4) ∗ all code *)
```
### 模式和穷尽性
从记录获取信息的另一种方法是使用模块匹配，就像下面`host_info_to_string`的定义所示。
```ocaml
# let host_info_to_string { hostname = h; os_name = os;
                            cpu_arch = c; timestamp = ts;
                          } =
       sprintf "%s (%s / %s, on %s)" h os c (Time.to_sec_string ts);;
val host_info_to_string : host_info -> string = <fun>
# host_info_to_string my_host;;
- : string = "ocaml-www1 (Linux / unknown, on 2013-08-18 14:50:48)"

(* OCaml Utop ∗ records/main.topscript , continued (part 5) ∗ all code *)
```
注意我们使用的模块只有一种情况，而不是由`|`分割的多种情况。我们只需要一个模式，是因为记录类型的模式是 **不可辩驳的（irrefutable）**，就是说一个记录的模式匹配在运行时永远都不会失败。这是有道理的，因为记录中的字段总是相同的。通常，固定结构类型的模式都是不会失败的，如记录和元组，而列表和变体这种可变结构的类型就不是。

记录模式的另一个特点是它们不需要是完整的：一个模式可以只包含记录的一部分字段。这会带来方便，但也容易出错。特别是，这意味着当向记录中添加新字段时，编译器不会提示必须要更新代码以反映这些新字段。

举个例子，假如我们向记录`host_info`添加一个叫作`os_release`的字段，如下所示：
```ocaml
# type host_info =
    { hostname   : string;
      os_name    : string;
      cpu_arch   : string;
      os_release : string;
      timestamp  : Time.t;
    } ;;
type host_info = {
  hostname : string;
  os_name : string;
  cpu_arch : string;
  os_release : string;
  timestamp : Time.t;
}

(* OCaml Utop ∗ records/main.topscript , continued (part 6) ∗ all code *)
```
这时`host_info_to_string`的代码不经修改也仍然可以编译。但这种情况下，无疑你是希望更新`host_info_to_string`以包含`os_release`的，编译器最好能针对这种改变给出一个警告。

幸运的是，OCaml的确提供了一个可选的警告用以提示一个记录模式中有字段缺失。打开这个警告（在toplevel中键入`#warning "+9"`），编译器就会警告缺失的字段：
```ocaml
# #warnings "+9";;
# let host_info_to_string { hostname = h; os_name = os;
                            cpu_arch = c; timestamp = ts;
                          } =
    sprintf "%s (%s / %s, on %s)" h os c (Time.to_sec_string ts);;


Characters 24-139:
Warning 9: the following labels are not bound in this record pattern:
os_release
Either bind these labels explicitly or add '; _' to the pattern.val host_info_to_string : host_info -> string = <fun> 
```
对于给定的模式，如果确定要忽略其余的字段，可以禁止这个警告。在模式最后加一个下划线即可：
```ocaml
# let host_info_to_string { hostname = h; os_name = os;
                            cpu_arch = c; timestamp = ts; _
                          } =
    sprintf "%s (%s / %s, on %s)" h os c (Time.to_sec_string ts);;
val host_info_to_string : host_info -> string = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 8) ∗ all code *)
```
打开不完整记录匹配的警告，然后在需要的地方用`_`显式禁止它是个好主意。

> **编译器警告**
>
> OCaml编译器有许多有用的警告，可以分别使能或禁止。编译器自身就有这方面文档，所以我们可以像下面这样查看9号警告：
> ```bash
>  $ ocaml -warn-help | egrep '\b9\b'
>  9 Missing fields in a record pattern.
>  R Synonym for warning 9.
>  # Terminal ∗ records/warn_help.out ∗ all code
> ```
> 你应该把OCaml的警告当成一组功能强大的表态分析工具，要在你的构建环境中积极使能它们。当然你通常不可能使能所有警告，但编译器自带的就已经很好了。
>
> 构建本书示例所用的警告是使用下面的标志指定的：`-w @A-4-33-41-42-43-34-44`。
>
> 上面这个语法可以运行`ocaml -help`查看，除了`A`后面显式列出的数字，这个标志会把所有警告都视为错误。
>
> 把警告当成错误（即，触发警告时OCaml停止编译任何代码）是一个很好的实践，因为要不这样，开发过程中就很容易忽略警告。但在准备要发行的包时，这确不是个好主意，因为编译器版本升级，警告可能会增加，这就可能使你的包在新版本编译器下编译失败。

### 字段双关
> Field punning

当变量名和记录的字段名一致时，OCaml提供了一些方便的快捷语法。如下面的函数，其中的模式把所有字段都绑定到同名变量上。这叫作 _字段双关_ :
```ocaml
# let host_info_to_string { hostname; os_name; cpu_arch; timestamp; _ } =
     sprintf "%s (%s / %s) <%s>" hostname os_name cpu_arch
       (Time.to_string timestamp);;
val host_info_to_string : host_info -> string = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 9) ∗ all code *)
```
字段双关也可以用于构造一个记录。考虑下面的代码，它创建了一个`host_info`记录：
```ocaml
# let my_host =
    let sh cmd = Shell.sh_one_exn cmd in
    let hostname   = sh "hostname" in
    let os_name    = sh "uname -s" in
    let cpu_arch   = sh "uname -p" in
    let os_release = sh "uname -r" in
    let timestamp  = Time.now () in
    { hostname; os_name; cpu_arch; os_release; timestamp };;
val my_host : host_info = {hostname = "flick.local"; os_name = "Darwin"; cpu_arch = "i386"; os_release = "13.0.0"; timestamp = 2013-11-05 08:49:41.499579-05:00}

(* OCaml Utop ∗ records/main.topscript , continued (part 10) ∗ all code *)
```
上面的代码中，我们根据记录字段定义了相关变量，然后记录声明就可以自己简单地列出所需的字段。

当从标签参数构造记录时，你可以同时获得字段双关和标签双关带来的好处：
```ocaml
# let create_host_info ~hostname ~os_name ~cpu_arch ~os_release =
    { os_name; cpu_arch; os_release;
      hostname = String.lowercase hostname;
      timestamp = Time.now () };;
val create_host_info : hostname:string -> os_name:string -> cpu_arch:string -> os_release:string -> host_info = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 11) ∗ all code *)
```
这比不使用双关要简明得多：
```ocaml
# let create_host_info
    ~hostname:hostname ~os_name:os_name
    ~cpu_arch:cpu_arch ~os_release:os_release =
    { os_name = os_name;
      cpu_arch = cpu_arch;
      os_release = os_release;
      hostname = String.lowercase hostname;
      timestamp = Time.now () };;
val create_host_info : hostname:string -> os_name:string -> cpu_arch:string -> os_release:string -> host_info = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 12) ∗ all code *)
```
标签参数、字段名以及字段和标签双关，这些加在一起，鼓励你的代码库中传递相同的名称。这通常一种好的实践，因为它鼓励一致的命名，这使源代码更易驾驭。

### 字段名复用
使用相同的名字的字段定义记录是有问题的。让我们看一个简单例子：构建一些类型用以表示一个日志服务器使用的协议。

我们将描述三类消息：`log_entry`，`heartheat`和`logon`。`log_entry`消息用以向服务器传递一条日志；`logon`消息用以初始化连接，包含连接用户的身份标识和认证证书；	heartbeat	消息由客户端定期发给服务器以表明该客户还活动并且已连接。所有这些消息都包含一个会话ID和一个消息创建时间：
```ocaml
# type log_entry =
    { session_id: string;
      time: Time.t;
      important: bool;
      message: string;
    }
  type heartbeat =
    { session_id: string;
      time: Time.t;
      status_message: string;
    }
  type logon =
    { session_id: string;
      time: Time.t;
      user: string;
      credentials: string;
    }
;;
type log_entry = {
  session_id : string;
  time : Time.t;
  important : bool;
  message : string;
}
type heartbeat = {
  session_id : string;
  time : Time.t;
  status_message : string;
}
type logon = {
  session_id : string;
  time : Time.t;
  user : string;
  credentials : string;
}

(* OCaml Utop ∗ records/main.topscript , continued (part 13) ∗ all code *)
```
复用相同的字段名会引发一些歧义。举个例子，如果我们想从一个记录中提取`session_id`，那么类型是什么呢?
```ocaml
# let get_session_id t = t.session_id;;
val get_session_id : logon -> string = <fun>
(* OCaml Utop ∗ records/main.topscript , continued (part 14) ∗ all code *)
```
这种情况下，OCaml只会采用该字段最近的定义。我们可以使用类型注释来强制OCaml认为我们在处理不同的类型（如`heartheat`）：
```ocaml
# let get_heartbeat_session_id (t:heartbeat) = t.session_id;;
val get_heartbeat_session_id : heartbeat -> string = <fun>
(* OCaml Utop ∗ records/main.topscript , continued (part 15) ∗ all code *0
```
尽管可以使用类型注释解决字段名歧义，这种歧意还是有点迷惑人。看下面这个函数，从一个`heartbeat`中提取会话ID和状态：
```ocaml
# let status_and_session t = (t.status_message, t.session_id);;
val status_and_session : heartbeat -> string * string = <fun>
# let session_and_status t = (t.session_id, t.status_message);;
Characters 44-58:
Error: The record type logon has no field status_message
# let session_and_status (t:heartbeat) = (t.session_id, t.status_message);;
val session_and_status : heartbeat -> string * string = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 16) ∗ all code *)
```
为什么第一个定义不用类型定义就可以成功而第二个却失败了呢?不同点就在于第一种情况时，类型检查会先处理`status_message`字段并确定这个记录是一个`heartbeat`。当顺序改变时，`session_id`被先考虑，因此类型被推导成`logon`，这时`t.status_message`就没有意义了。

通过不使用重复的字段名，或更一般的，通过为每个类型创建一个模块，我们就可以完全避免这种歧义。把类型包装在模块中是一个非常有用的惯用法（Core中大量使用这种技术），为每个类型提供一个命名空间，在其中放置相关的值。使用这种风格时，标准的实践就将模块相关的类型命名为`t`。使用这种风格我们可以这样写：
```ocaml
# module Log_entry = struct
    type t =
      { session_id: string;
        time: Time.t;
        important: bool;
        message: string;
      }
  end
  module Heartbeat = struct
    type t =
      { session_id: string;
        time: Time.t;
        status_message: string;
      }
  end
  module Logon = struct
    type t =
      { session_id: string;
        time: Time.t;
        user: string;
        credentials: string;
      }
  end;;
module Log_entry :
  sig
    type t = {
      session_id : string;
      time : Time.t;
      important : bool;
      message : string;
    }
  end
module Heartbeat :
  sig
    type t = { session_id : string; time : Time.t; status_message : string; }
  end
module Logon :
  sig
    type t = {
      session_id : string;
      time : Time.t;
      user : string;
      credentials : string;
    }
  end
(* OCaml Utop ∗ records/main.topscript , continued (part 17) ∗ all code *)
```
现在，我们的`log-entry-creation`函数可以像下面这样呈现：
```ocaml
# let create_log_entry ~session_id ~important message =
     { Log_entry.time = Time.now (); Log_entry.session_id;
       Log_entry.important; Log_entry.message }
  ;;
val create_log_entry :
  session_id:string -> important:bool -> string -> Log_entry.t = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 18) ∗ all code *)
```
需要使用模块名`Log_entry`来限定字段，因为此函数在定义记录类型的`Log_entry`模块之外。OCaml只要求限定一个记录字段，因此我们可以写得更简洁。注意模块路径和字段名之间允许加空白：
```ocaml
# let create_log_entry ~session_id ~important message =
     { Log_entry.
       time = Time.now (); session_id; important; message }
  ;;
val create_log_entry :
  session_id:string -> important:bool -> string -> Log_entry.t = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 19) ∗ all code *)
```
这不限于构造一个记录，我们也可以模式匹配中使用相同的技巧：
```ocaml
# let message_to_string { Log_entry.important; message; _ } =
    if important then String.uppercase message else message
  ;;
val message_to_string : Log_entry.t -> string = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 20) ∗ all code *)
```
当使用点号访问记录字段时，我们可以直接使用模块来限定字段：
```ocaml
# let is_important t = t.Log_entry.important;;
val is_important : Log_entry.t -> bool = <fun>

(* OCaml Utop ∗ records/main.topscript , continued (part 21) ∗ all code *)
```
第一次见到这样语法会使你大吃一惊。有一件事要记清楚，就是点号用了两种使用方法：第一个点是记录字段存取，右边的所有东西都会被解释为一个字段名；第二这点号是访问模块内容，指出`important`字段来看`Log_entry`模块。`Log_entry`是大写字母开头的，不能作为字段名，这使得两种用途不会被混淆。

对于记录定义所在模块中的函数定义而言，模块限定完全不需要。

### 函数式更新

### Mutable fields

### First-class fields
