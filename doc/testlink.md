# xampp
* 下载与安装xampp
    * 注意事项
    1. xampp的权限问题
    <br> Windows的Program Files有特殊权限，会限止web的程序一些功能
    2. 选择的功能模块
* 安装后的基本测试
    1. 测试http功能可以使用
    2. 测试php功能
    3. 测试mysql功能
    * 测试方法
        1. 点击apache的 admin 按钮
        <br>显示dashboard则表示http服务器成功
        2. 点击mysql的 admin 按钮
        <br>显示phpMyadmin则表示php和mysql安装成功
* 安装后的额外配置
    1. Apache的config按钮php.ini里找到error_log
    <br>检查发现安装目录下的php\logs目录未创建，新建目录logs
    2. phpmyadmin里装language语言项改为中文

# testlink
* 下载与安装testlink
    * 注意事项
    1. testlink的文件夹名
    2. 新建testlink的用户用来创建testlink的数据库，以保护数据安全
* 数据库设置
    1. phpmyadmin里找到账户项
    2. 新建用户，用户名这testlink
    3. 选择“创建与用户名同名的数据库”
    4. 点击执行
* 修改testlink的设置
    * 修改htdocs/testlink/config.inc.php文件
    * 找到unix example字样的关键行
    * 进行文件夹名替换，这涉及不同操作系统的目录访问
    * 注意事项
    1. **\\\\** 与 **\\** 之间的区别，很多语言里 **\\** 是转义
    2. php语言的行尾以 ***;*** 结束
* 使用默认来安装testlink
    * 访问localhost/testlink
    * 点击New installation
    * 点击check box，点击continue
    * 点击continue
    * Testlink DB Login用刚创建的testlink用户与密码
    <br>Database admin login使用root用户与密码
    * 使用testlink_create_udf0.sql来定义mysql的函数
        1. 打开testlink_create_udf0.sql文件
        2. 打开phpmyadmin
        3. 进入testlink数据库
        4. 点击SQL
        5. 将刚才的testlink_create_udf0.sql文件内容粘贴到SQL面板
        * 注意事项
        * sql语句里替换YOUR_TL_DBNAME删除
        <br>因为已经进入了该数据库，所以不用再进入了
        6. 点击执行
    * 访问localhost/testlink可以进入testlink
    * 删除testlink的install目录

