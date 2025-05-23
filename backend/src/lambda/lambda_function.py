import sys
import os
from hashlib import pbkdf2_hmac

import boto3

from date_utils import date_compare

# Visitors get recounted if they revisit the site after a this amount of time.
NUM_DAYS_TILL_EXPIRATION = 14

session_region = boto3.Session().region_name
if session_region:
    REGION = session_region
else:
    REGION = "us-west-1"

if sys.version_info[0:2] != (3, 13):
    raise Exception("Requires python 3.13")


# Class for creating DynamoDB resources that represent existing tables in the
# account.
class DynamoDBClass:
    def __init__(self, table_name):
        self.resource = boto3.resource("dynamodb", REGION)
        self.table_name = table_name
        self.table = self.resource.Table(self.table_name)


# Get table names from environment variables.
_DATA_TBL = DynamoDBClass(os.environ.get("data_tbl", "None"))
_VISITOR_TBL = DynamoDBClass(os.environ.get("visitor_tbl", "None"))


def get_num_visitors(data_tbl: DynamoDBClass) -> int:
    # Check if num-visitors is in table.
    try:
        num_visitors = data_tbl.table.get_item(
            Key={
                "p-key": "num-visitors",
                #
            },
        )["Item"]["value"]
    # Not in table.
    except KeyError:
        num_visitors = update_num_visitors(data_tbl, "PUT", 0)

    return num_visitors


def update_num_visitors(data_tbl: DynamoDBClass, action: str, value: int) -> int:
    num_visitors = data_tbl.table.update_item(
        Key={
            "p-key": "num-visitors",
        },
        AttributeUpdates={
            "value": {
                "Value": value,
                "Action": action,  # "ADD"|"PUT"|"DELETE"
            }
        },
        ReturnValues="UPDATED_NEW",
    )["Attributes"]["value"]
    print(num_visitors)
    return num_visitors


def hash_user_info(info: str) -> str:
    our_app_iters = 10
    dk = pbkdf2_hmac(
        "sha256", bytes(info, encoding="utf-8"), b"bad salt" * 2, our_app_iters
    )
    return dk.hex()


# The date is when the visitor was last counted, not necessarily the last time
# they visited the site.
def get_visitor_date(ip: str, browser: str, visitor_tbl: DynamoDBClass) -> str | None:
    # User information is stored hashed.
    ip_hashed = hash_user_info(ip)
    browser_hashed = hash_user_info(browser)

    # Check if visitor is in table.
    try:
        last_visit = visitor_tbl.table.get_item(
            Key={
                "ip-address": ip_hashed,
                "browser": browser_hashed,
            },
        )["Item"]["date"]
    # Not in table.
    except KeyError:
        return None

    return last_visit


def put_visitor(ip: str, browser: str, visitor_tbl: DynamoDBClass) -> dict:
    # Visitor information is hashed before storing in table.
    ip_hashed = hash_user_info(ip)
    browser_hashed = hash_user_info(browser)
    today = str(date_compare.today())

    visitor_tbl.table.put_item(
        Item={
            "ip-address": ip_hashed,
            "browser": browser_hashed,
            "date": today,
        },
    )

    return {
        "ip-address": ip,
        "browser": browser,
        "date": today,
    }


# Checks if the visitor is new, or if it time to recount the visitor.
def counted_visitor(
    ip: str, browser: str, visitor_tbl: DynamoDBClass
) -> tuple[bool, str]:
    last_visit = get_visitor_date(ip, browser, visitor_tbl)

    # User is in table.
    if last_visit:
        # Last visit was recent.
        if date_compare.Date(last_visit) >= date_compare.num_days_ago(
            NUM_DAYS_TILL_EXPIRATION
        ):
            return (True, f"Current visitor: {ip}, {browser}, {last_visit}")
        # Last visit is past expiration.
        else:
            return (False, f"Old visitor: {ip}, {browser}, {last_visit}")
    # Not in table.
    else:
        return (False, f"Unknown visitor: {ip}, {browser}, {date_compare.today()}")


# Main Lambda function.
def lambda_handler(event: dict, context: dict) -> dict:
    """Main function invoked by Lambda that processes incoming HTTP requests.

    Args:
        event (dict): Information about the function invocation and execution
            environment defined in integration request template in
            API Gateway.
        context (dict): Information about the function invocation and execution
            environment provided by AWS.

    Returns:
        dict: Request response.
    """
    response = {}

    if "http_method" in event:
        match event["http_method"]:
            case "GET":
                ip = event["source_ip"]
                browser = event["user-agent"]
                counted, _ = counted_visitor(ip, browser, _VISITOR_TBL)

                if counted:
                    num_visitors = get_num_visitors(_DATA_TBL)
                else:
                    put_visitor(ip, browser, _VISITOR_TBL)
                    num_visitors = update_num_visitors(_DATA_TBL, "ADD", 1)

                # print(visitor)

                response = {"num_visitors": num_visitors}

            case "":
                response = {"Error": "Empty HTTP method"}

            case _:
                response = {"Error": f"'{event["http_method"]}' is not valid"}
    else:
        response = {"Error": "No HTTP method"}

    return response
