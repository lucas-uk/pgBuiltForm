-----------------------------------------------------------
-- Calculating exterior and shared elements of polygons 
-- followed by the external ratio. This produces a table of
-- derived information on the length of exterior edges, the 
-- length of shared edges, the external wall ratio
-----------------------------------------------------------
-- Ensure you've got the tablefunc extension enabled

-- create exterior_ratio table
CREATE table topo_addressablebuildings.exterior_ratio_test as
	SELECT
		face, 
			exterior_edge_m, 
			shared_edge_m,
			case
				when shared_edge_m is null then 1
				else
					round(
						(exterior_edge_m/(exterior_edge_m+shared_edge_m))::numeric,
						2
						) 
				end exterior_ratio
		from
			(
			SELECT 
				*
				FROM crosstab
					(
					'
					SELECT
						face,
							edge_type,
							SUM(edge_length_m) total_edge_length_m
						from
							(
							SELECT
								left_face as face,
									left_face,
									right_face,
									case
										when element_id is null	then ''exterior''
										when right_face = 0	then ''exterior''
										else ''shared''
									end edge_type,
									round(ST_Length(edge.geom)::numeric,2) edge_length_m
								from
									topo_addressablebuildings.edge_data edge
								left outer join
									(select
										*
										from
											topo_addressablebuildings.relation
										where
											element_type = 3
									) poly_rel
								on
									edge.right_face = poly_rel.element_id
								UNION ALL SELECT
									right_face as face,
										left_face,
										right_face,
										case
											when element_id is null	then ''exterior''
											when right_face = 0	then ''exterior''
											else ''shared''
										end edge_type,
										round(ST_Length(edge.geom)::numeric,2) edge_length_m
									from
										topo_addressablebuildings.edge_data edge
									left outer join
										(select
											*
											from
												topo_addressablebuildings.relation
											where
												element_type = 3
										) poly_rel
									on
										edge.right_face = poly_rel.element_id
									where 
										edge.right_face >0 --remove universal face
							) subset
						group by
							face,
							edge_type
						order by
							face,
							edge_type
					',
					'
					select distinct 
						edge_type
						from
							(
							SELECT
								left_face,
									case
										when right_face = 0	then ''exterior''
										else ''shared''
									end edge_type,
									round(ST_Length(edge.geom)::numeric,2) edge_length_m
								from
									topo_addressablebuildings.edge_data edge
							) subset_distinct
						order by 
							edge_type
					'
					)
				AS edge
					(
					face numeric, 
					exterior_edge_m numeric, 
					shared_edge_m numeric
					)
			) pivot;
