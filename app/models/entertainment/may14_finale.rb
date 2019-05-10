module Entertainment
  class May14Finale < GitRecord::Embedded
    columns do |t|
      t.string :title
      t.string :imdb_url
      t.string :wikipedia_url
      t.string :poster_filename
      t.string :description
      t.date :date
    end
  end
end
