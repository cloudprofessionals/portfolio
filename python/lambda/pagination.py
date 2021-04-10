"""
This modules implements lambda functions that processes Athena data through Api requests. When the Lambda is invoked
it calls Athena API which returns job id immediately. We keep checking the status of the job until we succeeded or
encounter an error or a different state other than success. Once the Athena api invocation is successful we can then
process the data. The unique feature of this module is that it takes advantage of the pagination feature of Athena
to stream millions of rows of data.
"""

import boto3
import json
import time

session = boto3.Session()
client = session.client('athena', region_name='us-east-1')


def apply_filter(where_clause):
    """
    This function is for constructing sql query statement needed to be passed to Athena API. It takes where_clause
    parameter which is combination of two mandatory params service_end,service_start and any additional optional
    parameters. :param  where_clause: sql WHERE clause statement to help filter data :type where_clause: str :return:
    return full sql query statement :rtype: str
    """
    query = f'''select start_date,end_date,account_id, 
cost_categor, product_code, 
usage_amount, unblended_rate, 
unblended_cost, product_region, 
pricing_term, pricing_unit, number_of_reservations, 
pricing_rate_id, item_type, 
item_description, rateid, 
ratecode,bill_type,blended_cost FROM athena_database.db_table a
LEFT JOIN athena_database.db_view b
ON a.pricing_rate_id = CAST(b.rateid as varchar)
{where_clause}
ORDER BY start_date
'''
    return query


def get_params(query):
    """
        This function is just for convenience to help us construct sql query statement dynamically
        :param query: This is a full sql statement passed to Athena
        :type query: str
        :return: return the full Athena API request parameter
        :rtype: dict
    """
    params = {
        'region': 'us-east-1',  # AWS Region
        'database': 'athena_database',  # athena database
        'bucket': 'athena-query-results',  # bucket folder to store athena output result
        'path': 'mc2-query-results',  # s3 bucket for output result
        'query': query
    }
    return params


def get_row_value(col):
    """
    Mini function to help with data extraction from Athena.
    :param col: row data from
    :return:
    """
    result = []
    for record in col['Data']:
        if not record:
            continue
        result.append(record['VarCharValue'])
    return result


def check_request_status(execution_id, wait_time):
    """
    This function checks the job status of Athena. It takes execution id return from get_execution_id.
    :param execution_id: executionId from get_execution_id function
    :param wait_time: Time in seconds to wait for athena to process the job.
    :return: SUCCEEDED or None
    """
    wait_time = wait_time
    while wait_time > 0:
        wait_time = wait_time - 0.1
        response = client.get_query_execution(QueryExecutionId=execution_id)
        status = response['QueryExecution']['Status']['State']
        if status == "SUCCEEDED":
            return status
        elif status == "FAILED" or status == "CANCELLED":
            return None
        else:
            time.sleep(0.1)


def get_query_data(header, execution_id, max_result_per_page=None, next_token=None, skip_rows=1):
    """
    This function is responsible for extracting data from Athena json response. A little bit tricky here since
    we need to take into consideration if the request is the first time or subsequent requests
    :param header: column headers specified by fields variable above
    :param execution_id: executionId from get_execution_id function
    :param max_result_per_page: specified number of rows desired. Note athena supports max of 1000
    :param next_token: value of nextToke return from this function. If the page_size is greater than actual rows then
    the value is None.
    :param skip_rows: This value is either 1 or 0. It helps to determine where to start our data extraction, skip_rows
    is always 1 for the first request and 0 for the subsequent requests
    :return: extracted data and nextToken
    """
    if next_token:
        query_result = client.get_query_results(QueryExecutionId=execution_id, MaxResults=max_result_per_page,
                                                NextToken=next_token)
    else:
        query_result = client.get_query_results(QueryExecutionId=execution_id, MaxResults=max_result_per_page)
    try:
        next_token = query_result['NextToken']
    except KeyError:
        next_token = None
    if len(query_result['ResultSet']['Rows']) > 1:
        rows = query_result['ResultSet']['Rows'][skip_rows:]
        query_result = [dict(zip(header, get_row_value(row))) for row in rows]
        return query_result, next_token
    else:
        return [], next_token


def process_athena_data(event):
    """
    This function when called, will check querystring parameter from Api gateway for nextToken and executionId.
    If nextToken is not None, it means there is more data to be retrieve and it will call athena again.
    :param event: This is a lambda event parameter as result of the lambda invocation
    :return: returns json body including http header and status code
    """
    # columns header for queries.
    fields = ("start_date",
              "end_date",
              "account_id",
              "cost_category",
              "product_code",
              "usage_amount",
              "unblended_rate",
              "unblended_cost",
              "product_region",
              "pricing_term",
              "pricing_unit",
              "number_of_reservations",
              "pricing_rate_id",
              "item_type",
              "item_description",
              "rateid",
              "ratecode",
              "bill_type",
              "blended_cost"
              )

    if 'nextToken' in event["queryStringParameters"].keys():
        next_token = event["queryStringParameters"]["nextToken"]
        execution_id = event["queryStringParameters"]["executionId"]

        # nextToken could be None
        if next_token:
            usage, next_id = get_query_data(header=fields, execution_id=execution_id,
                                            max_result_per_page=int(event["queryStringParameters"]['page_size']),
                                            next_token=next_token, skip_rows=0)
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps(
                    {
                        "nextToken": next_id,
                        "executionId": execution_id,
                        "usage": usage
                    },
                    default=str
                )
            }

    query_id = get_execution_id(event)

    if check_request_status(execution_id=query_id, wait_time=20):
        usage, next_id = get_query_data(header=fields, execution_id=query_id,
                                        max_result_per_page=int(event["queryStringParameters"]['page_size']))
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps(
                {
                    "nextToken": next_id,
                    "executionId": query_id,
                    "usage": usage
                },
                default=str
            )
        }


def get_execution_id(event):
    """
    This function is a helper function that makes Athena api call. It is called one time only for athena asynchronous
    job id.
    :param event: This is a lambda event parameter as result of the lambda invocation
    :return: returns executionId of the athena request
    """
    # The where clause consists of two required parameters service_end and service_start
    where_clause = f"""where date(start_date) 
between 
date('{event["queryStringParameters"]["service_start"]}') 
and 
date('{event["queryStringParameters"]["service_end"]}')"""

    # variable to hold optional parameters.
    sql_params = {}

    """
    Check to to see if rateid,ratecode,cost_category,item_type are part of the queryStringParameters from the
    API Gateway. Update sql_params if there any
    """

    if 'rateid' in event["queryStringParameters"].keys():
        sql_params.update(rateid=int(event["queryStringParameters"]["rateid"]))
    if 'ratecode' in event["queryStringParameters"].keys():
        sql_params.update(ratecode=event["queryStringParameters"]["ratecode"])
    if 'cost_category' in event["queryStringParameters"].keys():
        sql_params.update(cost_category_milnum=event["queryStringParameters"]["cost_category"])
    if 'item_type' in event["queryStringParameters"].keys():
        sql_params.update(line_item_line_item_type=event["queryStringParameters"]["item_type"])

    for k, v in sql_params.items():
        if v == "":
            continue

        if k == 'rateid':  # rateid is an integer so we treat it different
            where_clause = where_clause + " and " + f"""{k}={v}"""
            continue
        where_clause = where_clause + " and " + f"""{k}='{v}'"""

    # get athena sql query statement
    query = apply_filter(where_clause)
    # get the entire Athena query parameters
    params = get_params(query)

    # call athena api using boto client
    response = client.start_query_execution(
        QueryString=params["query"],
        QueryExecutionContext={'Database': params['database']},
        ResultConfiguration={'OutputLocation': f"""s3://{params['bucket']}/{params['path']}/"""}
    )
    # first api call does not return data but id of the athena job
    return response['QueryExecutionId']


def handler(event, context):
    """
    This is the lambda function that call our main function get_usage_data
    :param event: carries input or request parameters
    :param context: provides information about the invocation,function adn execution environment
    :return: return data
    """
    return process_athena_data(event)
