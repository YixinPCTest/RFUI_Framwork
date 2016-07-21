*** Settings ***
Suite Setup       DesktopApp测试准备
Suite Teardown    关闭Desktop远程服务器
Resource          ../PubResource-POM/元子页面关键字.txt
Library           SikuliLibrary

*** Test Cases ***
传文件到手机
    DesktopAPP登录页_登入易信DesktopAPP
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_传文件到手机
    DesktopAPP会话页_点击发送文件
    DesktopAPP计算机页_打开文件
    DesktopAPP会话页_点击发送按钮
    DesktopAPP会话页_关闭窗口
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_退出

我的收藏_转发给我的手机
    DesktopAPP登录页_登入易信DesktopAPP
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_我的收藏
    DesktopAPP收藏页_搜索    测试.txt
    DesktopAPP收藏页_确定转发
    DesktopAPP会话页_关闭窗口
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_退出
