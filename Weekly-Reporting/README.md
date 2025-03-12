# Weekly Reporting

This project aims to automate the daily collection of our OpenStack Cloud statistics. These statistics are exported to an InfluxDB bucket. The aim is to store data over a long period of time (~1 year) to be able to see trends in Cloud usage.

This is achieved by various Bash and Python scripts which are modular allowing users to do each tasks individually. There is also a cron script that will run all the other scripts in order to automatically collect and export the data.

### Scripts (in order they should be run):
- [report.sh](report.sh): A Bash script that uses OpenStack commands to collect statistics about the Cloud writes it's outputs to yaml files.
- [format_raw_data.py](format_raw_data.py): A Python script to read the outputs of the above file into a single yaml document.
- [export.py](export.py): A Python script to upload the data from the formatted yaml document into an Influx bucket.
- [cron_export.sh](cron_export.sh): A bash script which runs all of the above scripts designed to be used with crontab

## Notes about each script:
#### [report.sh](report.sh):
- All output files have the date appended and are named in the format `<metric_name>_YYYY-MM-DD.yaml`
- Each metric has its own file. For example, `compute_service_list_2025-03-03.yaml` and `floating_ip_list_2025-03-03.yaml`.
- At the end of the script it calls [format_raw_data.py](format_raw_data.py) so the user does not have to.

#### [format_raw_data.py](format_raw_data.py):
- Is designed to read only the expected output of [report.sh](report.sh). I.e it does not fuzzy search for files names that have the word hypervisor in them.
- Produces a single yaml file named `weekly-report-YYYY-MM-DD.yaml` with all the data from [report.sh](report.sh)'s outputs.

#### [export.py](export.py):
- Uses argparse to create an intuitive and shell like CLI.
- Will only accept data from a data file in the format of the template [here](weekly-report-YYYY-MM-DD.yaml.template).
- It finds the Influx API token from the environment variables. It should be called `INFLUX_TOKEN`.
- If you need to back-fill data you can manually copy and fill in the template data file. Then on line 15 in `export.py` you can change the date to whenever the data was sourced. 

#### [cron_export.sh](cron_export.sh):
- Checks for a `.report-creds` file at `/etc/.report-creds` and exports the variables into the environment.
- Creates the directory `$HOME/weekly-reporting` which is created each time the script runs in case it does not exist.

## Instructions for manual export:

1. Clone the repository onto your machine
2. Source your openstack cli venv and OpenStack admin credentials.
3. Export your Influx API token as `INFLUXDB_API_TOKEN`
4. Run the `report.sh` script to generate the data file.
5. Run `export.py` with the correct arguments, see below:

```shell
python3 export.py --host="http://172.16.103.52:8086" \
--org="cloud" \
--bucket="weekly-reports-time"
--report-file="weekly-report-YYYY-MM-DD.yaml"
```

## Instructions for automatic exporting
1. Clone the repository onto your machine and cd into it
    ```shell
    git clone https://github.com/stfc/cloud-ops-tools.git
    cd cloud-ops-tools/Weekly-Reporting
    ```
2. Copy the cron_export.sh file to `/usr/local/sbin`
    ```shell
    cp cron_export.sh /usr/local/sbin
    ```
3. Fill in the secrets in `.report-creds-(dev/prod)` and copy to `/etc`
    ```shell
    sudo cp .report-creds-(dev/prod) /etc/.report-creds
    sudo chown /etc/.report-creds
    sudo chmod 660 /etc/.report-creds
    ```
4. Create a crontab entry to run the script
    ```shell
    crontab -e
    # Choose your editor
    # Insert the below code into the file then save and quit
    
    # Grafana Cron Report
    0 0 * * * /usr/local/sbin/cron_export.sh 2>&1| logger -t weeklyReporting
    ```
