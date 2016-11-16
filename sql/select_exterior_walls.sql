-----------------------------------------------------------
-- Selecting exterior walls query
-----------------------------------------------------------
SELECT
    left_face as face,
        left_face,
        right_face,
        case
            when element_id is null then 'non-shared'
            when right_face = 0 then 'non-shared'
            else 'shared'
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
    UNION SELECT
        right_face as face,
            left_face,
            right_face,
            case
                when element_id is null then 'non-shared'
                when right_face = 0 then 'non-shared'
                else 'shared'
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
        order by 
            1;
