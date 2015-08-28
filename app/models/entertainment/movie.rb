module Entertainment

  class Movie < GitRecord::Embedded

    columns do |t|
      t.string :title
      t.integer :year
      t.date :release_date
      t.string :poster_url
      t.hash :streams
      t.hash :references
    end

  end

end
