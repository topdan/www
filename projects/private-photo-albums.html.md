* [Introduction](#introduction)
* [The Solution](#the-solution)
* [The Implementation](#the-implementation)
* [Conclusion](#conclusion)

```raw
<p class="center"><img alt="Example Photo Album" src="album.jpg"/></p>
```

## [Introduction](#introduction)

Everyone has a web-connected camera and sharing via text, email, and social media has never been easier. [This age of communication](/living/the-communication-age.html) presents a new set of pitfalls ranging from [embarrassing](http://www.usmagazine.com/celebrity-news/news/alison-pill-topless-twitter-photo-accident-was-dumb-hideously-embarrassing-201349) to [criminal](http://www.forbes.com/sites/josephsteinberg/2014/08/31/nude-photos-of-jessica-lawrence-and-kate-upton-leak-five-important-lessons-for-all-of-us/). Sending photos may be easy but balancing privacy, ownership, simplicity, and convenience isn't:

* Text messages and emails are mostly private but don't organize well, while most social media organizes better but isn't private
* Facebook has [privacy settings](http://mattmckeon.com/facebook-privacy/) which are misused and changed so often [they introduced and recommend a privacy check-up](http://mattmckeon.com/facebook-privacy/)
* Facebook (owner of Instagram and WhatsApp) [claims a broad license on the photos you upload and only declares how it _currently_ uses it](https://www.facebook.com/notes/andy-rouse-wildlife-photography/facebook-picture-rights/270204724175)
* [Snapchat charges $0.33 for a replay](http://www.theverge.com/2015/9/15/9330955/snapchat-replay-snaps-paid-in-app) so pictures may be living somewhere long after they're sent

These tools and others like them are built to turn a profit through generating page views and gathering data for corporate and government partnerships. I'm not against companies turning profits, but in this case it conflicts with my desire for a simple, private, available-everywhere photo album.

```raw
<p class="alert alert-info center"><strong>My family doesn't share our photos on social media,<br> and I won't do so on their behalf.</strong></p>
```

## [The Solution](#the-solution)

I built my own private photo album on [Amazon Web Services](https://en.wikipedia.org/wiki/Amazon_Web_Services). Unlike Facebook and Twitter, AWS is a business (not social) platform, so privacy is a major priority, and it would never claim a license on my data. My remaining goals were simplicity and convenience:

* Display a wall of videos and photos with no wasted space
* Provide my family access to it anytime/anywhere
* Allow them to upload new videos and photos

## [The Implementation](#the-implementation)

The software is a combination of free libraries and AWS services coordinated by my application:

* [Amazon S3](https://aws.amazon.com/s3/) stores and protects the photos and videos better and _much_ cheaper than services like iCloud and Dropbox
* [Elastic Transcoder](https://aws.amazon.com/elastictranscoder/) converts videos into Apple's [HLS video format](https://en.wikipedia.org/wiki/HTTP_Live_Streaming) for efficient streaming
* [FlowPlayer](https://flowplayer.org/) adds HLS support for Chrome, IE, and Firefox via Flash
* [Cloudfront](https://aws.amazon.com/cloudfront/) serves the photos and videos to authorized users
* [Gamma Gallery](http://tympanus.net/codrops/2012/11/06/gamma-gallery-a-responsive-image-gallery-experiment/) provides a clean, responsive presentation via [jquery](https://jquery.com/) and [masonry](http://masonry.desandro.com/)
* [Ruby on Rails](/ruby-on-rails/index.html) and [aws-sdk](https://aws.amazon.com/sdk-for-ruby/) bring everything together into a private website

I encountered a few technical "challenges" along the way which I plan on writing about in more detail later:

* Authorizing CloudFront requests with signed-cookies
* Uploading files directly to Amazon S3
* Automating the Elastic Transcoder
* Adding video support and metadata editing to Gamma Gallery
* [Automatically loading more images as you scroll](/ruby-on-rails/simple-infinite-scrolling.html)

## [Conclusion](#conclusion)

Watching everyone in the photos change while scrolling down is a pleasant trip. I'm not sure if my whole family will use it, but I'll continue adding our photos and videos, so in 5/10/?? years we can look back. I may even start other albums for my extended family and close friends.

The project came together pretty quickly over the last couple weeks, but I already have some ideas for version 2:

* Clean up the permissions interface
* Improve touch's zoom user-experience
* Integrate the uploading UX more intimately
* Tag by people and events
* Filter by tags into more specific albums
* Auto-tag people via facial [recognition](https://dan.cunning.cc/living/past-present-and-future-of-computers.html#recognizing)

```raw
<div class="alert alert-info mt-4e">
  <p>If you're interested, here are some of <a href="/projects/index.html">my other projects</a>:</p>

  <ul>
    <li><a href="/projects/fantasy-sportsbook.html">Fantasy Sportsbook</a></li>
    <li><a href="/projects/now-streaming-email.html">"Now Streaming" Email</a></li>
    <li><a href="/projects/remifi-remote-controlled-browser.html">Firefox Remote Control</a></li>
    <li><a href="/projects/fixing-craigslist.html">Fixing Craigslist</a></li>
  </ul>
</div>
