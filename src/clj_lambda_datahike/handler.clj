(ns clj-lambda-datahike.handler
  (:require [clj-lambda-datahike.core :as core]))

(gen-class
  :name "clj_lambda_datahike.handler"
  :implements [com.amazonaws.services.lambda.runtime.RequestStreamHandler])

(defn -handleRequest [this in out ctx]
  (let [result (core/doit)]
    (spit out result)))
