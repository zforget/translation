## 附录A 安装
要实践《Real World OCaml》，你需要安装下列软件：
- [OCaml](http://caml.inria.fr/ocaml/)，版本4.1.0或以上。本书使用了一些写作过程中开发的工具，所以要运行书中的例子你至少需要这个版本。
- [OPAM](http://opam.ocamlpro.com/)，版本1.0或以上。使用它你可以访问本书用到的所有OCaml库。
- [Utop](https://github.com/diml/utop)，一个现代交互式解释噐，有命令历史和tab鍵补全功能，默认就能很好地支持本书中的例子。

安装OCaml最简单的方法通常是通过各操作系统的二进制包安装。然而，对于日常开发，使用源代码管理器来修改单独的库并自动重编译所有这些依赖更容易。

OCaml和Python或Ruby这样脚本语言有一个重大的不同就是静态类型安全，这也意味着你不能仅仅把编译好的库混合搭配在一起就行了。编译库时会检查接口，所以一个接口改变时，所有依赖的库都要重新编译。基于源代码的包管理器，像OPAM，会为你自动处理这些，使开发更为轻松。

### 获得OCaml
OCaml编译器在许多操作系统上都有二进制发布版。这是最简单也是推荐的安装方法，但我们也会介绍如何手动安装以作为最后的手段。
#### Mac OS X
[Homebrew](http://github.com/mxcl/homebrew)包管理器有一个OCaml安装器，通常会很快更新到最新的稳定版本。在安装OCaml之前，确保已经从苹果应用商店安装了最新的XCode（包括XCode的命令行工具）。
```bash
$ brew update
$ brew install ocaml
$ brew install pcre

 # Terminal ∗ installation/brew_install.out ∗ all code
```
Core套件需要使用Perl-compatible Regular Expression库（PCRE）。它不是OCaml必须的，但是一个常用的库，所以我们现在先装好以后就省事了。

Mac OS X的另一个流行的包管理器是[MacPorts](http://macports.org/)，也有OCaml。和使用Homebrew一样，也要确保安装了XCode，并且已经完成了MacPorts安装后面的步骤，然后键入：
```bash
$ sudo port install ocaml
$ sudo port install ocaml-pcre

 # Terminal ∗ installation/macports_install.out ∗ all code
```
#### Debian Linux
Debian Linux上你应该通过二进制包管理器使用OCaml。为了能引导OPAM，OCaml的版本最低为3.12.1，这就需要Debian Wheezy或更高的版本。不用担心具体的最新版本，你只要一个足够新的版本来编译OPAM，之后就可以OPAM来管理编译器的安装了。
```bash
# apt-get install \
  ocaml ocaml-native-compilers camlp4-extra \
  git libpcre3-dev curl build-essential m4

 # Terminal ∗ installation/debian_apt.out ∗ all code
```
注意除了OCaml编译器我们还安装了几个额外的包。第二行了构建OCaml包所需要的系统包。你可能会发现有些OCaml库依赖更多的系统库（如，libssl-dev），但我们会在书中介绍这些库时再突出这些。

#### Fedora and Red Hat
从Fedora8开始，OCaml已经包含在基本发布版里了，要安装最新的编译器，只要运行：
```bash
# yum install ocaml
# yum install ocaml-camlp4-devel
# yum install pcre-devel

 # Terminal ∗ installation/fedora_install.out ∗ all code
```
PCRE库供Core使用，在这里安装是为了以后方便。

#### Arch Linux
Arch Linux在标准库里提供了OCaml4.00.1（或更新的版本），所以最简单的安装方法即是使用pacman:
```bash
# pacman -Sy ocaml

 # Terminal ∗ installation/arch_install.out ∗ all code
```

#### Windows
目前本书中的例子不支持Windows，但正在进行中。在完成之前，我们建议你在本机上用虚拟机安装一个Deian Linux使用。

#### 从源代码构建
要从源代码安装OCaml，首先要安装C编译环境（通常是gcc或llvm）。
```bash
$ curl -OL https://github.com/ocaml/ocaml/archive/4.01.tar.gz
$ tar -zxvf 4.01.tar.gz
$ cd ocaml-4.01
$ ./configure
$ make world world.opt
$ sudo make install

 # Terminal ∗ installation/ocaml_src_install.out ∗ all code
```
最后一步需要管理员权限以安装到你的系统目录。你也可以通过向配置脚本传递prefix选项来安装到你的家目录下：
```bash
$ ./configure -prefix $HOME/my-ocaml

 # Terminal ∗ installation/ocaml_user_conf.out ∗ all code
```
如果安装到自定义的目录，安装完成后需要编译`~/.bash_profile`来`把`$HOME/my-ocaml/bin`添加到PATH。除非有特别的理由，你不应该这样做，所以源代码安装之前尝试一下安装二进制包。

> **致审查者**
>
> 我在此引导你安装OCaml的4.01分支，因为我们使用了一些新加入的语言特性，本书中会简单解释。4.01会在本书发布之前发布，但使用这个版本你可能会碰到由于太新造成的问题（“bleeding edge” bugs）。如果碰到这些问题请在此提交，我们会处理的。

### 获得OPAM
OPAM可以同时管理多个OCaml编译器和库的安装，通过更新跟踪库的版本，会自动重编译过期的依赖。在本书中都使用它来获得并使用第三方库。

安装OPAM之前，确保按上面的要求安装了OCaml编译器。装完后，OPAM数据库存在你的家目录中（通常是`$HOME/.opam`）。如果出错了，删除这个.opam目录就可以从头重新开始。如何你使用beta版的OPAM，使用之前请将其更新到最新的1.0.0版或更新。

#### Mac OS X
源码安装OPAM在现代机器上大约需要1分钟。最新的OPAM有Homebrew包：
```bash
$ brew update
$ brew install opam

 # Terminal ∗ installation/brew_opam_install.out ∗ all code
```
使用MacPort可以像下面这样安装：
```bash
$ sudo port install opam

 # Terminal ∗ installation/macports_opam_install.out ∗ all code
```

#### Debian Linux
最近OPAM已经为Debian打包好了，不久就会进入unstable发布版。如果你使用的是更早的稳定版，如wheezy，可以从源代码安装，或从ubstable中提取OPAM包：
```bash
# apt-get update
# apt-get -t unstable install opam

 # Terminal ∗ installation/debian_apt_opam.out ∗ all code
```

#### Ubuntu Raring
Ubuntu Raring中，OPAM在Personal Pachage Archive(PPA)中可以得到，i386和x86_64都有。可以这样安装：
```bash
$ add-apt-repository ppa:avsm/ppa
$ apt-get update
$ apt-get install ocaml opam

 # Terminal ∗ installation/ubuntu_opam_ppa.out ∗ all code
```
#### Fedora and Red Hat
目前在Fedora或Red Hat上没有RPM，请按后面的步骤从源代码安装OPAM。
#### Arch Linux
OPAM在Arch User Repository（AUR）中有两个包。你首先需要安装ocaml和base-devel包：
- opam，包含最新的稳定版，推荐。
- opam-git，从最新的上游代码构建，只要在你需要特定的新特性时才使用。

运行下面的命令来安装OPAM包：
```bash
$ sudo pacman -Sy base-devel
$ wget https://aur.archlinux.org/packages/op/opam/opam.tar.gz
$ tar -xvf opam.tar.gz && cd opam
$ makepkg
$ sudo pacman -U opam-<version>.tar.gz

 # Terminal ∗ installation/arch_opam.out ∗ all code
```

#### 源代码安装
如果你的系统上没有opam的二进制包，你需要从源代码安装最新的OPAM。你可以参考在线文档[快速安装指南](http://opam.ocamlpro.com/doc/Quick_Install.html)。

### 配置OPAM
整个OPAM数据库都存你家目录下的.opam目录，包括编译器。在Linux和Mac OS X上，就是`~/.opam`目录。安装包时你不应该切换到管理员用户，因为不会有任何东西会安装到家目录之外。遇到问题时，删了整个`~/.opam`目录，按`opam init`步骤中的指令安装即可。

让我们开始初始化OPAM包数据库。这需要网络连接，结束时会问你几个交互式问题。对这些问题回答yes是安全的，除非你是高级用户，想要手动控制配置步骤。
```bash
$ opam init
<...>
=-=-=-= Configuring OPAM =-=-=-=
Do you want to update your configuration to use OPAM ? [Y/n] y
[1/4] Do you want to update your shell configuration file ? [default: ~/.profile] y
[2/4] Do you want to update your ~/.ocamlinit ? [Y/n] y
[3/4] Do you want to install the auto-complete scripts ? [Y/n] y
[4/4] Do you want to install the `opam-switch-eval` script ? [Y/n] y
User configuration:
  ~/.ocamlinit is already up-to-date.
  ~/.profile is already up-to-date.
Gloabal configuration:
  Updating <root>/opam-init/init.sh
    auto-completion : [true]
    opam-switch-eval: [true]
  Updating <root>/opam-init/init.zsh
    auto-completion : [true]
    opam-switch-eval: [true]
  Updating <root>/opam-init/init.csh
    auto-completion : [true]
    opam-switch-eval: [true]

 # Terminal ∗ installation/opam_init.out ∗ all code
```
这个命令你只要运行一次，它会创建`~/.opam`目录，并和在线的最新版OPAM数据库同步。

`init`结束后，你会看到一些环境变量的说明。OPAM永远不会向你的系统目录安装文件（这需要管理员权限）。它默认安装到你的家目录，输出一组shell命令，它们用正确的PATH变量配置你的shell以使用这些包。

如果你选择不让OPAM将自身添加到你的shell配置，你还是可以使用下面的命令在当前shell中即时配置它。
```bash
$ eval `opam config env`

 # Terminal ∗ installation/opam_eval.out ∗ all code
```
这会在当前shell中对`opam config env`的结果求值，设置变量以使接下来的命令可以使用它们。这只会在你当前的shell中有效，只有在你的登录脚本中添加这一行后才能在以后的shell中自动使用。在Mac OS X或Debian中，如果你使用默认的shell，登录脚本通常是`~/.bash_profile`。如果你使用其它shell，则可能是`~/.zshrc`。OPAM的这种方法并不特殊，SHH的`ssh-agent`也这样工作，所以如果你碰到问题，就查看一下你的配置脚本看一下它是如何被调用的。

如果在`opam init`过程中你选择了yes，这些应该都为你设置好了。你可以通过列举可用的包来检查一下工作是否正常。
```bash
$ opam list
Installed packages for 4.01.0:
async                  109.38.00  Monadic concurrency library
async_core             109.38.00  Monadic concurrency library
async_extra            109.38.00  Monadic concurrency library
<...>

 # Terminal ∗ installation/opam_list.out ∗ all code
```

> **致审查者**
>
> OPAM 1.0.0把登录命令放到你的`~/.profile`文件中，当你使用bash时，它不是总会被执行。这个问题在接下来的版本中已经修正了，现在你需要手动将`~/.profile`中的内容拷贝到`~/.bash_profile`。

我们需要安装的最重要的包就是Core，用以替代标准库，本书中所有的例子都要使用。安装之前，先确保已经安装了正确的编译器。
```bash
$ opam switch 4.01.0dev+trunk
$ eval `opam config env`

 # Terminal ∗ installation/opam_switch.out ∗ all code
```
在一台现代机器上，这一步需要10到15分钟，会下载并安装OCaml编译器到`~/.opam`目录。OPAM支持安装多个编译器，这在如果你决定要Hack编译器内部或想要体验最新版本而不影响当前安装时会很有帮助。你只需要安装一次编译器，以后的更新会很快，因为只要重新编译编译器对应的库就行了。

新的编译器会安装被安装到`~/.opam/4.01.beta1`，你为它安装的任何库都会和为系统OCaml安装的分开维护。你可以同时安装任意多个编译器，但一次只能激活一个。可以运行`opam switch list`来游览可用的编译器。

现在我们终于准备好安装Core库了。执行：
```bash
$ opam install core core_extended core_bench async

 # Terminal ∗ installation/opam_install.out ∗ all code
```
构建会花费5到10分钟，会安装一系列的包。OPAM会为你自动解决依赖，但是下面这4个包尤为重要：
- `core`是主要部分，是由Jane Street提供良好支持的Core发布版。
- `core_bench`是一个基准测试库，便于通过命令行接口测试函数性能情况。
- `core_extended`包含了一些试验性的，但很有用的扩展库，正在审查以进入Core，我们在一些合适的地方会使用它们，但是比Core本身要少得多。
- `async`是一个网络编程库，我们在第二部分中用来和其它主机交互。如果愿意你可以在开始时跳过它，看到第二部分时再装。

### 编辑环境
开始体验例子之前你还有最后一样东西要安装。默认的ocaml命令提供了一个命令行让我们可以不用编译就能体验代码。但是，体验太差了，所以我们使用了一个更现代的替代。
```bash
$ opam install utop

 # Terminal ∗ installation/opam_install_utop.out ∗ all code
```
utop包是一个OCaml交互式命令行接口，有tab键补全功能、持久化的历史记录并且可以和Emacs集成，这样你就可以在编辑环境中运行它了。

记住前面提到过了，OPAM不会直接向你的系统目录安装文件，utop也是如此。你会在`~/.opam/4.01beta1/bin`中找到这个包。然而，在你的shell中键`utop`是可以工作的，这是因为前面步骤中的`opam config env`已经设置好了。不要忘了之前描述的自动化工作，这会使开发OCaml代码更轻松。

#### 命令行
utop提供了方便的交互式toplevel，有完整的命令历史、命令宏以及模块名补全。第一次运行utop时，你会得到一个交互提示符，屏幕下面还有一个条。底条会随着你输入的文本动态更新，包含你正在输入的短语可用的模块或变量名。你可以按tab键来用第一个选项补全短语。

家目录下的`~/.ocamlinit`文件使用常用的库和语法扩展来初始化utop，这样你就不用每次都输入它们了。目前你已经安装了Core，应该更新这个文件，以在每次启动utop后都加载它，添加下面几行：
```bash
$ cat ~/.ocamlinit
#use "topfind"
#thread
#camlp4o
#require "core.top"
#require "core.syntax"

 # Terminal ∗ installation/show_ocamlinit.out ∗ all code
```
如果你只使用Core库（对于使用本书来尝试OCaml的初学者就应该这样），你也可以默认打开Core模块。向.ocamlinit中添加下面一行即可。
```ocaml
open Core.Std

(* OCaml ∗ installation/open_core.ml ∗ all code *)
```
给utop添加了这些初始化后，它启动时就应该打开了Core并可以使用了。如果你没有默认打开`Core.Std`，那么一定要记得在运行本书交互式示例之前打开它。

#### 编辑器
> **致审查者**
>
> 编辑器安装说明这部分尚未完成。如果你有相关技巧或HOWTO，欢迎提交直接或间接的说明。

##### Emacs
Emacs用户可以使用tuareg和[Typerex](http://www.typerex.org/)。

要在Emacs中直接使用utop，需要向`~/.emacs`文件添加下面的行：
```common-lisp
(autoload 'utop "utop" "Toplevel for OCaml" t)

;; Scheme ∗ installation/emacsrc.scm ∗ all code
```
你还需要Emacs能找到utop.el文件。OPAM中的utop安装在`~/.opam`目录，如`~/.opam/system/share/emacs/site-lisp/utop.el`，你需要用你当前的编译器代替其中的`system`，如`4.01.0beta1`。

Emacs加载成功后，你就可以在Emacs中执行utop命令了。在[utop主页](https://github.com/diml/utop#integration-with-emacs)有更详细的说明。

##### Vim
Vim用户可以使用内建的风格，[ocaml-annot](http://github.com/avsm/ocaml-annot)可能也用得上。

##### Eclipse
Eclipse是Java开发的流行IDE。OCaml Development Tools(ODT)工程提供了编辑和编译OCaml代码的IDE特性，如自动编译和名称补全功能。

ODT以[主页](http://ocamldt.free.fr/)为Eclipse环境提供一组插件的形式发布。你把这些插件拷贝到Eclipse中就可以访问新加的OCaml设施了。
