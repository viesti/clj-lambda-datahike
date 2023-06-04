(ns clj-lambda-datahike.handler
  (:require [clj-lambda-datahike.core :as core]
            [jsonista.core :as json]))

;; To read number from json into long value, so we can use :db.type/long
(.configure json/keyword-keys-object-mapper com.fasterxml.jackson.databind.DeserializationFeature/USE_LONG_FOR_INTS true)

(gen-class
  :name "clj_lambda_datahike.handler"
  :implements [com.amazonaws.services.lambda.runtime.RequestStreamHandler])


#_{:clj-kondo/ignore [:clojure-lsp/unused-public-var]}
(defn -handleRequest [_this in out _ctx]
  (case (System/getenv "BACKEND_ROLE")
    "writer" (let [{:keys [body] :as _event} (json/read-value in json/keyword-keys-object-mapper)
                   {:keys [command data]} (json/read-value body json/keyword-keys-object-mapper)
                   result (case command
                            "migrate" (core/migrate-db)
                            (core/write-db data))]
               (spit out (json/write-value-as-string {:statusCode 200
                                                      :body (json/write-value-as-string result)})))
    "reader" (spit out (json/write-value-as-string {:statusCode 200
                                                    :body (json/write-value-as-string (core/scan-db))}))
    (spit out (json/write-value-as-string {:statusCode 500
                                           :body (json/write-value-as-string {:message "Unknown backend role"})}))))
