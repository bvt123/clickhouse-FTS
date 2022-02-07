-- tokenizer: lower case, split text to tokens, drop one char words, lemmatize and make Bag Of Words with counts
create or replace function stemTokenizer as x ->
      arrayMap(y-> stem('en', y),
         arrayFilter(z -> length(z) > 1,
            splitByRegexp('\P{L}+', lowerUTF8(x) )));


-- search
with 'George Gershwin' as s,
    1.5 as k1, 0.75 as b,
    p as (select arrayJoin(stemTokenizer(s)))
select --title,
    concat('<a href="https://en.wikipedia.org/wiki/', replace(title, ' ','_'),'">',title,'</a>') as link,
    round(tfidf,3) as tfidf,
    round(arrayReduce('sum',arrayMap(x -> x.3*x.1/x.2*(k1+1)/(x.1/x.2+k1*(1-b+b*x.2/110)), scores)),3) as BM25,
    round(tfidf*log10(scores[1].2/2),3 ) as sc2
    --,tfidf.2 as len
    --,redirect_title
from wiki_pages
join (
    select id, sum(sign*freq/ntk * idf) as tfidf, groupArray((freq,ntk,idf)) as scores
    from ( select * from wiki_text where token in p ) as t1
    join ( select token, log(((select count() from wiki_pages) - (sum(c) as sc) +0.5 ) / (sc + 0.5) + 1 ) as idf
           from token2id
           where token in p
           group by token
          ) as t2 using token
    group by id
    order by count() desc, tfidf desc
    limit 100
) as t1 using id
--where redirect_title=''
order by sc2 desc
limit 20
settings allow_experimental_nlp_functions=1;
