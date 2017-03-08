source : <https://realworldocaml.org/>

# 序言

## 为什么要选OCaml？
你使用的编程语言会影响你写的代码。它们会影响你代码的可靠性、安全性和性能，同时也影响它阅读、重构和扩展的难度。你所熟知的语言也会改变你的思维方式，影响你设计软件甚至是使用软件的方式。

我们写这本书是因为我们相信编程语言的重要性，并且 OCaml 是一种尤其值得学习的语言。我们三个在学术和职业生涯中已经使用 OCaml 超过 15 年了，并将其视为构建复杂软件系统的秘密武器。本书的目标就是提供一个在现实世界中高效使用 OCaml 所需求知识的清晰指南，以让更多读者获得这种秘密武器。

OCaml 如此特别是因为其极佳的语言设计。它提供了其它语言不具备的效率、表达能力和实用性的组合。这在很大程度上是因为 OCaml 是过去 40 年来开发出来的一些关键语言特性的优雅组合。这些特性包括：

- 用于自动内存管理的*垃圾收集*，现在是几乎所有现代高级语言都有的特性。
- 像在 JavaScript、Common Lisp 和 C# 中一样，*函数作为一等公民*可以像普通的值一样传递。
- 静态类型检查，可以提升性能并减少一些运行时错误，就像在 Java 和 C# 中那样。
- *参数多态*，允许构建可以在不同数据类型上工作的抽象，类似 Java 和 C# 中的泛型还有 C++ 中的模板。
- 对*不可变编程*的良好支持，如，编程时不对数据结构做破坏性更新。这个特性存在于像 Scheme 那样的传统函数式编程语言中，在像 Hadoop 这样的分布式、大数据框架中也可以见到。
- *自动类型推导*，可以不用辛苦地为程序中的每一个单独变量都定义类型，而是基于一个值的使用方式推导出其类型。在 C# 中有隐式类型的局部变量还有 C++11 中的`auto`关键字都是这个特性的受限形式。
- *代数数据类型*和*模式匹配*，用以定义和操作复杂数据类型。Scala 和 F# 支持。

> 代数数据类型（Algebraic data types），是一种组合类型，“代数”一词是因为有两种代数类型，主要是 Product 类型（如元组和记录，在代数上类似于笛卡尔乘）和 Sum 类型（如变体，在代数上类似于 Disjoint Unions，即交集为空集的集合的并操作）。代数类型在模式匹配中极为重要的。

你们中一些人了解并喜欢所有这些特性，而对其它人而言它们可能是全新的，但大多数人都是在他们使用的语言中或多或少见过一些。贯穿本书，我们都会展示，使这些特性在同一种语言中并存且能相互作用是具有变革性的。尽管如此重要，这些概念只是有限地进入了主流语言中，并且即使是在主流语言中，如 C# 中的高阶函数或 Java 中的参数多态，通常都是受限和笨拙的形式。完整包含这些概念的只有*静态函数式编程语言*，像 OCaml、F#、Haskell、Scala 和 Standard ML。

在这组优秀的语言中，OCaml 脱颖而出，因为它在保持高度实用性的同时设法提供了强大特功能。其编译器有一种直接的编译策略，不需要过度优化和或复杂的动态 JIT 编译就能产生高性能代码。这一点，加上 OCaml 严格的计算模型，使得运行时行为容易预测。垃圾收集器是*增量*的，这意味着可以避免 GC 引起大的暂停；也是精确的，就是说会收集所有没有引用的数据（不像许多引用计数收集器那样）；并且运行时简单且高度可移植。

所有这些都使得 OCaml 成为对编程语言有追求的程序员的绝佳选择，同时也可以完成实际的工作。
​	
### 简史
OCaml 是法国 INRIA 的 Xavier Leroy，Jérôme Vouillon，Damien Doligez 和 Didier Rémy 在 1996 年写的。灵感来自 1960 年代以来对 ML 的大量研究，并且持续和学院社区保持紧密联系。

ML 最开始是 Robin Milner（当时在斯坦福，后来到了剑桥）1972 年发布的 LCF 证明辅助系统的元语言。ML 后来变成了一个编译器以使得在不同机器上使用 LCF 更容易，并在1980 年代逐渐转变成一个完备的独立系统。

第一个 Caml 实现出现在 1987 年，最开始由 Ascánder Suárez 创建，后来由 Pierre Weis 和 Michel Mauny 继续。1990 年，Xavier Leroy 和 Damien Doligez 构建一个新的实现叫 Caml Light，Caml Light 基于一个拥有快速垃圾收集器的字节码解释器。之后的几年出现了一些有用的库，如 Michel Mauny 的语法处理工具等，这些都促进了 Caml 在教育和研究领域的使用。

Xavier Leroy 继续扩展 Caml Light 的新特性，这就有了 1995 年发布的 Caml Special Light。加入了一个快速的原生机器码编译器来大幅度提高程序性能，从而使Caml 的性能可以和 C++ 这样的主流语言相抗衡。从 Standard ML 借鉴来的模块系统给 Caml 提供了强大的抽象工具，使得构建大型程序更容易。

随着 Didier Rémy 和 Jérôme Vouillon 实现的一个强大、优雅的对象系统，现代 OCaml 于 1996 年出现。这个对象系统的亮点是可以以静态类型安全的方式支持许多通用的面向对象惯用法，而在其它像 C++ 和 Java 这些语言中则需要运行时检查。2000 年，Jacques Garrigue 用如多态方法、变体（variant）、标签参数和可选参数等一些新特性进一步扩展了 OCaml。

过去 10 年，OCaml 吸引了大量用户，语言改进不断添加以支持日益增长的商业和学术代码库。作为一等公民的模块、广义代数数据类型（Generalized Algebraic Data Types，GADTs）以及动态链接提高了语言的灵活性，另外快速的本地代码支持 x86_64、ARM、PowerPC 和 Sparc，这使得在同时关注资源使用、可预测性和性能的系统中，OCaml 成为一个很好的选择。

### Core 标准库
光有语言还不够。你需要丰富的库作为应用程序的基础。学习 OCaml 时一种常见的挫败感就是编译器自带的标准库很有限，只是你所期望的通用目的标准库设施的一个很小的子集。这是因为标准库不是通用目的工具，它是被开发出来自举编译器的，被刻意保持短小和简单。

庆幸的是，开源世界里从来就没有什么能阻止写出其它库来扩充编译器提供的标准库。这就是“Core”发布版的目的。

Jane Street，一家已经使用 OCaml 超过 10 年的公司，开发 Core 是自用的，但是设计开始就具有前瞻性，要成为通用目的标准库。和 OCaml 自身一样，Core 设计也充分考虑了正确性、可靠性和性能。

Core 以语法扩展的形式发布，为 OCaml 提供了有用的新功能，也提供了额外的库，如异步网络通信库，使 Core 适合构建复杂分布式系统。所有这些库都是以自由的 Apache 2 许可发布的，无论出于兴趣，还是学术，甚至是在商业环境中，都允许使用。 

### OCaml 平台
Core 是一个全面高效的标准库，但除此之外还有许多 OCaml 软件。自 1996 年 OCaml 首次发布以来，已经有一个庞大的程序员社区在使用 Ocaml，并且开发了大量有用的库和工具。在本书课程的例子中，我们会介绍其中一些库。


[OPAM](http://opam.ocaml.org/) 包管理器大大简化了第三方库的安装和管理。本书中我们会更详细介绍 OPAM，它构成了平台的基础，包括一组工具和库，配合 OCaml 编译器，让你可以又快又好地构建实用的应用程序。

我们也使用 OPAM 来安装 **utop** 命令行界面。这是一个现代解释器，支持命令历史、宏展开，模块补全和其它细节，使得使用 OCaml 更舒服。贯穿本书，我们都会使用 **utop**，这样你就可以交互式单步运行例子。

## 关于本书
*Real World OCaml* 的目标读者是有一些传统语言经验的程序员，但对于静态类型函数式语言经验没有要求。根据你的背景，我们涵盖的一些概念对你来说也许的全新的，包括诸如高阶函数和不可变数据类型等传统的函数式编程技术，还有 OCaml 强大的类型和模块系统。

如果你已经会了 OCaml，本书也会让你有意外之喜。Core 重定义了许多标准命名空间以更好地利用 OCaml 模块系统，并且还默认地暴露了一些强大的、可重用的数据结构。旧的 OCaml 代码仍可以和 Core 交互，但你需要修改一下才能获得最大的好处。我们写的新代码都使用 Core，我们相信 Core 是值得学习的，它已经在一个巨大的几百万行的代码库中成功使用，扫除了 OCaml 构建复杂应用的一个巨大障碍。

只使用传统编译器标准库的代码总是存在的，网络上有一些其它资源可以用来学习它们。*Real World OCaml* 聚焦于作者们用于构建可扩展的、健壮的软件系统的技术。

### 内容简介
*Real World OCaml* 被分为 3 个部分：

- 第一部分涵盖了语言本身，开始以一个快速浏览来展现语言的骨架。不要试图去理解浏览中的一切，它只是为了让你尝试一下这种语言中不一样的地方，其中涉及的概念后面的章节会深入解释。

    语言核心之后，第一部分转向更高级的特性，像模块、算子和对象，这些可能要消化一段时间，但理解这些概念很重要。在 OCaml 之外，转向其它现代语言（许多都受 ML 启发）时，这些概念也可以给你带来好处。
- 第二部分建立在使用有用的工具和技术来应对普通实际应用程序的工作之上，应用包含从命令行解析到异步网络编程的方方面面。通过这种方式，你可以看到第一部分中的概念如何组合在一个真实的库中，还有组合语言的不同特性来达到更好的效果的工具。

- 第三部分讨论了 OCaml 的运行时系统和编译工具链。和其它语言（如 Java 或 .NET 的 CLR ）相比这非常简单。阅读这部分可以使你创建出非常高性能的系统，或者如何与 C 库配合。这一部分也介绍使用 GNU gdb 等工具进行性能分析和调试的技术。

#### 安装指导
*Real World OCaml* 使用了一些在本书写作过程中开发的工具。其中的一些导致对编译器要求的提升，也就是说你要使用最新的开发环境（使用 4.01 版编译器）。OPAM 包管理器使安装过程高度自动化。如何安装以及需要哪些库请参考[这里](https://github.com/realworldocaml/book/wiki/Installation-Instructions)。

发稿时，Core 还不支持 Windows 系统，所有只有 Mac OS X、Linux、FreeBSD 和 OpenBSD 可以可靠地工作。请查看在线安装指导以获得最新的 Windows 支持情况，或安装一个 Linux 虚拟机来学习本书。

本书不是参考手册。我们的目标是教你这门语言、库、工具和技术来使你成为更高效的 OCaml 程序员。但是不能替代 API 文档或 OCaml 手册和 man 页。书中提及的库和工具的文档你都可以[在线](https://realworldocaml.org/doc)获得。

### Code Examples
All of the code examples in this book are available freely online under a public-domain- like license. You are most welcome to copy and use any of the snippets as you see fit in your own code, without any attribution or other restrictions on their use.The code repository is available online at https://github.com/realworldocaml/examples. Every code snippet in the book has a clickable header that tells you the filename in that repository to find the source code, shell script, or ancillary data file that the snippet was sourced from.If you feel your use of code examples falls outside fair use or the permission given above, feel free to contact us at permissions@oreilly.com.

本书所有的示例代码都可以免费在线获得，许可近似于完全公开，我们欢迎你拷贝合适的代码片到你的代码中，没有任何归属声明或其它限制。

在线代码库地址是：<https://github.com/realworldocaml/examples>。书中每个代码片都有一个可以点击的头来说明源代码、shell 脚本或辅助数据文件的在代码库中的文件名。

如果你认为你对示例代码的使用超出了公平使用或上述许可的范围，尽可以通过 <permissions@oreilly.com> 联系我们。
