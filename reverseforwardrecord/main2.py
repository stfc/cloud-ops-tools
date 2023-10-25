import csv

# for forward records


# 8 and 10 for the tt csv grab parts and 8 is fqdn so goes first when putting them together

def write_file(values):
    with open('idrac_fqdn.txt', 'w', encoding="utf-8") as out_file:
        for fqdn, idrac in zip(hypervisors, ip_addresses):
            out_file.write(f"{fqdn}    IN A    {idrac}\n")


# opens file and grabs a certain column
if __name__ == "__main__":

    hypervisors = []
    ip_addresses = []
    with open("tt.csv") as file_handle:
        reader = csv.reader(file_handle)

        column_to_print = 8
        column_to_print2 = 10
        for row in reader:
            fqdn = row[column_to_print]
            idrac = row[column_to_print2]
            hypervisors.append(fqdn.split('.')[0])
            ip_addresses.append(idrac)
            print(fqdn)
            print(idrac)
        write_file(hypervisors)
