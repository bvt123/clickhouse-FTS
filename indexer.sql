CREATE MATERIALIZED VIEW bvt.to_wiki TO bvt.wiki
(
    `id` UInt32,
    `title` String,
    `url` String,
    `tokens` Array(String)
) AS
WITH
    '(\\d+)\\s(?:<feed>)?<doc><title>Wikipedia: (.+)</title><url>(.+)</url><abstract>(.+)</abstract><links></links></doc>' AS re,
    extractAllGroupsVertical(row, re)[1] AS r,
    (select max(id) from wiki) as lastId
SELECT
    toUInt32OrZero(r[1])+lastId AS id,
    r[2] AS title,
    r[3] AS url,
    splitByNonAlpha(lower(r[4])) AS tokens
FROM tmp1;

/*
индексация википедии
grep -v \<sublink enwiki-latest-abstract.xml | sed -u 's#</doc>#</doc>\a#g' | tr -d '\n' | tr  '\a' '\n'  > 11 &
cat -n 11 | head -20 | clickhouse-client -d bvt -u bvt -q "insert into tmp1 format LineAsString" --send_logs_level=debug
*/

insert into wIndex
select arrayJoin(tokens) as token, groupBitmapState(id) as ids
from wiki
group by token;
