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

    delegate :latitude, to: :coordinates
    delegate :longitude, to: :coordinates

  end

end
