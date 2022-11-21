create or replace temp view vo_calidad_aire_promedio_diario as
select
		fecha,
		avg(case when co_centenario <> -1 then co_centenario else null end) as co_centenario_avg,
		avg(case when no2_centenario <> -1 then no2_centenario else null end) as no2_centenario_avg,
		avg(case when pm10_centenario <> -1 then pm10_centenario else null end) as pm10_centenario_avg,
		avg(case when co_cordoba <> -1 then co_cordoba else null end) as co_cordoba_avg,
		avg(case when no2_cordoba <> -1 then no2_cordoba else null end) as no2_cordoba_avg,
		avg(case when pm10_cordoba <> -1 then pm10_cordoba else null end) as pm10_cordoba_avg,
		avg(case when co_la_boca <> -1 then co_la_boca else null end) as co_la_boca_avg,
		avg(case when no2_la_boca <> -1 then no2_la_boca else null end) as no2_la_boca_avg,
		avg(case when pm10_la_boca <> -1 then pm10_la_boca else null end) as pm10_la_boca_avg,
		avg(case when co_palermo <> -1 then co_palermo else null end) as co_palermo_avg,
		avg(case when no2_palermo <> -1 then no2_palermo else null end) as no2_palermo_avg,
		avg(case when pm10_palermo <> -1 then pm10_palermo else null end) as pm10_palermo_avg
from calidad_aire
where fecha is not null
group by 1;--

create or replace temp view vo_calidad_aire_diaria_proporcional_v1 as
select
		a.fecha,
		a.co_centenario_avg/b.co_contamination_limit as co_contamination_proportion_centenario,
		a.no2_centenario_avg/b.no2_contamination_limit as no2_contamination_proportion_centenario,
		a.pm10_centenario_avg/b.pm10_contamination_limit as pm10_contamination_proportion_centenario,
		a.co_cordoba_avg/b.co_contamination_limit as co_contamination_proportion_cordoba,
		a.no2_cordoba_avg/b.no2_contamination_limit as no2_contamination_proportion_cordoba,
		a.pm10_cordoba_avg/b.pm10_contamination_limit as pm10_contamination_proportion_cordoba,
		a.co_la_boca_avg/b.co_contamination_limit as co_contamination_proportion_la_boca,
		a.no2_la_boca_avg/b.no2_contamination_limit as no2_contamination_proportion_la_boca,
		a.pm10_la_boca_avg/b.pm10_contamination_limit as pm10_contamination_proportion_la_boca,
		a.co_palermo_avg/b.co_contamination_limit as co_contamination_proportion_palermo,
		a.no2_palermo_avg/b.no2_contamination_limit as no2_contamination_proportion_palermo,
		a.pm10_palermo_avg/b.pm10_contamination_limit as pm10_contamination_proportion_palermo
from vo_calidad_aire_promedio_diario a
inner join vo_lkp_calidad_aire b
	on
		True;--
		
create or replace temp view vo_calidad_aire_diaria_proporcional_v2 as
select
	fecha, co_contamination_proportion_centenario as co_contamination_proportion, no2_contamination_proportion_centenario as no2_contamination_proportion, pm10_contamination_proportion_centenario as pm10_contamination_proportion
from vo_calidad_aire_diaria_proporcional_v1
union all
select
	fecha, co_contamination_proportion_cordoba, no2_contamination_proportion_cordoba, pm10_contamination_proportion_cordoba
from vo_calidad_aire_diaria_proporcional_v1
union all
select
	fecha, co_contamination_proportion_la_boca, no2_contamination_proportion_la_boca, pm10_contamination_proportion_la_boca
from vo_calidad_aire_diaria_proporcional_v1
union all
select
	fecha, co_contamination_proportion_palermo, no2_contamination_proportion_palermo, pm10_contamination_proportion_palermo
from vo_calidad_aire_diaria_proporcional_v1;--

create or replace temp view vo_calidad_aire_agrupada as
select 
	fecha,
	avg(co_contamination_proportion) as co_contamination_proportion_avg,
	avg(no2_contamination_proportion) as no2_contamination_proportion_avg,
	avg(pm10_contamination_proportion) as pm10_contamination_proportion_avg
from vo_calidad_aire_diaria_proporcional_v2
group by fecha;--

create or replace temp view vo_calidad_aire_agrupada_indice as
select 
	fecha,
	ROUND(cast(co_contamination_proportion_avg as numeric), 4) as co_contamination_proportion_avg,
	round(cast(no2_contamination_proportion_avg as numeric), 4) as no2_contamination_proportion_avg,
	round(cast(pm10_contamination_proportion_avg as numeric), 4) as pm10_contamination_proportion_avg,
	round(cast((coalesce(co_contamination_proportion_avg, 0) + coalesce(no2_contamination_proportion_avg, 0) * 1.1 + coalesce(pm10_contamination_proportion_avg,0) * 1.25) as numeric), 4) as indice_calidad_aire,
	case when co_contamination_proportion_avg is null then False else True end as co_measure_flag,
	case when no2_contamination_proportion_avg is null then False else True end as no2_measure_flag,
	case when pm10_contamination_proportion_avg is null then False else True end as pm10_measure_flag
from vo_calidad_aire_agrupada;--


with indices_ranked_mes as (
select 
		to_char(fecha, 'YYYY-MM') as year_month,
		indice_calidad_aire,
		row_number() over(partition by to_char(fecha, 'YYYY-MM') order by indice_calidad_aire asc) as indice_rank
from vo_calidad_aire_agrupada_indice 
where pm10_measure_flag)
select 
		year_month,
		indice_calidad_aire
from indices_ranked_mes
where indice_rank <= 3