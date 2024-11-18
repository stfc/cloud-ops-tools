A playbook for the automatic configuration of the Bluefield BMC interface amongst other networking.

Should be run with the following variables in mind:
ansible-playbook config.yml -e '{"IP":"<IPHERE", "MAC":"<MACHERE>","PASSWORD":"<PASSHERE>","FIRSTSTART":true}'


Still need to:
Add interface to dhcp config
Get NTP config working
Get a working DHCP on start
DNSMasq?
