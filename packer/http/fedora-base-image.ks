text

lang en_US.UTF-8
keyboard de
timezone Europe/Berlin --isUtc
selinux --disabled

skipx
rootpw --lock --iscrypted locked
 
firewall --disabled

network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,cloud-init,cloud-init-local,cloud-config,cloud-final,dnsmasq,qemu-guest-agent --disabled=systemd-resolved
 
zerombr
clearpart --all
autopart --noboot --nohome --noswap --nolvm

repo --name=rawhide --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=rawhide&arch=$basearch
url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=rawhide&arch=$basearch

shutdown

bootloader --timeout=1 --append="no_timer_check console=tty1 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 systemd.unified_cgroup_hierarchy=0"

%packages
kernel-core
@^cloud-server-environment
systemd-udev
which
nfs-utils
libnfs-utils
portmap
wget
vim
haproxy
openssh-clients
unzip
which
dnf-yum
rsync
qemu-guest-agent
fuse-sshfs
docker
bind-utils
dnsmasq
-dracut-config-rescue
-biosdevname
-iprutils
-uboot-tools
-kernel
-plymouth
%end

%post --erroronfail --interpreter=/bin/bash
{ 
echo -n "Setting default runlevel to multiuser text mode"
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .
 
echo "Removing linux-firmware package."
rpm -e linux-firmware
 
echo "Removing firewalld."
#dnf -C -y erase "firewalld*"
 
# Another one needed at install time but not after that, and it pulls
# in some unneeded deps (like, newt and slang)
echo "Removing authconfig."
dnf -C -y erase authconfig
# instlang hack. (Note! See bug referenced above package list)
find /usr/share/locale -mindepth  1 -maxdepth 1 -type d -not -name en_US -exec rm -rf {} +
localedef --list-archive | grep -v ^en_US | xargs localedef --delete-from-archive
# this will kill a live system (since it's memory mapped) but should be safe offline
mv -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
build-locale-archive
echo '%_install_langs C:en:en_US:en_US.UTF-8' >> /etc/rpm/macros.image-language-conf
 
echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf
 
echo -n "Network fixes"
# initscripts don't like this file to be missing.
# and https://bugzilla.redhat.com/show_bug.cgi?id=1204612
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
DEVTIMEOUT=10
EOF
 
# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF
 
# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
 
EOF
echo .

echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount
 
# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot
 
echo "Removing random-seed so it's not the same in every image."
rm -f /var/lib/systemd/random-seed
 
echo "Cleaning old dnf repodata."
dnf clean all
truncate -c -s 0 /var/log/dnf.log
truncate -c -s 0 /var/log/dnf.rpm.log

echo "Import RPM GPG key"
releasever=$(rpm --eval '%{fedora}')
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
 
# that don't support selinux will give us errors
# /usr/sbin/fixfiles -R -a restore || true
 
echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
rm -f /var/tmp/zeros
echo "(Don't worry -- that out-of-space error was expected.)"
 
# When we build the image with oz, dracut is used
# and sets up a ifcfg-en<whatever> for the device. We don't
# want to use this, we use eth0 so it is always the same.
# So we remove all these ifcfg-en<whatever> devices so
# The 'network' service can come up cleanly.
rm -f /etc/sysconfig/network-scripts/ifcfg-en*
 
/sbin/chkconfig network on
 
# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

useradd hcops
usermod -G docker -a hcops

curl http://192.168.0.171:8088/workspace/cookbook/packer/kvm-libvirt-fedora-hc-products/scripts/consul-install.sh -o /tmp/consul-install.sh
curl http://192.168.0.171:8088/workspace/cookbook/packer/kvm-libvirt-fedora-hc-products/scripts/vault-install.sh -o /tmp/vault-install.sh
curl http://192.168.0.171:8088/workspace/cookbook/packer/kvm-libvirt-fedora-hc-products/scripts/nomad-install.sh -o /tmp/nomad-install.sh

bash /tmp/vault-install.sh
bash /tmp/consul-install.sh
bash /tmp/nomad-install.sh

wget https://raw.githubusercontent.com/alacritty/alacritty/master/extra/alacritty.info
sudo tic -xe alacritty,alacritty-direct alacritty.info

cat > /etc/dnsmasq.d/consul-dns.conf << EOF
server=/consul/127.0.0.1#8600
server=192.168.0.171

listen-address=127.0.0.1

no-resolv
no-poll
EOF

cat > /etc/NetworkManager/NetworkManager.conf << EOF
[main]
plugins = ifcfg-rh,
dns=none
EOF

# Anaconda is writing an /etc/resolv.conf from the install environment.
# The system should start out with an empty file.
truncate -s 0 /etc/resolv.conf

cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
EOF

echo "Cleaning history"
history -c

} 2>&1 | tee /root/postinstall.log > /dev/tty3
%end
