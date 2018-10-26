# RELEASE NOTES for v 0.41.2 10/25/2018

Fixed a rare but troublesome bug that had been occurring for some time. It turns out that the MT4 infrastructure would very occasionally return an error when selecting an order to get its current status, and the error was not being checked for.  This resulted in invalid status being returned, and ultimately resulted in attempts to manipulate an order with a zero trade ID, which is invalid.

## WARNING when using Range Lines:

Do NOT change the period of the chart (e.g. from M15 to M5, or to M30) if you have an active order that resulted from a range breakout.  The change in the candle size is seen by the program as the start of a new candle, and triggers the logic to check for "close back inside range" conditions, and may result in the order being erroneously closed.

# RELEASE NOTES for v 0.41.1 8/28/2018

This release adds some new features and makes some very significant improvements to existing features.

## Range Lines

The pending orders that are set when you click the "Draw Range Lines" button (if you have SetPendingOrders enabled) will now be automatically cancelled with 2 minutes to go in the candle to avoid a pending order being triggered in violation of the "Two Minute Rule" (no range break out trades are to be taken during the final two minutes of a candle).  Orders that are cancelled by this feature will be automatically re-set at the opening of the next candle.  This feature is controlled by the "ObserveTwoMinuteRule" configuration variable.

Orders that have been set by pressing the "Draw Range Lines" button, but were then manually deleted, are not re-set at the start of the next candle.

Realizing that there might be occasions where you want to prevent orders from being re-set (e.g., when a news event is coming up and you don't want to risk a pending order being taken in by a news spike), but when the pending orders have already been canceled by the TwoMinuteRule, I have changed the function of the Draw Range Button during the Two Minute interval.  At the time the pending orders are canceled, the "Draw Range Lines" button changes to a yellow background, and it's legend changes to "Cancel Range Lines".  If the button is clicked while it is in this state, it wil remove the range lines that have been set (the pending orders have already been canceled), and will prevent the orders from being re-set.

In addition, trades that are entered as a result of a pending order on a range breakout being executed will be checked at the start of each candle for being back inside the range that it broke out of (a condition known as CBIR - Closed Back Inside Range).  If so, the trade can be automatically closed (if the AutoCloseOnCBIR configuration variable is set) or an alert will be issued (if AlertOnCBIR is set).  If neither variable is set, the check is not performed. Trades that close on the line will result in an alert being issued and will not be automatically closed.

## Screen Capture

There is a slightly breaking change to the way ScreenShot Capture files are handled.  In prior versions, all such files were saved directly to the Files directory in the MQL4 Data Folder tree.  Now, there is a screen shot root directory named "ScreenShots" added to the Files directory, and all ScreenShots are saved in this directory or a subdirectory underneath it, as described before.

There is a new configuration variable named "SortScreenShotBy".  The valid values are "None", "Date", and either "Pair" or "Symbol" (which are synonymous, but I couldn't decide which made more sense, so I decided to accept them both.

If the value is "None", then all screen shots are saved in the Files\ScreenShots directory with no organization. If the Date option is used, then a series of directories are added to the ScreenShots directory to mirror the date. There is a directory for the year (e.g., 2018), one for the month using a two-digit month number, a hyphen, and a 3 character English month abbreviation (e.g. "08-AUG"), and finally, a directory for each day of the month that the Trading Assistant is running, using a two digit number.  All trades that are taken on that day will appear in the corresponding folder. So, as I write this, it's August 28, 2018.  Today's trades are in Files\ScreenShots\2018\08-AUG\28.

If the value of the SortScreenShotsBy variable is set to Pair or Symbol, then one directory will be created under the File\ScreenShots directory for each pair, and all screen shots captured for a given pair will be stored in that pair's directory.

Note that, since the configuration variables are set for each pair that the trading assistant is running on, it is possible to mix these schemes, though I can't see a reason for it and it might be a little confusing.

Secondly, one of the drawbacks to using auto-captured screen shots that I noted in the User's Guide is that the files can accumulate unnoticed and fill up your disk. This release adds a configuration variable "DaysToKeepScreenShots". If this is set to a non-zero value, then at the end of each trading day, a routine will run through the ScreenShots directory and all subdirectories recursively, and delete any screen shot file that is found that was created more than that many days ago. Again, this routine is running for each pair, and will only delete screen shots for that pair.  In order to be deleted, the file must be a leaf file (i.e., not a directory), must contain the pair name in its file name, it's file name must end in ".PNG", and today's date (using your server's idea of the date) minus the file creation time (which is established by your computer clock) must be greater than the value of the configuration variable.  This routine runs as part of the end-of-day cleanup, so the MetaTrader platform and the PATI Trading Assistant EA must be left running till the end of the day for it to run.

There are also some minor enhancements. In the past, most processing takes place on each incoming tick of the price data.  I have observed some pairs, notably the Australian Dollar and New Zealand Dollar pairs, that, at certain times of the day are very slow moving, and may sometimes go as much as 30 seconds or more between ticks, which means that no processing takes place during that time.  Realizing that there are now some time-sensitive operations being performed (i.e., canceling pending orders at the 2 minute mark), I didn't want to risk being frozen out.  So the tick processing is now called once a second whether there has been any change in the price data or not.  Also, in response to a request from a user, I have added configuration variables to control the color and size of the label boxes at the end of the Range Lines.
# RELEASE NOTES for v 0.34.2 8/22/2018

This is a very minor release with a fix for a minor issue that I discovered in v 0.34 (and v 0.34.1), and a minor enhancement suggested by user Tim Black (@IsItCoffeeYet) that allows control of the size of screen shot captures.

The design for the "Draw Range Lines" feature was to have the line drawn extend to the end of the New York session, i.e., approximately 5:00 PM Eastern Time. At the time I implemented it, I was using a server that was set to New York time, and the implementation worked as expected. I recently switched to a server that was set to GMT, and discovered that my range lines were ending at around noon local time, and, occassionally, disappearing almost completely.  Since determining what time zone the server time is running is tricky, I implemented a work around in v 0.34.2 that makes sure that the line is drawn at least 5 hours past the current candle. 

In the earlier implementations of the ScreenCaptureFiles feature, the chart height and width as displayed on the terminal was used for the capture file.  Tim Black pointed out that you can specify the pixel width and height of the area to be captured at run time independent of the area displayed on the terminal. Version 0.34.2 adds two new integer Configuration variables, "ScreenShotHeight" and "ScreenShotWidth". If those variables are 0, then the actual chart height and width will be used.  If they have a value, then the height and width of the captured file will be set to those values. This allows capturing wide screen images even if you're not using that much screen real estate in your display.

# RELEASE NOTES for v 0.34.1 10/15/2017

This release has fixes for a couple minor bugs that slipped out in v 0.34

## Missing "Draw Range Lines" Button 

In v 0.34, if the Trading Assistant is left running overnight, the end-of-day clean up routine will remove the "Draw Range Lines" button when it cleans up everything else.  The bug fix redraws it after the clean up.

## Non-integer Range Line Margins got rounded down to integers

The configuration variable for "MarginForPendingRangeOrders" is a value intended to take fractional numbers (a double in computer programming terms), but, in v 0.34, if non-integer values were used, the result was as though the next smallest integer value had been input.  For example, entering a value of 1.5 would result in a pending order 1.0 pips away from the range.  This release fixes that bug.

# RELEASE NOTES for v 0.34 9/2/2017

This enhancement adds a new feature that, on command, will draw horizontal line at the High and Low of the day (HOD/LOD) as an aid in recognizing and responding to Range Breakouts (RBO's).  It also draws a Right Price Arrow to the right of the line giving the range. The HOD/LOD calculation takes into account a new configuration variable, BeginningOfDayOffsetHours, to offset the start of day from your server's clock.  The calculation extends up to BUT NOT INCLUDING the current open candle.

Computation and display of the range lines takes place when a new button labeled "Draw Range Lines", in the lower left of the chart, is clicked.

When the button is clicked, there is also the option, via configuration variable "SetPendingOrdersOnRanges", to set pending orders at or just outside the range limits.

The release also resolves an issue recently discovered with some brokers (notably, in my experience, OANDA) that handle a triggered pending order by canceling the pending order and creating a new order, with a new trade id, as a market order. Because the trade id is different, the trading assistant was not following the relationship to the original pending order, and was failing to, first of all, even recognize the new order, and secondly, to adjust the stops from the pending order if the active order was entered at a slightly different price (due to market slippage).  This required a change to the NewTradeIndicator to scan the entire array of orders on each clock tick, and there is a new configuration variable, "ScanAllTradesEveryTick" in NewTradeIndicator version 0.33 to enable this behavior.  With this configuration variable set false, it will only scan for new trade id's when there is a change in the total number of trades open orders. This variable should also be set true if you use the SetPendingOrdersOnRanges feature described above.

Finally, this release allows automatically capturing a screen shot of the chart at the moment a new trade goes active.  The screen shot is a PNG file stored in the "Files" folder (reached via the File->Open Data Folder menu item, then navigating to MQL4\Files).  The file has a filename representing the calendar day and time of day (to the minute), followed by the pair symbol, an 'L' for a long trade or an 'S' for a short trade, and a sequence number of that type trade for that pair on that day. (E.g., "2017.06.08 09_21_USDJPY L1" )  This feature is enabled by the boolean "CaptureScreenShotsInFiles" configuration variable.

# RELEASE NOTES for v 0.33 12/23/2016

The enhancement in this version is that, if selected, stops and take profit limits will be added to Pending Orders as well as active orders.

In this way, if you lose the internet connection to your broker after placing your pending order but before the order is triggered, your order will still be protected by a stop loss and take profit limit placed as quickly as possible after the pending order is placed.

Note that the stop loss point and take profit point are set based on the trigger point.  When the order is activated, the stop loss and take profit limit will be adjusted based on the actual entry price. (This behavior is controlled by configuration variables.)

# RELEASE NOTES for v 0.32 11/7/2015
This is the first of a series of planned releases that will make some enhancements to the existing PATI Trading Assistant.

The principal enhancement in this version is that the restriction of only one active trade/order per pair is removed.  This is a BREAKING CHANGE, and requires that v0.32 of the NetTradeIndicator be used with version 0.32 of the PATITradingAssistant.

The motivation is a couple scenarios in which the one active trade restriction caused a problem.
	1) If you had a pending trade in place and then entered a market order without first removing the pending trade, the market order would not be recognized.
	2) The restriction meant that you could not enter two simultaneous pending orders for breakouts at the top and bottom of a range, or at the top and bottom of the "No-Entry Zone".  These situations can now be accommodated with no problems.

# RELEASE NOTES for v 0.31 4/1/2015

This release fixes a bug in which, if the EA was re-initialized (as by changing the period on a chart, changing parameters, or re-starting the EA) while trades were open trades, it would reset the Stop Loss and Take Profit to calculated values regardless of how they might have been changed.

It also adds some minor feature updates:

1. In the alert message on closing a trade, it will indicate net profit or loss for the trade in pips.
2. If you create a saved configuration file and then rename it to remove the symbol name (e.g. from "PTA_EURUSD_Configuration.txt" to "PTA__Configuration.txt", that file will then become a "global" configuration file that will be applied to all charts before applying any pair-specific configuration file.

PATITradingAssistant
====================

A MQL4  (forex) expert adviser to assist with some bookkeeping after entering a trade

# Introduction
When entering a trade in a fast moving forex market, I often found that taking the time to execute several "bookkeeping" actions that needed to be done right after a trade was entered often took my attention away from other potential setups.

This trading assistant will monitor open trades on your account. It was specifically built to implement some of the style and conventions taught by the Price Action Traders Institute (PATI).

When it detects a new trade, it will do the following:

1. Set your stop loss the appropriate number of pips (according to the PATI rules).
2. Add an arrow at your entry point
3. Set your take profit at the next level.

In addition, on detecting that a trade has been closed, it will

4. Add a right arrow at the exit, and draw a line between entry and exit arrows
5. If the trade resulted in a loss, it will add a "no-entry" rectangle, indicating the zone in which you cannot make a new entry.

All these actions are configurable.

Beginning in Release v.34, it adds a feature that, on command (by clicking a button), it will find the high and low for the current day, and draw range lines on the chart, and, optionally, set pending orders at those levels.  Beginning with Release 0.41, it will cancel those pending orders with two minutes to go in the candle, and then re-set them at the start of the next candle. It can also auto-close or alert if the candle closes inside the range.

Beginning in Release v.34, it can automatically save a screen capture file of the chart when the trade is executed. Beginning with Release 0.41, it can sort those screen shots into directories, either by date or by the pair name, and can purge screen shot files older than a configurable number of days in order to keep from taking up too much disk space.


# Installation:

The Trading Assistant has 2 components:

1. The "New Trade Indicator" (NTI)  which is an indicator (not expert advisor) that needs to be run on ONE AND ONLY ONE chart in your MT4 platform.
It works off a one-second interval timer, not off ticks, so which chart it's placed on doesn't matter.  Its function is to monitor for new trades and closed trade across the entire account.
2. The PATITradingAssistant (PTA) which is an expert advisor that needs to run on each pair that you trade.  
It will monitor the global variables set by NTI and detect when you have entered a new trade for that pair.  It will then execute the configured actions. 
Although it is not entering trades, it is modifying them (in order to set stop loss and take profit), so it needs to have AutoTrading enabled.

To install the Trading assistant,

1. Open your MT4 platform.
2. Click on File -> Open Data Folder menu item, then open the MQL4 directory under your platform specific data directory
3. Copy the NewTradeIndicator.ex4 to the MQL4/Indicators directory.
4. Copy the PATITradingAssistant.ex4 to the MQL/Experts directory.  
5. Restart MT4, open the Navigator under the View menu, and drag the NewTradeIndicator from the Indicators folder onto any ONE chart, and drag the PATITradingAssistant from the Experts folder onto each chart that you intend to trade.
6. In the Expert configuration dialog box that comes up for the PATITradingAssistant, click the Common tab, and make sure that "Allow Live Trading" is checked. (Alternatively, go into the Tools -> Options menu of the MetaTrader4 platform, navigate to the Expert Advisors tab, and check the "Allow Automated Trading" box.  This will then apply to all Expert Advisors added after that point.) Also verify that "Auto Trading" button in the toolbar of the MetaTrader4 platform has been clicked. (It should show a green dot in the icon, not a red one.)

# Configuration

## NewTradeIndicator:

There are three configuration variables in the NewTradeIndicator: Testing and PairOffsetWithinSymbol.

<dl>
<dt>Testing</dt> <dd>is a variable that allows development-level testing.  It should be set to false.  Setting it to true will keep the indicator from completing its initialization, and execution will terminate immediately after completing the tests. The default value is false.</dd>

<dt>PairOffsetWithinSymbol</dt>
<dd> should normally be 0, unless your broker adds a prefix to the symbol name to indicate a special account designation.  Most brokers simply return the pair name (e.g. "EURUSD") as the symbol, but some either prepend or append some designator to the pair name to indicate something characteristic of the account or trade (e.g. 'm' to denote a mini account).  If such a designator is post-fixed to the symbol (e.g. "EURUSDm"), it gets handled automatically, but if it is prefixed (e.g., "mEURUSD", we need to know how many characters to take off the front of the symbol in order to get the pair name. The default value is 0.</dd>

<dt>ScanAllSymbolsOnEachTick</dt>
<dd> If set to false, the list of open orders is retrieved from the server only if there has been a change in the total number of open orders since the last clock tick.  This reduces the amount of network traffic to and from the server. However, it makes you vulnerable to missing a trade if there is a closed or canceled trade and an offsetting new trade in the same clock tick (one second).  If set to true, the indicator will get the entire list of open trade ids on each clock tick. (See release notes for v0.34. The default is true.
</dd>
</dl>


## PATITradingAssistant:

There are numerous configuration variable for the Trading Assistant in order to allow configuration of the different actions according to your preferences. In v.0.34, the variables were re-ordered to place them in logical groupings.  The order they are presented here reflects the new order.
### General

<dl>
<dt>Testing</dt> <dd>Same function and description as under NewTradeIndicator.</dd>

<dt>PairOffsetWithinSymbol</dt> <dd>Same function and description as under NewTradeIndicator.</dd>

<dt>AlertOnTrade</dt> <dd>this is a boolean variable that determines whether to raise an alert on detecting a trade entry and trade exit. The alert was originally put in as a debugging feature during development, but I decided I rather liked it as confirmation. Note also that the message displayed in the alert on trade exit includes the actual gain/loss in pips.  I recognized that it may get annoying though, so you have the capability to turn it off.  Default value is true.</dd>

<dt>MakeTickVisible</dt> <dd>This boolean variable can normally be ignored. It aids in debugging by displaying a message on each tick that is received to confirm that the Trading Assistant is still operating. Default value is false.</dd>

<dt>SaveConfiguration</dt> <dd>I have often found, when using an EA, that there are a few values that I consistently want to set different from the default values.  Unless I have access to the source code (and want to go to the trouble of rebuilding the EA), I have no choice but to enter those values every time I start the EA. Setting this variable to true will copy out each of the configuration variables to a file in the Terminal's Files area.  On subsequent startups, this configuration file will be read and those values used in place of whatever is set in the settings dialog. If you want to start without using the configuration file after you have saved it, simply go into the Files area (by using the File -> Open Data Folder menu item, then navigating down the MQL\Files.  The file is named "PTA_&lt;symbol>_Configuration.txt".  You can delete that file (in which case you will have to save the configuration again if you want to use it), or rename it to something else (in which case you can rename it back the next time you want to use it). Since the file is an editable text file, you can also edit and change the values in the file itself.</dd>

</dl>
### Configure Stop Loss Levels
<dl>
<dt>DefaultStopPips</dt> <dd> For any pair not listed in the Exceptions variable (see below) this variable gives the number of pips away from the entry that the stop loss will be set. Default value is 12.</dd>

<dt>Exceptions</dt>  <dd>This is a string variable that lists any pairs that have a different stop loss from the Default.  The format is a list of one or more pair names separated by commas, then followed by a forward slash ('/') and the number of pips that becomes the stop loss for that pair or pairs.  This can then be followed by a semicolon and another list and value.  The default value is  "EURUSD/8;AUDUSD,GBPUSD,EURJPY,USDJPY,USDCAD/10", which will set an 8 pip stop for the EURUSD, a 10 pip stop for the AUDUSD, GBPUSD, EURJPY, USDJPY, and USDCAD.  All other pairs will use he value of DefaultStopPips (12).  This is in keeping with the current PATI rules at the time of the first implementation of the PATI Trading Assistant. If you choose to trade other pairs, or the set of pairs traded by PATI is modified after the trading assistant is released, you may want to modify this value.</dd>

<dt>SendSLandTPToBroker</dt> <dd>this is a boolean variable that determines whether or not to actually send the calculated values for stop loss and take profit to the broker automatically. If true, an order modification is sent with the calculated values using the "OrderReliable" package that will detect retryable errors and retry up to ten times if an error occurs.  The default value is true.</dd>

<dt>SetLimitsOnPendingOrders</dt> <dd> Added in version 0.33, this boolean variable determines whether or not the trading assistant will modify a pending order by adding stop loss and take profit limits to the order.  If false, the order is left unmodified.  Default is true. </dd>

<dt>AdjustStopOnTriggeredPendingOrders</dt> <dd>Added in version 0.33. When a pending order is entered, stop loss and take profit points are calculated based on the trigger price of the pending order.  When the order is actually triggered, the entry price may be different, sometimes substantially different, than the trigger price due to slippage.  If this variable is true, the trading assistant will modify the order and send new stop loss and take profit points based on the actual entry price. Default is true.</dd>

</dl>
### Configure Trade Display
<dl>

<dt>ShowEntry</dt> <dd>this is a boolean variable that determines whether or not to show an arrow indicator at the entry point to a trade.  The arrow will be blue. (See also EntryIndicator.) The default value is true.</dd>

<dt>ShowInitialStop</dt> <dd>this is a boolean variable that determines whether or not to show an arrow (a small red dash) at the level of the initial stop setting.  The default value is true.</dd>

<dt>ShowExit</dt> <dd>this is a boolean variable that determines whether or not to show an arrow indicating the exit price and time when a trade closes.  (See also EntryIndicator, WinningExitColor, and LosingExitColor.) The default value is true.</dt>

<dt>ShowTradeTrendLine</dt> <dd>this is a boolean variable that determines whether or not draw a trendline from the entry point to the exit point upon exiting a trade. (See also TradeTrendLineColor.) The default is true.</dd>

<dt>EntryIndicator</dt> <dd>This is an integer variable that gives the MQL4 arrow code to use for entry (and exit by implication) arrows, if used. The only values that I have found that make sense are 2 (the default), and 5. 2 will draw a small right-facing arrow at the entry, while 5 will draw "Left Price Label" arrow with the numeric price shown in the arrow.  For the exit arrow, the next higher arrow code is used (3 or 6). 3 will draw a small left-facing arrow to the right of the exit point, while 6 will draw a "Right Price Label" arrow with the exit price shown in the arrow box. If ShowEntry and/or ShowExit are false, this value has no effect.The default value is 2.</dd>

<dt>WinningExitColor</dt> <dd>This is a color variable that sets the color that the Exit trade indicator will be drawn in if the trade resulted in positive pips.  The default is Green.  If ShowExit is false, the value has no effect.</dd>

<dt>LosingExitColor</dt> <dd>This is a color variable that sets the color that the Exit trade indicator will be drawn in if the trade resulted in negative pips.  The default is Red. If ShowExit is false, the value has no effect.</dd>

<dt>TradeTrendLineColor</dt> <dd>This is a color variable that sets the color that the TradeTrendLine will be drawn in. The default is Blue.  If ShowTradeTrendLine is false, this value has no effect.</dd>

</dl>
### Configure No-Entry Zone
<dl>

<dt>ShowNoEntryZone</dt> <dd>this is a boolean variable that determines whether or not to display the "NoEntry" rectangle following an exit that loses pips.  The NoExitZone will be a rectangle extending from the current time to the end of the day, and from the "next level" above and below the trade entry. (See also MinNoEntryPad and NoEntryZoneColor.) Default value is true.</dd>

<dt>NoEntryZoneColor</dt> <dd>This is a color variable that sets the color that the NoEntryZone will be drawn in.  The default is DarkGray. If ShowNoEntryZone is false, this value has no effect.</dd>

<dt>MinNoEntryPad</dt> <dd>This a double value that represents the minimum distance in pips that the entry price has to be away from the "next level" when establishing the "NoEntryZone".  If the entry price is closer than that to a level, the "next level" chosen for the NoEntry rectangle will be one level beyond that. As an example, if you have a losing trade in the EURUSD with an entry price of 1.0612, which is 8 pips from the next level up of 1.0620, and the MinNoEntryPad is set at the default of 15, then the top of the NoEntry rectangle will not be at 1.0620, but at the next level, 1.0650.  Default value is 15 pips. If ShowNoEntryZone is false, this value has no effect.</dd>

</dl>
### Configure Take Profit Levels
<dl>

<dt>UseNextLevelTPRule</dt> <dd>this is a boolean (true/false) variable that determines whether or not to set a Take Profit (TP) that implements the "Exit at the next level" PATI objective take profit setting. (See also MinRewardRatio.) Default value is true.</dd>

<dt>MinRewardRatio</dt> <dd>When setting the "Next Level" take profit price, it makes no sense to set it so close to the entry that there is not sufficient reward-to-risk ratio.  For example, if you have entered a long trade on the EURUSD at 1.0618, technically, the next level would be 1.0620.  But that would only result in a 2 pip profit, compared to a 8 pip risk.  That is hardly the recipe for a profitable strategy.  This variable takes the stop loss pips that is used for the pair, multiplies that by this factor, and sets that as the minimum take profit target. If the "next level" is less than this value, it sets the TP target one more level up.  Thus, in our example, since EURUSD uses an 8 pip stop (by default), using the default MinRewardRatio, we would be looking for minimum TP target of 12 pips, 1.0630.  The next level above this is 1.0650, which is where the TP would be set. The default value is 1.5. If UseNextLevelTPRule is false, this value has no effect.</dd>

</dl>
### Configure Draw Range Lines feature
<dl>

<dt>ShowDrawRangeButton</dt> <dd>If true, the button controlling the Draw Range Lines feature is drawn in the lower left corner of the chart. If false, the button is not drawn, and the feature is inaccessible. Default value is true.</dd>

<dt>RangeLinesColor</dt><dd>This color variable sets the color that will be used to draw the high and low range lines. Default value is Yellow.</dd>

<dt>RangeLineLabelColor></dt><dd> [Added in Release 0.41.1] Specifies the color of the Right Price Arrow (label) that is drawn at the right end of the range lines. Default is Blue.</dd>

<dt>RangeLineLabelSize</dt><dd> [Added in Release 0.41.1] Specifies the size of the Right Price Arrow (label) that is drawn at the right end of the range lines. This should be a small positive integer.  Default value is 1. </dd>

<dt>SetPendingOrdersOnRanges</dt><dd> If true, pending orders will be placed at or just outside (see MarginForPendingRangeOrders below) the calculated ranges immediately after the ranges are drawn. At the same time, it will cancel any existing Buy Stop or Sell Stop orders because the newly placed range orders will replace them. In this way, it is safe to simply click the "Draw Range Lines" button again to re-calculate range limits and re-place the corresponding orders without having to first cancel the existing orders. The default value is false.</dd>

<dt>MarginForPendingRangeOrders</dt><dd>If SetPendingOrdersOnRanges is true, this variable determines the number of pips outside the calculated ranges that the pending orders will be placed. This allows you to wait for the price to actually come through the limit, rather than just touching it, before triggering your order.  The value can be set to 0.0 to trigger the order if the limit is touched, and, technically, could be set to a negative number to trigger the order before the limit is reached.  The default value is 1.0.</dd>

<dt>ObserveTwoMinuteRule</dt><dd> [Added in Release 0.41] If SetPendingOrdersOnRanges is true, any existing pending orders set by the drawing range lines will be cancelled with two minutes left in the candle, and then re-set at the start fo the next candle.  If a pending order is manually deleted before the two minute point, that order will not be re-set. At the two minute mark, the "Draw Range Lines" button will be changed to a "Cancel Range Lines", with a yellow background.  If that button is clicked, the range lines will be removed, and the pending orders that were cancelled will not be re-set. The default value for this variable is True.</dd>

<dt>AutoCloseOnCBIR</dt><dd> [Added in Release 0.41] For any trades that resulted from pending orders set by drawing range lines, the Trading Assistant will check at the start of each candle, and, if the bid price has fallen back inside the range, the order will be automatically closed. If the price closes "on the line" (i.e., equal to the range limit), an alert will be issued and the trade will NOT be closed. The default value for this variable is True.</dd>

<dt>AlertOnCBIR</dt><dd> [Added in Release 0.41] For any trades that resulted from pending order set by drawing range lines, the Trading Assistant will check at the start of each candle, and, if the bid price has fallen back inside the range, it will issue an alert. The default value for this variable is False.</dd>

<dt>AccountForSpreadOnPendingBuyOrders</dt><dd>If SetPendingOrdersOnRanges is true, this variable determines whether you add the spread to the calculated Buy Stop trigger price at the top of the range. If set false, it would cause the order to be triggered if the Ask price touches the limit (plus the designated margin described above). However, the calculated range is based on the Bid price, so this would result in your order be triggered before the bid price actually reached the limit. Note: the spread is taken into account at the time the pending order is set.  The pending order price is not adjusted for changes in the spread after the order is set. The default value is true.</dd>

<dt>PendingLotSize</dt><dd>If SetPendingOrdersOnRanges is true, this variable determines the number of lots that the pending order will be set for. If the value is 0.0, it will attempt to find the number of lots used on the last order for this pair, and use that.  The default value is 0.0.</dd>

<dt>CancelPendingTrades</dt><dd>If this variable is true, when a pending order is triggered, it will automatically cancel all other pending trades in the same direction, to prevent the possibility of their being triggered and resulting in double execution. This actually applies to all trades, not just those entered as a result of drawing range lines. The default value is true.</dd>

</dl>
### Timing Related Configuration
<dl>
<dt>BeginningOfDayOffsetHours<dt>
<dd>This variable will offset the beginning of the day from your broker's clock.  This offset is used in calculating the High of the day and Low of the day (HOD/LOD) when drawing range lines.  Default value = 0 </dd>

<dt>EndOfDayOffsetHours</dt> <dd>Added in version 0.33, this variable alters the time at which the trading assistant will "clean up" the various graphic elements it may have added to the chart (arrows, boxes, trendlines, etc.)  It also adjusts the right edge of the "No Entry Zone" rectangle if that is in use.</dd>

</dl>
### Screen Shot Capture Configuration
<dl>
<dt>CaptureScreenShotsInFiles</dt><dd> [Added in Release 0.34] If set to True, the Trading Assistant will capture a screen shot file in the Files directory of the local MQL4 file tree.  The file name will have the date and time (to the minute, using your local computer clock), followed by the pair name, and either 'L' or 'S', depending on whether it's a long or short trade, and then the sequence number of trades of that type in that pair today.  The captured file will be a ".png" (Portable Network Graphics) file.</dd>

<dt>ScreenShotWidth</dt><dd> [Added in Release 0.34.2] Specifies the width in pixels of the screen shot file to be captured.  If the value is 0, the screen capture will use the width of the chart in the terminal window at the time the trade is executed.  Default value is 0.</dd>

<dt>ScreenShotHeight</dt><dd> [Added in Release 0.34.2] Specifies the height in pixels of the screen shot file to be captured.  If the value is 0, the screen capture will use the height of the chart in the terminal window at the time the trade is executed.  Default value is 0.</dd>

<dt>DaysToKeepScreenShots</dt><dd> [Added in Release 0.41] If set to a non-zero value, this will cause the Trading Assistant scan through all the screen capture files for the current pair in the directory Files\ScreenShots, and delete any files that are older than that many days. This scan takes place during the end-of-day processing, so the MetaTrader4 platform and the Trading Assistant must be left running through the end of the day in order for this clean up to take place. Default value is 0.</dd>

<dt>SortScreenShotsBy</dt><dd> [Added in Release 0.41] The valid values for this string variable are "None", "Date", and either "Pair" or "Symbol", which are both equivalent.  Value is not case sensitive.  If the value is None, all screen capture files will be captured in the directory Files\ScreenShots, with no sorting.  If the value is Date, a hierarchical date folder structure will be set up within the Files\ScreenShots folder, with a year folder, a month folder (consisting of a 2-digit month number and a 3-character English month abbreviation), and a day folder for each day of the month the Trading Assistant is active.  All screen shots for that day will be saved in the appropriate folder. If value is either Pair or Symbol, a folder for each pair name will be set up in Files\ScreenShots, and all screen shots for the given pair will be saved in those folders.  The default value is None</dd>
</dl>
# Limitations

In my use, PATI Trading Assistant (PTA) has worked exactly as expected 99% of the time. However, there are a couple limitations that you need to understand to avoid some surprises.

~~The first is that the New Trade Indicator (NTI), which feeds the trade data into PTA, can only track one open trade per pair at a time, including pending orders. If you have a pending order for a pair, and then decide to enter an order manually before cancelling the pending order, then the new order won't be seen, and PTA won't act on it.~~  [This limitation has been removed in version 0.32 and later of NTI]


~~This happens to me occasionally when I get caught up in responding to a sudden change.~~ If NTI should fail to recognize an order for some reason,   there is a way to tell PTA about the trade manually.  NTI communicates trades to PTA through MT4 Global Variables, which are accessible using the Tools -> Global Variables menu of the MT4 platform. Follow this procedure:

1. ~~Cancel the pending order if it is still open.~~

2. Open the Tools -> Global Variables menu, and locate the variable corresponding to the pair you are trading.  (It will be named "NTI_<symbol>LastOrderId", for example, NTIEURUSDLastOrderId). Double-click the Value column for that variable.

3. Locate the trade in your terminal, and type the Order number for that trade in to the Global Variable value. Hit enter, and PTA should "see" the trade and act on it.

Another consequence of this limitation is that, if you enter add-on orders to an open position, they will not be handled by PTA, and will have to be handled manually.

The second limitation is based on the design of NTI. In order to reduce network traffic and the load on the CPU, NTI queries the server every second and says, in effect, "How many open orders are there for this account?" As long as that number comes back the same as it was the last time it was asked, then NTI assumes no new orders have been entered or closed. And 99.9% of the time that is true.

However, if it were to happen that you entered a new order in the same second that an open position was closed, then it is possible that the new order might be missed.  I have never seen this happen, but it's theoretically possible.

This limitation is removed in NTI v0.33 when setting the ScanAllSymbolsOnEachTick variable to true, which now comes as the default value. This setting is mandatory when using brokers such as OANDA that replace pending orders when the are triggered (rather than modifying the existing order into an active order), because there now a deleted order (the pending order) and and added order (the replaced active order) in the same instant. It is also recommended if you use the SetPendingOrdersOnRanges feature because it is possible for a net pending order to cancel and replace an existing one in the same instant.

