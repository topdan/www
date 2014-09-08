module Entertainment

  class Movie < GitRecord::Embedded

    columns do |t|
      t.string :title
      t.integer :year
      t.date :release_date
      t.string :netflix_url
      t.string :hbogo_url
      t.string :maxgo_url
      t.string :showtime_url
      t.string :apple_trailers_url
      t.string :redbox_url
      t.string :poster_url
      t.string :imdb_url
      t.string :rotten_tomatoes_url
      t.string :amazon_url
      t.boolean :on_netflix_instant
      t.boolean :on_amazon_prime
    end

    def rotten_tomatoes?
      !rotten_tomatoes_url.blank?
    end

    def netflix_instant?
      on_netflix_instant?
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
