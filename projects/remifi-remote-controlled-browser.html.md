* [Introduction](#introduction)
* [The Problem](#the-problem)
* [The Solution](#the-solution)
  * [Embedded Web Server](#embedded-web-server)
  * [Dashboard](#dashboard)
  * [Searching and Navigating](#searching-and-navigating)
  * [Tabs and Windows](#tabs-and-windows)
  * [Mouse and Keyboard Controls](#mouse-and-keyboard)
  * [Bookmarklets](#bookmarklets)
* [Wrap-Up](#wrap-up)

## [Introduction](#introduction)

I bought a big new flatscreen television around 2009 and wanted to watch streaming Internet video on it. These videos went beyond Netflix and Hulu, which produced custom integrations for game consoles and dongles. I wanted access to __all Internet video__, and Adobe Flash was still king, making the web browser an important part of my goal.

## [The Problem](#the-problem)

Using an adapter and HDMI cable, I connected an old Mac Mini to my television, but web browsers and Flash video players were aimed at the mouse and keyboard, which aren't practical for 10-foot interfaces (someone should have told that to [Google TV](http://en.wikipedia.org/wiki/Google_TV)). On the other hand, I could easily spend a couple hours on my couch browsing the web on my iPhone, but I just didn't like watching videos on it. __How could I display Flash video on my big TV but interact with it like my iPhone?__

## [The Solution](#the-solution)

I would make an interface for controlling my computer's web browser with my iPhone. As you can imagine, easier said than done.

### [Embedded Web Server](#embedded-web-server)

The first step was establishing how my iPhone would communicate with my web browser. Being a web developer, HTTP seemed like the obvious answer, and I found [POW (Plain Old Webserver)](https://addons.mozilla.org/en-US/firefox/addon/pow-plain-old-webserver/) which embedded a javascript-based HTTP server inside a Firefox plugin, so it was possible!

I pulled what I needed out of POW and [wrote a simpler version in Coffee-script](https://github.com/topdan/remifi-firefox/blob/master/content.coffee/remifi/firefox/server.coffee) that responded to HTML requests and served static images, scripts, and stylesheets. [Apple's Bonjour](http://en.wikipedia.org/wiki/Bonjour_%28software%29) made it possible to avoid exposing IP addresses: my web browser would now respond to samuel.local:4000

### [Dashboard](#dashboard)

![Dashboard](dashboard.jpg)

1. Back one page
2. Forward one page
3. Open "Searching and Navigating"
4. Open "Tabs and Windows"
5. Open "Mouse and Keyboard Controls"
6. Open "Dashboard"
7. Navigate to a common streaming video website

### [Searching and Navigating](#searching-and-navigating)

![Searching and Navigating](searching-and-navigating.jpg)

1. Search Google
2. Go to an explicit web address

### [Tabs and Windows](#tabs-and-windows)

![Tabs and Windows](tabs-and-windows.jpg)

1. Switch to a different tab. Swipe to close.
2. Open the browser's current webpage on your iPhone.
3. Open a new tab.
4. Switch to a different window. Swipe to close.

### [Mouse and Keyboard Controls](#mouse-and-keyboard)

![Mouse and Keyboard](mouse-and-keyboard.jpg)

1. Move the mouse around your television.
2. Left click the mouse.
3. Move the mouse a little bit up, down, left, or right.
4. Open the Keyboard interface that lets you hit return, escape, and input text.
5. Scroll the current page up a large amount.
6. Scroll the current page down a large amount.

### [Bookmarklets](#bookmarklets)

The above functionality manages the web browser, but it's still basically a 10-foot interface. By creating a [bookmarklet](http://en.wikipedia.org/wiki/Bookmarklet), you can push the webpage on your iPhone to your computer's browser and full-screen the video with the mouse controls. __You browse 100% on your phone and watch 100% on your TV.__

## [Wrap-Up](#wrap-up)

I spent some time polishing up the Firefox plugin and named it [remifi](http://www.remifi.com) (REMote-control over wIFI), but overall lacked the drive to market or expand. Since then the streaming video options have grown: Apple TV3, Airplay, Google TV, Roku, Chromecast, and Fire TV, but __remifi still sits as my way of watching Internet video and reigns as my most-used, longest-lasting personal creation__:

* Many sites still require Adobe Flash
* Airplay is blocked by several apps
* Airplay drains your battery and has occasional issues multitasking
* Apple TV content costs ~$1 more than most
* 10-foot interfaces still smell

```raw
<p class="alert alert-info mt-2e">
  You can review the source code on <a href="https://github.com/topdan/remifi-firefox">github</a> and watch the demostrations at <a href="http://www.remifi.com">remifi.com</a>.
</p>
```
