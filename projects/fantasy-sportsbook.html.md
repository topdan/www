* [Introduction](#introduction)
  * [Downsides of Sportsbooks](#downsides-of-sportsbooks)
  * [Downsides of Fantasy Football](#downsides-of-fantasy-football)
* [The Rules](#the-rules)
* [Screenshots](#screenshots)
  * [Dashboard](#dashboard)
  * [Leaderboard](#leaderboard)
  * [Balancesheets](#balancesheets)
  * [Placing a Bet](#placing-a-bet)
  * [Placing a Parlay](#placing-a-parlay)
  * [Mobile Web App](#mobile-web-app)
* [Wrap-Up](#wrap-up)

```raw
<div class="alert alert-error">
  <p><span class="label label-important"><i class="icon-exclamation-sign">&nbsp;</i> Disclaimer</span> Fantasy Sportsbook does not involve any money and nothing of value is ever wagered. All "points" are imaginary and how leagues may or may not award winners at the end of the season is entirely up to them and completely independent of Fantasy Sportsbook.</p>

  <p class="punchline"><strong>Fantasy Sportsbook is not a gambling site.</strong></p>
</div>
```

## [Introduction](#introduction)

Every fall, football fans dive into two different games: one on the field and one online. Both benefit from the other. The online game comes in two varieties: sportsbooks and fantasy football. For different reasons, I stay away from both, but I can't go out and watch a football game without hearing _a lot_ about both, so I borrowed my favorite elements from each to create a new game called __Fantasy Sportsbook__.

### [Downsides of Sportsbooks](#downsides-of-sportsbooks)

Whether at a casino or online, sportsbooks rake in money. They create lines to entice bets and guarentee their bottom-line all while charging a price to play ([the juice](http://en.wikipedia.org/wiki/Vigorish)). The more people playing: the more money they make, and because the odds are stacked against the better, the more you play: the more likely you lose. And when you lose, your money disappears into a faceless giant.

Unless you and your friends bet on the same game, sportsbooks also lack shared experience and competition. It's your money and your agony/joy. Onlookers may be impressed by [your large bets](http://grantland.com/the-triangle/floyd-mayweather-suffers-his-first-defeat-at-the-sportsbook/) but unless they share your payout, they don't share your experience.

### [Downsides of Fantasy Football](#downsides-of-fantasy-football)

On the other side, fantasy football thrives on shared experience: people grouped together in friendly competition. If an NFL game is on, everyone has someone to cheer for or against and a friend to brag to later, but its landscape is lopsided to the beginning of the season. Have a good draft: have a good year. All but a handful of players are eliminated on or before week 13, and it's finished before the actual playoffs begin. __Fantasy Football players are more excited about Week 1 than the Super Bowl.__

Also, drafting and cheering for individual players is off-putting inside a team-driven sport like football, and fantasy football simply doesn't work for college football's large number of players with incredibly mismatched talent.

## [The Rules](#the-rules)

You can probably see where I'm going: people grouped together in friendly competition betting imaginary "points". Here are the rules:

* Upon joining the league, a player is provided 10,000 points
* Players can bet these imaginary points on a handful of different results
* Players can group these bets to exponentially steadily increase the points they could earn
* To encourage betting, there's no juice and leagues can increase the payouts
* Players can view everyone's finished/pending bets as well as the current leaderboard
* Since players can see one another's bets, players are allowed to cancel a bet before they start with a minimal penalty.
* At the end of the season, the player(s) with the most points wins

It's that simple. If leagues want to award the winner(s) a prize, they can but it's their choice and completely separate from Fantasy Sportsbook. __Nothing of value is ever bet or gambled on Fantasy Sportsbook.__

## [Screenshots](#screenshots)

Since football season hasn't started yet, I'm beta testing the application with Major League Baseball, but the design works the same for any sport. In the following screenshots, features are numbered in red and referenced in the explanations underneath.

### [Dashboard](#dashboard)

![Dashboard of Upcoming Games](dashboard-upcoming.png)

1. Your current place among all the players
2. Your available point balance
3. View completed games and bets
4. The game's bets: your bets are blue, gray bets are closed, black bets are open
4. Game status or game start time
5. Total number of bets involving this game among all players

![Dashboard of Finished Games](dashboard-finished.png)

1. Wagers for this game: wins are green, losses are red, pushes are orange.
2. Game status
3. Number of winning, losing, and pushed bets among all players
4. Hide the completed games and just view in-progress or future games

### [Leaderboard](#leaderboard)

![Leaderboard](leaderboard.png)

1. Remaining available points
2. Points placed on pending bets
3. Balance + Pending. This number determines your rank.

### [Balancesheets](#balancesheets)

To provide transparency and an explanation of why someone is winning and others are badly losing, the application displays every change that occurs to someone's balance.

![Balance](balance.png)

1. Reason for the change
2. Amount of the change. Spending points is red. Gaining points is green.
3. The remaining balance

### [Placing a Bet](#placing-a-bet)

1. Select the game
2. Select the terms
3. Set the bet
4. Place the bet

![Placing a Single Bet](placing-single.gif)

### [Placing a Parlay](#placing-a-parlay)

A parlay groups multiple bets together, exponentially raising the payout also making them more difficult to win.

1. Select a game
2. Select the terms
3. Select more games and terms (watch the payout grow)
3. Set the bet
4. Place the bet

![Placing a Parlay Bet](placing-parlay.gif)

### [Mobile Web App](#mobile-web-app)

The application is not a native "iPhone Application", but it can behave like one by using the "Add to Home Screen" action.

![Mobile Web App](mobile-web-app.gif)

## [Wrap-Up](#wrap-up)

I'm proud of the mobile interface: lots of information cleanly displayed in a small space. Placing bets is simple and hopefully not prone to error. If I ever make it public, I'll likely remove the logos and limit references to trademarked names.

I'm looking forward to seeing if it helps the casual fan become more interested in games and whether seasoned bettors receive a reasonable thrill while limiting their overall risk and losses. It should be a fun season of football.

```raw
<p class="alert alert-info punchline"><strong>If you're going to lose, lose to your friends.</strong></p>

<p class="copyright">Images and logos used in the screenshots on this page are property of Major League Baseball</p>
```
