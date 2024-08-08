import unittest
from unittest import mock
from unittest.mock import patch, NonCallableMock, call, MagicMock, Mock
import pytest
from get_dns_record import parse_args_dns, get_dns_record, read_from_netbox, parse_netbox_info, write_output, \
    create_file, check_ip, check_reachability, is_reachable_ip, is_reachable_dns


@patch("get_dns_record.read_from_netbox")
@patch("get_dns_record.parse_netbox_info")
@patch("get_dns_record.write_output")
@patch("get_dns_record.check_ip")
@patch("get_dns_record.create_file")
def test_get_dns_record(mock_create_file,
                        mock_check_ip,
                        mock_write_output,
                        mock_parse_netbox_info,
                        mock_read_from_netbox):
    """
    tests main function
    should call all appropriate functions
    """
    mock_netbox_filepath = NonCallableMock()
    mock_fqdn_column = NonCallableMock()
    mock_idrac_ip_column = NonCallableMock()
    mock_reverse_order = NonCallableMock()
    mock_output_filepath = NonCallableMock()

    # Set up return values for the mocks
    mock_read_from_netbox.return_value = Mock()
    mock_parse_netbox_info.return_value = Mock()

    # Call the function under test
    get_dns_record(
        mock_netbox_filepath,
        mock_fqdn_column,
        mock_idrac_ip_column,
        mock_reverse_order,
        mock_output_filepath,
    )

    # Assert that the functions were called with the correct arguments
    mock_create_file.assert_called_once_with(mock_output_filepath)
    mock_read_from_netbox.assert_called_once_with(mock_netbox_filepath, mock_fqdn_column, mock_idrac_ip_column)
    mock_parse_netbox_info.assert_called_once_with(mock_read_from_netbox.return_value, mock_reverse_order)
    mock_write_output.assert_called_once_with(mock_parse_netbox_info.return_value, mock_output_filepath,
                                              mock_reverse_order)


def test_parse_netbox_info_empty():
    """
    tests if the parse netbox info is able to look through each
    of the items in netbox info and reduce each of strings so that they are formatted
    correctly then parse the items into a list and return the info
    """

    mock_netbox_info = []
    mock_reverse_order = NonCallableMock()
    res = parse_netbox_info(mock_netbox_info, mock_reverse_order)
    assert res == []


def test_parse_netbox_info_with_one_set_reversed():
    """
    tests if the parse netbox info is able to look through each
    of the items in netbox info and reduce each of strings so that they are formatted
    correctly then parse the items into a list and return the info
    """

    mock_netbox_info = [{"idrac_ip": "192.168.0.1", "fqdn": "www.google.com"}]
    mock_reverse_order = True
    res = parse_netbox_info(mock_netbox_info, mock_reverse_order)
    assert res == [{"ip_address": "1.0.168", "hypervisor": "www.google.com"}]


def test_parse_netbox_info_with_one_set_not_reversed():
    """
    tests if the parse netbox info is able to look through each
    of the items in netbox info and reduce each of strings so that they are formatted
    correctly then parse the items into a list and return the info
    """

    mock_netbox_info = [{"idrac_ip": "192.168.0.1", "fqdn": "www.google.com"}]
    mock_reverse_order = False
    res = parse_netbox_info(mock_netbox_info, mock_reverse_order)
    assert res == [{"ip_address": "192.168.0.1", "hypervisor": "www"}]


def test_parse_netbox_info_with_two_sets():
    """
    tests if the parse netbox info is able to look through each
    of the items in netbox info and reduce each of strings so that they are formatted
    correctly then parse the items into a list and return the info
    """

    mock_netbox_info = [
        {"idrac_ip": "192.168.0.1", "fqdn": "www.google.com"},
        {"idrac_ip": "192.168.0.1", "fqdn": "www.google.com"},
    ]
    mock_reverse_order = False
    res = parse_netbox_info(mock_netbox_info, mock_reverse_order)
    assert res == [{"ip_address": "192.168.0.1", "hypervisor": "www"},
                   {"ip_address": "192.168.0.1", "hypervisor": "www"}]


@pytest.fixture(name="run_read_from_netbox_test_case")
def run_read_from_netbox_test_case_fixture():
    """A fixture for running read_from_netbox() with different inputs"""

    @patch("get_dns_record.pd")
    def _run_read_from_netbox_test_case(
            mock_sheet_names, read_excel_return, expected_return, mock_pd
    ):
        """function which runs read_from_netbox() test case"""
        mock_pd.ExcelFile.return_value.sheet_names = mock_sheet_names

        mock_netbox_filepath = NonCallableMock()
        mock_fqdn_column = "FQDN"
        mock_idrac_ip_column = "IDRAC IP"

        mock_pd.read_excel.return_value.to_dict.side_effect = read_excel_return

        res = read_from_netbox(
            mock_netbox_filepath, mock_fqdn_column, mock_idrac_ip_column
        )

        mock_pd.ExcelFile.assert_called_once_with(mock_netbox_filepath)

        mock_read_excel_calls = []
        for name in mock_sheet_names:
            mock_read_excel_calls.append(
                call(mock_netbox_filepath, sheet_name=name, engine="openpyxl")
            )
            mock_read_excel_calls.append(
                call().to_dict()
            )

        mock_pd.read_excel.assert_has_calls(mock_read_excel_calls)
        assert mock_pd.read_excel.return_value.to_dict.call_count == len(mock_sheet_names)

        assert res == expected_return

    return _run_read_from_netbox_test_case


def test_read_from_netbox_with_one_sheet_one_row(run_read_from_netbox_test_case):
    """
    tests read from netbox
    checks the load workbook and if it reads the sheets properly
    """
    mock_sheet_names = ["Sheet1"]

    read_excel_return = [{
        "FQDN": {1: "fqdn1"},
        "IDRAC IP": {1: "idrac_ip1"}
    }]

    expected_return = [{"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"}]

    run_read_from_netbox_test_case(mock_sheet_names, read_excel_return, expected_return)


def test_read_from_netbox_no_sheets(run_read_from_netbox_test_case):
    """should return nothing if there is no sheets to be given"""
    mock_sheet_names = []
    read_excel_return = []
    expected_return = []
    run_read_from_netbox_test_case(mock_sheet_names, read_excel_return, expected_return)


def test_read_from_netbox_one_sheet_many_rows(run_read_from_netbox_test_case):
    """checks return if there is one sheet to many rows working"""

    mock_sheet_names = ["Sheet1"]

    read_excel_return = [{
        "FQDN": {1: "fqdn1", 2: "fqdn2"},
        "IDRAC IP": {1: "idrac_ip1", 2: "idrac_ip2"}
    }]

    expected_return = [
        {"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"},
        {"fqdn": "fqdn2", "idrac_ip": "idrac_ip2"},
    ]

    run_read_from_netbox_test_case(mock_sheet_names, read_excel_return, expected_return)


def test_read_from_netbox_many_sheet_many_rows(run_read_from_netbox_test_case):
    """checks return if there is many sheet to many rows working"""

    mock_sheet_names = ["Sheet1", "Sheet2"]

    read_excel_return = [
        {
            "FQDN": {1: "fqdn1", 2: "fqdn2"},
            "IDRAC IP": {1: "idrac_ip1", 2: "idrac_ip2"}
        },
        {
            "FQDN": {1: "fqdn3", 2: "fqdn4"},
            "IDRAC IP": {1: "idrac_ip3", 2: "idrac_ip4"}
        }
    ]

    expected_return = [
        {"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"},
        {"fqdn": "fqdn2", "idrac_ip": "idrac_ip2"},
        {"fqdn": "fqdn3", "idrac_ip": "idrac_ip3"},
        {"fqdn": "fqdn4", "idrac_ip": "idrac_ip4"},
    ]

    run_read_from_netbox_test_case(mock_sheet_names, read_excel_return, expected_return)


@patch("get_dns_record.pd")
def test_read_from_netbox_FQDN_not_found(mock_pd):
    """
    tests read from netbox if there's a runtime error
    and the fqdn is not found
    """

    mock_pd.ExcelFile.return_value.sheet_names = ["Sheet1"]

    mock_netbox_filepath = NonCallableMock()
    mock_fqdn_column = "FQDN"
    mock_idrac_ip_column = "IDRAC IP"

    mock_pd.read_excel.return_value.to_dict.side_effect = [{
        "IDRAC IP": {1: "idrac_ip3", 2: "idrac_ip4"}
    }]

    with pytest.raises(RuntimeError):
        read_from_netbox(mock_netbox_filepath, "FQDN", "IDRAC IP")


@patch("get_dns_record.pd")
def test_read_from_netbox_IDRAC_IP_not_found(mock_pd):
    """
    tests read from netbox if there's a runtime error
    and the IDRAC IP is not found
    """

    mock_pd.ExcelFile.return_value.sheet_names = ["Sheet1"]

    mock_netbox_filepath = NonCallableMock()

    mock_pd.read_excel.return_value.to_dict.side_effect = [{
        "FQDN": {1: "fqdn3", 2: "fqdn4"}
    }]

    with pytest.raises(RuntimeError):
        read_from_netbox(mock_netbox_filepath, "FQDN", "IDRAC IP")


def test_write_output_reversed_order():
    """
    tests whether the write output function works in the reversed order format
    uses txt in the format of ip addresses and url's
    """
    mock_parsed_info = [{"ip_address": "1.0.168", "hypervisor": "www.google.com"}]
    mock_output_filepath = NonCallableMock()

    with mock.patch("builtins.open") as mock_open:
        write_output(mock_parsed_info, mock_output_filepath, True)

    mock_open.assert_called_once_with(mock_output_filepath, "w", encoding="utf-8")
    mock_open.return_value.__enter__.return_value.writelines.assert_called_once_with(["1.0.168\tIN PTR\twww.google.com\n"])


def test_write_output_non_reversed_order():
    """
    tests whether the write output function works in the non-reversed order format
    uses txt in the format of ip addresses and url's
    """
    mock_parsed_info = [{"ip_address": "192.168.0.1", "hypervisor": "www"}]
    mock_output_filepath = NonCallableMock()

    with mock.patch("builtins.open") as mock_open:
        write_output(mock_parsed_info, mock_output_filepath, False)

    mock_open.assert_called_once_with(mock_output_filepath, "w", encoding="utf-8")
    mock_open.return_value.__enter__.return_value.writelines.assert_called_once_with(["www\tIN A\t192.168.0.1\n"])


def test_create_file():
    """
    tests whether a file is created properly
    """
    mock_file_path = NonCallableMock()
    with patch('builtins.open') as mock_open:
        create_file(mock_file_path)
    mock_open.assert_called_once_with(mock_file_path, "w")


@patch("get_dns_record.argparse")
def test_parse_args(mock_argparse):
    """
    tests that arguments have been parsed through argparse when using the script
    using test arguments as a NCM (non-callable-mock) and calls and expected arguments
    """
    mock_expected_args = NonCallableMock()
    mock_ap = mock_argparse.ArgumentParser.return_value

    mock_argparse.ArgumentParser.return_value.parse_known_args.return_value = (mock_expected_args, NonCallableMock())
    test_args = NonCallableMock()
    res = parse_args_dns(test_args)

    mock_argparse.ArgumentParser.assert_called_once_with(description='option-selector')
    mock_ap.add_argument.assert_has_calls(
        [
            call('input_filepath', type=mock_argparse.FileType.return_value),
            call('output_filepath', default='output.txt', nargs="?", type=mock_argparse.FileType.return_value),
            call('-r', "--reverse", default=False, help="if set reverses format if not set forwards format",
                 action="store_true"),
            call("-c", "--check", default=False, help="check ips if they would work"),
            call("-d", "--fqdn-column-name", default="FQDN", help="set FQDN column name"),
            call("-i", "--idrac-ip-column-name", default="IDRAC IP", help="set IDRAC IP column name")
        ]
    )
    mock_ap.parse_known_args.assert_called_once_with(test_args)
    assert res == mock_expected_args


def test_check_ip():
    """
    tests the function check ip accesses a file and is able to append to lists from that file
    """
    mock_file = NonCallableMock()
    with patch('builtins.open') as mock_open:
        check_ip(output_filepath=mock_file)
    mock_open.assert_called_once_with(mock_file, "r")


class TestIsReachableIp(unittest.TestCase):
    @patch('subprocess.run')
    def test_is_reachable_ip(self, mock_run):
        """
        tests that an ip is reachable
        """
        mock_run.return_value = MagicMock(returncode=0)
        result = is_reachable_ip("8.8.8.8")
        self.assertTrue(result)
        mock_run.assert_called_once_with(["ping", "-c", "1", "8.8.8.8"], capture_output=True)


class TestIsReachableDns(unittest.TestCase):
    @patch('socket.gethostbyname')
    def test_is_reachable_dns_success(self, mock_get_host_by_name):
        """
        tests that a dns is reachable
        """
        # Mock a successful DNS resolution
        mock_get_host_by_name.return_value = '127.0.0.1'
        result = is_reachable_dns("example.com")
        self.assertTrue(result)
        mock_get_host_by_name.assert_called_once_with("example.com")


class TestCheckReachability(unittest.TestCase):
    @patch('get_dns_record.is_reachable_ip')
    @patch('get_dns_record.is_reachable_dns')
    def test_check_reachability(self, mock_is_reachable_dns, mock_is_reachable_ip):
        """
        tests whether the ips found and dns found appended from a text file from a csv or xlsx
        are reachable using the other functions and then tests using assert whether the responses
        are true or not using side effects for exceptions
        """
        # Mocking is_reachable_ip responses
        mock_is_reachable_ip.side_effect = [True, False, True]
        # Mocking is_reachable_dns responses
        mock_is_reachable_dns.side_effect = [False, True, False]

        ips_found = ['192.168.1.1', '192.168.1.2', '192.168.1.3']
        dns_found = ['example.com', 'example.org', 'example.net']

        reachable_ips, unreachable_ips, reachable_dns, unreachable_dns = check_reachability(ips_found, dns_found)

        self.assertEqual(reachable_ips, ['192.168.1.1', '192.168.1.3'])
        self.assertEqual(unreachable_ips, ['192.168.1.2'])
        self.assertEqual(reachable_dns, ['example.org'])
        self.assertEqual(unreachable_dns, ['example.com', 'example.net'])

        self.assertEqual(mock_is_reachable_ip.call_count, 3)
        self.assertEqual(mock_is_reachable_dns.call_count, 3)