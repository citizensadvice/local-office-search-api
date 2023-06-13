# frozen_string_literal: true

# encode geographies as GeoJSON when encoding to JSON
RGeo::ActiveRecord::GeometryMixin.set_json_generator(:geojson)
