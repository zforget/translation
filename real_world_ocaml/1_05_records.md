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
你可能会问编译器是如何知道`my_host`是`host_info`类型的。这里编译器用以推断类型的方法就是根据记录的字段名。本意稍后我们会讨论当一个作用域中出现多个有相同字段名的记录类型时会如何。

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
注意我们使用的模块只有一种情况，而不是由`|`分割的多种情况。我们只需要一个模块是因为记录类型的模式是 **不可辩驳的（irrefutable）**，就是说一个记录的模式匹配在运行时永远都不会失败。这是有道理的，因为记录中的字段总是相同的。通常，固定结构类型的模式都是不会失败的，如记录和元组，而列表和变体这种可变结构的类型就不是。

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


### Field punning

### Reusing field names

### Functional updates

### Mutable fields

### First-class fields
