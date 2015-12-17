#怎样技术提升

很久没写东西了，最近在学 swift，也是颇有心得，不过今天这一篇不是关于 swift 的，是我翻译的一篇文章。总得好好学英语嘛。

原文连接：[https://www.bignerdranch.com/blog/leveling-up/][10]

以下是译文，有错别字或者翻译不对的地方欢迎留言：

类似 Clash of the Coders 这样的比赛挺不错的，你需要保持72小时紧张，不能睡觉，时刻都在努力的跟 Objective-c runtime, UIApplication, 和 layer 层关系这样的东西打交道。用尽自己的所能去颠覆它是很有冲击力的事情。

有一次我跟一个牧场一起工作的人聊天的时候，他提及了一个让人沮丧的问题：“ MarkD, 我怎样才能把所有细节都把握？我现在感觉我卡住了，仿佛在一个被孤立的陆地上，只是在用 tableview 这种东西。” 尤其当这个问题是一个工程师提出来的，如果你回答：“你就做这些吗？” 并不是一个好答案。

我做了23年编程，比我一些同事的年龄还大。上面的想法是一个比较恐怖的想法。这些年我的学习和探索方式确实给我了不少意外收获。每个人的想打也许都不一样，但是，我会这么回答他。

##阅读
多阅读，把信息都往你的脑子里塞。有很多书或者博客都可以供你阅读，尤其是和过去对比，所有的 Mac 开发的书籍加起来可以放满一个小型的宜家书柜。我最喜欢的书是 Rob Napier 和 Mugunth Kumar 联合出版的 [iOS6: Pushing The Limits], 当然我页必须给 [Advanced Mac OS X Programming: The Big Nerd Ranch Guide] 打打广告，因为它有很多都挖掘到了 OS X 更低层次的细节，这些细节一大部分还是 iOS 通用的。对了，不要忘记 Anit Singh 的厚实的 [OS X Internals book] ，它的 ebook 版本甚至可以让你的 Kindle 更重。还有一部分都已经过了时代了，比较吸引我的是那些讲述操作系统底层核心的书。

我们生活在一个充满信息的年代，线上也一样。除了我们的[博客][1]外，你也应该关注一下 Mike Ash 的 [NSBlog]。我也会经常阅读 [NSHipster] 和 [Jeremy W.Sherman] 的博客。

不要忘了阅读官方文档。在 XCode 中浏览 Cocoa/UIKit 的文档。我把文档都下载下来在 iPad 上了，这样我在等什么东西的时候就可以看一看了。不要把自己限制在你总在使用的那几个类里面。总是在做 NSTableView (备注：Mac OS X 开发中的列表是 NSTableView)?读读 [IOService], 你可能从来没用过 ，但是你在阅读的时候也许可以找到一些能让你突发灵感的东西。

我尝试定期阅读编译程序和 debug 程序，[gdb] 的文档不错，gdb 现在还是存在的，lldb 在设备上运行还是有些不可靠（备注：这篇文章是2013年写的，后面 lldb 已经很强大了）。[lldb] 网站上面有一些文档，了解它的构造方式可以帮助你学习一些有用的命令。要确定你读了所有的东西。要是看到了深奥的内容，多想想为什么。（可能是少看了哪里）

相关的编译代码可以在 [http://clang.llvm.org] 找到，不要忘了头文件。有很多有用的信息埋在[头文件][2]里面。

你也许会问，看那么多都记不住有什么用。说实话，我现在什么都不记得，我最近干的大部分事情都不记得了。不过当我看到某些东西的时候我会有印象：“我好像在哪看到过这个东西，是哪里呢？”, 沉思了一会儿我终于想起来了，“ 对对对， Jeremy 在他的博客里面发表了他使用 12 行代码重新实现了 Cocoa，并且发布了一个非常棒的高序信息分类应该会很有帮助。”。


##剖析

当学习一个东西怎么工作的时候，我喜欢观察这个事情是怎么表现的。了解了哪个方法调用哪个方法是非常有帮助的。“谁在创建这个未完成的管理器？” 是解决程序出 [Bug][3] 的关键。看看 App 内部的各种通知可以帮助你发现 MPMusicPlayerController 在将一个歌曲移动到歌曲列表的时候干了什么。

我们有很多非常强大的工具可以让我们大概了解到我们的程序和库。虽然你不会用到每一个，有一些你用到的也是很少用到，几个月不会用到一次的，但是你懂这些东西是很重要的事情。

**源(Source)：**calng 和 lldb 的源是很容易下载到的，下载后你就可以编译它们。你如果明白一段代码在一个语言中是怎么实现的，在源里面看看，一般都能找到。你可以在 [http://www.opensource.apple.com] 这里看看 Core Foundation 的代码。最有意思的部分就是 “xnu”：内核，“CF”：CoreFoundation，还有 objective-c runtime 运行时。你还可以从 Cocoa 的头文件中往下挖掘类似 NSAssert 等你不了解的部分，然后研究一下它到底是怎么工作的。

**Debugger:** 你可以在任何地方放置断点，无论是你的代码还是某些库的代码。你可以在 XCode 里面使用 “特征断点” 来编辑断点(右键可以编辑)。你还可以在模拟器里面触发一个内存警告然后观察怎么处理的。

**监控通知(Notification)：**通知是一个减少耦合的最普遍的方法。发生了某件事，然后就会有一个通知被发送。NSNorificationCenter 和其支持实在是方便，几乎大家都在用。你可以添加一个[通知监控][4]来输出所有发送过的通知。

**DTrace:** 我知道大家都希望我可以不在谈论 [DTrace] 。 我是怎么发现 _perforMemoryWarning 的表现的？很明显不是在苹果的文档里面。我使用 DTrace ，将其安装到模拟器上，触发一个内存警告，然后看看发生了什么。在 Clash of Coder 里我也想过回答一些其他的问题，例如 “UITouches 是在什么时候被创建然后再传送的？”或者“当加载一个 nib 文件的时候文件系统到底加载的是什么？” 因此有了一个工具脚本，[spy.d]。

spy.d 根据 objc 运行时跟踪程序在运行时的 Ojective-C 消息的脚本，它屏蔽了一些普通的消息，然后输出一些`特别的`消息。我运行了 spy.d 跟踪了模拟器里面的内存警告：

```
# ./spy.d  61271
...
UIApplication -didReceiveMemoryWarning
NSNotificationCenter +defaultCenter
NSNotificationCenter -postNotificationName:object:
...
UIImage(UIImageInternal) +_flushCache:
UIViewController +_traverseViewControllerHierarchyWithDelayedRelease:
UIViewController -didReceiveMemoryWarning
UIViewController -_traverseViewControllerHierarchyFromLevel:withBlock:
RMScheduleVC -didReceiveMemoryWarning
```

UIApplication 获取到内存警告。它会发一个通知。UIImage 会清除它的缓存，然后 UIViewContriller 的子类，会一层一层的将消息传送，最后流入我的自定义 viewController 。

**类处理：**Objective-C 运行时是一个非常丰富的元数据。你可以在运行时的时候给一个类插入一个方法，当然还有很多好玩的地方。这些信息其实是直接存在程序的二进制文件中的，还可以取出来。Steve Bygard 的[类处理][5]取出了这些元数据，例如 UIApplication 的接口：

```
...
- (void)_purgeSharedInstances;
- (void)setReceivesMemoryWarnings:(BOOL)arg1;
- (void)_receivedMemoryNotification;
- (void)didReceiveMemoryWarning;
- (void)_performMemoryWarning;
- (BOOL)_isHandlingMemoryWarning;
- (void)_processScriptEvent:(struct __GSEvent *)arg1;
- (void)_dumpScreenContents:(struct __GSEvent *)arg1;
- (void)_dumpUIHierarchy:(struct __GSEvent *)arg1;
- (void)setSystemVolumeHUDEnabled:(BOOL)arg1;
...
```

还有很多有意思的东西可以做深入的研究。你可以放断点，然后查看消息执行栈。你还可以挖掘到实现文件。

**反汇编：** [反汇编][6]是一个阅读 object 代码然后输出相符的汇编语言的工具。反汇编输出的是伪代码，但是你可以从中看出来代码是怎么执行的。

这也是一个学习汇编语言的更方便的方法。但是也要小心，因为这些代码是编译器搞出来的，所以有时候代码会有点混乱。

**Instruments:** Instruments 并不只是用来寻找性能问题，无论在你自己写的代码或者是三方库的代码里，它都可以帮你定位出问题代码的位置，这样你就可以着手处理问题了。想知道 UISlider 在其生存轨迹下都干了什么吗 ？打开 Instruments，然后运行一个有 UISlider app，随便滑动 10 秒，然后看看调用栈中都有什么。然后你可以在模拟器上启用 DTrace 或者让程序崩溃，看看会怎么样。

**警告：**你从这些工具里面学习到的知识，再用的时候要非常小心。它们虽然可以非常方便的来做 debug 和学习到代码执行的规则。但是太依赖那些实现的细节和私有 API 会让你的代码非常脆弱，当新的系统版本更新就有可能无法使用。如果你是为了回馈你的用户而写代码，或者说用户用你的程序做一些很重要的事情的时候，你就是一个专业的程序员了。

##实践

现在，你已经有了一堆学习的途径了，赶紧去学一些吧。实践是最好的学习。不要怕犯错。如果你对深度研究 UITableView 感兴趣，写上一段关于 table view 的代码。浏览文档，看看 API 里面的头文件，有哪些是你之前没有用过的 ，尝试用用它们，然后看看发生了什么。阅读一些博客，看看一些你感兴趣的私有 API，然后看看你是不是能用常用的方式实现它。使用 DTrace 查看一下信息流。添加一些通知监听器然后看看这些工具想要告诉你什么。如果你写的代码有问题了，使用你常用的 debug 方式查看问题来源，看看你能不能自我提高。

我更趋向于在 UIKit/AppKit 下工作，所以我写了很多可以学习到数据结构和[语言特性][7]的代码。我的同事 Steve Sparks ，他用 tabview 和 navigation controller 创建了一个可以在任何时候实践新的功能的 Xcode 工程。 想要试试 UIScrollView ？你可以创建一个新的 ViewController，然后扔进来一个 UIScrollView，现在你可以在模拟器或者设备上随便玩了。对了，你最好做好[代码托管][8]这样你就可以记录下来你所有写过的代码。

##吸收

你决定了要学一些东西，然后你也写了一堆代码了，你也 debug 了，你甚至还[记了很多log][9]。你现在应该要消化这些知识了。睡一觉，出去玩一趟，洗个澡。让你学的这些新的东西融入一种模式。看看你能不能将这模式抽象出来，然后在其他地方使用。很多开发都是机器驱动的，你所要做的就是将一些特性和实现和一些类粘起来。

让你的大脑构建关于新知识的关系是吸收新知识最有趣的一部分。这篇文章中很多例子就是因为我们在工作中遇见的简单的问题，比如：“怎样触发内存警告？”，这样能帮我我们处理内存或者缓存的问题。整个过程如下：

*  我们可以在模拟器里面触发内存警告
*  用通知监听器看看这个时候是不是有通知在传送，他们为什么发送通知，我们可以连接它并回应它。
*  发送没并不会触发任何东西的通知，没用的东西，我想知道为什么。
*  哪些方法被触发了？使用 spy.d 看看发生了什么事，_performMemoryWarning 好像挺有意思的。
*  还有其他的内存警告方法我应该看？把类打开，看看里面都有什么方法。
*  发送 _performMemoryWarning 到 UIApplication，好像触发了所有的内存警告机制。那为什么没有发送通知呢？
*  娱乐一下，打开 Hopper 然后看看到底发生了什么事。看，它有一个视图控制器等级和 sqlite 的东西，只是发送通知是不能触发的。
*  在 debug 窗口添加一个内存警告触发按钮，封装在 #if debug 代码块里面，这样就不会把这玩意发送上线了。

##总结

这差不多就是我提高代码技巧的秘密方法：

* 阅读 - 把一堆事实扔到脑子里，有些可能不好理解。但是如果我发现这个东西还挺有意思的，我就会享受它。
* 剖析 - 多多使用工具，从高级到第低级的工具，不要害怕使用。即是你使用一种很奇怪的方式使用，也不要害怕。DTrace 是一个大榔头，你可以用它来把一个 bug 敲碎，敲成一些很小的 bug。用这些工具深入挖掘到软件中，看看它是怎么实现的。答应我，不要用这些东西做坏事。
* 实践 - 写代码，写一堆代码，实践是最好的方式，它能使你最快融入新的模式。
* 吸收 - 认真思考，抛出问题，解决问题，不停的重复。今天起后面的 20 年，一直停的学习。记住，让自己的技能相当厉害是一个长时间不停学习的结果。








[iOS6: Pushing The Limits]: http://www.amazon.com/iOS-Programming-Pushing-Limits-Application/dp/1118449959
[Advanced Mac OS X Programming: The Big Nerd Ranch Guide]:https://www.bignerdranch.com/we-write/advanced-mac-osx-programming/
[OS X Internals book]: http://www.amazon.com/Mac-OS-Internals-Systems-Approach/dp/0321278542/
[NSBlog]: https://www.mikeash.com/pyblog/
[NSHipster]: http://nshipster.com/
[Jeremy W.Sherman]:https://jeremywsherman.com/
[IOService]: https://developer.apple.com/library/mac/documentation/Kernel/Reference/IOService_reference/index.html
[gdb]:http://www.gnu.org/software/gdb/documentation/
[lldb]:http://lldb.llvm.org/
[http://clang.llvm.org]:http://clang.llvm.org
[http://www.opensource.apple.com]:http://www.opensource.apple.com
[DTrace]:https://www.bignerdranch.com/blog/hooked-on-dtrace-part-1/
[spy.d]:https://gist.github.com/markd2/5596426

[1]:https://www.bignerdranch.com/blog/
[2]:https://www.bignerdranch.com/blog/spelunkhead/
[3]:https://www.bignerdranch.com/blog/hooked-on-dtrace-part-3/
[4]:https://www.bignerdranch.com/blog/notifications-part-2-handling-and-spying/
[5]:http://stevenygard.com/projects/class-dump/
[6]:http://www.hopperapp.com/
[7]:https://www.bignerdranch.com/blog/tiny-programs-the-atomic-edition/
[8]:https://www.bignerdranch.com/blog/you-need-source-code-control-now/
[9]:https://www.bignerdranch.com/blog/adventures-in-debugging-keeping-a-log/
[10]:https://www.bignerdranch.com/blog/leveling-up/



