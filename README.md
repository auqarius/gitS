# gitSkills List

## OverView

**This is my git learn command list.**

* $ git init // cd到需要git的目录，然后init，就可以把这个目录变成git可以管理的仓库。
* $ git add README.md // 把工作区修改过的README.me文件提交到暂存区
* $ git commit -m "description" // 把暂存区的改动提交到本地仓库
* $ git status //查看git状态，是不是有没有提交的
* $ git diff README.md // 查看README.md 文件被修改了什么
* $ git log // 查看提交历史
* $ git log --pretty=oneline // 查看简化提交历史
* $ git reset --hard HEAD^ // 回退到上一个版本,HEAD指的是这个版本，^指上一个，^^指上上一个
* $ git reset --hard 36d2s3 // 回退到某个特定的版本
* $ git reflog // 输入git历史命令
* $ git checkout -- README.md // 让文件回到最近一次git commit 或git add 的状态
* $ git reset HEAD README.md // 把暂存区的修改退回到工作区，相当于撤销git add
* $ git rm README.md // 删除某个文件，类似add只是提交到缓存区了一个修改而已，要保存到版本库中还要git commit,如果不小心误删，使用 git checkout README.md就可以。
* $ ssh-keygen -t rsa -C "410592634@qq.com" // 添加ssh,id_rsa私钥，不能泄漏，id_rsa.pub公钥
* $ git remote add origin https://github.com/auqarius/gitS.git // 添加远程仓库
* $ git push -u origin master // 将本地库的内容推送到远程库的master库, 并且将远程库的master分支和本地库的master分支关联起来
* $ git push origin master // 直接提交master到远程库(必须关联后)
* $ git clone https://github.com/auqarius/gitS.git // 从远程仓库克隆内容
* $ git checkout -b dev // 创建并切换到dev分支
* $ git branch dev // 创建dev分支
* $ git checkout dev // 切换到dev分支
* $ git branch // 查看分支
* $ git merge dev // 将dev分支的内容合并到当前分支上(Fast Forward模式，删除分支后，会丢掉分支信息)
* $ git merge --no-ff -m "merge with no-ff" dev // 将dev分支的内容合并到当前分支上(非 Fsat Forward 模式)
* $ git branch -d dev // 删除dev分支
* $ git log --garph --prett=oneline --abbrev-commit // 以图形模式显示提交历史和分支合并情况
* `一般每个人有自己的分支，例如 branch KralLee, 然后dev分支是大家合并的分支，属于不稳定的开发版本，而master上的一定是用来发布的分支。`
* $ git stash // 存储工作现场，这个时候可以切换任何分支进行修改，然后提交，一般在bug修改的时候用
* $ git stash list // 查看目前存在的工作暂存工作现场
* $ git stash apply stash@{0} // 恢复到某一个现场，必须在所对应的分支上
* $ git stash pop // 删除工作现场
* $ git branch -D feature-co // 强制删除某个分支`在开发时可能在某个分支遇到某些内容被取消了，然后我们开发好的东西也得删除的时候，如果不合并，是没有办法删除的，只有强制删除，然后就内容分支一起删。`
* $ git remote // 查看远程库信息
* $ git remote -v // 显示更详细的远程库信息
* $ git push origin dev // 推送dev分支到远程库
* $ git checkout -b dev origin/dev // 将远程的dev分支创建到本地
* $ git pull // 拉取当前分支的内容
* $ git branch --set-upstream dev origin/dev // 将本地的dev分支和远程的dev分支联系起来
* $ git tag v1.0 // 给当前分支的最新一次提交打上标签
* $ git tag v1.0 325dw2 // 给当前分支的某一次提交打上标签
* $ git tag // 查看标签
* $ git show v1.0 // 查看某一个标签
* $ git tag -a v1.0 -m "version 1.0 released" 231532 // 给tag加说明文字
* $ git tag -d v1.0 // 删除标签
* $ git push origin v1.0 // 将标签推送到远程库
* $ git push origin --tags // 推送所有标签到远程库
* $ git oush origin :refs/tags/v1.0 // 在远程库删除tag，但是得要在本地库线删除
* git config --global alias.st status // 将git status 命令替换为git st
* git config --global alias.last 'log -1' // 配置一个 git last 让其显示最后一次提交的信息
* git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" // 格式化log
* 