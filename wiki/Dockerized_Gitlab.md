[TOC]

## 前情与内容提要
本文描述如何使用Docker镜像构建本地Gitlab服务。本文目标读者是掌握基本docker操作，希望通过docker镜像快速搭建自己Gitlab服务器的用户。
[前面的文章](http://blog.csdn.net/rhinocero/article/details/55806196)我们介绍了如何在本地Linux环境中部署Docker Engine。主要注意以下几个方面：
*  尽量使用安装源的本地镜像，如阿里云，DaoCloud等；
*  下载到本地的docker镜像文件保存位置，如果系统根文件所在分区较小，需要把本地镜像的保存位置从Docker默认的`/var/lib/docker` 转移到其他地方；
* 添加docker用户组，使用普通用户身份操作docker。
本篇仍然会涉及到不少docker知识，尤其是docker compose相关的内容。

## 下载所需镜像
使用docker pull分别下载 Gitlab、Redis和PostgreSQL镜像：
```
$docker pull gitlab/gitlab-ce:latest
$docker pull sameersbn/postgresql:9.4
$docker pull redis:latest
```
> `:latest` 表示下载镜像的最新版本，也可以指定版本号，例如`sameersbn/postgresql:9.4`
> gitlab使用的是其community版本：[文档在此](https://docs.gitlab.com/ce/README.html)
> 下载镜像的步骤也可以直接在docker-compose中一气呵成，为了突出重点，我们先手动下载。

下载完成后运行
```
$docker images |grep -E 'gitlab|redis|postgresql'
```
应该能看到列表中有上述三个镜像文件

## Docker Compose 大法
Docker的Logo形象地展示了docker为什么能够让应用快速地以平台无关的方式部署运行：docker容器就像是一个集装箱，不管你的应用是Ruby on Rails写的Gitlab还是ANSI C写的Redis或PostgreSQL，都可以用docker“集装箱（镜像）”装起来，以镜像的形式分发，然后通过Docker Engine产生一个容器实例来运行它。

因为Docker不像传统的虚拟化那样包含完整的操作系统软件栈，所以它非常“轻量级”，可以便捷地分发和部署，并且可以通过发布方提供的Dockerfile（可以理解为配方）快速地构建出和发布方提供的镜像一模一样的Docker镜像。这就使得基于Docker的应用部署和运行变得异常便捷。

又因为Docker将每个应用都隔离在单独的容器里，互相通过暴露通信端口和共享数据卷等形式进行数据交换，这就使得“微服务”的架构得以高效实施，极大地提高了应用整体的健壮性。而数以千万计运行在容器中的“微服务”，也势必需要一种能够统一进行管理的手段，这就是docker compose等编排工具存在的意义。

如果容器只能在同一台docker host上执行，那么docker的强大还是无从体现，真正让docker成为革命性技术手段的，是容器之间跨主机的协同工作，通过编排工具让运行在不同主机上的容器协同工作构建应用，从而使得应用规模可以在计算和存储资源之上任意伸缩，服务的部署和运行获得有前所未有的灵活性。

这里，由于我们的应用比较简单，我们将只用三个容器在同一主机上分别运行gitlab, redis和postgresql来构建我们的Gitlab Service。而在同一主机上同时运行多个容器构建一个应用，最便捷的方式是使用docker compose。

docker compose的使用非常的简单：撰写docker-compose.yml文件描述应用如何由多个镜像构建并描述每个容器的运行时环境，之后一个简单的docker-compose up命令就可以让容器协同工作起来。

下面就是我们要使用的docker-compose.yml文件：
```
# Example Docker Compose file for Gitlab service

postgresql:
    image: "sameersbn/postgresql:9.4"
    environment:
        DB_NAME: "gitlab_xxxx"
        DB_USER: "gitlab"
        DB_PASS: "your_password"
    volumes:
        - /srv/work/_db/postgresql/data:/var/lib/postgresql

redis:
    image: "redis:latest"

gitlab:
    image: "gitlab/gitlab-ce:latest"
    ports:
        - "10022:22"
        - "10080:80"
    links:
        - redis:redisio
        - postgresql:postgresql
    volumes:
        - /srv/work/_db/gitlab/data:/srv/git/data
        - /srv/work/_db/gitlab/log:/var/log/gitlab
        - /srv/work/_db/gitlab/config:/etc/gitlab
    environment:
        GITLAB_PORT: 10080
        GITLAB_SSH: 10022
        GITLAB_BACKUPS: "daily"
        GITLAB_HOST: "gitlab.yourdomain.com"
        GITLAB_SIGNUP: "true"
        GITLAB_ROOT_PASSWORD: "your_password"
        GITLAB_GRAVATAR_ENABLED: "true"
        SMTP_ENABLED: "true"
        SMTP_DOMAIN: "gmail.com"
        SMTP_HOST: "smtp.gmail.com"
        SMTP_PORT: 587
        SMTP_STARTTLS: "true"
```
注释：
这份compose“配方”指定了三个容器同时运行，分别为：postgresql, redis 和gitlab。每个容器都通过`image: `导语指定了从哪个镜像文件生成容器；`environment: ` 指定了容器运行时的环境变量取值；`volumes: ` 指定了容器所挂载的数据卷，其语法为：
```
Docker Host上的路径/A : 容器内的路径/B
```
意思是将Docker Host上的目录A映射为容器内的目录B，这样容器内就有了一个可以和Docker host宿主环境共享数据的地方。

为什么需要这样做呢？ Docker的快捷分发和部署的特性源于它使用一种UnionFS文件系统，这种文件系统是一种分层文件系统。每个Docker镜像实际上都是由若干层这种只读文件系统存储的，当镜像变成容器执行时，Docker通过在只读层上面创建一个薄薄的读写层来记录容器运行时产生的各种数据。当容器销毁时，docker会释放该读写层，这样容器所作的所有修改就都灰飞烟灭了。那么要保存容器运行的成果怎么办？就需要执行docker commit来向docker engine提交容器相对于其启动时所脱胎的镜像所作的修改。这时，docker就向镜像添加一个新的只读层，用来落实所有的变化。但这个做法最大的问题在于如果需要修改的数据量非常大，那么久而久之，镜像就会变得臃肿不堪，docker也就失去它存在的意义了。况且有些数据也是用户不希望保存到镜像之中的。

基于以上原因，docker需要一种将数据和容器实例的生存期分离的手段，于是`volumes: ` 数据卷映射机制应运而生。通过这种方式，用户可以将需要持久保存的数据映射到容器中，再通过容器去使用这些数据。本实例中，我们的Gitlab映射了三个文件夹，分别用于存放运行时产生的数据、日志和配置，这三个文件夹映射后是双向读写的，即在宿主环境中修改和容器内修改内容效果是一样的。

理解了`volumes: ` 就不难理解`ports: ` 和 `links: ` 它们有相似的语法，分别表示将宿主机上的TCP/IP端口映射到容器相应的端口上，以及指定运行在同一宿主机上的容器如何互相连接。本实例中，Gitlab分别与Redis和PostgreSQL相连接，Redis提供持久化功能，PostgreSQL提供Gitlab后端的数据库服务。

需要特别注意的就是端口映射中`A : B` ，A为宿主机端口，不能指定已经被其他应用占用的端口。连接中 `A : B` A为宿主环境中容器的名称，B为该容器环境中所识别的连接到的容器名称。例如，` - redis: redisio` 指定docker-compose文件中的redis容器要连接到gitlab容器，在gitlab容器中，它所访问到的redis服务就是redisio。

再有就是映射的路径或是端口都需要记住，不能和一些配置文件里的参数冲突或者出现不一致。

最后需要说明的就是，虽然可以在命令行通过docker run命令一个一个地执行三个容器构建服务，但docker-compose.yml是更推荐的方式，它清晰明了，简洁高效。命令行只有在调试的时候特别有用。

剩下的事情就格外简单了，只需一个简单的命令：
```
$docker-compose up
```
我们用docker镜像搭建的Gitlab服务就随着三个容器的先后运行上线了。执行docker-compose命令的终端会成为我们Gitlab应用的控制终端，接收三个容器输出的日志信息，如果一切正常。你就可以尝试通过http://localhost:10080 来访问你的Gitlab服务了。

## 调试容器
通常你的应用搭建都不会一帆风顺，当出现异常时，出现问题的容器会退出运行，这时从浏览器前段就无法访问你的应用了。那么如何来调试应用呢？

首先，如果docker-compose up命令直接返回错误，说明你的docker-compose.yml文件有语法错误，可以根据出错提示信息修改你的.yml文件。还可以用
```
$docker-compose config
```
来检查你的.yml文件语法（必须在你的docker-compose.yml文件所在路径下执行）。
如果docker-compose up执行后有容器退出，那么说明docker-compose.yml中指定的某些参数不能为容器所接受。需要检查是否有资源被占用或指定路径不可达的问题。

如果容器能够正常运行，但我们的Gitlab应用还是无法访问。那么情况就比较复杂了。这时候进入容器内一探究竟或许能有所帮助：
```
$docker exec -it ${YOUR_GITLAB_CONTAINER_NAME_OR_HASH_ID} /bin/bash
```
上面这个命令能够attach到你所运行的Gitlab容器(被docker-compose命名为`gitlab_gitlab_1`，Redis容器为`gitlab_redis_1`，PostgreSQL为`gitlab_postgresql_1`)上，并打开一个终端并在终端里运行bash。
如果你看到你的命令行提示符变为类似
```
root@a_hash_id:/#   		[注：a_hash_id 是当前所登入的容器的ID]
```
就说明你成功地通过终端登入容器中，这时候你可以使用命令行工具来查看容器的运行情况。输入`exit` 命令可以退出容器。
当然，在容器外，你还可以使用
```
$docker logs ${YOUR_GITLAB_CONTAINER_NAME_OR_HASH_ID}
```
来查看日志。

## 使用SMTP服务器作为Gitlab的邮件发送服务端
从上一节的docker-compose文件中我们已经看到Gitlab容器的环境变量中有不少关于SMTP的设定了。但实际运行时发现这些设置都是可以被覆盖的，那么比较保险的做法就是在gitlab_rails配置文件：`gitlab.rb`中进行SMTP设定。配置文件如下，放在`volumes: ` 指定的config目录下，可以在宿主机环境中编辑，也可以进入容器在`/etc/gitlab/` 目录下编辑：
```
# gitlab SMTP configurations
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "gitlab_your_email_account@gmail.com"
gitlab_rails['smtp_password'] = "123456!@#"
gitlab_rails['smtp_domain'] = "gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

# If your SMTP server does not like the default 'From: gitlab@localhost' you
# # can change the 'From' with this setting.
gitlab_rails['gitlab_email_from'] = 'gitlab_your_email_account@gmail.com'
gitlab_rails['gitlab_email_reply_to'] = 'gitlab_your_email_account@gmail.com'
```
本例使用的Gmail作为SMTP服务端，注意`smtp_user_name`和`smtp_password`就是你的Gmail邮箱帐号。邮箱设置可以参考Gmail的帮助文档，或者gitlab_rails的[配置文档](http://docs.gitlab.com/omnibus/settings/smtp.html)。

配置文件写好后，需要重新应用该配置更新gitlab：
```
$docker exec -it ${YOUR_GITLAB_CONTAINER_NAME_OR_HASH_ID} /bin/bash
# 以下为容器内操作
root@a_hash_id:/# gitlab-ctl reconfigure
# 也可以重启一下
root@a_hash_id:/# gitlab-ctl restart
```
完成后一切正常的话你的gitlab.rb中的配置就应该生效了。
手动测试一下邮件发送的效果，也可以先用telnet尝试登陆smtp服务器，测试一下与smtp服务器的连通性: 
```
root@a_hash_id:/# gitlab-rails console
#以下为gitlab-rails console下的操作
irb(main):001:0> Notify.test_email('my_email@163.com', 'Test mail frm gitlab', 'Hello').deliver_now
```
如果能收到邮件，说明设定的Gmail SMTP带发能正常工作。如果收不到，就要根据gitlab-rails console上Notify的执行回复分析问题所在了。

## Next ==>使用Ngrok内网穿透远程访问Gitlab私服


