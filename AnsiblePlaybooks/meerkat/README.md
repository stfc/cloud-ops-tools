# Meerkat Benchmarking
This is the Meerkat benchmarking tool, which uses Ansible to spin up VMs in Openstack, run a benchmark on them and shut those VMs down.

Currently Meerkat has the following benchmarks available:
- HEPScore, a CPU benchmark
- A custom storage benchmark (to be added)

## Running Meerkat
Meerkat can be run from this directory with the command:

`ansible-playbook meerkat.yaml`

With the extra vars:
- `victoria_url`
    - The URL of a VictoriaMetrics instance for benchmarks to send their results to
- `harbor_username` and `harbor_password`
    - Harbor credentials to pull the HEPScore container
- `key_name`
    - The name of the Openstack key name used to access newly created VMs
- `openstack_username`
    - The name of the user to log into VMs as

It may also be necessary to set the environment variable `ANSIBLE_HOST_KEY_CHECKING` to False. This prevents an interactive prompt appearing for every VM to verify the host key.