# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2023 United Kingdom Research and Innovation
from dataclasses import dataclass, fields
from typing import Optional


# pylint: disable = R0902
@dataclass
class Device:
    """
    This class instantiates device objects with the device data.
    """

    tenant: str
    device_role: str
    manufacturer: str
    device_type: str
    status: str
    site: str
    location: str
    rack: str
    position: str
    name: str
    serial: str
    face: Optional[str] = None
    airflow: Optional[str] = None

    def return_attrs(self):
        """
        This method returns a list of the names of the fields above.
        """
        return [field.name for field in list(fields(self))]
