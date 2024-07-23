import sys
from typing import List, Dict, Tuple
from functools import reduce
import socket
import pandas as pd
import argparse
import subprocess

"""
The IP Resolver script is a utility designed to validate and resolve IP addresses and DNS records
from provided data files. The script supports input files in both XLSX and CSV formats,
containing specific columns for Fully Qualified Domain Names (FQDN) and IDRAC IP addresses.
Using these inputs, the script ensures that the IP addresses and DNS records are correctly
formatted and reachable.
"""


def create_file(
        out_filepath: str = "output.txt"
):
    """
    makes a txt file for the results to be returned into
    :return: output.txt
    """
    with open(out_filepath, "w"):
        pass


def read_from_netbox(
        netbox_filepath: str, fqdn_column: str = "FQDN", idrac_ip_column: str = "IDRAC IP"
) -> List[Dict]:
    """
    reads from netbox file, in a xlsx format
    :param netbox_filepath: path for the netbox info
    :param fqdn_column: full qualified domain name column in netbox file
    :param idrac_ip_column: idrac ip column name in netbox file
    :return: a list of dictionaries containing fqdn and idrac_ip pairs
    """

    sheetnames = pd.ExcelFile(netbox_filepath).sheet_names

    # get all sheets on the XLSX file.
    workbook_info = []

    for i, sheet in enumerate(sheetnames, 1):
        workbook = pd.read_excel(netbox_filepath, sheet_name=sheet, engine='openpyxl').to_dict()

        if fqdn_column not in workbook or idrac_ip_column not in workbook:
            raise RuntimeError(
                f"Error: you've provided an excel sheet: (no. {i}) which does not contain one or more of these "
                f"following column in workbook: {fqdn_column}, {idrac_ip_column}"
            )
        for key, fqdn_val in workbook[fqdn_column].items():
            workbook_info.extend([
                {
                    "fqdn": fqdn_val,
                    "idrac_ip": workbook[idrac_ip_column][key]
                }
            ])
    return workbook_info


def parse_netbox_info(
        netbox_info: List[Dict], reverse_order: bool = False
) -> List[Dict]:
    """
    Parse info from netbox and create corresponding hypervisor fqdn and ip value
    :param netbox_info: list of dictionaries holding fqdn and idrac_ip
    :param reverse_order: use reverse or forward order / if true use forward if  false use reverse
    :return: list of dictionaries which will contain hypervisor fqdn and ip keys-value pairs
    """
    parsed_info = []
    for item in netbox_info:
        parsed_item = {}
        if reverse_order:
            idrac = reduce(
                lambda x, y: f"{x}.{y}", item["idrac_ip"].split(".")[::-1]
            )  #
            idrac = idrac.rsplit(".", 1)[0]
            parsed_item["ip_address"] = idrac
            parsed_item["hypervisor"] = item["fqdn"]
        else:
            parsed_item["ip_address"] = item["idrac_ip"]
            parsed_item["hypervisor"] = item["fqdn"].split(".")[0]
        parsed_info.append(parsed_item)
    return parsed_info


def write_output(
        parsed_info: List[Dict], output_filepath: str, reverse_order: bool = False
):
    """
    write parsed netbox info to a file
    :param parsed_info: list of dictionaries which contains hypervisor fqdn and ip keys
    :param output_filepath: file path for output
    :param reverse_order: use reverse or forward order / if true use forward if false use reverse
    :return: the text written into the file
    """
    print(output_filepath)
    with open(output_filepath, "w", encoding="utf-8") as out_file:
        for item in parsed_info:
            if reverse_order:
                out_file.write(f"{item['ip_address']}\tIN PTR\t{item['hypervisor']}\n")
            else:
                out_file.write(f"{item['hypervisor']}\tIN A\t{item['ip_address']}\n")


def parse_args_dns(inp_args):
    """
    Parse command line args
    :param inp_args: the arguments putted in via command line from cmd_args to inp_args
    :return: the function according to the flags used
    """
    ap = argparse.ArgumentParser(description='option-selector')
    ap.add_argument("input_filepath", type=argparse.FileType("r"))
    ap.add_argument("output_filepath", default="output.txt", nargs="?", type=argparse.FileType("w"))
    ap.add_argument("-r", "--reverse", default=False, help="if set reverses format if not set forwards format",
                    action="store_true")
    ap.add_argument("-c", "--check", default=False, help="check ips if they would work")
    ap.add_argument("-d", "--fqdn-column-name", default="FQDN", help="set FQDN column name")
    ap.add_argument("-i", "--idrac-ip-column-name", default="IDRAC IP", help="set IDRAC IP column name")
    args, _ = ap.parse_known_args(inp_args)
    return args


def check_ip(reverse_order: bool = False,
             output_filepath: str = "output.txt"):
    """
    checks for the ips and then appends them to lists to be checked on from later on in the script
    :param reverse_order: reverse order tracks where to use the position in the function to be able
    to correctly append the right string
    :param output_filepath: filepath used to grab the ips from
    :return: returns ips_found, dns_found
    """
    using_file = output_filepath
    if not reverse_order:
        position_dns = 0
        position_ip = 2
    else:
        position_dns = 2
        position_ip = 0
    ips_found = []
    dns_found = []
    with open(using_file, 'r') as outfile:
        for line in outfile.read().splitlines():
            ips_found.append(line.split('\t')[position_ip])
            dns_found.append(line.split('\t')[position_dns])
    return ips_found, dns_found


def is_reachable_ip(ip: str) -> bool:
    """
    used to ping an ip and see whether it is reachable or not
    :param ip: converts ip to string
    :return: returns boolean result
    """
    try:
        result = subprocess.run(["ping", "-c", "1", ip], capture_output=True)
        return result.returncode == 0
    except Exception as e:
        print(f"Error pinging IP {ip}: {e}")
        return False


def is_reachable_dns(dns_name: str) -> bool:
    """
    used to resolve a dns and see whether it is reachable or not
    :param dns_name: converts dns to string
    :return: returns boolean result
    """
    try:
        socket.gethostbyname(dns_name)
        return True
    except socket.error as e:
        print(f"Error resolving DNS {dns_name}: {e}")
        return False


def check_reachability(ips_found: List[str], dns_found: List[str]) \
        -> Tuple[List[str], List[str], List[str], List[str]]:
    """
    checks whether the ips and dns names are reachable, using two previous functions and then
    appending the results of those to the lists which are after displayed to the command line
    :params ips_found: ips in a list to be tested
    :params dns_found: dns names in a list to be tested
    :params tuple_lists: lists that cant be changed
    :return: all the ips found and dns names found that into 2 sections being reachable meaning
    working ips or dns or unreachable which are out of use ips or dns that cannot be reached
    """
    reachable_ips = []
    unreachable_ips = []
    reachable_dns = []
    unreachable_dns = []

    for ip in ips_found:
        if is_reachable_ip(ip):
            reachable_ips.append(ip)
        else:
            unreachable_ips.append(ip)

    for dns_name in dns_found:
        if is_reachable_dns(dns_name):
            reachable_dns.append(dns_name)
        else:
            unreachable_dns.append(dns_name)

    return reachable_ips, unreachable_ips, reachable_dns, unreachable_dns


def get_dns_record(
        netbox_filepath: str,
        fqdn_column_name: str = "FQDN",
        idrac_ip_column_name: str = "IDRAC IP",
        reverse_order: bool = False,
        output_filepath: str = "output.txt", ):
    """
    this function will create a file for the output for dns records
    also testing each of the ips and dns to see whether they are usable or not printing after
    to display the result
    :param netbox_filepath: path for the netbox info
    :param fqdn_column: full qualified domain name column in netbox file
    :param idrac_ip_column: idrac ip column in netbox file
    :param reverse_order: use reverse or forward order / if true use forward if false use reverse
    :param output_filepath: file path for output
    :return: None
    """
    create_file(output_filepath)
    netbox_info = read_from_netbox(netbox_filepath, fqdn_column_name, idrac_ip_column_name)
    parsed_netbox_info = parse_netbox_info(netbox_info, reverse_order)
    write_output(parsed_netbox_info, output_filepath, reverse_order)
    check_ip(reverse_order, output_filepath)


def main():
    cmd_args = parse_args_dns(sys.argv[1:])
    get_dns_record(
        cmd_args.input_filepath.name,
        cmd_args.fqdn_column_name,
        cmd_args.idrac_ip_column_name,
        cmd_args.reverse,
        cmd_args.output_filepath.name
    )
    ips_found, dns_found = check_ip(cmd_args.check)
    reachable_ips, unreachable_ips, reachable_dns, unreachable_dns = check_reachability(ips_found, dns_found)
    print(f"Reachable IPs: {reachable_ips}")
    print(f"Unreachable IPs: {unreachable_ips}")
    print(f"Reachable DNS: {reachable_dns}")
    print(f"Unreachable DNS: {unreachable_dns}")


# input filepath name, fqdn row name, idrac ip row name, -r or -f for order, output path or file


if __name__ == "__main__":
    main()
