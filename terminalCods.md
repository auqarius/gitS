
# 打开xcode的插件目录
alias xcp="open /Users/Aquarius/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins"
# 安装cocoapod
alias podsetup="mkdir -p ~/.cocoapods/repos &>/dev/null;git clone --depth=1 https://git.oschina.net/lexrus/specs.git $HOME/.cocoapods/repos/master 2>/dev/null; git -C ~/.cocoapods/repos/master/ remote set-url origin https://github.com/CocoaPods/Specs.git"
# 同步cocoapod
alias podsync="git -C ~/.cocoapods/repos/master/ remote set-url origin https://git.oschina.net/lexrus/specs.git;/usr/bin/env pod repo update;git -C ~/.cocoapods/repos/master/ remote set-url origin https://github.com/CocoaPods/Specs.git"
# 安装pods到项目
alias podinstall="pod install --no-repo-update"
# 更新pods到项目
alias podupdate="pod update --no-repo-update"
# 打开当前目录下的workspace/xcodeprj
alias ox="open ./*.xcworkspace 2>/dev/null || open ./*.xcodeproj 2>/dev/null"
# 清理xcode缓存
alias ded="rm -rf $HOME/Library/Developer/Xcode/DerivedData"
# 在当前目录开一个web服务
alias www="twistd -onl - --pidfile=/tmp/twistd.pid web --path=./ --port=8000;"
# 打开xcode
/Applications/Xcode.app/Contents/MacOS/Xcode </dev/null &>/dev/null &
如果你使用了 fish 那么后面的一段可以不要:
/Applications/Xcode.app/Contents/MacOS/Xcode

# CocoaPods 安装有问题
$ mkdir -p $HOME/Software/ruby
$ export GEM_HOME=$HOME/Software/ruby
$ gem install cocoapods
[...]
1 gem installed
$ export PATH=$PATH:$HOME/Sofware/ruby/bin
$ pod --version
0.37.2