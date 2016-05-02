module Entertainment

  class TvShow < GitRecord::Embedded

    columns do |t|
      t.string :title
      t.string :poster_url
      t.date :latest_episode_aired_on
      t.date :first_episode_aired_on
      t.date :final_episode_aired_on
      t.integer :unwatched_episodes_count
      t.hash :streams
      t.hash :references
    end

    def url
      references[:wikipedia] || references[:imdb] || references[:rotten_tomatoes]
    end

    def categories
      streams.keys
    end

  end

end
