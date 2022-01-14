insert into wIndex
select arrayJoin(tokens) as token, groupBitmapState(id) as ids
from wiki
group by token;
