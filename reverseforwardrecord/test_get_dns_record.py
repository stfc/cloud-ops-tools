from unittest import mock
import pytest
from unittest.mock import patch, MagicMock, NonCallableMock, Mock
from get_dns_record import main, read_from_netbox, parse_netbox_info, write_output


# patch is for calling functions in a function
# magic mock is to mock the parameters
# you only put anything in the parameters that are needed later in the mock test


@patch("get_dns_record.read_from_netbox")
@patch("get_dns_record.parse_netbox_info")
@patch("get_dns_record.write_output")
def test_main(mock_write_output, mock_parse_netbox_info, mock_read_from_netbox):
    """
    tests main function
    should call all appropriate functions
    """
    mock_netbox_filepath = NonCallableMock()
    mock_fqdn_column = NonCallableMock()
    mock_idrac_ip_column = NonCallableMock()
    mock_reverse_order = NonCallableMock()
    mock_output_filepath = NonCallableMock()

    main(
        mock_netbox_filepath,
        mock_fqdn_column,
        mock_idrac_ip_column,
        mock_reverse_order,
        mock_output_filepath,
    )
    mock_read_from_netbox.assert_called_once_with(
        mock_netbox_filepath, mock_fqdn_column, mock_idrac_ip_column
    )
    mock_parse_netbox_info.assert_called_once_with(
        mock_read_from_netbox.return_value, mock_reverse_order
    )
    mock_write_output.assert_called_once_with(
        mock_parse_netbox_info.return_value, mock_output_filepath, mock_reverse_order
    )


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

    @patch("get_dns_record.load_workbook")
    def _run_read_from_netbox_test_case(
            workbook_return, expected_return, mock_load_workbook
    ):
        """function which runs read_from_netbox() test case"""
        mock_netbox_filepath = NonCallableMock()
        mock_fqdn_column = 0
        mock_idrac_ip_column = 1
        mock_load_workbook.return_value = workbook_return

        res = read_from_netbox(
            mock_netbox_filepath, mock_fqdn_column, mock_idrac_ip_column
        )
        mock_load_workbook.assert_called_once_with(filename=mock_netbox_filepath)
        assert res == expected_return

    return _run_read_from_netbox_test_case


def test_read_from_netbox_with_one_sheet_one_row(run_read_from_netbox_test_case):
    """
    tests read from netbox
    checks the load workbook and if it reads the sheets properly
    """
    fqdn_row1_item = MagicMock()
    fqdn_row1_item.value = "fqdn1"

    idrac_ip_row1_item = MagicMock()
    idrac_ip_row1_item.value = "idrac_ip1"

    workbook_return = {
        "sheet1": [[], [fqdn_row1_item, idrac_ip_row1_item]],
    }

    expected_return = [{"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"}]

    run_read_from_netbox_test_case(workbook_return, expected_return)


def test_read_from_netbox_no_sheets(run_read_from_netbox_test_case):
    """should return nothing if there is no sheets to be given"""
    workbook_return = {}
    expected_return = []

    run_read_from_netbox_test_case(workbook_return, expected_return)


def test_read_from_netbox_one_sheet_many_rows(run_read_from_netbox_test_case):
    """checks return if there is one sheet to many rows working"""

    fqdn_row1_item = MagicMock()
    fqdn_row1_item.value = "fqdn1"

    idrac_ip_row1_item = MagicMock()
    idrac_ip_row1_item.value = "idrac_ip1"

    fqdn_row2_item = MagicMock()
    fqdn_row2_item.value = "fqdn2"

    idrac_ip_row2_item = MagicMock()
    idrac_ip_row2_item.value = "idrac_ip2"

    workbook_return = {
        "sheet1": [
            [],
            [fqdn_row1_item, idrac_ip_row1_item],
            [fqdn_row2_item, idrac_ip_row2_item],
        ],
    }

    expected_return = [
        {"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"},
        {"fqdn": "fqdn2", "idrac_ip": "idrac_ip2"},
    ]

    run_read_from_netbox_test_case(workbook_return, expected_return)


def test_read_from_netbox_many_sheet_many_rows(run_read_from_netbox_test_case):
    """checks return if there is many sheet to many rows working"""

    fqdn_row1_item = MagicMock()
    fqdn_row1_item.value = "fqdn1"

    idrac_ip_row1_item = MagicMock()
    idrac_ip_row1_item.value = "idrac_ip1"

    fqdn_row2_item = MagicMock()
    fqdn_row2_item.value = "fqdn2"

    idrac_ip_row2_item = MagicMock()
    idrac_ip_row2_item.value = "idrac_ip2"

    workbook_return = {
        "sheet1": [
            [],
            [fqdn_row1_item, idrac_ip_row1_item],
            [fqdn_row2_item, idrac_ip_row2_item],
        ],
        "sheet2": [
            [],
            [fqdn_row1_item, idrac_ip_row1_item],
            [fqdn_row2_item, idrac_ip_row2_item],
        ],
    }

    expected_return = [
        {"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"},
        {"fqdn": "fqdn2", "idrac_ip": "idrac_ip2"},
        {"fqdn": "fqdn1", "idrac_ip": "idrac_ip1"},
        {"fqdn": "fqdn2", "idrac_ip": "idrac_ip2"},
    ]

    run_read_from_netbox_test_case(workbook_return, expected_return)


@patch("get_dns_record.load_workbook")
def test_read_from_netbox_index_error(mock_load_workbook):
    mock_netbox_filepath = NonCallableMock()
    fqdn_row1_item = MagicMock()
    fqdn_row1_item.value = "fqdn1"

    idrac_ip_row1_item = MagicMock()
    idrac_ip_row1_item.value = "idrac_ip1"
    mock_load_workbook.return_value = {"sheet1": [fqdn_row1_item, idrac_ip_row1_item]}

    with pytest.raises(RuntimeError):
        read_from_netbox(mock_netbox_filepath, 0, 2)

    with pytest.raises(RuntimeError):
        read_from_netbox(mock_netbox_filepath, 2, 1)


def test_write_output_reversed_order():
    mock_parsed_info = [{"ip_address": "192.168.0.1", "hypervisor": "www"}]
    mock_output_filepath = NonCallableMock()

    with mock.patch("builtins.open") as mock_open:
        write_output(mock_parsed_info, mock_output_filepath, True)

    mock_open.return_value.assert_called_once_with(mock_output_filepath, "w", encoding="utf-8")
    mock_open.return_value.__enter__.return_value.write.assert_called_once_with("1.0.168\tIN PTR\twww.google.com")


def test_write_output_non_reversed_order():
    mock_parsed_info = [{"ip_address": "192.168.0.1", "hypervisor": "www"}]
    mock_output_filepath = NonCallableMock()

    with mock.patch("builtins.open") as mock_open:
        write_output(mock_parsed_info, mock_output_filepath, False)

    mock_open.return_value.assert_called_once_with(mock_output_filepath, "w", encoding="utf-8")
    mock_open.return_value.__enter__.return_value.write.assert_called_once_with("192.168.0.1\tIN A\twww")
