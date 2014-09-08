module Entertainment

  class TvShow < GitRecord::Embedded

    columns do |t|
      t.string :title
      t.string :network
      t.string :imdb_url
      t.string :wikipedia_url
      t.string :hulu_url
      t.string :hbogo_url
      t.string :maxgo_url
      t.string :showtime_url
      t.string :netflix_url
      t.string :amazon_url
      t.string :poster_url
      t.boolean :on_netflix_instant
      t.boolean :on_amazon_prime
      t.date :latest_episode_aired_on
    end

    def netflix_instant?
      on_netflix_instant?
    end

    def hulu?
      !hulu_url.blank?
    end

    def hbogo?
      !hbogo_url.blank?
    end

    def maxgo?
      !maxgo_url.blank?
    end

    def showtime?
      !showtime_url.blank?
    end

    def amazon?
      !amazon_url.blank?
    end

    def amazon_prime?
      on_amazon_prime?
    end

  end

end
