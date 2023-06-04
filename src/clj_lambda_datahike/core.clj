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
    (try
      (d/transact conn data)
      (finally
        (d/release conn))))
  (println "Data written")
  "ok")

(defn scan-db []
  (let [conn (d/connect (cfg))]
    (try
      ;; Force a read to backing S3 store, to get fresh data
      (swap! (:wrapped-atom conn) (fn [db] (update db :writer #(assoc % :streaming? false))))
      (d/q '[:find ?e ?n ?a
             :where
             [?e :name ?n]
             [?e :age ?a]]
           @conn)
      (finally
        (d/release conn)))))
