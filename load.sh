#!/bin/bash

wget https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles.xml.bz2
bzcat enwiki-latest-pages-articles.xml.bz2 | \
sed -u 's#</page>#</page>\r#g'| tr -d '\n'| tr '\r' '\n' | \
split -l 50000

for i in `ls x??`; do
  echo $i
  cat $i | clickhouse-client -d bvt -u bvt --password xxx -q "insert into wiki_rows format LineAsString" --receive_timeout=1200 --max_memory_usage='60G'
done
