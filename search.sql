-- tokenizer: lower case, split text to tokens, drop one char words, stem and make Bag Of Words with counts
create or replace function stemTokenizer as x ->
      arrayMap(y-> stem('en', y),
         arrayFilter(z -> length(z) > 1,
            splitByRegexp('\P{L}+', lowerUTF8(x) )));

create or replace function Tokenizer as x ->
         arrayFilter(z -> length(z) > 1,
            splitByRegexp('\P{L}+', lowerUTF8(x) ));

-- lemmarizer is not working as expected https://github.com/ClickHouse/ClickHouse/issues/34332

-- search
with 'vegan zoo' as s, p as (select arrayJoin(Tokenizer(s))),
    1.5 as k1, 0.75 as b,
    t_idf as ( select token, log(((select count() from wiki_pages) - (sum(c) as sc) +0.5 ) / (sc + 0.5) + 1 ) as idf
               from token2id
               where token in p
               group by token  )
select title
    --concat('<a href="https://en.wikipedia.org/wiki/', replace(title, ' ','_'),'">',title,'</a>') as link,
   -- round(tfidf,3) as tfidf,
    --round(arrayReduce('sum',arrayMap(x -> x.3*x.1/x.2*(k1+1)/(x.1/x.2+k1*(1-b+b*x.2/110)), scores)),3) as BM25,
    --round(tfidf*log10(scores[1].2/2),3 ) as sc2
    --,tfidf.2 as len
    --,redirect_title
from wiki_pages
join (
    select id, sum(sign*freq/ntk * idf) as tfidf, tfidf*log10(any(ntk)/2) as sc2
    --, groupArray((freq,ntk,idf)) as scores
    from ( select * from wiki_text where token in p) as t1
    join t_idf using token
    group by id
    order by count() desc, sc2 desc
    limit 20
) as t1 using id
--where redirect_title=''
order by sc2 desc
limit 20
settings allow_experimental_nlp_functions=1, use_uncompressed_cache=1;

-- в два слова на массивах. но медленнее :(
with 'George Gershwin' as s,
    p as (select arrayJoin(Tokenizer(s))),
    ( select groupArray((token,idf)) from (
               select token,
                   round(log(((select count() from wiki_pages) - (sum(c) as sc) +0.5 ) / (sc + 0.5) + 1 ),2) as idf
               from token2id
               where token in p
               group by token
               order by idf desc )) as v_idf,
    (select groupArray((id,round(sign*freq/ntk,4),v_idf[1].2)) from wiki_text where token = v_idf[1].1) as t1,
    (select groupArray((id,round(sign*freq/ntk,4),v_idf[2].2)) from wiki_text where token = v_idf[2].1 and id in (select arrayJoin(t1.1))) as t2,
    arrayJoin(arrayConcat(t1,t2)) as t3
select title from wiki_pages where id in (select  t3.1 as id group by id order by sum(t3.2 * t3.3 ) desc limit 20)
;
