module Living

  class Restaurant < GitRecord::Embedded

    columns do |t|
      t.string :place
      t.hash :coordinates
      t.hash :address
      t.hash :specials
      t.timestamps
    end

    embeds_one :address
    embeds_one :coordinates, class_name: 'GeoLocation'

    def to_map_listing
      MapListing.new({
        title: place,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        filters: specials.keys,
        parent: self,
      })
    end

  end

end
