"""
This an API client module that is used to consume data from API Gateway. This client was developed to address the need
of processing millions of rows of data from AWS Athena without hitting API Gateway and Lambda resource limit.
Usage:
    set your api request parameters as dictionary
    usage_request = {"service_start": "2021-03-01","service_end": "2021-03-06","page_size": 1000}
    call the function
    usage = get_usage(usage_request)
    process your usage as desired
    print(usage)
"""
import requests
from urllib3 import disable_warnings

# disable insecure warnings
disable_warnings()


def get_usage(data: dict):
    """
    This function processes response from rest api. The rest response contains two important
    keys: nextToken and executionId. We check for nextToken, if the nextToken is None then we reach the end of data
    otherwise we continue to check for nextToken till all data is returned and processed
    :param data: This is dict object that has 3 required parameters service_start,service_end and page_size
    :return: usage_data which is a list
    """

    # an arbitrary container for our usage report
    daily_usage = []

    next_token = None

    # http request headers
    headers = {
        'Accept': 'application/json',
        'x-api-key': 'APs789key789kew4kfxGXAc'
    }

    # Api Gateway endpoint
    url = "https://apigatewayurl.execute-api.us-east-1.amazonaws.com/prod/usage/pages"

    # make api call
    response = requests.get(url, headers=headers, verify=False, params=data).json()
    print(response)
    try:
        # we expect nextToken in the api response
        next_token = response['nextToken']
    except KeyError:
        next_token = next_token

    # extract the usage data from the api call
    first_usage_data = response['usage']
    # we expect executionId in the response
    execution_id = response['executionId']

    # return usage data to our container
    daily_usage.extend(first_usage_data)

    # make additional api call as long as next_token is not None
    while next_token:

        # update our data parameter variable with new nextToken and athena executionId processed
        data.update(nextToken=next_token)
        data.update(executionId=execution_id)

        url = "https://apigatewayurl.execute-api.us-east-1.amazonaws.com/prod/usage/pages"
        response = requests.get(url, headers=headers, verify=False, params=data).json()
        try:
            next_token = response['nextToken']
        except KeyError:
            next_token = None
        addition_usage_data = response['usage']
        daily_usage.extend(addition_usage_data)
        execution_id = response['executionId']

    # return our final daily usage report.
    return daily_usage
