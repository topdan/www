module Entertainment

  class MusicVideo < GitRecord::Embedded

    columns do |t|
      t.string :artist
      t.string :song
      t.string :video_url
      t.string :thumbnail_url
      t.string :added_at
    end

    def artist_and_song
      "#{artist} - #{song}"
    end

  end

end
