(ns clj-lambda-datahike.core
  (:require [datahike.api :as d]
            [datahike-s3.core]))

(defn cfg []
  {:store {:backend :s3
           :bucket (System/getenv "DATAHIKE_S3_BACKEND")
           :region (System/getenv "AWS_REGION")}})

(defn migrate-db []
  (d/create-database (cfg))
  (let [conn (d/connect (cfg))]
    (d/transact conn [{:db/ident       :name
                       :db/valueType   :db.type/string
                       :db/cardinality :db.cardinality/one}
                      {:db/ident       :age
                       :db/valueType   :db.type/long
                       :db/cardinality :db.cardinality/one}]))
  (println "Migration done")
  "ok")

(defn write-db [data]
  (prn "writing data" data)
  (let [conn (d/connect (cfg))]
    (d/transact conn data))
  (println "Data written")
  "ok")

(defn scan-db []
  (let [conn (d/connect (cfg))]
    (d/q '[:find ?e ?n ?a
           :where
           [?e :name ?n]
           [?e :age ?a]]
         @conn)))
