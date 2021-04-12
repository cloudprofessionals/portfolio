from pyathena import connect
import json

cursor = connect(s3_staging_dir="s3://etl-athena-demo-bucket/results/",
                 region_name="us-east-1").cursor()

fields = ("timecreated",
          "caseid",
          "servicecode",
          "displayid",
          "severitycode",
          "subject",
          "submittedby",
          "body")


def apply_filter(where_clause):
  query = f'''select at.detail.timecreated,at.detail.caseid,ac.item.servicecode,ac.item.displayid,ac.item.severitycode,ac.item.subject,ac.item.submittedby,at.detail.body
from 
(select detail from 
(SELECT 
item.recentcommunications.communications as comm
FROM (etl_demo_db.ticket_details CROSS JOIN UNNEST(cases) AS t(item))) CROSS JOIN UNNEST(comm) as t(detail)) as at
inner join
(SELECT item FROM (etl_demo_db.tickets CROSS JOIN UNNEST(cases) t (item))) as ac on ac.item.caseid = at.detail.caseid
{where_clause}
order by ac.item.servicecode
'''
  return query


def handler(event, context):

  where_clause = f'''where cast(from_iso8601_timestamp(at.detail.timecreated) as date) between date('{event["queryStringParameters"]["service_start"]}') and 
    date('{event["queryStringParameters"]["service_end"]}')'''

  sql_params = {}

  if 'caseid' in event["queryStringParameters"].keys():
    sql_params.update(caseid=event["queryStringParameters"]["caseid"])
  if 'subject' in event["queryStringParameters"].keys():
    sql_params.update(subject=event["queryStringParameters"]["subject"])
  if 'submittedby' in event["queryStringParameters"].keys():
    sql_params.update(submittedby=event["queryStringParameters"]["submittedby"])

  for k, v in sql_params.items():
    if v == "":
      continue
    where_clause = where_clause + " and " + f"""at.detail.{k}='{v}'"""

  # get constructed query
  query = apply_filter(where_clause)

  rows = cursor.execute(query, sql_params).fetchall()

  # placeholder for our daily usage
  all_tickets = []

  for row in rows:
    ticket = dict(zip(fields, row))
    all_tickets.append(ticket)

  return {
      'statusCode': 200,
      'headers': {'Content-Type': 'application/json'},
      'body': json.dumps(
          {
              'tickets': all_tickets
          },
          default=str
      )
  }
