{% docs _fivetran_synced -%} The timestamp that Fivetran last synced the record.
{%- enddocs %}

{% docs source_relation -%} The source where this data was pulled from. If you are making use of the `union_schemas` variable, this will be the source schema. If you are making use of the `union_databases` variable, this will be the source database. If you are not unioning together multiple sources, this will be an empty string.
{%- enddocs %}

{% docs created -%} Time at which the record was created. Dates in the requested timezone, or UTC if not provided.
{%- enddocs %}

{% docs created_at -%} Time at which the record was created. Dates in the requested timezone, or UTC if not provided.
{%- enddocs %}

{% docs created_utc -%}
Time at which the record was created. Dates in UTC.
{%- enddocs %}

{% docs city -%}
City, district, suburb, town, or village.
{%- enddocs %}

{% docs country -%}
Two-letter country code (ISO 3166-1 alpha-2).
{%- enddocs %}

{% docs line_1 -%}
Address line 1 (e.g., street, PO Box, or company name).
{%- enddocs %}

{% docs line_2 -%}
Address line 2 (e.g., apartment, suite, unit, or building).
{%- enddocs %}

{% docs postal_code -%}
ZIP or postal code.
{%- enddocs %}

{% docs state -%}
State, county, province, or region.
{%- enddocs %}

{% docs convert_values -%}
Values can be expressed either in the smallest currency unit (default) or in the major currency unit (divided by 100), as determined by the `stripe__convert_values` variable. Refer to the [README]((https://github.com/fivetran/dbt_stripe_source?tab=readme-ov-file#enabling-cent-to-dollar-conversion)) for more information.
{%- enddocs %}
