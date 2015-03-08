module Living

  class Restaurant < GitRecord::Embedded

    columns do |t|
      t.string :place
      t.hash :coordinates, class_name: 'GeoLocation'
      t.hash :address, class_name: true
      t.hash :specials
      t.timestamps
    end

    delegate :latitude, to: :coordinates
    delegate :longitude, to: :coordinates

  end

end
