# clickhouse-FTS

https://github.com/RediSearch/ftsb

Сравнение систем https://habr.com/ru/post/581394/
Сделано продавцами Эластика
Неспортивно - маленький датасет, надо бы увеличивать на 1-3 (!) порядка
Ориентир - 1Tb компресованных данных
Почему-то сравнивают на поиске по распространенным словам - кому это надо? Почему не редкие/сбалансированные?

Делаем обратный индекс в виде таблички
это лучше чем bloom

Индексы
- индексы без партиционирования
- индексы соответствуют партиционированию исходных данных
- гранулярность индексов 256

Токены
- встроенный стемминг по словарю
- токены в виде хешей

Два уровня поиска
- обратный индекс дает приблизительное попадание (в парт?)
- bloom индекс
