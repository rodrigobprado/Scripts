#!/bin/bash

apt-get update
apt-get dist-upgrade -y 

###################
# Pacotes Básicos #
###################
apt-get install gnupg git locate python-pip fail2ban mcrypt mlocate inotify-tools telnet htop iptraf iftop tcpdump iptables \
vim ntp zip unzip byobu ssh postfix elinks mailutils sed chkrootkit rkhunter tzdata ntpdate sudo rsync apt-listchanges \
iotop nfs-common nload smartmontools -y 

echo "cron.*                          /var/log/cron.log"  >> /etc/rsyslog.conf
service rsyslog restart

###############################################
# Ajusta o Vim como editor padrão do servidor #
###############################################
update-alternatives --set editor /usr/bin/vim.basic

echo "
export HISTTIMEFORMAT=\"%d/%m/%y %T => \" 
HISTSIZE=10000000000000000
HISTFILESIZE=2000000000000000000000

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias agora='date \"+%Y-%m-%d-%H:%M:%S\"'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l='ls -CF'
alias la='ls -A'
alias lf='ls -lahFcips --full-time | awk '\''{k=0;for(i=0;i<=8;i++)k+=((substr($3,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\" %0o \",k);print}'\'''
alias lg='ls -l | grep --color=auto '
alias ll='ls -alF'
alias llm='ls -l | less'
alias lo='ls -lah --color | awk '\''{k=0;for(i=0;i<=8;i++)k+=((substr(\$1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(\" %0o \",k);print}'\'''
alias ls='ls --color=auto'
alias nocomment='grep -Ev '\''^(#|$|;)'\'''
alias psg='ps ax | grep -v grep | grep --color=auto  '
alias psram='ps aux | sort -rnk 4 | head'
alias ssh='ssh -X -C -v'
alias wtf='man' 

if [[ \${EUID} == 0 ]] ; then
                PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;31m\]\t | \u@\h |\[\033[01;34m\] \w \n\\$\[\033[00m\] '
       else
                PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\t | \u@\h |\[\033[01;34m\] \w \n\\$\[\033[00m\] '
       fi
" >> /etc/bash.bashrc

echo -e "\"#################################
\"# Confirugrações personalizadas #
\"#################################
set number
set bg=dark
set nocp
set smartcase
set showcmd
set showmatch
set ignorecase
set incsearch
set hidden
set nobomb
syntax on
" >> /etc/vim/vimrc

echo -e "/sbin/nologin
/bin/false
/usr/sbin/nologin " >> /etc/shells

#################################################
# Adiciona a senha nos usuários administrativos #
#################################################
touch /root/.bash_history
chattr +a /root/.bash_history

#######
# NTP #
#################################################
# Alterar a timezone para Hora legal Brasileira #
#################################################
rm /etc/localtime
ln -s /usr/share/zoneinfo/Brazil/East /etc/localtime
ntpdate -u pool.ntp.br

#########################################################################
# Configurar o crontab para atualizar a hora do sistema automaticamente #
#########################################################################
echo -e "
###########################
# Sincronizar data e hora #
###########################
0\t	*\t	*\t	*\t	*\t	root\t	/usr/sbin/ntpdate -u pool.ntp.br >/dev/null 2>&1" >> /etc/crontab

echo -e "
##########################
# Checagens de seguranca #
##########################
0\t	6\t	*\t	*\t	*\t	root\t	/usr/sbin/chkrootkit
15\t	6\t	*\t	*\t	*\t	root\t	/usr/bin/rkhunter -c --nocolors --update --versioncheck --skip-keypress

" >> /etc/crontab

echo -e "
##########
# Search #
##########
40\t	*\t	*\t	*\t	*\t	root\t	/usr/bin/updatedb

" >> /etc/crontab

echo -e "
##########
# Updates #
##########
55\t	*\t	*\t	*\t	*\t	root\t	/usr/bin/apt-get update >/dev/null 2>&1
0\t	*\t	*\t	*\t	*\t	root\t	/usr/bin/apt-get dist-upgrade -y >/dev/null 2>&1

" >> /etc/crontab

echo -e "
#############
# Montagens #
#############
40\t	*\t	*\t	*\t	*\t	root\t	/bin/mount -a  >/dev/null 2>&1
" >> /etc/crontab


#
# Permitir que apenas o root possa agendar tarefas
#
echo "root" >> /etc/cron.allow
echo "root" >> /etc/at.allow

#
# Configuração o SSHD
#

mv /etc/ssh/sshd_config /etc/ssh/sshd_config-original
echo -e '#
##############
# SSH Config #
##############
Port 2269

ListenAddress 0.0.0.0
ListenAddress ::

Protocol 2

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key

UsePrivilegeSeparation yes

KeyRegenerationInterval 3600
ServerKeyBits 16384

SyslogFacility AUTH
LogLevel INFO

LoginGraceTime 30

PermitRootLogin no

StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile     %h/.ssh/authorized_keys

IgnoreRhosts yes

RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication no

GatewayPorts yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes

AcceptEnv LANG LC_*

Subsystem sftp internal-sftp

UsePAM yes
UseDNS no

MaxStartups 3:50:6

AllowUsers deploy admin backup prado.rodrigo

Match group sftponly
     ChrootDirectory %h
     X11Forwarding no
     AllowTcpForwarding yes
     ForceCommand internal-sftp
' > /etc/ssh/sshd_config

groupadd sftponly

service ssh restart

echo -e "
##############################
# Monitor de espaço em disco #
##############################
*\t	*\t	*\t	*\t	*\t	root\t	/root/monitor-df.sh  >/dev/null 2>&1
" >> /etc/crontab

groupadd prado.rodrigo
useradd -g 0 -G 'prado.rodrigo' -c "Rodrigo Prado" -s /bin/bash deploy -d /home/prado.rodrigo
adduser prado.rodrigo sudo
mkdir -p /home/prado.rodrigo/.ssh
echo -e "ssh-rsa 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 rodrigo@DESKTOP-AEU45RK " > /home/prado.rodrigo/.ssh/authorized_keys
sed -i "s~^prado.rodrigo:[^:]\+:\(.\+\)$~prado.rodrigo:\$6\$g3XA7Dxf6JfuUIPS$sfZANIoNocyqrvNWB33ZbXDYCuCRertPXMXj30dRn\/ew0C1G9R2.KPHKaIEd8XRP0r6PV6\/1UL6.DqdB5OWWq." /etc/shadow

chmod 700 -R /home/prado.rodrigo/.ssh
chmod 400 /home/prado.rodrigo/.ssh/authorized_keys
chown -R prado.rodrigo:prado.rodrigo /home/prado.rodrigo/.ssh
chown -R prado.rodrigo:prado.rodrigo /home/prado.rodrigo/
chattr +i /home/prado.rodrigo/.ssh/authorized_keys
touch /home/prado.rodrigo/.bash_history
chattr +a /home/prado.rodrigo/.bash_history
