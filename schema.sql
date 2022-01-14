
CREATE TABLE bvt.wiki
(
    `id` UInt32,
    `title` String,
    `url` String,
    `tokens` Array(String),
    INDEX ix_tokens tokens TYPE bloom_filter GRANULARITY 3
)
ENGINE = MergeTree
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE bvt.wiki2
(
    `id` UInt32,
    `title` String,
    `url` String,
    `tokens` Array(String)
)
ENGINE = MergeTree
ORDER BY id
SETTINGS index_granularity = 256;

create table bvt.tmp1 ( row String ) engine = Null;

CREATE TABLE bvt.wIndex
(
    `token` String,
    `ids` AggregateFunction(groupBitmap, UInt32)
)
ENGINE = MergeTree
ORDER BY token
SETTINGS index_granularity = 8192;

CREATE TABLE bvt.wIndex1
(
    `token` String,
    `ids` AggregateFunction(groupBitmap, UInt32)
)
ENGINE = Join(any, left, token);

drop table wIndex2;
CREATE TABLE bvt.wIndex2
(
    `token` String,
    `ids` AggregateFunction(groupBitmap, UInt32)
)
ENGINE = MergeTree
ORDER BY token
SETTINGS index_granularity = 256;

