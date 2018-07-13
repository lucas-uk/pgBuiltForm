-----------------------------------------------------------
-- Classify built form using qualitative spatial reasoning
-----------------------------------------------------------


-- create function to test for existance of fields before adding new ones
CREATE OR REPLACE function f_add_col(
   _tbl regclass, _col  text, _type regtype, OUT success bool)
    LANGUAGE plpgsql AS
$func$
BEGIN

IF EXISTS (
   SELECT 1 FROM pg_attribute
   WHERE  attrelid = _tbl
   AND    attname = _col
   AND    NOT attisdropped) THEN
   success := FALSE;

ELSE
   EXECUTE '
   ALTER TABLE ' || _tbl || ' ADD COLUMN ' || quote_ident(_col) || ' ' || _type;
   success := TRUE;
END IF;

END
$func$;


SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_toid_crossreference', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_spatially_within', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_spatially_within_non_add', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'count_st_touch_addresses', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'form_based_on_addressgeometry', 'varchar(25)');
SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_spatial_rpc_only', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_spatial_postal_rpc', 'bigint');
SELECT f_add_col('derivedinfo.buildingsandheights', 'abp_cnt_spatially_within_old', 'bigint');

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
				os_addressbase.addressbaseplus abp
             where
                 	(abp.RPC < 3)
                    and 
                    (abp.STATE = 2
                    or abp.STATE = 3
                    or abp.STATE = 5
                    or abp.STATE is null)                   
                    and 
                    (abp.ADDRESSBASE_POSTAL <> 'M'
                    and abp.ADDRESSBASE_POSTAL <> 'N' )    
                    
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
           			and
                 	(abp.RPC < 3)
                    and 
                    (abp.STATE = 2
                    or abp.STATE = 3
                    or abp.STATE = 5
                    or abp.STATE is null)                   
                    and 
                    (abp.ADDRESSBASE_POSTAL <> 'M'
                    and abp.ADDRESSBASE_POSTAL <> 'N' )          
			group by
				bld.ogc_fid
		) AS cnt
	WHERE cnt.ogc_fid = bld.ogc_fid;




-- update abp_cnt_spatially_within_non_add based on spatial relationship
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		abp_cnt_spatially_within_non_add = cnt.abp_count 
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
           			and
                 	(abp.RPC < 3)
                    and 
                    (abp.STATE = 2
                    or abp.STATE = 3
                    or abp.STATE = 5
                    or abp.STATE is null)      
			group by
				bld.ogc_fid
		) AS cnt
	WHERE cnt.ogc_fid = bld.ogc_fid;
    



-- update abp_cnt_spatially_within_old based on spatial relationship
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		abp_cnt_spatially_within_old = cnt.abp_count 
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
				and abp.RPC < 3
				and abp.STATE <> 1
				and abp.STATE <> 4
				and abp.STATE <> 6
                and abp.STATE is not null
                and abp.ADDRESSBASE_POSTAL <> 'M'
                and abp.ADDRESSBASE_POSTAL <> 'N'
			group by
				bld.ogc_fid
		) AS cnt
	WHERE cnt.ogc_fid = bld.ogc_fid;




-- update abp_cnt_spatial_rpc_only based on spatial relationship
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		abp_cnt_spatial_rpc_only = cnt.abp_count 
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
                and abp.RPC < 3
			group by
				bld.ogc_fid
		) AS cnt
	WHERE cnt.ogc_fid = bld.ogc_fid;



-- update abp_cnt_spatial_postal_rpc based on spatial relationship
UPDATE 
	derivedinfo.buildingsandheights bld
	SET    
		abp_cnt_spatial_postal_rpc = cnt.abp_count 
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
                and abp.RPC < 3
                and abp.ADDRESSBASE_POSTAL <> 'M'
                and abp.ADDRESSBASE_POSTAL <> 'N'
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


