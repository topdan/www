module Living

  class InspiringVideos < GitRecord::Embedded

    columns do |t|
      t.string :id, primary: true
      t.string :title
      t.text :description_html
      t.string :youtube1_key
      t.string :youtube2_key
      t.timestamps
    end

    def youtube1_url
      youtube_url(youtube1_key)
    end

    def youtube2_url
      youtube_url(youtube2_key)
    end

    protected

    def youtube_url(key)
      "http://www.youtube.com/watch?v=#{key}"
    end

  end

end
