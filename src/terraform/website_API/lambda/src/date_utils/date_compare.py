import datetime
from typing import overload


class Date:
    # Dates have the format ##/##/## (month/day/year). Years less than 2000
    # aren't valid since there are only two digits to represent the year. 
    def __init__(self, month_day_year):
        values = month_day_year.split('/')
        self.year = int(values[2])
        self.month = int(values[0])
        self.day = int(values[1])
        if len(values) > 3 or self.day > 31 or self.month > 12 or self.year > 99:
            raise ValueError("Error: Date is formatted incorrectly.")
    
    # Overrides the < operator.
    def __lt__(self, other):
        if self.year < other.year:
            return True
        elif self.year > other.year:
            return False

        if self.month < other.month:
            return True
        elif self.month > other.month:
            return False

        if self.day < other.day:
            return True

        return False

    # Overrides the <= operator.
    def __le__(self, other):
        if self.year < other.year:
            return True
        elif self.year > other.year:
            return False

        if self.month < other.month:
            return True
        elif self.month > other.month:
            return False

        if self.day < other.day:
            return True
        elif self.day == other.day and self.month == other.month and self.year == other.year:
            return True

        return False

    # Overrides the str() method.
    def __str__(self):
        return str(self.month) + "/" + str(self.day) + "/" + str(self.year)

@overload
def reformat_date(d: str) -> Date:
    pass

@overload
def reformat_date(d: datetime.date) -> Date:
    pass

# year-month-day --> month/day/year
def reformat_date(d):
    try:
        values = str(d).split('-')
        year = values[0][-2:]
        month = values[1][1] if values[1][0] == '0' else values[1]
        day = values[2][1] if values[2][0] == '0' else values[2]
    except:
        raise ValueError("Error: Date is formatted incorrectly.")
    return Date(month + "/" + day + "/" + year)

def today() -> Date:
    return reformat_date(datetime.date.today())

def num_days_ago(n_days: int) -> Date:
    today_sub_14 = datetime.date.today() - datetime.timedelta(days=n_days)
    return reformat_date(today_sub_14)

def fourteen_days_ago() -> Date:
    return num_days_ago(14)