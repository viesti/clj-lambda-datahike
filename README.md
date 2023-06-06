# clj-lambda-datahike

Simple example of Datahike with S3 backend

# Usage

First, build the Lambda uberjar

```
bb run build
```

Then deploy infra. This will deploy two Lambda instances, one for writing and one for reading, along with a S3 bucket for data and S3 bucket for storing the Lambda uberjars.

The writer Lambda is configured to use reserved concurrency of 1, so that we would have a single writer only.

Both Lambdas are configured to be accessible via Lambda Function URL without authentication, so you can call them via HTTP.

```
bb run deploy
```

Then, migrate schema:

```
$ curl -X POST $(cat terraform/writer-url.txt) -H "content-type: application/json" -H "X-API-KEY: $(cat terraform/api-key.txt)" -d '{"command": "migrate"}'
"ok"
```

After this, you can do writes and reads by invoking the Lambdas.

```
$ curl -X POST $(cat terraform/writer-url.txt) -H "content-type: application/json" -H "X-API-KEY: $(cat terraform/api-key.txt)" -d '{"data": [{"name": "Alice", "age": 32}]}'
"ok"
0% curl $(cat terraform/reader-url.txt)
[[4,"Alice",32]]
```
