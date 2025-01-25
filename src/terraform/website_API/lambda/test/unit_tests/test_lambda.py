import json
import os
import random

import boto3
import pytest
from moto import mock_aws

import lambda_function as lam_func
from date_utils import date_compare
from lambda_function import DynamoDBClass

REGION = "us-west-1"


@pytest.fixture()
def data_tbl():
    with mock_aws():
        table_name = "test_data_tbl"

        # Add test DynamoDB table to the account.
        dynamodb = boto3.resource("dynamodb", REGION)
        dynamodb.create_table(
            AttributeDefinitions=[{"AttributeName": "p-key", "AttributeType": "S"}],
            TableName=table_name,
            KeySchema=[{"AttributeName": "p-key", "KeyType": "HASH"}],
            BillingMode="PAY_PER_REQUEST",
        )

        # Create DynamoDBClass object for the table above.
        yield lam_func.DynamoDBClass(table_name)

        # Delete table.
        dynamodb = boto3.client("dynamodb", region_name=REGION)
        dynamodb.delete_table(TableName=table_name)


@pytest.fixture()
def visitor_tbl():
    with mock_aws():
        table_name = "test_visitor_tbl"

        # Add test DynamoDB table to the account.
        dynamodb = boto3.resource("dynamodb", REGION)
        dynamodb.create_table(
            AttributeDefinitions=[
                {"AttributeName": "browser", "AttributeType": "S"},
                {"AttributeName": "ip-address", "AttributeType": "S"},
            ],
            TableName=table_name,
            KeySchema=[
                {"AttributeName": "ip-address", "KeyType": "HASH"},
                {"AttributeName": "browser", "KeyType": "RANGE"},
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        # Create DynamoDBClass object for the table above.
        yield lam_func.DynamoDBClass(table_name)

        # Delete table.
        dynamodb = boto3.client("dynamodb", region_name=REGION)
        dynamodb.delete_table(TableName=table_name)


def get_test_data(file_name: str) -> list:
    # Get the json path to json events.
    dir_path = os.path.dirname(os.path.realpath(__file__))
    file_path = f"{dir_path}/../test_data/{file_name}.json"

    # Get json data.
    with open(file_path, "r") as f:
        test_data: list = json.load(f)

    return test_data


@pytest.fixture()
def visitor_tbl_initialized(visitor_tbl: DynamoDBClass, request) -> DynamoDBClass:
    visitors: list = get_test_data("visitors")

    for visitor in visitors:
        # Visitor information is hashed before storing in table.
        ip_hashed = lam_func.hash_user_info(visitor["ip-address"])
        browser_hashed = lam_func.hash_user_info(visitor["browser"])
        date = request.param

        visitor_tbl.table.put_item(
            Item={
                "ip-address": ip_hashed,
                "browser": browser_hashed,
                "date": visitor["date"] if not date else date,
            },
        )
    print(visitor_tbl)
    # print(visitor_tbl.table.scan(Select="ALL_ATTRIBUTES"))
    return visitor_tbl


def test_get_num_visitors(data_tbl: DynamoDBClass):
    random_val = random.randint(0, 100)
    data_tbl.table.put_item(
        Item={
            "p-key": "num-visitors",
            "value": random_val,
        },
    )
    # print(data_tbl.table.scan(Select="ALL_ATTRIBUTES"))
    ret = lam_func.get_num_visitors(data_tbl)
    # print(ret)
    assert ret == random_val


def test_increment_num_visitors(data_tbl: DynamoDBClass):
    random_val = random.randint(0, 100)
    data_tbl.table.put_item(
        Item={
            "p-key": "num-visitors",
            "value": random_val,
        },
    )
    # print(data_tbl.table.scan(Select="ALL_ATTRIBUTES"))
    ret = lam_func.increment_num_visitors(data_tbl)
    # print(ret)
    assert ret == (random_val + 1)


def test_get_visitor_date(visitor_tbl: DynamoDBClass):
    ip = "6.5.4.3"
    browser = "DuckDuckGo"
    date = "1/1/11"

    # Visitor information is hashed before storing in table.
    ip_hashed = lam_func.hash_user_info(ip)
    browser_hashed = lam_func.hash_user_info(browser)

    visitor_tbl.table.put_item(
        Item={
            "ip-address": ip_hashed,
            "browser": browser_hashed,
            "date": date,
        },
    )

    visitor_date = lam_func.get_visitor_date(ip, browser, visitor_tbl)

    assert visitor_date == date


def test_put_visitor(visitor_tbl: DynamoDBClass):
    ip = "99.88.77.66"
    browser = "FireWolf"

    ip_hashed = lam_func.hash_user_info(ip)
    browser_hashed = lam_func.hash_user_info(browser)
    today = str(date_compare.today())

    test_visitor = {
        "ip-address": ip_hashed,
        "browser": browser_hashed,
        "date": today,
    }

    lam_func.put_visitor(ip, browser, visitor_tbl)

    visitor = visitor_tbl.table.get_item(
        Key={
            "ip-address": ip_hashed,
            "browser": browser_hashed,
        }
    )["Item"]

    assert visitor == test_visitor


@pytest.mark.parametrize("visitor", get_test_data("visitors"))
@pytest.mark.parametrize(
    "visitor_tbl_initialized", [str(date_compare.today())], indirect=True
)
def test_counted_visitor_current(visitor: dict, visitor_tbl_initialized: DynamoDBClass):
    # visitor_tbl_initialized = initialize_visitor_tbl(visitor_tbl)
    ip = visitor["ip-address"]
    browser = visitor["browser"]

    assert lam_func.counted_visitor(ip, browser, visitor_tbl_initialized) == (
        True,
        f"Current visitor: {ip}, {browser}, {str(date_compare.today())}",
    )


@pytest.mark.parametrize("visitor", get_test_data("visitors"))
@pytest.mark.parametrize("visitor_tbl_initialized", [""], indirect=True)
def test_counted_visitor_old(visitor: dict, visitor_tbl_initialized: DynamoDBClass):
    # visitor_tbl_initialized = initialize_visitor_tbl(visitor_tbl)
    ip = visitor["ip-address"]
    browser = visitor["browser"]
    last_visit = visitor["date"]

    assert lam_func.counted_visitor(ip, browser, visitor_tbl_initialized) == (
        False,
        f"Old visitor: {ip}, {browser}, {last_visit}",
    )


@pytest.mark.parametrize("visitor", get_test_data("visitors"))
def test_counted_visitor_unknown(visitor: dict, visitor_tbl: DynamoDBClass):
    ip = visitor["ip-address"]
    browser = visitor["browser"]

    assert lam_func.counted_visitor(ip, browser, visitor_tbl) == (
        False,
        f"Unknown visitor: {ip}, {browser}, {date_compare.today()}",
    )