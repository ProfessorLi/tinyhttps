## http格式

http请求包含三个部分，分别是：起始行、消息包头、请求正文

```c
Request Line<CRLF>
Header-Name: header-value<CRLF>
Header-Name: header-value<CRLF>
//一个或多个，均以<CRLF>结尾
<CRLF>
body//请求正文
```

![](/home/likewise-open/SENSETIME/zhangshuo/Desktop/0628/http请求报文格式.png)



1、起始行以一个方法符号开头，以空格分开，后面跟着请求的URI和协议的版本，格式如下：

```c
Method Request-URL HTTP-Version CRLF
```

​    **请求方法 统一资源标识符  HTTP协议版本  回车换行符**

2、请求方法（所有方法全为大写）有多种，各个方法的解释如下：

- GET 请求获取Request-URI所标识的资源
- POST 在Request-URI所标识的资源后附加新的数据
- HEAD 请求获取由Request-URI所标识的资源的响应消息报头
- PUT 请求服务器存储一个资源，并用Request-URI作为其标识
- DELETE 请求服务器删除Request-URI所标识的资源
- TRACE 请求服务器回送收到的请求信息，主要用于测试或诊断
- CONNECT 保留将来使用
- OPTIONS 请求查询服务器的性能，或者查询与资源相关的选项和需求

应用举例：  GET方法：在浏览器的地址栏中输入网址的方式访问网页时，浏览器采用GET方法向服务器获取资源，eg: 

```c
GET /form.html HTTP/1.1 (CRLF)
```

POST方法要求被请求服务器接受附在请求后面的数据，常用于提交表单。eg：

```c
POST /reg.jsp HTTP/ (CRLF)
Accept:image/gif,image/x-xbit,... (CRLF)
...
HOST:www.guet.edu.cn (CRLF)
Content-Length:22 (CRLF)
Connection:Keep-Alive (CRLF)
Cache-Control:no-cache (CRLF)
(CRLF)         //该CRLF表示消息报头已经结束，在此之前为消息报头
user=jeffrey&pwd=1234  //此行以下为提交的数据
```



## Tinyhttpd中包含的主要函数

包含的函数

```c
void accept_request(int);
void bad_request(int);
void cat(int, FILE *);
void cannot_execute(int);
void error_die(const char *);
void execute_cgi(int, const char *, const char *, const char *);
int get_line(int, char *, int);
void headers(int, const char *);
void not_found(int);
void serve_file(int, const char *);
int startup(u_short *);
void unimplemented(int);
```

交互流程

![](/home/likewise-open/SENSETIME/zhangshuo/Desktop/0628/tinyhttpd学习过程.assets/交互流程.jpg)





### main函数 

sockaddr_In结构体： 解决了sockaddr的缺陷，将port和addr分开存储。

```c
struct sockaddr_in { 
　　 short int sin_family;
　　 unsigned short int sin_port; 
    struct in_addr sin_addr;
	struct in_addr { 
    	unsigned long s_addr;
    }        
    unsigned char sin_zero[8];
}   
```

#### 使用socklen_t记录clientname长度

socklen_t的定义出现在，与int具有相同的长度。

windows平台下: 头文件：

#include<ws2tcpip.h>  

linux平台下,下面两个头文件都有定义

1）#include <sys/socket.h>

2）#include <unistd.h>

#### 使用pthread记录新线程的id

#### 调用startup函数 开启端口

socket函数进行调用 

```c
httpd = socket(PF_INET, SOCK_STREAM, 0);
```

建立socket指定协议时，采用PF，设置地址时，采用AF。

##### socket函数原型

socket()函数的原型如下，这个函数建立一个协议族为domain、协议类型为type、协议编号为protocol的套接字文件描述符。如果函数调用成功，会返回一个标识这个套接字的文件描述符，失败的时候返回-1。

```c
#include<sys/types.h>
#include<sys/socket.h>
int socket(int domain, int type, int protocol);
```

###### domain

函数socket()的参数domain用于设置网络通信的域，函数socket()根据这个参数选择通信协议的族。通信协议族在文件sys/socket.h中定义。

| 名称             | 含义              | 名称         | 含义                     |
| ---------------- | ----------------- | ------------ | ------------------------ |
| PF_UNIX,PF_LOCAL | 本地通信          | PF_X25       | ITU-T X25 / ISO-8208协议 |
| AF_INET,PF_INET  | IPv4 Internet协议 | PF_AX25      | Amateur radio AX.25      |
| PF_INET6         | IPv6 Internet协议 | PF_ATMPVC    | 原始ATM PVC访问          |
| PF_IPX           | IPX-Novell协议    | PF_APPLETALK | Appletalk                |
| PF_NETLINK       | 内核用户界面设备  | PF_PACKET    | 底层包访问               |

此次使用的为PF_INET，即IPv4协议。

###### type

函数socket()的参数type用于设置套接字通信的类型，主要有SOCKET_STREAM（流式套接字）、SOCK——DGRAM（数据包套接字）等。

| 名称           | 含义                                                         |
| -------------- | ------------------------------------------------------------ |
| SOCK_STREAM    | Tcp连接，提供序列化的、可靠的、双向连接的字节流。支持带外数据传输 |
| SOCK_DGRAM     | 支持UDP连接（无连接状态的消息）                              |
| SOCK_SEQPACKET | 序列化包，提供一个序列化的、可靠的、双向的基本连接的数据传输通道，数据长度定常。每次调用读系统调用时数据需要将全部数据读出 |
| SOCK_RAW       | RAW类型，提供原始网络协议访问                                |
| SOCK_RDM       | 提供可靠的数据报文，不过可能数据会有乱序                     |
| SOCK_PACKET    | 这是一个专用类型，不能在通用程序中使用                       |

此次使用的为SOCK_STREAM。

###### protocol

函数socket()的第3个参数protocol用于制定某个协议的特定类型，即type类型中的某个类型。通常某协议中只有一种特定类型，这样protocol参数仅能设置为0；但是有些协议有多种特定的类型，就需要设置这个参数来选择特定的类型。

- 类型为SOCK_STREAM的套接字表示一个双向的字节流，与管道类似。流式的套接字在进行数据收发之前必须已经连接，连接使用connect()函数进行。一旦连接，可以使用read()或者write()函数进行数据的传输。流式通信方式保证数据不会丢失或者重复接收，当数据在一段时间内任然没有接受完毕，可以将这个连接人为已经死掉。
- SOCK_DGRAM和SOCK_RAW 这个两种套接字可以使用函数sendto()来发送数据，使用recvfrom()函数接受数据，recvfrom()接受来自制定IP地址的发送方的数据。
- SOCK_PACKET是一种专用的数据包，它直接从设备驱动接受数据。

startup函数中调用方法为建立一个流式套接字。

---

sockaddr_in 在使用前用0进行初始化。

并且进一步填充接口。

```c
memset(&name, 0, sizeof(name));
name.sin_family = AF_INET;
name.sin_port = htons(*port);
name.sin_addr.s_addr = htonl(INADDR_ANY);
```

---

##### bind函数

利用bind函数对socket套接字进行命名。

```c
if (bind(httpd, (struct sockaddr *)&name, sizeof(name)) < 0)
  error_die("bind");
```

###### bind函数介绍

```c
#include <sys/types.h>
#include <sys/socket.h>    
int bind(int socket, const struct sockaddr* my_addr, socklen_t addrlen);
```

bind将my_addr所指的socket地址分配给未命名的sockfd文件描述符，addrlen参数指出该socket地址的长度。 调用成功返回0, 失败返回-1,并设置errno。

---

##### getsockname和getpeername函数

getsockname函数用于获取与某个套接字关联的本地协议地址 
getpeername函数用于获取与某个套接字关联的外地协议地址

```c
#include<sys/socket.h>
int getsockname(int sockfd, struct sockaddr *localaddr, socklen_t *addrlen);
int getpeername(int sockfd, struct sockaddr *peeraddr, socklen_t *addrlen);
```

对于这两个函数，如果函数调用成功，则返回0，如果调用出错，则返回-1。

使用这两个函数，我们可以通过套接字描述符来获取自己的IP地址和连接对端的IP地址，如在未调用bind函数的TCP客户端程序上，可以通过调用getsockname()函数获取由内核赋予该连接的本地IP地址和本地端口号，还可以在TCP的服务器端accept成功后，通过getpeername()函数来获取当前连接的客户端的IP地址和端口号。

---

##### 使用listen函数监听指定端口

```c
#include<sys/socket.h>
int listen(int sockfd, int backlog)
```

第一个参数即为sock文件描述符，第二个参数存在争议：

有关于第二个参数含义的问题网上有好几种说法，我总结了下主要有这么3种：

1. Kernel会为`LISTEN状态`的socket维护**一个队列**，其中存放`SYN RECEIVED`和`ESTABLISHED`状态的套接字，`backlog`就是这个队列的大小。
2. Kernel会为`LISTEN状态`的socket维护**两个队列**，一个是`SYN RECEIVED`状态，另一个是`ESTABLISHED`状态，而`backlog`就是这两个队列的大小之和。
3. 第三种和第二种模型一样，但是`backlog`是队列`ESTABLISHED`的长度。

有关上面说的两个状态`SYN RECEIVED`状态和`ESTABLISHED`状态，是`TCP三次握手`过程中的状态转化，具体可以参考下面的图（在新窗口打开图片）：  

![](/home/likewise-open/SENSETIME/zhangshuo/Desktop/0628/tinyhttpd学习过程.assets/三次握手协议讲解.png)

现在采用的多事backlog指已建立的连接的数量。

sockfd参数指定被 监听的socket。

backlog参数提示内核监听队列的最大长度。如果监听队列的长度超过backlog，服务器将不受理新的客户连接，客户端也将收到ECONNREFUSED错误信息。在内核版本2.2之前，backlog是指所有处于半连接状态（SYN_RCVD）和完全连接状态（ESTABLISHED）的socket上限。但在内核版本2.2以后，   它只表示处于完全连接状态的socket上限，处于半连接状态的socket上限则由/proc/sys/net/ipv4/tcp_max_syn_backlog内核参数定义。

backlog参数的典型值为5

调用成功时返为0, 失败时为-1, 并设置errno

详细讲解见网址 [backlog讲解](URL'http://localhost:38964/')

![](/home/likewise-open/SENSETIME/zhangshuo/Desktop/0628/tinyhttpd学习过程.assets/服务器监听后的状态.png)

----

##### accept 函数讲解

```c
client_sock = accept(server_sock,
                     (struct sockaddr *)&client_name,
                     &client_name_len);
```

serversock 即为startup之后返回的socket文件符。

sockfd是由socket函数返回的套接字描述符，参数addr和addrlen用来返回已连接的对端进程（客户端）的协议地址。**如果我们对客户端的协议地址不感兴趣，可以把arrd和addrlen均置为空指针**

如果accept成功，那么其返回值是由内核自动生成的一个**全新描述符**，代表与客户端的TCP连接。一个服务器通常仅仅创建`一个监听套接字`，它在该服务器生命周期内一直存在。内核为`每个由服务器进程接受的客户端连接创建一个已连接套接字`。当服务器完成对某个给定的客户端的服务器时，相应的已连接套接字就被关闭。

函数原型

```c
#include <sys/types.h>
#include <sys/socket.h>
int accept(int sockfd, struct sockaddr* addr, socklen_t *addrlen);
```

addr参数用来获取被接受连接的远端socket地址，该地址的长度由addrlen参数指出。

调用成功时返回一个新的连接socket，该socket唯一标识了被接受的这个连接，服务器可通过读写该socket来与客户端通信; 失败时返回-1,并设置errno



---

#### pthread_create 用法

调用方法

```c
if (pthread_create(&newthread , NULL, accept_request, (void *)&client_sock) != 0)
   perror("pthread_create");
```

建立多线程来执行`accept_request`函数。运行参数传入的socket文件符为空指针的形式。





```c
#include <pthread.h>
int pthread_create(pthread_t *restrict tidp,const pthread_attr_t *restrict attr,
                   void *(*start_rtn)(void),void *restrict arg);
```

C99 中新增加了 restrict 修饰的指针： 由  restrict修饰的指针是最初唯一对指针所指向的对象进行存取的方法，仅当第二个指针基于第一个时，才能对对象进行存取。对对象的存取都限定于基于由restrict  修饰的指针表达式中。 由 restrict 修饰的指针主要用于函数形参，或指向由 malloc()分配的内存空间。restrict  数据类型不改变程序的语义。 编译器能通过作出 restrict修饰的指针是存取对象的唯一方法的假设，更好地优化某些类型的例程。

第一个参数为指向线程标识符的指针。
第二个参数用来设置线程属性。
第三个参数是线程运行函数的起始地址。
最后一个参数是运行函数的参数。

---

## 调用指针函数accept_request

#### 指针函数与函数指针的区别

注意指针函数与函数指针表示方法的不同，千万不要混淆。最简单的辨别方式就是看函数名前面的指针*号有没有被括号（）包含，如果被包含就是函数指针，反之则是指针函数。

`指针函数`为返回指为变量地址的函数，即指针的值，`函数指针`为一个指向函数的指针变量。

##### getline函数

使用getline函数从socket中读取一行内容

```c
numchars = get_line(client, buf, sizeof(buf));
```

---

调用了socket中`recv`函数，因此简单整理`recv`和`send`函数。

###### recv和send函数

```c
int send( SOCKET s, const char FAR *buf, int len, int flags );  
```

不论是客户还是服务器应用程序都用send函数来向TCP连接的另一端发送数据。客户程序一般用send函数向服务器发送请求，而服务器则通常用send函数来向客户程序发送应答。

该函数的第一个参数指定**发送端套接字描述符**；第二个参数指明一个存放应用程序要**发送数据的缓冲区**；第三个参数指明实际要发送的**数据的字节数**；第四个参数一般置0。这里只描述同步Socket的send函数的执行流程。当调用该函数时，（1）send先比较待发送数据的长度len和套接字s的发送缓冲的长度， 如果len大于s的发送缓冲区的长度，该函数返回SOCKET_ERROR；（2）如果len小于或者等于s的发送缓冲区的长度，那么send先检查协议是否正在发送s的发送缓冲中的数据，如果是就等待协议把数据发送完，如果协议还没有开始发送s的发送缓冲中的数据或者s的发送缓冲中没有数据，那么send就比较s的发送缓冲区的剩余空间和len（3）如果len大于剩余空间大小，send就一直等待协议把s的发送缓冲中的数据发送完（4）如果len小于剩余 空间大小，send就仅仅把buf中的数据copy到剩余空间里（**注意并不是send把s的发送缓冲中的数据传到连接的另一端的，而是协议传的，send仅仅是把buf中的数据copy到s的发送缓冲区的剩余空间里**）。

如果send函数copy数据成功，就返回实际copy的字节数，如果send在copy数据时出现错误，那么send就返回SOCKET_ERROR；如果send在等待协议传送数据时网络断开的话，那么send函数也返回SOCKET_ERROR。

要注意send函数把buf中的数据成功copy到s的发送缓冲的剩余空间里后它就返回了，但是此时这些数据并不一定马上被传到连接的另一端。如果协议在后续的传送过程中出现网络错误的话，那么下一个Socket函数就会返回SOCKET_ERROR。（每一个除send外的Socket函数在执行的最开始总要先等待套接字的发送缓冲中的数据被协议传送完毕才能继续，如果在等待时出现网络错误，那么该Socket函数就返回 SOCKET_ERROR）

注意：在Unix系统下，如果send在等待协议传送数据时网络断开的话，调用send的进程会接收到一个SIGPIPE信号，进程对该信号的默认处理是进程终止。

通过测试发现，异步socket的send函数在网络刚刚断开时还能发送返回相应的字节数，同时使用select检测也是可写的，但是过几秒钟之后，再send就会出错了，返回-1。select也不能检测出可写了。

```c
int recv( SOCKET s, char FAR *buf, int len, int flags);  
```

不论是客户还是服务器应用程序都用recv函数从TCP连接的另一端接收数据。该函数的第一个参数指定**接收端套接字描述符**；第二个参数指明**一个缓冲区**，该缓冲区用来存放recv函数接收到的数据；第三个参数指明**buf的长度**；    第四个参数一般置0。

这里只描述同步Socket的recv函数的执行流程。当应用程序调用recv函数时，（1）recv**先等待s的发送缓冲中的数据被协议传送完毕**，如果协议在传送s的发送缓冲中的数据时出现网络错误，那么recv函数返回SOCKET_ERROR，（2）如果s的发送缓冲中没有数据或者数据被协议成功发送完毕后，recv**先检查套接字s的接收缓冲区**，如果s接收缓冲区中没有数据或者协议正在接收数据，那么recv就一直等待，直到协议把数据接收完毕。当协议把数据接收完毕，recv函数就把s的接收缓冲中的数据copy到buf中（**注意协议接收到的数据可能大于buf的长度，所以 在这种情况下要调用几次recv函数才能把s的接收缓冲中的数据copy完。recv函数仅仅是copy数据，真正的接收数据是协议来完成的**）， recv函数返回其实际copy的字节数。如果recv在copy时出错，那么它返回SOCKET_ERROR；如果recv函数在等待协议接收数据时网络中断了，那么它返回0。

注意：在Unix系统下，如果recv函数在等待协议接收数据时网络断开了，那么调用recv的进程会接收到一个SIGPIPE信号，进程对该信号的默认处理是进程终止。

---

此处buf的长度为1，即为逐字节的方式进行读取。

通过第一次的行读取，拿到http中的method方法。判断是get方法还是post方法。

如果都不是，调用unimplemented函数，即向发送端发送相关说明。

对于post方法，需要调用cgi文件对传入表单进行处理。

对于get方法，在读取第二项URL时需要对URL中的内容进行解析处理。

---

这里涉及到URL中的一些特殊字符的含义和处理方式。

##### ？问号的作用

```http
http://www.xxx.com/Show.asp?id=77&nameid=2905210001&page=1
```

在这样的链接中，问号的含义不是上面文章中所提到的版本号问题，而是传递参数的作用。这个问号将show.asp文件和后面的id、nameid、page等连接起来。

除此之外，链接中的问号还有一个作用，就是清除缓存的作用。  比如这样的链接：  

```http
http://www.xxxxx.com/index.html 和 http://www.xxxxx.com/index.html?test123123
```

第一个链接和第二个链接虽然打开的是同一个首页文件，但效果可能会不相同。   因为后面的链接中带有问号，后面还添加了一些字符，浏览器就会认为这是一个新的地址，而不是读取原来的那个index.html文件在电脑中的缓存。   与其说这个功能是清除缓存，不如说是让旧地址变成新地址更恰当。正因为加了问号，浏览器认为它是一个新地址，就会重新读取。

---

那么在对get请求作回应时，如果URL中有？存在，那么URL中会有参数传入，因此需要使用cgi文件对相应的输入做出对应的处理。

利用stat函数判断所请求的网页是否存在。

###### stat函数

```c
#include <sys/stat.h>
#include <unistd.h>
int stat(const char *file_name, struct stat *buf);
```

函数说明:    通过文件名filename获取文件信息，并保存在buf所指的结构体stat中返回值: 执行成功则返回0，失败返回-1，错误代码存于errno

如果发现所请求的文件不存在，那么将recv的buf中剩余的文件头全部取出后，调用not_found函数报告文件缺失的异常。

进一步通过stat结构体的数据进行判断，若是url指向的最终文件为目录，那么在最后添加index.html的文件，如果为可执行文件，那么将会调用有关的cgi文件。

#### server_file函数

首先将http请求剩余内容从recv的buf换从中拿掉清除。

之后打开请求的文件，调用headers函数，发送相应的文件头。

再调用cat函数，使用fgets函数逐行读取文件内容。

```c
char *fgets(char *buf, int bufsize, FILE *stream);
```

#### execute_cgi函数

同样对文件头进行处理，如果是POST请求，那么将会读取content-length的长度。

所采用的函数为

```c
 if (pipe(cgi_output) < 0) {
  cannot_execute(client);
  return;
 }
 if (pipe(cgi_input) < 0) {
  cannot_execute(client);
  return;
 }
```

采用pipe函数进行系统调用

```c
#include<unistd.h>
int  pipe(int fd[2]);
```

功能： 创建一个简单的管道，若成功则为数组fd分配两个文件描述符，其中fd[0] 用于读取管道，fd[1]用于写入管道。 返回：成功返回0，失败返回-1；

管道，顾名思义，当我们希望将两个进程的数据连接起来的时候就可以使用它，从而将一个进程的输出数据作为另一个进程的输入数据达到通信交流的目的。但值得我们注意的是：管道它有自身的特点。（1）管道通信是单向的，并且遵守先进先出的原则，即先写入的数据先读出。（2）管道是一个无结构，无固定大小的字节流。（3） 管道把一个进程的标准输出和另一个进程的标准输入连接在一起。数据读出后就意味着从管道中移走了，消失了。其它的进程都不能再读到这些数据。就像我们平常见到的管子水流走了就没有了。 这点很重要！！（4） pipe这种管道用于两个有亲缘关系的进程之间。eg:父子进程......

---

##### 文件描述符简单讲解

一个进程在此存在期间，会有一些文件被打开，从而会返回一些文件描述符，从shell中运行一个进程，默认会有3个文件描述符存在(0、１、2)，0与进程的标准输入相关联，１与进程的标准输出相关联，2与进程的标准错误输出相关联，一个进程当前有哪些打开的文件描述符可以通过/proc/进程ID/fd目录查看。　

![](/home/likewise-open/SENSETIME/zhangshuo/Desktop/0628/tinyhttpd学习过程.assets/文件描述符.jpeg)

文件表中包含：文件状态标志、当前文件偏移量、v节点指针，这些不是本文讨论的重点，我们只需要知道**每个打开的文件描述符(fd标志)在进程表中都有自己的文件表项**，由文件指针指向。

###### dup 和 dup2 函数

```c
#include <unistd.h>
int dup(int oldfd);
int dup2(int oldfd, int newfd);
```

复制一个现存的文件描述符

当调用dup函数时，内核在进程中创建一个新的文件描述符，此描述符是当前可用文件描述符的最小数值，这个文件描述符指向oldfd所拥有的文件表项。   dup2和dup的区别就是可以用newfd参数指定新描述符的数值，如果newfd已经打开，则先将其关闭。如果newfd等于oldfd，则dup2返回newfd, 而不关闭它。dup2函数返回的新文件描述符同样与参数oldfd共享同一文件表项。   APUE用另外一个种方法说明了这个问题：   实际上，调用dup(oldfd)等效于，`fcntl(oldfd, F_DUPFD, 0)`   而调用dup2(oldfd, newfd)等效于，`close(oldfd)；fcntl(oldfd, F_DUPFD, newfd)；`

----

###### cgi中的dup2

写过CGI程序的人都清楚，当浏览器使用post方法提交表单数据时，CGI读数据是从标准输入stdin，写数据是写到标准输出stdout(C语言利用printf函数)。按照我们正常的理解，printf的输出应该在终端显示，原来CGI程序使用dup2函数将STDOUT_FINLENO(这个宏在unitstd.h定义，为１)这个文件描述符重定向到了连接套接字：dup2(connfd, STDOUT_FILENO)。   如第一节所说，一个进程默认的文件描述符１(STDOUT_FILENO)是和标准输出stdout相关联的，对于内核而言，所有打开的文件都通过文件描述符引用，而内核并不知道流的存在(比如stdin、stdout)，所以printf函数输出到stdout的数据最后都写到了文件描述符１里面。至于文件描述符0、１、2与标准输入、标准输出、标准错误输出相关联，这只是shell以及很多应用程序的惯例，而与内核无关。   用下面的流图可以说明问题(ps: 虽然不是流图关系，但是还是有助于理解)：   printf －> stdout －> STDOUT_FILENO(1) －> 终端(tty)   printf最后的输出到了终端设备，文件描述符１指向当前的终端可以这么理解：   STDOUT_FILENO = open(“/dev/tty”, O_RDWR);   使用dup2之后STDOUT_FILENO不再指向终端设备，而是指向connfd, 所以printf的输出最后写到了connfd。是不是很优美？

----

采用pipe获得文件符后利用dup2进行重定向输出和输入。

之后根据具体请求的不同，GET或POST来改变环境变量。采用putenv函数。

管道状态的先后变化如下图所示：	

![](/home/likewise-open/SENSETIME/zhangshuo/Desktop/0628/tinyhttpd学习过程.assets/管道初始状态.png)











