#!/bin/bash

# Check if firewalld is running
if systemctl is-active --quiet firewalld.service; then
    # Open ports for mail traffic
    firewall-cmd --add-port=25/tcp --permanent
    firewall-cmd --add-port=587/tcp --permanent
    firewall-cmd --add-port=465/tcp --permanent

    # Reload FirewallD service
    systemctl reload firewalld

# Check if UFW is running
elif ufw status | grep -q 'Status: active'; then
    # Open ports for mail traffic
    ufw allow 25/tcp
    ufw allow 587/tcp
    ufw allow 465/tcp

    # Reload UFW service
    systemctl reload ufw

# Check if IPTABLES service is running
elif systemctl is-active --quiet iptables.service; then
    # Open ports for mail traffic
    iptables -A INPUT -p tcp --dport 25 -j ACCEPT
    iptables -A INPUT -p tcp --dport 587 -j ACCEPT
    iptables -A INPUT -p tcp --dport 465 -j ACCEPT

    # Save IPTABLES rules
    service iptables save

# If no running firewall service is found, start and enable firewalld
else
    # Start and enable Firewalld
    systemctl start firewalld
    systemctl enable firewalld

    # Open ports for mail traffic
    firewall-cmd --add-port=25/tcp --permanent
    firewall-cmd --add-port=587/tcp --permanent
    firewall-cmd --add-port=465/tcp --permanent

    # Reload FirewallD service
    systemctl reload firewalld
fi

exit 0
