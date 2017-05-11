#!/usr/bin/env python
#
# Copyright (c) 2017 Juniper Networks, Inc. All rights reserved.
#

import socket

from jsonschema import validators, Draft4Validator, FormatChecker
from jsonschema.exceptions import ValidationError


# Custom validator to validate csip (comma seperated ipaddress).
def is_csip(validator, value, instance, schema):
    invalid_ips = []
    for ip in instance.split(','):
        try:
            socket.inet_aton(ip)
        except socket.error:
            invalid_ips.append(ip)

    if invalid_ips:
        yield ValidationError("Invalid ip's %s specified in %s" %
                              (invalid_ips, instance))


# Adding custom validators to existing ones.
contrail_validators = dict(Draft4Validator.VALIDATORS)
contrail_validators['is_csip'] = is_csip


# Create a new custom contrail validator class with new contrail validators.
ContrailValidator = validators.create(
    meta_schema=Draft4Validator.META_SCHEMA,
    validators=contrail_validators
)

# Create a new format checker and register all custom format checkers
contrail_formatchecker = FormatChecker()


# Register a new format checker method for format 'odd_count'
@contrail_formatchecker.checks('odd_count')
def odd_count(value):
    return (len(value.split(',')) % 2) != 0
