#!/bin/bash
exec > >(tee -a /usr/local/osmosix/logs/service.log) 2>&1
echo "Executing acpnodecentos7 service script.."
. /usr/local/cliqr/etc/userenv
# main entry
case
$1 in
    install)
            echo "Installing dependencies"
            yum -y install wget libcgroup cifs-utils nano openssh-clients libcgroup-tools unzip iptables-services net-tools
            service cgconfig start
            echo "root:${rootPass}" | chpasswd
            echo "Updating domain info in resolv.conf"
            cat > /etc/resolv.conf << EOF
            nameserver ${dcip}
            search ${domainName}.${domainSuf}
            domain ${domainName}.${domainSuf}
            EOF
            chattr +i /etc/resolv.conf
            echo "Updating hosts file"
            x=$(hostname -I)
            eval ipval=($x)
            ip=${ipval[0]}
            echo "$ip ${serverName}" >> /etc/hosts
            hostnamectl set-hostname ${serverName}
            echo "Updating sshd to allow root login via ssh"
            sed -i 's/#\?\(RSAAuthentication\s*\).*$/\1 yes/' /etc/ssh/sshd_config
            echo "Creating repo mounts"
            mkdir -p /apprenda/repo/apps
            mkdir -p /apprenda/repo/sys
            mkdir -p /apprenda/docker-binds
            chmod -R 777 /apprenda/docker-binds
            echo "//${repo}/Applications /apprenda/repo/apps cifs username=${platformadmin},password=${platformadminpass} 0 0" >> /etc/fstab
            echo "//${repo}/Apprenda /apprenda/repo/sys cifs username=${platformadmin},password=${platformadminpass} 0 0" >> /etc/fstab
            echo "//${repo}/Binds /apprenda/docker-binds cifs username=${platformadmin},password=${platformadminpass},file_mode=0777,dir_mode=0777,noperm 0 0" >> /etc/fstab
            mount -a
            service iptables stop
            cd /apprenda/repo/sys/${ver}/System/Nodes/RPM
            ls | grep -v rhel6 | xargs yum -y localinstall
            /apprenda/apprenda-updater/bin/configure-node.sh -a /apprenda/repo/apps -s /apprenda/repo/sys -h ${serverName} -o /tmp/output.log -c http://${acpurl}
            service iptables start
        ;;
    deploy)
        ;;
    configure)
        ;;
    start)
                  systemctl start apprenda
                  ;;
    stop)
                  systemctl stop apprenda
                  ;;
    restart)
                  systemctl restart apprenda
                  ;;
    cleanup)
        ;;
    reload)
        ;;
    upgrade)
        ;;
    *)
                  exit 127
                  ;;
esac