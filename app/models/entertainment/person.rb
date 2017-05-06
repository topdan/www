class Entertainment::Person < GitRecord::Embedded

  columns do |t|
    t.string :name
    t.string :job
    t.string :poster_url
    t.hash :references
  end

  def title
    name
  end

  def url
    references[:imdb] || references[:rotten_tomatoes]
  end

  def actor?
    job == 'actor'
  end

  def director?
    job == 'director'
  end

  def categories
    if actor?
      %w(actor)
    elsif director?
      %w(director)
    else
      raise "Unknown job for #{title.inspect}"
    end
  end

  def streams
    {}
  end

end
