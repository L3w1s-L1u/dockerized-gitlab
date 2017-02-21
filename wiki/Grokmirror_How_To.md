### **目录**
[TOC]
### **需求的提出**
开源软件开发和嵌入式软件开发会经常需要使用Linux内核源码。你是否经常会从[The Linux Kernel Archives](https://www.kernel.org/) 上下载源码，时间久了，不同版本的源码在本地堆得到处都是，是不是很烦？并且由于大天朝局域网接近断流的出国带宽，经常需要使用内核源码时拽不下来急死人有没有？这个时候总是会想能不能在本地做一个内核镜像，利用空闲时候的带宽同步内核代码，需要时直接从本地checkout需要的版本，方便多了。所幸这个需求并不小众，git的威力就在于它是一个分布式的版本管理系统，所以做个镜像是很轻松的事。

但是。。。

这里有两个问题，内核的git仓库是个“集群”，这意味着：

 1. 几个内核仓库之间可能存在引用关系（通过objects/info/alternates可以查看），例如，待会儿我选择进行同步的arm-soc.git和linux-stable.git就通过objects/info/alternates指向其他仓库。那么同步的时候实际上没有必要同步重复的objects造成带宽和存储空间的浪费。
 2. 当内核的git仓库“集群”中增加了新的仓库时，我们希望能够察觉到这个变化并自动镜像这些新添加的仓库。

以上这两条，也是Grokmirror的作者所指出的，为什么不用Linux的“计划任务”crond定时执行git pull去同步内核仓库的主要原因。更详细的解释戳[这里](https://github.com/mricon/grokmirror)。
 
### **什么是Grokmirror? grok|korg -- grokmirror is mirror of korg :）**
啰嗦这么多，那什么是Grokmirror呢？它是一个用Python开发的Linux内核源码仓库“集群”的同步工具，使用GitPython作为与Git的接口。Grokmirror使用一个manifest （清单）文件登记源码仓库“集群”中需要镜像的仓库，镜像仓库群（以下简称Mirror）根据用户配置定期地去poll被镜像仓库群（以下简称Master）的manifest文件，并对比本地manifest文件的记录数和各条记录的时间戳，如果Master有新加仓库记录，或者Master的manifest文件中有更新时间更迟的记录，那么Mirror就会自动更新本地的manifest，使其与Master保持同步，并且根据更新后的manifest，自动同步各个仓库。

#### **工作流程**
一图胜千言，下面来个时序图描述下大致的工作流程
```sequence
Note over Master: www.kernel.org
Note over Mirror: Grokmirror server
Note over repo c: user's local clone of a repo in Mirror(w/ work-tree)
Note right of Master: initial run ...
Master->Mirror: grok-pull: sync repos listed in manifest
Master->Mirror: grok-pull: make local copy of manifest according to repos.conf and sync result
Note right of Master: later ... run grok-pull again 
Mirror->Master: grok-manifest: get repos' fingerprint
Master->Mirror: grok-manifest: update Mirror's manifest
Master->Mirror: grok-pull: sync repos listed in manifest
Mirror->Mirror: grok-fsck: check local git repos
Mirror->repo c: git clone
```
*这里特别声明：*

*1. 我只是借用时序图来描述其工作流程，图中箭头方向并不代表对象之间发送消息，可以理解为执行操作时数据的流向，这是不符合时UML规范的。*

 *2. 这里描述了两个Use Case: 首次运行和再次运行的情况*

#### **manifest文件**
从上面的流程我们可以看到，grokmirror自动同步的关键就是manifest文件了:
```
{
  "/pub/scm/linux/kernel/git/arm/arm-soc.git": {
    "description": "ARM SoC tree",
    "fingerprint": "72e964761f2b3d6d4cd0b236664b47d12b5129c5",
    "modified": 1460587597,
    "owner": "ARM Maintainer group",
    "reference": "/pub/scm/linux/kernel/git/torvalds/linux.git"
  },
  "/pub/scm/linux/kernel/git/stable/linux-stable.git": {
    "description": "Linux kernel stable tree",
    "fingerprint": "4eae33462b52dc825799862d18521cc8c5febb92",
    "modified": 1461135735,
    "owner": "Greg Kroah-Hartman",
    "reference": "/pub/scm/linux/kernel/git/torvalds/linux.git"
  },
  "/pub/scm/linux/kernel/git/torvalds/linux.git": {
    "description": "Linux kernel source tree",
    "fingerprint": "db51977fda266a63e1f6b7231c9b76c9a487b5b0",
    "modified": 1461179135,
    "owner": "Linus Torvalds",
    "reference": null,
    "symlinks": [
      "/pub/scm/linux/kernel/git/torvalds/linux-2.6.git"
    ]
  }
}
```
这是根据我的repos.conf配置，首次运行grok-pull脚本后生成的manifest文件，其中包含了三个仓库对象，每个仓库的json语法如下：
```
{
	"/path/to/bare/repository.git": {
		"description": "Repository description",
		"reference": "/path/to/reference/repository.git",
		"modified": timestamp,
		"fingerprint": sha1sum(git show-ref),
		"symlinks": [
		"/location/to/symlink",
		...
		],
} 
```
其中，fingerprint是对源仓库执行git show-ref的输出进行哈希（相当于对所有refs的哈希值再进行一次特征取样，确保内容的唯一性）的结果，用于和本地仓库的“sha1sum(git show-ref)”结果进行比对，确认仓库是否需要更新。而timestamp记录仓库最后修改的时间，用于和本地库的修改时间进行比对以决定是否需要更新。

而reference则指向该仓库所引用的仓库，既本文开头提到的第一个问题。我的manifest中，引用关系是这样的： arm/arm-soc.git --> torvalds/linux.git <-- stable/linux-stable.git。

那么manifest文件中的这些json对象是怎么来的呢？一句话的解释就是根据我们在repos.conf文件中的设定裁切Master的manifest文件生成的。具体是如何生成，又是如何更新的，需要我们先把Grokmirror运行起来再解释。

下面我们开始在Mirror，也就是我们用来作为提供镜像服务的Linux系统上部署Grokmirror。这里我使用的是一台Ubuntu 12.04LTS。
### **安装Grokmirror**
#### **GitPython**
Grokmirror需要GitPython库来操作git，从[官网](https://pypi.python.org/pypi/GitPython)下载GitPython或者使用包管理器安装：
```
# aptitude install python-git
```
如果是下载的需要解压后执行：
```
# python setup.py install
```
anyjson的安装与GitPython类似：
#### **anyjson**
从[Python官网](https://pypi.python.org/pypi/anyjson)下载anyjson或者使用apt安装：
```
# aptitude install python-anyjson
```
#### **Grokmirror**
可以从[Github](https://github.com/mricon/grokmirror)上clone源码，并运行Python安装脚本: 
```
# cd grokmirror && sudo python setup.py install
```
安装完成后可以看到源码包中grokmirror目录下的四个Python脚本被安装到了`/usr/local/bin` 下面。
### **设置Grokmirror**
#### **repos.conf**
Grokmirror只有这一个核心的配置文件。 我们看一下针对我的这个需求，配置文件的详细内容。原文件注释很多，有删节并只注解和我们主题相关的部分：

```
# You can pull from multiple grok mirrors, just create
# a separate section for each mirror. The name can be anything.
[kernel.org]
# site保存你需要镜像的对象，即Master。这里就是Linux内核的官方git服务
site = git://git.kernel.org
#
# Where the grok manifest is published. The following protocols
# are supported at this time:
# http:// or https:// using If-Modified-Since http header
# file:// (when manifest file is on NFS, for example)
# 支持grok的Master必须用以上两种方式对外公布自己的manifest文件
manifest = http://git.kernel.org/manifest.js.gz
#
# Where are we going to put the mirror on our disk?
# Mirror下来的仓库群在本地文件系统的绝对路径
toplevel = /srv/work/repos/_mirror
#
# Where do we store our own manifest? Usually in the toplevel.
# 本地manifest文件的存放路径
mymanifest = /srv/work/repos/_mirror/manifest.js.gz
#
# Write out projects.list that can be used by gitweb or cgit.
# Leave blank if you don't want a projects.list.
# Projects.list文件可用于gitweb和cgit，这里我们暂时用不上
projectslist = /srv/work/repos/_mirror/projects.list
#
# 去掉 projectslist中仓库群URL地址中目录的公共部分，例如我的三个仓库都位于/pub/scm/linux/kernel/git目录下，所以trimtop=/pub/scm/linux/kernel/git
projectslist_trimtop = /pub/scm/linux/kernel/git
#
#（此处省略一万字，在后续文章中我们再深入讨论这些细节） 
projectslist_symlinks = no
#
# A simple hook to execute whenever a repository is modified.
# It passes the full path to the git repository modified as the only
# argument.
# 这个我们对外发布Mirror服务时才用得上
#post_update_hook = /usr/local/bin/make-git-fairies-appear
post_update_hook =
# （防止本地仓库被意外删除，详细地解释请参考原文）
purgeprotect = 5
#
# If owner is not specified in the manifest, who should be listed
# as the default owner in tools like gitweb or cgit?
default_owner = Grokmirror User
#
# Where do we put the logs?
log = /var/log/mirror/kernelorg.log
#
# Log level can be "info" or "debug"
loglevel = info
#loglevel = info
#
# 允许使用几个线程进行同步？实际上我只观察到2个线程，为了减轻Master负荷，不要设太大
pull_threads = 5
#
# Use shell-globbing to list the repositories you would like to mirror.
# If you want to mirror everything, just say "*". Separate multiple entries
# with newline plus tab. Examples:
#
# mirror everything:
#include = *
#
# mirror just the main kernel sources:
#include = /pub/scm/linux/kernel/git/torvalds/linux.git
#          /pub/scm/linux/kernel/git/stable/linux-stable.git
#          /pub/scm/linux/kernel/git/next/linux-next.git
#
# mirror just git:
#include = /pub/scm/git/*
# 这是整个配置中最关键的一个变量了 —— 指定你要镜像的仓库。支持Shell式的通配符匹配，这也是为什么grokmirror可以支持对新添加的仓库自动镜像：比如你指定include = *， 那么当Master上有新仓库加入，自然也会被manifest文件include进去
include =  	/pub/scm/linux/kernel/git/stable/linux-stable.git 
		/pub/scm/linux/kernel/git/arm/arm-soc.git
        /pub/scm/linux/kernel/git/torvalds/linux.git
# This is processed after the include. If you want to exclude some specific
# entries from an all-inclusive globbing above. E.g., to exclude all linux-2.4
# git sources:
# 排除特定的仓库
exclude = */linux-2.4*
```
配置完成后我们便可以首次运行grok-pull，Grokmirror会根据repos.conf的内容（include指定的仓库列表）帮我们生成一个manifest文件，并在镜像成功后更新这个文件。
#### **kernelorg.log**
这是你在repos.conf中指定的日志文件，你可以用tail命令读取文件的实时写入，这样方便你观察你的crond自动执行Grokmirror的情况。
```
# tail -F /var/log/mirror/krenelorg.log
```
#### **projects.list**
这个文件当你需要用你的Mirror对外发布gitweb或cgit服务时才会用到。首次运行成功后会将这个文件写入你的镜像仓库的根目录。

###**运行Grokmirror**
#### **手动运行Grokmirror**
我们先手动运行一遍grok-pull，确认Everything is OK之后我们再尝试用crond来自动运行。
```
# cd /srv/work/repos/_mirror
# grok-pull -c repos.conf
```
如果你用`tail -F` 查看日志，可以看到grok-pull会首先尝试从Master获取manifest文件，之后发现本地还没有生成manifest文件，于是进入首次运行的模式，根据repos.conf指定的include仓库列表调用git clone去逐个镜像。这个过程会比较漫长，取决于你使用的网络。

成功镜像各个仓库之后，grok-pull会根据结果生成本地的manifest文件，这样，在以后的同步流程中，grok-pull都会比对本地和Master上的manifest文件记录，决定是否要更新、添加或者删除本地的仓库。
#### **WTF is bare repository?**
如果你打开同步完成后的仓库（例如linux-stable.git）你会发现里面并没有work-tree，只有一堆以前貌似是存在于.git目录下的东西。这是因为Grokmirror目前只滋瓷镜像bare repository。关于bare repository和一般的repository区别，戳[这里](http://www.saintsjd.com/2011/01/what-is-a-bare-git-repository/)。简单的说bare repo由于没有work-tree，即没有本地的修改，所以可以方便不同的用户向其提交修改。
这也意味着我们不能直接在镜像上进行git的日常操作，当我们要使用某个repo时，我们需要git clone一下，就像流程图所示那样。
#### **使用git hooks更新本地manifest文件**
git提供了大量的钩子方便我们在远端的git执行特定的操作时本地能够接收到通知从而做出相应的用户自定义操作。Grokmirror便利用这一点，让我们在Mirror接收到push过来的修改时能够自动更新本地的manifest文件，只需将
```
/usr/local/bin/grok-manifest -m /srv/work/repos/_mirror/repos.conf -t /pub/scm/linux/kernel/git -n `pwd`
```
添加到每个repo_name_xxx.git/hooks/post-receive.sample中，并将.sample后缀去掉，就可以让post-receive钩子生效。这样如果我们在repo c中做出修改并向Mirror进行push，Mirror会在接收到push后调用我们注册的这个钩子，更新Mirror的manifest文件。这时，如果有别的仓库是从我们的Mirror克隆过去的，他就会发现我们的Mirror的manifest文件更新了，于是他的grok-pull就会把这个更新自动镜像过去。
#### **使用Crond自动运行Grokmirror**
如果上面的步骤一切顺利，接下来就是把脚本添加到crontab中，让它定时执行了。出于对安全的考虑，作者建议我们开一个单独的帐号来做这个事情。我添加一个系统用户组mirror，里面有一个系统用户mirror，登陆shell设置成`/usr/sbin/nologin` （不能用mirror登陆系统）将/usr/local/bin/grok-xxx的执行权限和/var/log/mirror以及/srv/work/repos/_mirror文件夹的读、写、执行权限赋予mirror组，然后在crontab中添加：

```
00 02 * * * mirror /usr/local/bin/grok-pull -r -c /srv/work/repos/_mirror/repos.conf
```
在每天凌晨2点使用mirror用户身份执行grok-pull进行镜像的更新。

### **小结**
本文介绍了为什么需要Grokmirror，Grokmirror的基本工作原理、配置及运行。当你只有一个git仓库需要镜像时，使用crond去自动定时pull是能够满足需要的，但如果是kernel这样复杂的git仓库集群，就必须要请Grokmirror帮忙了。

grok-pull和grok-manifest还支持许多参数作者没有在Readme文档中一一说明，可以参考这些命令的python源码。

Grokmirror也可以用于镜像kernel.org以外的仓库，只要你能将Grokmirror的manifest文件通过http协议或文件共享协议发布出去。后面我们来尝试用Grokmirror管理自己的git仓库。

本文主要参考Grokmirror的Readme文档和源码进行分析，并在Ubuntu 12.04LTS 64bit环境下调试通过，成功地定时更新指定的三个仓库：arm-soc.git, linux-stable.git及torvalds/linux.git。**文中难免存在错误，恳请务必指正，以免误导需要参考的同学，感激不尽！**

（写完这篇时，马球王绝杀埃弗顿带领曼联挺进祖宗杯决赛，+2又一次续命成功……大巴黎心喜穆帅，穆帅心喜曼联，这个夏天是不是要尴尬了…… 马夏尔越来越像大帝亨利，这个孩子的未来不可限量啊！）
