{% if execute %}

{% set config_values = get_config(this.name, var('workspace_id')) %}
{% set materialize_mode = config_values['materialize_mode'] %}
{% set primary_key = config_values['primary_key'] %}
{% set cursor_field = config_values['cursor_field'] %}
{% set full_refresh = config_values['full_refresh'] %}


{{ config(
    enabled=true, 
    materialized=materialize_mode, 
    unique_key=primary_key,
    full_refresh=full_refresh
    ) }}

{% do log(this.name ~ ' from within model - Primary Key: ' ~ primary_key, info=True) %}
{% do log(this.name ~ ' from within model - Materilization Mode: ' ~ materialize_mode, info=True) %}

WITH 
base AS (
SELECT
    _airbyte_data ->> 'id' as id,
    _airbyte_data -> 'contacts' as contacts,
    (_airbyte_data ->> 'archived')::boolean as archived,
    (_airbyte_data ->> 'createdAt')::timestamp as createdat,
    (_airbyte_data ->> 'updatedAt')::timestamp as updatedat,
    _airbyte_data -> 'properties' as properties,
    _airbyte_data -> 'properties' ->> 'name' as name,
    _airbyte_data -> 'properties' ->> 'phone' as phone,
    _airbyte_data -> 'properties' ->> 'type' as type,
    _airbyte_data -> 'properties' ->> 'industry' as industry,
    _airbyte_data -> 'properties' ->> 'website' as website,
    _airbyte_data -> 'properties' ->> 'description' as description,
    _airbyte_data -> 'properties' ->> 'hubspot_owner_id' as hubspot_owner_id,
    _airbyte_data -> 'properties' ->> 'hs_created_by_user_id' as hs_created_by_user_id,
    _airbyte_data -> 'properties' ->> 'hs_analytics_source' as hs_analytics_source,
    _airbyte_data -> 'properties' ->> 'annualrevenue' as annualrevenue,
    (_airbyte_data -> 'properties' ->> 'hs_last_sales_activity_date')::timestamp as hs_last_sales_activity_date,
    (_airbyte_data -> 'properties' ->> 'hs_lastmodifieddate')::timestamp as hs_lastmodifieddate,
    _airbyte_data -> 'properties' ->> 'numemployees' as numemployees
FROM {{source ('hubspot', '_airbyte_raw_companies')}}
)

{% if materialize_mode == 'incremental' %}

    {{ dedup_logic(primary_key, cursor_field) }}

{% else %}

SELECT *,
    now() AS dbt_sync_time
FROM
base

{% endif %}

{% endif %}