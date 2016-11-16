-----------------------------------------------------------
-- Classify built form using qualitative spatial reasoning
-----------------------------------------------------------


SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_toid_crossreference', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_spatially_within', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'count_st_touch_addresses', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'form_based_on_addressgeometry', 'varchar(25)');

-- update abp_cnt_toid_crossreference based on TOID
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		abp_cnt_toid_crossreference = cnt.abp_count 
	FROM  
		(
		select 
			os_topo_toid,
				count(*) abp_count
			from
				os_addressbase.addressbaseplus
			group by
				os_topo_toid
		) AS cnt
	WHERE cnt.os_topo_toid = bld.fid;
	
-- update abp_cnt_spatially_within based on spatial relationship
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		abp_cnt_spatially_within = cnt.abp_count 
	FROM  
		(
		select
			bld.ogc_fid,
				count(*) abp_count
			from 
				derivedinfo.buildingsandheights bld,
				os_addressbase.addressbaseplus abp
			where 
				st_intersects
					(
					bld.wkb_geometry,
					abp.geometry
					)
				and abp.RPC<3
				and abp.STATE <> 1
				and abp.STATE <> 4
				and abp.STATE <> 6
				and abp.STATE is not null
				and abp.POSTAL_ADDRESS <> 'M'
				and abp.POSTAL_ADDRESS <> 'N'
			group by
				bld.ogc_fid
		) AS cnt
	WHERE cnt.ogc_fid = bld.ogc_fid;

-- identify the number of addressable buildings touched by other addressable buidlings:

UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		count_st_touch_addresses = b.number_of_addressable_neighbours
	FROM  
		(
		select
			a.ogc_fid,
				count(*) as number_of_addressable_neighbours
			from
				(
				select
					*
					from
						derivedinfo.buildingsandheights
					where
						abp_cnt_spatially_within > 0
						or abp_cnt_toid_crossreference > 0
				) as a
			join
				derivedinfo.buildingsandheights as b
			on 
				ST_Touches(a.wkb_geometry,b.wkb_geometry)
			where
				b.abp_cnt_spatially_within > 0
				or b.abp_cnt_toid_crossreference > 0
			group by
				a.ogc_fid
		) b
	WHERE b.ogc_fid = bld.ogc_fid;

-- deal with detached buildings
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		count_st_touch_addresses = 0
	from
		(
		select
			ogc_fid,
				count_st_touch_addresses,
				abp_cnt_spatially_within,
				abp_cnt_toid_crossreference
			from
				derivedinfo.buildingsandheights
			where
				count_st_touch_addresses is null
				and abp_cnt_spatially_within > 0
				or count_st_touch_addresses is null
				and abp_cnt_toid_crossreference > 0
		) a
	WHERE a.ogc_fid = bld.ogc_fid;

-- These queries can be simplified by use of a dict/lookup

-- flag detached
UPDATE 
	derivedinfo.buildingsandheights
	SET    
		form_based_on_addressgeometry = 'detached'
	WHERE 
		count_st_touch_addresses = 0;

-- flag semi-detached
UPDATE 
	derivedinfo.buildingsandheights
	SET    
		form_based_on_addressgeometry = 'semi-detached'
	WHERE 
		count_st_touch_addresses = 1;
-- flag mid-terraced
UPDATE 
	derivedinfo.buildingsandheights
	SET    
		form_based_on_addressgeometry = 'mid-terraced'
	WHERE 
		count_st_touch_addresses = 2;
-- flag end-terraced
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		form_based_on_addressgeometry = 'end-terraced'
	from
		(
		select
			endt.ogc_fid
			from
				derivedinfo.buildingsandheights endt
			join
				derivedinfo.buildingsandheights ter
			on 
				ST_Touches(endt.wkb_geometry,ter.wkb_geometry)
			where
				endt.count_st_touch_addresses = 1
				and ter.count_st_touch_addresses = 2
		) a
	WHERE a.ogc_fid = bld.ogc_fid;
-- flag complex
UPDATE 
	derivedinfo.buildingsandheights
	SET    
		form_based_on_addressgeometry = 'complex'
	WHERE 
		count_st_touch_addresses > 2;