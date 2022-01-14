
select count() from wiki where id in
    (select arrayJoin(bitmapToArray(groupBitmapAndState(ids))) from wIndex2 where token in ['green','wood'] limit 20);

select count() from wiki where hasAll(tokens,['green','wood']);

select count() from wiki2
where id in
    (select arrayJoin(bitmapToArray(ids)) from wIndex2 where token = 'wood' limit 20)
--where has(tokens,'wood')
;
