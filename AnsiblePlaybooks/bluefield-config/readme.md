A playbook for the automatic configuration of the Bluefield BMC interface amongst other networking.

Should be run with the following variables in mind:
ansible-playbook config.yml -e '{"IP":"<IPHERE>", "MAC":"<MACHERE>", "PASSWORD":"<PASSHERE>", "FIRSTSTART":true, "NETMASK":"<NETMASKHERE>", "GATEWAY":"<GATEWAYHERE>", "NTPSERV":"<NTPSERVHERE>", "INTERFACE":"eth0"}'


Still need to:
DNSMasq?
