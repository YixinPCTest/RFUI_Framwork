# coding=utf-8
"""A automatic CI script support multiple OS.
"""
import os
import re
import sys
import urllib
import urllib2
import shutil
import optparse
import platform
from time import ctime
from HTMLParser import HTMLParser


class MyParser(HTMLParser):
    """the main class
    """
    xunit = 'NULL'
    version = 'NULL'
    include = 'NULL'
    testcase = 'NULL'
    outputdir = 'NULL'

    dev_model = 'NULL'
    dev_os_version = 'NULL'
    dev_manufacturer = 'NULL'

    resault = 'NULL'
    pwd = "/your/script/workspace/path"

    def __init__(self):
        HTMLParser.__init__(self)
        self.options = self.parse_option()

    def parse_option(self):
        opt = optparse.OptionParser()
        opt.add_option('-i', '--include', metavar='tag',
                       help='Select the cases tOutput run by tags, Example: --include citest  --include P0')
        opt.add_option('-e', '--exclude', metavar='tag',
                       help='Select the cases tOutput not to run by tags, Example: --exclude noauto')
        opt.add_option('-d', '--outputdir', metavar='dir', default='./RFUI_outputs_dir',
                       help='directory to create output files,  (defalt: .\RFUI_outputs_dir)')
        opt.add_option('-x', '--xunit', metavar='FILE', default='xunitOutput.xml',
                       help='xUnit compatible result file,  (defalt: xunitOutput.xml)')
        options, arguments = opt.parse_args()
        return options

    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            for name, value in attrs:
                if name == 'href':
                    self.resault = value  # merged by the latest version info

    def getHtml(self, url):
        page = urllib.urlopen(url)
        html = page.read()
        return html

    def start_appium(self):
        # cmd = 'start /b appium'
        # cmd = 'nohup appium & '
        # cmd = 'echo `nohup /usr/local/bin/appium &` &'
        cmd = 'ps aux'
        print "-------%s-------" % ctime()
        print os.popen(cmd).read()

    def manage_output_dir(self):
        # output_dir = self.get_opt_content("--outputdir")
        output_dir = self.options.outputdir
        if os.path.exists(output_dir):
            try:
                shutil.rmtree(output_dir)
                os.mkdir(output_dir)
            except IOError, error:
                print IOError, ">>>", error
        else:
            try:
                os.makedirs(output_dir)
            except IOError, error:
                print IOError, ">>>", error

    def get_newest_apk(self):
        html = self.getHtml('http://10.240.129.99/nightly/')
        self.feed(html)  # -->def handle_starttag():
        print "-------%s-------" % ctime()
        apk_version = self.resault
        apk_version = apk_version.replace('/', '')
        print '>>>' + apk_version

        flip = open('test_dev_info.properties', 'w')
        flip.write('android_app_version=' + apk_version + '\n')
        flip.close()

        # remove old apk
        for item in os.listdir('./'):
            if os.path.splitext(item)[1] == ".apk":
                if item != (apk_version + ".apk"):
                    os.remove(item)

        if os.path.exists('./' + apk_version + '.apk'):
            print "the Apk already up-to-date\n"
        else:
            # download newest apk
            download_url = "http://10.240.129.99/nightly/" \
                           + apk_version + '/' + apk_version + ".apk"
            flip = urllib2.urlopen(download_url)
            self.pwd = sys.path[0]
            print self.pwd
            data = flip.read()
            filename = apk_version + ".apk"
            with open(filename, "wb") as code:
                code.write(data)
            print "Download Done!"

        # link newest apk to ./Res*/yixin_test.apk
        # Win:ln <src>  <des>  |  Mac/Linux: ln -s <src> <des>
        uname_str = platform.system()
        os_arch = re.search("Windows", uname_str)
        if os_arch:
            cmd = "copy /y  .\\" + apk_version + ".apk" \
                  + "   " + ".\\Resources\\yixin_test.apk"
            print os.popen(cmd).read()
        else:
            cmd = "cp -f ./" + apk_version + ".apk" \
                  + "   " + " ./YX_RFUI_Framework/Resources/yixin_test.apk"
            print os.popen(cmd).read()

    def get_device_info(self):
        """:return Motorola XT1080 4.4.4 ,etc.
        """
        cmd = "adb devices"
        dev_info = os.popen(cmd).read()
        if len(dev_info) > len('List of devices attached\n\n'):
            cmd = "adb shell cat /system/build.prop"
            dev_info = os.popen(cmd).read()
            tag = re.search(r"ro.product", dev_info)
            if tag:
                self.dev_manufacturer = re.search(r"(ro.product.manufacturer=)(\S+)", dev_info).group(2)
                self.dev_model = re.search(r"(ro.product.model=)(\S+)", dev_info).group(2)
                self.dev_os_version = re.search(r"(ro.build.version.release=)(\S+)", dev_info).group(2)
                print '>>>' + self.dev_manufacturer, self.dev_model, self.dev_os_version
                flip = open('test_dev_info.properties', 'a')
                flip.write('android_dev_name=' + self.dev_manufacturer + '\n')
                flip.write('android_dev_model=' + self.dev_model + '\n')
                flip.write('android_version=' + self.dev_os_version + '\n')
                flip.close()
            else:
                print "\n\n>>>[x]:No device connect!\n\n"
                sys.exit()
        else:
            print "\n\n>>>[x]:No device connect!\n\n"
            sys.exit()

    def get_gitbucket(self):
        """pull remote repo to current dir
        """
        cmd = "git clone https://git.hz.netease.com/git/yxplusQA/YX_RFUI_Framework_demo.git"
        print os.popen(cmd).read()

    def job_mac(self):
        """Mac's job
        """
        print "\n\n>>>here is from Mac\n\n"
        cmd = ' '.join(sys.argv[1:])
        cmd = 'pybot' + ' ' + cmd
        os.system(cmd)

    def job_windows(self):
        """Win's job
        """
        print "\n\n>>>here is from Windows\n\n"
        cmd = ' '.join(sys.argv[1:])
        cmd = r'C:\Python27\python -m robot.run' + ' ' + cmd
        os.system(cmd)

    def job_linux(self):
        """Linux's job
        """
        print "[info]:Linux fx() need added in future ;-)"

    def job_operate(self):
        """run corresponding job according to current OS system
        """
        uname_str = platform.system()
        if re.search("Darwin", uname_str):
            self.get_gitbucket()  # git clone *_demo
            self.job_mac()
        elif re.search("Windows", uname_str):
            self.job_windows()
        elif re.search("Linux", uname_str):
            self.get_gitbucket()  # git clone *_demo
            self.job_linux()
        else:
            print "[x]:can NOT detect OS type :-("


if __name__ == '__main__':
    parse = MyParser()
    parse.manage_output_dir()
    parse.get_newest_apk()
    parse.get_device_info()
    # parse.get_gitbucket()
    parse.job_operate()