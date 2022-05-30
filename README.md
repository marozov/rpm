Управление пакетами. Дистрибьюция софта

Домашнее задание

1) создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями)
2) создать свой репо и разместить там свой RPM
реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо 


Стенд со всеми этими операциями собирается в автоматическом режиме.

Создание своего RPM
Первым делом устанавливаем пакеты: 

```

yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc

```

Скачиваем src.rpm - 

```
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm

```
При использовании этой команды с параметром -i, распаковываются src и spec файл: 

```
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm

```
Переходим в каталог rpmbuild:

В папке SPECS лежит spec-файл. Файл, который описывает что и как собирать.

Открываем файл nano SPECS/nginx.spec и добавляем в секцию %build необходимый нам модуль OpenSSL:

```
%build
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}" \
    --with-openssl=/root/rpmbuild/openssl-1.1.1c
make %{?_smp_mflags}
%{__mv} %{bdir}/objs/nginx \
    %{bdir}/objs/nginx-debug
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}"
make %{?_smp_mflags}

```
Устанавливаем зависимости - 

```
yum-builddep SPECS/nginx.spec

```
Собираем - 

```
rpmbuild -bb SPECS/nginx.spec

```
Устанавливаем rpm пакет: 

yum localinstall -y RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm

Запускаем nginx - 

```
systemctl start nginx 

```
и можем посмотреть с какими параметрами nginx был скомпилирован nginx -V
Также стоит отметить, что nginx можно собрать через 
./configure && make && make install. Ссылка на мануал.

Создаем свой репозиторий
Создаем папку в / нашего nginx - 

```
mkdir /usr/share/nginx/html/repo

```
Копируем наш скомпилированный пакет nginx в папку с будущим репозиторием - cp rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
Скачиваем дополнительно пакет - 

```
wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm

```
Создаем репозиторий -

```
createrepo /usr/share/nginx/html/repo/ и 
createrepo --update /usr/share/nginx/html/repo/

```
В location / в файле /etc/nginx/conf.d/default.conf добавим директиву autoindex on. В результате location будет выглядеть так:

```
location / {
root /usr/share/nginx/html;
index index.html index.htm;
autoindex on; Добавили эту директиву
}

```
Проверяем синтаксис nginx -t и nginx -s reload
Теперь можем просмотреть наши пакеты через HTTP - lynx http://localhost/repo/ или curl -a http://localhost/repo/
Теперь чтобы протестировать репозиторий - создаем файл /etc/yum.repos.d/otus.repo и вписываем в него следующее:

```
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
```

Можем посмотреть подключенный репозиторий - 

```
yum repolist enabled | grep otus и yum list | grep otus или yum list --showduplicates | grep otus

```

```
yum list --showduplicates | grep otus
percona-release.noarch                      0.1-6                      @otus
nginx.x86_64                                1:1.8.1-1.el7.ngx          otus
nginx.x86_64                                1:1.12.2-1.el7_4.ngx       otus
nginx.x86_64                                1:1.14.1-1.el7_4.ngx       otus
percona-release.noarch                      0.1-6                      otus

```

```
yum list | grep otus
percona-release.noarch                      0.1-6                      @otus
Важно: в случае когда мы удаляем или добавляем пакеты в наш репозиторий, нам необходимо выполнить createrepo <наш репозиторий> и createrepo --update <наш репозиторий>, после чего на всякий случай можем выполнить yum clean all и теперь yum list --showduplicates | grep otus
```
