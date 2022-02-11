drop table wiki_rows;
create table wiki_rows (row String) engine = Null;

drop table wiki_pages;
create table wiki_pages
(
    title            String,
    namespace        UInt16,
    id               UInt32,
    redirect_title   String,
    revision_id      UInt32,
    revision_parent  UInt32,
    timestamp        DateTime,
    contributor_name LowCardinality(String),
    contributor_id   UInt32,
    contributor_ip   String,
    comment          String,
    model            LowCardinality(String),
    bytes            UInt32,
    text             String,
    text_bow         Map(String,UInt16),
    comment_bow      Map(String,UInt16),
    sign             Int8,
    INDEX ix1 mapKeys(text_bow)    TYPE bloom_filter GRANULARITY 3,
    INDEX ix2 mapKeys(comment_bow) TYPE bloom_filter GRANULARITY 3,
    INDEX ix3 text TYPE tokenbf_v1(1000000000, 4, 12345) GRANULARITY 3
) engine = VersionedCollapsingMergeTree(sign,revision_id)
order by (id,revision_id)
settings index_granularity=1024;

drop table wiki_text;
create table wiki_text
    (
        token String,
        id    UInt32,
        freq  UInt16,
        ntk   UInt16,
        sign  Int8
    ) engine = MergeTree order by (token,id)
settings index_granularity=256,
         storage_policy = 'fast';
create table wiki_text1
    (
        token String,
        id    UInt32,
        freq  UInt16,
        ntk   UInt16,
        sign  Int8
    ) engine =Join(ALL, INNER , token) ;

drop table wiki_comment;
create table wiki_comment
    (
        token String,
        id    UInt32,
        freq  UInt16,
        ntk   UInt16,
        sign  Int8
    ) engine = MergeTree order by (token,id)
settings index_granularity=256,
         storage_policy = 'fast';
-- у нас не так много данных, так что нет смысла оставлять гранулярность по умолчанию 8196


-- for idf
drop table token2id;
create table token2id (token String, c UInt32)  engine = SummingMergeTree order by token;
