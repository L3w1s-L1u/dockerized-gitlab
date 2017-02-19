
[TOC]

##内容提要
本文描述如何针对本地（中国大陆）网络环境优化Docker Engine的安装过程。
本文的目标读者是初次接触Docker的用户，目的是为在Docker上构建应用环境做准备。如果你已经熟悉Docker的使用，可以直接跳过本篇。
## 什么是Docker? 为什么要用 Docker?
![Docker project on Github][1]
Docker是一种基于容器技术构建的"轻量级"应用虚拟化解决方案，可以将任何应用封装到容器中并迁移到任意支持Docker的平台运行。
由于Docker容器硬件无关、平台无关的特性，使得容器化的应用实例可以不依赖特定的语言、应用程序开发框架和保管理系统而运行在小到笔记本大到云计算设施的所有平台上。
Docker技术的出现使得“微服务”架构能够被高效实施，极大地提升了网络应用从开发、测试到部署的效率和一体化程度。
## 在Linux主机上安装Docker
Docker技术发展迅猛，短短几年已经得到几乎所有IT巨头的鼎力支持，可以轻松部署到Linux/Windows/MacOS以及各种云平台上，各种VPS也竞相推出直接集成Docker的主机产品。
下面的例子都以最常见的Ubuntu开发环境为例，解释如何在Ubuntu上使用Docker。
限于篇幅，这里不详细介绍在Ubuntu上安装Docker的步骤，Docker官方网站提供了非常详尽的[安装说明][2]。严格按照该说明步骤操作可确保正确安装Docker。
> * 为避免更新内核等操作带来的麻烦，建议直接使用Ubuntu 16.04 （内核版本3.2以上）以上的发行版作为Docker Engine的安装平台。
>* 为了加速包管理器的下载，可以将Ubuntu系统中`/etc/apt/sources.list`文件中的Repo URL替换为：
网易开源镜像地址：[http://mirrors.163.com][3]
或阿里云开源镜像地址：[http://mirrors.aliyun.com][4]
## 测试Docker安装是否成功
安装完成后，运行：
```bash  
#docker version
```
>[注：代码示例中行首的“#”或"$"是root用户或普通用户的命令行提示符]

得到如下结果，说明Docker Engine能够正常工作
```
Client:
 Version:      1.11.2
 API version:  1.23
 Go version:   go1.5.4
 Git commit:   b9f10c9
 Built:        Wed Jun  1 21:42:09 2016
 OS/Arch:      linux/amd64

Server:
 Version:      1.11.2
 API version:  1.23
 Go version:   go1.5.4
 Git commit:   b9f10c9
 Built:        Wed Jun  1 21:42:09 2016
 OS/Arch:      linux/amd64

```
Docker 引擎默认需要root权限才能正常工作，但日常操作从安全考虑应该避免使用root用户操作docker。
可以在系统内添加一个docker用户组，将常用用户加入该组即可：
```bash
$sudo group add docker
$sudo gpasswd -a ${YOUR_USER_NAME} docker  [注：将YOUR_USER_NAME替换为你的用户名]
$sudo service docker restart
```
即可以普通用户身份执行docker指令了。

## 使用DaoCloud加速Docker镜像的下载速度
DaoCloud是一家提供基于Docker的企业级云计算平台的厂商，为方便大中华局域网内的用户使用docker官方的镜像仓库，提供了本地镜像加速功能，这样从DaoCloud的镜像服务器上下载Docker image速度会快很多。
使用下面的命令下载镜像加速脚本，运行脚本注册DaoCloud本地镜像仓库到Docker后，使用docker pull命令下载镜像就快多了
```bash
$curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://0cb3ea9e.m.daocloud.io
```
>手动添加镜像加速功能的步骤在此：http://guide.daocloud.io/dcs/daocloud-9153151.html

## 更改本地镜像文件的保存位置
Docker Engine默认的安装位置在`/var/lib/docker`

如果你的Linux系统没有为/var单独分配分区，那么下载到本地的镜像文件可能会很快耗光你的根文件系统所在分区空间。所以最好单独准备足够的空间并将/var/lib/docker指向它：
```
$sudo mv /var/lib/docker /var/lib/docker.bk
$sudo ln -s ${YOUR_ACTUAL_DOCKER_ROOT_DIR} /var/lib/docker 
	[注：YOUR_ACTUAL_DOCKER_ROOT_DIR为你新准备的磁盘分区所挂载的文件夹]
```
更为规范的做法是设置Docker的环境变量，指定保存Docker镜像的默认位置。
修改完成后重启docker engine，并下载所需的Docker镜像文件：
```
$sudo service docker restart
$docker image [查看本地docker镜像文件]
$docker image -a [查看所有docker镜像文件]
```
可以使用docker search命令查找所需的镜像并下载，使用“--no-trunc”选项可看到完整的镜像文件说明：
```
$docker search --no-trunc postgresql
$docker pull sameersbn/postgresql:latest
```
> docker search 返回的列表中，STAR代表该镜像受欢迎程度，OFFICIAL一列有\*表明为官方版本，应尽量使用官方版本。
## Next==> 使用Docker搭建Gitlab私服

  [1]: https://github.com/docker/docker/blob/master/docs/static_files/docker-logo-compressed.png
  [2]: https://docs.docker.com/engine/installation/linux/ubuntu/
  [3]: http://mirrors.163.com
  [4]: http://mirrors.aliyun.com
