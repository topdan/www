module Entertainment

  class GilmoreGirlAlum < GitRecord::Embedded

    columns do |t|
      t.string :name
      t.string :imdb_url
      t.string :job
      t.integer :episodes_count
      t.array :posters
      t.string :description
    end

  end

end
