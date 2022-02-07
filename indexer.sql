create or replace function getBoW as x ->
    arrayReduce('sumMap',
       arrayMap(m-> map(m,1),
          arrayFilter(z -> length(z) > 1,
              arrayFlatten(arrayMap(y-> [stem('en', y),y],
                 splitByRegexp('\P{L}+', lowerUTF8(x)) ))
          )
       )
    );
-- unit test: {'germani':1,'russia':1,'tabl':2,'абц':2}
select getBoW('a on the table tables абц. [АБЦ] Germany Russia George Gershwin') settings allow_experimental_nlp_functions=1;

create or replace function wikiXMLSchemaRE as ->  -- https://regex101.com/r/90HtDk/1
'<page>\s*<title>([^<]+)<\/title>\s*<ns>([^<]+)<\/ns>\s*<id>([^<]+)<\/id>\s*(?:<redirect title="([^\"]+)" \/>)?\s*<revision>\s*<id>([^<]+)<\/id>(?:\s*<parentid>([^<]+)?<\/parentid>)?\s*<timestamp>([^<]+)<\/timestamp>\s*(?:<contributor>(?:\s*<username>([^<]+)<\/username>)?(?:\s*<id>([^<]+)<\/id>)?\s*(?:<ip>([^<]+)<\/ip>)?\s*<\/contributor>)?(?:<contributor deleted=\"deleted\" \/>)?(?:\s*<minor \/>)?\s*(?:<comment deleted=\"deleted\" \/>)?(?:<comment>([^<]+)<\/comment>)?\s*(?:<model>([^<]+)<\/model>\s*<format>([^<]+)<\/format>)?\s*(?:<text bytes="([^\"]+)" xml:space="preserve">([^<]+)<\/text>)?(?:<text bytes="0" \/>)?\s*<sha1>([^<]+)<\/sha1>\s*<\/revision>\s*<\/page>'
;

drop table to_wiki;
create materialized view to_wiki to wiki_pages as
with extractAllGroupsVertical(row,wikiXMLSchemaRE())[1] as a
select decodeXMLComponent(a[1])            as title,
       toUInt16OrZero(a[2])                as namespace,
       toUInt32OrZero(a[3])                as id,
       decodeXMLComponent(a[4])            as redirect_title,
       toUInt32OrZero(a[5])                as revision_id,
       toUInt32OrZero(a[6])                as revision_parent,
       parseDateTimeBestEffortOrZero(a[7]) as timestamp,
       a[8]                                as contributor_name,
       toUInt32OrZero(a[9])                as contributor_id,
       a[10]                               as contributor_ip,
       decodeXMLComponent(a[11])           as comment,
       a[12]                               as model,
       toUInt32OrZero(a[14])               as bytes,
       decodeXMLComponent(a[15])           as text,
       getBoW(text)                        as text_bow,
       getBoW(comment)                     as comment_bow,
       1                                   as sign
from wiki_rows
where id != 0
  and timestamp != 0
settings allow_experimental_nlp_functions=1;

drop table to_wiki_bad;
create materialized view to_wiki_bad to wiki_bad as
with extractAllGroupsVertical(row,wikiXMLSchemaRE())[1] as a,
    toUInt32OrZero(a[3]) as id,
    parseDateTimeBestEffortOrZero(a[7]) as timestamp
select row from wiki_rows
where id = 0 or timestamp = 0;

drop table to_w_text;
create materialized view to_w_text to wiki_text as
select token, id, freq, length(mapValues(text_bow)) as ntk, sign
from wiki_pages array join mapKeys(text_bow) as token, mapValues(text_bow) as freq;

drop table to_w_comment;
create materialized view to_w_comment to wiki_comment as
select token, id, freq, length(mapValues(text_bow)) as ntk, sign
from wiki_pages array join mapKeys(comment_bow) as token, mapValues(comment_bow) as freq;


drop table to_token2id;
create materialized view to_token2id to token2id as
select token, sign*uniqExact(id) c
from wiki_pages array join mapKeys(comment_bow) as token
group by token,sign
;
