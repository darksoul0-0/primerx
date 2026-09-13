SELECT count(*) FROM primerx.alerts;


SELECT
    HCP_ID,
    COUNT(*) AS alert_count,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS doctor_rank
FROM primerx.alerts
GROUP BY HCP_ID
ORDER BY alert_count DESC
LIMIT 10;


SELECT
    s.HCP_ID,
    SUM(s.Prescription_Volume) AS total_rx_volume,
    RANK() OVER (
        ORDER BY SUM(s.Prescription_Volume) DESC
    ) AS doctor_rank
FROM primerx.sales s
INNER JOIN (
    SELECT DISTINCT HCP_ID
    FROM primerx.alerts
) a
ON s.HCP_ID = a.HCP_ID
GROUP BY s.HCP_ID
ORDER BY total_rx_volume DESC
LIMIT 10;

SELECT *
FROM primerx.alerts
LIMIT 5;

SELECT *
FROM primerx.sales
LIMIT 5;

WITH first_positive AS (
    SELECT
        HCP_ID,
        MIN(STR_TO_DATE(Alert_Date,'%d-%m-%Y')) AS first_positive_date
    FROM primerx.alerts
    WHERE Lab_Result = 'Positive'
    GROUP BY HCP_ID
)
SELECT *
FROM first_positive;

WITH first_positive AS (
    SELECT
        HCP_ID,
        MIN(STR_TO_DATE(Alert_Date,'%d-%m-%Y')) AS first_positive_date
    FROM primerx.alerts
    WHERE Lab_Result = 'Positive'
    GROUP BY HCP_ID
)
SELECT
    fp.HCP_ID
FROM first_positive fp
LEFT JOIN primerx.sales s
    ON fp.HCP_ID = s.HCP_ID
    AND STR_TO_DATE(s.Prescription_Date,'%d-%m-%Y')
        BETWEEN fp.first_positive_date
        AND DATE_ADD(fp.first_positive_date, INTERVAL 30 DAY)
GROUP BY fp.HCP_ID
HAVING COUNT(s.Prescription_ID) = 0;

WITH first_positive AS (
    SELECT
        HCP_ID,
        MIN(STR_TO_DATE(Alert_Date,'%d-%m-%Y')) AS first_positive_date
    FROM primerx.alerts
    WHERE Lab_Result = 'Positive'
    GROUP BY HCP_ID
),
target_doctors AS (
    SELECT
        fp.HCP_ID
    FROM first_positive fp
    LEFT JOIN primerx.sales s
        ON fp.HCP_ID = s.HCP_ID
        AND STR_TO_DATE(s.Prescription_Date,'%d-%m-%Y')
            BETWEEN fp.first_positive_date
            AND DATE_ADD(fp.first_positive_date, INTERVAL 30 DAY)
    GROUP BY fp.HCP_ID
    HAVING COUNT(s.Prescription_ID) = 0
)
SELECT
    a.HCP_ID,
    COUNT(*) AS positive_alert_count,
    RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS doctor_rank
FROM primerx.alerts a
JOIN target_doctors td
    ON a.HCP_ID = td.HCP_ID
WHERE a.Lab_Result = 'Positive'
GROUP BY a.HCP_ID
ORDER BY positive_alert_count DESC
LIMIT 10;



select count(distinct HCP_ID) from primerx.alerts where Lab_Result='Positive';

-- how many had more than 1 positive
select count(*) from (
    select HCP_ID from primerx.alerts
    where Lab_Result='Positive'
    group by HCP_ID
    having count(*) > 1
) t;


-- drug share for top 10 alert doctors - using left join to catch any with no sales
select t.rnk, t.HCP_ID,
    coalesce(sum(s.Prescription_Volume),0) as total_vol,
    round(100 * coalesce(sum(case when s.Drug_ID = 'DRG001' then s.Prescription_Volume else 0 end),0)
        / nullif(coalesce(sum(s.Prescription_Volume),0),0), 2) as our_share,
    round(100 * coalesce(sum(case when s.Drug_ID <> 'DRG001' then s.Prescription_Volume else 0 end),0)
        / nullif(coalesce(sum(s.Prescription_Volume),0),0), 2) as comp_share
from (
    select HCP_ID, count(*) as alert_cnt,
    rank() over (order by count(*) desc) as rnk
    from primerx.alerts
    group by HCP_ID
    order by alert_cnt desc
    limit 10
) t
left join primerx.sales s on t.HCP_ID = s.HCP_ID
group by t.rnk, t.HCP_ID
order by t.rnk;


-- top competitor drug among the high alert doctors
select Drug_Name, Drug_ID, sum(Prescription_Volume) as vol
from primerx.sales
where HCP_ID in (
    select HCP_ID from primerx.alerts
    group by HCP_ID order by count(*) desc limit 10
)
and Drug_ID <> 'DRG001'
group by Drug_Name, Drug_ID
order by vol desc
limit 1;

DESCRIBE primerx.affliation;

-- account level - which accounts have lowest conversion (alerts vs our drug rx)
select
    rank() over (order by coalesce(ar.our_rx,0)/aa.tot_alerts asc) as rnk,
    ta.Account_ID,
    aa.tot_alerts,
    coalesce(ar.our_rx,0) as our_drug_rx,
    round(coalesce(ar.our_rx,0)/aa.tot_alerts, 4) as conversion
from (
    select af.Account_ID, af.Account_Name, count(*) as tot
    from primerx.affliation af
    join primerx.alerts al on af.HCP_ID = al.HCP_ID
    group by af.Account_ID, af.Account_Name
    order by tot desc limit 10
) ta
join (
    select af.Account_ID, count(*) as tot_alerts
    from primerx.affliation af
    join primerx.alerts al on af.HCP_ID = al.HCP_ID
    group by af.Account_ID
) aa on ta.Account_ID = aa.Account_ID
left join (
    select af.Account_ID, sum(s.Prescription_Volume) as our_rx
    from primerx.affliation af
    join primerx.sales s on af.HCP_ID = s.HCP_ID
    where s.Drug_ID = 'DRG001'
    group by af.Account_ID
) ar on ta.Account_ID = ar.Account_ID
order by conversion asc;


-- rx per active doctor by account
select
    rank() over (order by coalesce(dv.vol,0)/nullif(coalesce(ad.actv,0),0) asc) as rnk,
    a.Account_ID,
    a.total_docs,
    coalesce(ad.actv,0) as active_docs,
    coalesce(dv.vol,0) as our_drug_vol,
    round(coalesce(dv.vol,0)/nullif(coalesce(ad.actv,0),0),2) as vol_per_doc
from (
    select Account_ID, count(distinct HCP_ID) as total_docs
    from primerx.affliation group by Account_ID
) a
left join (
    select af.Account_ID, count(distinct s.HCP_ID) as actv
    from primerx.affliation af
    join primerx.sales s on af.HCP_ID = s.HCP_ID
    where s.Drug_ID = 'DRG001'
    group by af.Account_ID
) ad on a.Account_ID = ad.Account_ID
left join (
    select af.Account_ID, sum(s.Prescription_Volume) as vol
    from primerx.affliation af
    join primerx.sales s on af.HCP_ID = s.HCP_ID
    where s.Drug_ID = 'DRG001'
    group by af.Account_ID
) dv on a.Account_ID = dv.Account_ID
order by vol_per_doc asc
limit 10;


-- first positive date per doctor (reusing for lift calc below)
select HCP_ID, min(STR_TO_DATE(Alert_Date,'%d-%m-%Y')) as first_pos
from primerx.alerts
where Lab_Result = 'Positive'
group by HCP_ID;


-- pre vs post lift - 90 days before and after first positive alert
with fp as (
    select HCP_ID, min(STR_TO_DATE(Alert_Date,'%d-%m-%Y')) as first_pos
    from primerx.alerts where Lab_Result='Positive'
    group by HCP_ID
)
select
    rank() over (order by
        case when pre_v = 0 and post_v > 0 then 999999
        else ((post_v - pre_v)/nullif(pre_v,0))*100 end desc
    ) as rnk,
    HCP_ID,
    pre_v as rx_before,
    post_v as rx_after,
    round(case
        when pre_v = 0 and post_v > 0 then 100
        when pre_v = 0 then 0
        else ((post_v-pre_v)/pre_v)*100
    end, 2) as lift_pct
from (
    select fp.HCP_ID,
        coalesce(sum(case
            when STR_TO_DATE(s.Prescription_Date,'%d-%m-%Y')
                between DATE_SUB(fp.first_pos, interval 90 day)
                and DATE_SUB(fp.first_pos, interval 1 day)
            then s.Prescription_Volume else 0 end),0) as pre_v,
        coalesce(sum(case
            when STR_TO_DATE(s.Prescription_Date,'%d-%m-%Y')
                between fp.first_pos
                and DATE_ADD(fp.first_pos, interval 90 day)
            then s.Prescription_Volume else 0 end),0) as post_v
    from fp
    left join primerx.sales s on fp.HCP_ID = s.HCP_ID and s.Drug_ID='DRG001'
    group by fp.HCP_ID
) x
order by lift_pct desc
limit 10;


-- segment doctors: new starters, growers, non-responders
with fp as (
    select HCP_ID, min(STR_TO_DATE(Alert_Date,'%d-%m-%Y')) as first_pos
    from primerx.alerts where Lab_Result='Positive'
    group by HCP_ID
),
vols as (
    select fp.HCP_ID,
        coalesce(sum(case when STR_TO_DATE(s.Prescription_Date,'%d-%m-%Y')
            between DATE_SUB(fp.first_pos,interval 90 day) and DATE_SUB(fp.first_pos,interval 1 day)
            then s.Prescription_Volume else 0 end),0) as pre_v,
        coalesce(sum(case when STR_TO_DATE(s.Prescription_Date,'%d-%m-%Y')
            between fp.first_pos and DATE_ADD(fp.first_pos,interval 90 day)
            then s.Prescription_Volume else 0 end),0) as post_v
    from fp
    left join primerx.sales s on fp.HCP_ID = s.HCP_ID and s.Drug_ID='DRG001'
    group by fp.HCP_ID
)
select
    case
        when pre_v = 0 and post_v > 0 then 'New Starters'
        when pre_v > 0 and ((post_v-pre_v)/pre_v)*100 >= 20 then 'Growers'
        else 'Non-Responders'
    end as segment,
    count(*) as hcp_count,
    round(avg(case when pre_v = 0 then null else ((post_v-pre_v)/pre_v)*100 end),2) as avg_lift,
    sum(post_v - pre_v) as incremental_vol
from vols
group by segment
order by incremental_vol desc;
