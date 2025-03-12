"""Format the raw data from the report shell script."""

from typing import Dict, List
from datetime import datetime
import yaml


date = datetime.now().strftime("%Y-%m-%d")


def main():
    """
    Format the raw data from the shell script.
    """
    hypervisor_list_raw = read_file(f"hypervisor_list_{date}.yaml")
    compute_service_list_raw = read_file(f"compute_service_list_{date}.yaml")
    floating_ip_list_raw = read_file(f"floating_ip_list_{date}.yaml")
    server_list_raw = read_file(f"server_list_{date}.yaml")

    hypervisor_list = _format_hypervisor_list(hypervisor_list_raw)
    enabled_hypervisor_list_hostnames = [
        hv["Host"] for hv in compute_service_list_raw if hv["Status"] == "enabled"
    ]

    cpu = _get_cpu(hypervisor_list, enabled_hypervisor_list_hostnames)
    memory = _get_memory(hypervisor_list, enabled_hypervisor_list_hostnames)
    storage = {
        "storage": {
            "sirius": {"in_use": 0.0, "total": 0.0, "nodes": 0},
            "deneb": {"in_use": 0.0, "total": 0.0},
            "arided": {"in_use": 0.0, "total": 0.0},
        }
    }
    hv = _get_hv(compute_service_list_raw, hypervisor_list)
    vm = _get_vm(server_list_raw)
    fip = _get_fip(floating_ip_list_raw)
    virtual_worker_nodes = _get_vwn(server_list_raw)

    with open(f"weekly-report-{date}.yaml", "w", encoding="utf-8") as file:
        yaml.dump(
            {**cpu, **memory, **storage, **hv, **vm, **fip, **virtual_worker_nodes},
            file,
        )


def _format_hypervisor_list(hypervisor_list: List[Dict]) -> List[Dict]:
    """
    Check that all HVs have a total CPU value of not 0 and change if required.
    :param hypervisor_list: OpenStack Hypervisor hosts
    :return: Fixed Hypervsior list
    """
    fixed_list = []
    for hv in hypervisor_list:
        hv_name = hv["Hypervisor Hostname"].split(".")[0]
        if hv["vCPUs"] == 0:
            if hv_name.startswith("hv-"):
                if "ref2023-rtx4000" in hv_name:
                    hv["vCPUs"] = 60
                elif "hv-rtx4000-" in hv_name:
                    hv["vCPUs"] = 60

            elif hv_name[2].isdigit() and hv_name.startswith("hv"):
                hv_number = int(hv_name[2:])

                if 300 <= hv_number <= 499:
                    hv["vCPUs"] = 124
                elif 500 <= hv_number <= 799:
                    hv["vCPUs"] = 128
                elif 900 <= hv_number <= 1004:
                    hv["vCPUs"] = 252
                elif 800 <= hv_number <= 899:
                    hv["vCPUs"] = 252

        fixed_list.append(hv)

    if len(fixed_list) != len(hypervisor_list):
        raise RuntimeError(
            "The formatted hypervisor list does not match the length of the raw hypervisor file."
        )

    return fixed_list


def _get_cpu(hypervisor_list: List[Dict], enabled_hypervisor_list: List[str]) -> Dict:
    """
    Get the CPU stats from the hypervisor list.
    :param hypervisor_list: OpenStack Hypervisor hosts
    :param enabled_hypervisor_list: Hostnames that are enabled as compute service hosts.
    :return: CPU statistics
    """
    used = sum(
        hv["vCPUs Used"]
        for hv in hypervisor_list
        if hv["Hypervisor Hostname"] in enabled_hypervisor_list
    )
    total = sum(
        hv["vCPUs"]
        for hv in hypervisor_list
        if hv["Hypervisor Hostname"] in enabled_hypervisor_list
    )
    return {"cpu": {"in_use": used, "total": total}}


def _get_memory(
    hypervisor_list: List[Dict], enabled_hypervisor_list: List[str]
) -> Dict:
    """
    Get the memory stats from the hypervisor list.
    :param hypervisor_list: OpenStack Hypervisor hosts
    :param enabled_hypervisor_list: Hostnames that are enabled as compute service hosts.
    :return: Memory statistics
    """
    used = round(
        sum(
            hv["Memory MB Used"]
            for hv in hypervisor_list
            if hv["Hypervisor Hostname"] in enabled_hypervisor_list
        )
        / 1000000,
        2,
    )
    total = round(
        sum(
            hv["Memory MB"]
            for hv in hypervisor_list
            if hv["Hypervisor Hostname"] in enabled_hypervisor_list
        )
        / 1000000,
        2,
    )
    return {"memory": {"in_use": used, "total": total}}


def _get_vm(server_list: List[Dict]) -> Dict:
    """
    Get the VM stats from the server list.
    :param server_list:
    :return: VM statistics
    """
    active = len([vm for vm in server_list if vm["Status"] == "ACTIVE"])
    error = len([vm for vm in server_list if vm["Status"] == "ERROR"])
    build = len([vm for vm in server_list if vm["Status"] == "BUILD"])
    shutoff = len([vm for vm in server_list if vm["Status"] == "SHUTOFF"])
    return {
        "vm": {"active": active, "error": error, "build": build, "shutoff": shutoff}
    }


def _get_vwn(server_list: List[Dict]) -> Dict:
    """
    Get the virtual worker nodes stats from the server list.
    :param server_list:
    :return: VWN statistics
    """
    active = len(
        [
            vm
            for vm in server_list
            if "vwn-static" in vm["Name"] and vm["Status"] == "ACTIVE"
        ]
    )
    return {"virtual_worker_nodes": {"active": active}}


def _get_fip(floating_ip_info: Dict) -> Dict:
    """
    Get the floating IP stats from the floating IP info file.
    :param floating_ip_info:
    :return: Floating IP statistics
    """
    total = floating_ip_info["total_ips"]
    used = floating_ip_info["used_ips"]
    return {"floating_ip": {"in_use": used, "total": total}}


def _get_hv(compute_service_list: List[Dict], hypervisor_list: List[Dict]) -> Dict:
    """
    Get the HV stats from the compute service list.
    :param compute_service_list: OpenStack compute service hosts
    :param hypervisor_list: OpenStack Hypervisor hosts
    :return: HV statistics
    """
    up_and_enabled = len(
        [
            hv
            for hv in compute_service_list
            if hv["State"] == "up" and "hv" in hv["Host"] and hv["Status"] == "enabled"
        ]
    )
    down = len(
        [
            hv
            for hv in compute_service_list
            if hv["State"] == "down" and "hv" in hv["Host"]
        ]
    )
    disabled = len(
        [
            hv
            for hv in compute_service_list
            if hv["State"] == "up" and hv["Status"] == "disabled" and "hv" in hv["Host"]
        ]
    )
    cpu_full = len(
        [
            hv
            for hv in hypervisor_list
            if hv["vCPUs Used"] == hv["vCPUs"] and hv["State"] == "up"
        ]
    )
    memory_full = len(
        [
            hv
            for hv in hypervisor_list
            if (
                hv["Memory MB"] - hv["Memory MB Used"] <= 8192
                and not hv["State"] == "down"
            )
        ]
    )
    return {
        "hv": {
            "cpu_full": cpu_full,
            "memory_full": memory_full,
            "down": down,
            "disabled": disabled,
            "up": up_and_enabled,
        }
    }


def read_file(file_name: str) -> List[Dict] | Dict:
    """
    Read data from a yaml file.
    :param file_name:
    :return: File data
    """
    with open(file_name, "r", encoding="utf-8") as file:
        data = yaml.safe_load(file)
    return data


if __name__ == "__main__":
    main()
