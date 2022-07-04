ATTACH TABLE _ UUID 'ec5fab27-5507-415a-ac5f-ab275507d15a'
(
    `fingerprint` UInt64 CODEC(DoubleDelta, LZ4),
    `timestamp_ms` Int64 CODEC(DoubleDelta, LZ4),
    `value` Float64 CODEC(Gorilla, LZ4)
)
ENGINE = MergeTree
PARTITION BY toDate(timestamp_ms / 1000)
ORDER BY (fingerprint, timestamp_ms)
SETTINGS index_granularity = 8192
