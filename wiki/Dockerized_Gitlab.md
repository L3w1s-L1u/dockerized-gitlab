[TOC]

## ǰ����������Ҫ
�����������ʹ��Docker���񹹽�����Gitlab���񡣱���Ŀ����������ջ���docker������ϣ��ͨ��docker������ٴ�Լ�Gitlab���������û���
[ǰ�������](http://blog.csdn.net/rhinocero/article/details/55806196)���ǽ���������ڱ���Linux�����в���Docker Engine����Ҫע�����¼������棺
*  ����ʹ�ð�װԴ�ı��ؾ����簢���ƣ�DaoCloud�ȣ�
*  ���ص����ص�docker�����ļ�����λ�ã����ϵͳ���ļ����ڷ�����С����Ҫ�ѱ��ؾ���ı���λ�ô�DockerĬ�ϵ�`/var/lib/docker` ת�Ƶ������ط���
* ���docker�û��飬ʹ����ͨ�û���ݲ���docker��
��ƪ��Ȼ���漰������docker֪ʶ��������docker compose��ص����ݡ�

## �������辵��
ʹ��docker pull�ֱ����� Gitlab��Redis��PostgreSQL����
```
$docker pull gitlab/gitlab-ce:latest
$docker pull sameersbn/postgresql:9.4
$docker pull redis:latest
```
> `:latest` ��ʾ���ؾ�������°汾��Ҳ����ָ���汾�ţ�����`sameersbn/postgresql:9.4`
> gitlabʹ�õ�����community�汾��[�ĵ��ڴ�](https://docs.gitlab.com/ce/README.html)
> ���ؾ���Ĳ���Ҳ����ֱ����docker-compose��һ���ǳɣ�Ϊ��ͻ���ص㣬�������ֶ����ء�

������ɺ�����
```
$docker images |grep -E 'gitlab|redis|postgresql'
```
Ӧ���ܿ����б������������������ļ�

## Docker Compose ��
Docker��Logo�����չʾ��dockerΪʲô�ܹ���Ӧ�ÿ��ٵ���ƽ̨�޹صķ�ʽ�������У�docker����������һ����װ�䣬�������Ӧ����Ruby on Railsд��Gitlab����ANSI Cд��Redis��PostgreSQL����������docker����װ�䣨���񣩡�װ�������Ծ������ʽ�ַ���Ȼ��ͨ��Docker Engine����һ������ʵ������������

��ΪDocker����ͳ�����⻯�������������Ĳ���ϵͳ���ջ���������ǳ����������������Ա�ݵطַ��Ͳ��𣬲��ҿ���ͨ���������ṩ��Dockerfile���������Ϊ�䷽�����ٵع������ͷ������ṩ�ľ���һģһ����Docker�������ʹ�û���Docker��Ӧ�ò�������б���쳣��ݡ�

����ΪDocker��ÿ��Ӧ�ö������ڵ��������������ͨ����¶ͨ�Ŷ˿ں͹������ݾ����ʽ�������ݽ��������ʹ�á�΢���񡱵ļܹ����Ը�Чʵʩ������������Ӧ������Ľ�׳�ԡ�������ǧ��������������еġ�΢���񡱣�Ҳ�Ʊ���Ҫһ���ܹ�ͳһ���й�����ֶΣ������docker compose�ȱ��Ź��ߴ��ڵ����塣

�������ֻ����ͬһ̨docker host��ִ�У���ôdocker��ǿ�����޴����֣�������docker��Ϊ�����Լ����ֶεģ�������֮���������Эͬ������ͨ�����Ź����������ڲ�ͬ�����ϵ�����Эͬ��������Ӧ�ã��Ӷ�ʹ��Ӧ�ù�ģ�����ڼ���ʹ洢��Դ֮����������������Ĳ�������л����ǰ��δ�е�����ԡ�

����������ǵ�Ӧ�ñȽϼ򵥣����ǽ�ֻ������������ͬһ�����Ϸֱ�����gitlab, redis��postgresql���������ǵ�Gitlab Service������ͬһ������ͬʱ���ж����������һ��Ӧ�ã����ݵķ�ʽ��ʹ��docker compose��

docker compose��ʹ�÷ǳ��ļ򵥣�׫дdocker-compose.yml�ļ�����Ӧ������ɶ�����񹹽�������ÿ������������ʱ������֮��һ���򵥵�docker-compose up����Ϳ���������Эͬ����������

�����������Ҫʹ�õ�docker-compose.yml�ļ���
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
ע�ͣ�
���compose���䷽��ָ������������ͬʱ���У��ֱ�Ϊ��postgresql, redis ��gitlab��ÿ��������ͨ��`image: `����ָ���˴��ĸ������ļ�����������`environment: ` ָ������������ʱ�Ļ�������ȡֵ��`volumes: ` ָ�������������ص����ݾ����﷨Ϊ��
```
Docker Host�ϵ�·��/A : �����ڵ�·��/B
```
��˼�ǽ�Docker Host�ϵ�Ŀ¼Aӳ��Ϊ�����ڵ�Ŀ¼B�����������ھ�����һ�����Ժ�Docker host���������������ݵĵط���

Ϊʲô��Ҫ�������أ� Docker�Ŀ�ݷַ��Ͳ��������Դ����ʹ��һ��UnionFS�ļ�ϵͳ�������ļ�ϵͳ��һ�ֲַ��ļ�ϵͳ��ÿ��Docker����ʵ���϶��������ɲ�����ֻ���ļ�ϵͳ�洢�ģ�������������ִ��ʱ��Dockerͨ����ֻ�������洴��һ�������Ķ�д������¼��������ʱ�����ĸ������ݡ�����������ʱ��docker���ͷŸö�д�㣬�������������������޸ľͶ��ҷ������ˡ���ôҪ�����������еĳɹ���ô�죿����Ҫִ��docker commit����docker engine�ύ���������������ʱ����̥�ľ����������޸ġ���ʱ��docker���������һ���µ�ֻ���㣬������ʵ���еı仯����������������������������Ҫ�޸ĵ��������ǳ�����ô�ö���֮������ͻ���ӷ�ײ�����dockerҲ��ʧȥ�����ڵ������ˡ�������Щ����Ҳ���û���ϣ�����浽����֮�еġ�

��������ԭ��docker��Ҫһ�ֽ����ݺ�����ʵ���������ڷ�����ֶΣ�����`volumes: ` ���ݾ�ӳ�����Ӧ�˶�����ͨ�����ַ�ʽ���û����Խ���Ҫ�־ñ��������ӳ�䵽�����У���ͨ������ȥʹ����Щ���ݡ���ʵ���У����ǵ�Gitlabӳ���������ļ��У��ֱ����ڴ������ʱ���������ݡ���־�����ã��������ļ���ӳ�����˫���д�ģ����������������޸ĺ��������޸�����Ч����һ���ġ�

�����`volumes: ` �Ͳ������`ports: ` �� `links: ` ���������Ƶ��﷨���ֱ��ʾ���������ϵ�TCP/IP�˿�ӳ�䵽������Ӧ�Ķ˿��ϣ��Լ�ָ��������ͬһ�������ϵ�������λ������ӡ���ʵ���У�Gitlab�ֱ���Redis��PostgreSQL�����ӣ�Redis�ṩ�־û����ܣ�PostgreSQL�ṩGitlab��˵����ݿ����

��Ҫ�ر�ע��ľ��Ƕ˿�ӳ����`A : B` ��AΪ�������˿ڣ�����ָ���Ѿ�������Ӧ��ռ�õĶ˿ڡ������� `A : B` AΪ�������������������ƣ�BΪ��������������ʶ������ӵ����������ơ����磬` - redis: redisio` ָ��docker-compose�ļ��е�redis����Ҫ���ӵ�gitlab��������gitlab�����У��������ʵ���redis�������redisio��

���о���ӳ���·�����Ƕ˿ڶ���Ҫ��ס�����ܺ�һЩ�����ļ���Ĳ�����ͻ���߳��ֲ�һ�¡�

�����Ҫ˵���ľ��ǣ���Ȼ������������ͨ��docker run����һ��һ����ִ�����������������񣬵�docker-compose.yml�Ǹ��Ƽ��ķ�ʽ�����������ˣ�����Ч��������ֻ���ڵ��Ե�ʱ���ر����á�

ʣ�µ�����͸�����ˣ�ֻ��һ���򵥵����
```
$docker-compose up
```
������docker������Gitlab��������������������Ⱥ����������ˡ�ִ��docker-compose������ն˻��Ϊ����GitlabӦ�õĿ����նˣ��������������������־��Ϣ�����һ����������Ϳ��Գ���ͨ��http://localhost:10080 ���������Gitlab�����ˡ�

## ��������
ͨ�����Ӧ�ô������һ����˳���������쳣ʱ������������������˳����У���ʱ�������ǰ�ξ��޷��������Ӧ���ˡ���ô���������Ӧ���أ�

���ȣ����docker-compose up����ֱ�ӷ��ش���˵�����docker-compose.yml�ļ����﷨���󣬿��Ը��ݳ�����ʾ��Ϣ�޸����.yml�ļ�����������
```
$docker-compose config
```
��������.yml�ļ��﷨�����������docker-compose.yml�ļ�����·����ִ�У���
���docker-compose upִ�к��������˳�����ô˵��docker-compose.yml��ָ����ĳЩ��������Ϊ���������ܡ���Ҫ����Ƿ�����Դ��ռ�û�ָ��·�����ɴ�����⡣

��������ܹ��������У������ǵ�GitlabӦ�û����޷����ʡ���ô����ͱȽϸ����ˡ���ʱ�����������һ̽��������������������
```
$docker exec -it ${YOUR_GITLAB_CONTAINER_NAME_OR_HASH_ID} /bin/bash
```
������������ܹ�attach���������е�Gitlab����(��docker-compose����Ϊ`gitlab_gitlab_1`��Redis����Ϊ`gitlab_redis_1`��PostgreSQLΪ`gitlab_postgresql_1`)�ϣ�����һ���ն˲����ն�������bash��
����㿴�������������ʾ����Ϊ����
```
root@a_hash_id:/#   		[ע��a_hash_id �ǵ�ǰ�������������ID]
```
��˵����ɹ���ͨ���ն˵��������У���ʱ�������ʹ�������й������鿴�������������������`exit` ��������˳�������
��Ȼ���������⣬�㻹����ʹ��
```
$docker logs ${YOUR_GITLAB_CONTAINER_NAME_OR_HASH_ID}
```
���鿴��־��

## ʹ��SMTP��������ΪGitlab���ʼ����ͷ����
����һ�ڵ�docker-compose�ļ��������Ѿ�����Gitlab�����Ļ����������в��ٹ���SMTP���趨�ˡ���ʵ������ʱ������Щ���ö��ǿ��Ա����ǵģ���ô�Ƚϱ��յ�����������gitlab_rails�����ļ���`gitlab.rb`�н���SMTP�趨�������ļ����£�����`volumes: ` ָ����configĿ¼�£������������������б༭��Ҳ���Խ���������`/etc/gitlab/` Ŀ¼�±༭��
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
����ʹ�õ�Gmail��ΪSMTP����ˣ�ע��`smtp_user_name`��`smtp_password`�������Gmail�����ʺš��������ÿ��Բο�Gmail�İ����ĵ�������gitlab_rails��[�����ĵ�](http://docs.gitlab.com/omnibus/settings/smtp.html)��

�����ļ�д�ú���Ҫ����Ӧ�ø����ø���gitlab��
```
$docker exec -it ${YOUR_GITLAB_CONTAINER_NAME_OR_HASH_ID} /bin/bash
# ����Ϊ�����ڲ���
root@a_hash_id:/# gitlab-ctl reconfigure
# Ҳ��������һ��
root@a_hash_id:/# gitlab-ctl restart
```
��ɺ�һ�������Ļ����gitlab.rb�е����þ�Ӧ����Ч�ˡ�
�ֶ�����һ���ʼ����͵�Ч����Ҳ��������telnet���Ե�½smtp������������һ����smtp����������ͨ��: 
```
root@a_hash_id:/# gitlab-rails console
#����Ϊgitlab-rails console�µĲ���
irb(main):001:0> Notify.test_email('my_email@163.com', 'Test mail frm gitlab', 'Hello').deliver_now
```
������յ��ʼ���˵���趨��Gmail SMTP��������������������ղ�������Ҫ����gitlab-rails console��Notify��ִ�лظ��������������ˡ�

## Next ==>ʹ��Ngrok������͸Զ�̷���Gitlab˽��


