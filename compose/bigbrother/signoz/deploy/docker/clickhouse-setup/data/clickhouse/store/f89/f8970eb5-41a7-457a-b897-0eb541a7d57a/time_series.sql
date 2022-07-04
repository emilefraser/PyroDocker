ATTACH TABLE _ UUID 'c8c78767-b1dc-4760-88c7-8767b1dcf760'
(
    `date` Date CODEC(DoubleDelta, LZ4),
    `fingerprint` UInt64 CODEC(DoubleDelta, LZ4),
    `labels` String CODEC(ZSTD(5))
)
ENGINE = ReplacingMergeTree
PARTITION BY date
ORDER BY fingerprint
SETTINGS index_granularity = 8192
