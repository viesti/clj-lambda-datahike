# clj-lambda-datahike

Simple example of Datahike with S3 backend

# Usage

First, build the Lambda uberjar

```
bb run build
```

Then deploy infra. This will deploy two Lambda instances, one for writing and one for reading, along with a S3 bucket for data and S3 bucket for storing the Lambda uberjars.

The writer Lambda is configured to use reserved concurrency of 1, so that we would have a single writer only.

```
bb run deploy
```

Then, migrate schema:

```
bb run write '{"command": "migrate"}'
{"result":"ok","status":"ok"}
```

After this, you can do writes and reads by invoking the Lambdas.

```
0% bb run write '{"data": [{"name": "Alice", "age": 32}]}'
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"result":"ok","status":"ok"}
0% bb run read
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"result":[[3,"Alice",32]],"status":"ok"}
```
