module Entertainment

  class TvShowRingtone < GitRecord::Embedded

    columns do |t|
      t.string :show
      t.string :video_url
      t.string :thumbnail_url
      t.text :description
    end

  end

end
