(ns clj-lambda-datahike.core
  (:require [datahike.api :as d]
            [datahike-s3.core]))

(defn cfg []
  {:store {:backend :s3
           :bucket (System/getenv "DATAHIKE_S3_BACKEND")
           :region (System/getenv "AWS_REGION")}})

(defn doit []
  (d/create-database (cfg))

  (let [conn (d/connect (cfg))]

    ;; The first transaction will be the schema we are using:
    (prn (d/transact conn [{:db/ident       :name
                            :db/valueType   :db.type/string
                            :db/cardinality :db.cardinality/one }
                           {:db/ident       :age
                            :db/valueType   :db.type/long
                            :db/cardinality :db.cardinality/one }]))

    ;; Let's add some data and wait for the transaction
    (prn (d/transact conn [{:name "Alice"
                            :age  20 }
                           {:name "Bob"
                            :age  30 }
                           {:name "Charlie"
                            :age  40 }
                           {:age 15 }]))

    ;; Search the data
    (prn (d/q '[:find ?e ?n ?a
                :where
                [?e :name ?n]
                [?e :age ?a]]
              @conn))
    ;; => #{[3 "Alice" 20] [4 "Bob" 30] [5 "Charlie" 40]}

    ;; Clean up the database if it is not needed any more
    ;; TODO: Database delete now deletes the whole bucket, which is kind of dangerous
    #_(d/delete-database (cfg))))
