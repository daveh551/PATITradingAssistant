#RELEASE NOTES for v 0.33 12/23/2016

The enhancement in this version is that, if selected, stops and take profit limits will be added to Pending Orders as well as active orders.

In this way, if you lose the internet connection to your broker after placing your pending order but before the order is triggered, your order will still be protected by a stop loss and take profit limit placed as quickly as possible after the pending order is placed.

Note that the stop loss point and take profit point are set based on the trigger point.  When the order is activated, the stop loss and take profit limit will be adjusted based on the actual entry price. (This behavior is controlled by configuration variables.)

#RELEASE NOTES for v 0.32 11/7/2015
This is the first of a series of planned releases that will make some enhancements to the existing PATI Trading Assistant.

The principal enhancement in this version is that the restriction of only one active trade/order per pair is removed.  This is a BREAKING CHANGE, and requires that v0.32 of the NetTradeIndicator be used with version 0.32 of the PATITradingAssistant.

The motivation is a couple scenarios in which the one active trade restriction caused a problem.
	1) If you had a pending trade in place and then entered a market order without first removing the pending trade, the market order would not be recognized.
	2) The restriction meant that you could not enter two simultaneous pending orders for breakouts at the top and bottom of a range, or at the top and bottom of the "No-Entry Zone".  These situations can now be accommodated with no problems.

#RELEASE NOTES for v 0.31 4/1/2015

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


# Installation:

The Trading Assistant has 2 components:

1. The "New Trade Indicator" (NTI)  which is an indicator (not expert advisor) that needs to be run on one and only one chart in your MT4 platform.
It works off a one-second interval timer, not off ticks, so which chart it's placed on doesn't matter.  Its function is to monitor for new trades and closed trade across the entire account.
2. The PATITradingAssistant (PTA) which is an expert advisor that needs to run on each pair that you trade.  
It will monitor the global variables set by NTI and detect when you have entered a new trade for that pair.  It will then execute the configured actions. 
Although it is not entering trades, it is modifying them (in order to set stop loss and take profit), so it needs to have AutoTrading enabled.

To install the Trading assistant,

1. Open your MT4 platform.
2. Click on File -> Open Data Folder menu item, then open the MQL4 directory under your platform specific data directory
3. Copy the NewTradeIndicator.ex4 to the MQL4/Indicators directory.
4. Copy the PATITradingAssistant.ex4 to the MQL/Experts directory.  
5. Restart MT4, and drag the NewTradeIndicator indicator onto any one chart, and drag the PATITradingAssistant expert onto each chart that you intend to trade.
6. In the Expert configuration dialog box that comes up for the PATITradingAssistant, click the Common tab, and make sure that "Allow Live Trading" is checked. (Alternatively, go into the Tools -> Options menu of the MetaTrader4 platform, navigate to the Expert Advisors tab, and check the "Allow Automated Trading" box.  This will then apply to all Expert Advisors added after that point.) Also verify that "Auto Trading" button in the toolbar of the MetaTrader4 platform has been clicked. (It should show a green dot in the icon, not a red one.)

# Configuration

## NewTradeIndicator:

There are two configuration variables in the NewTradeIndicator: Testing and PairOffsetWithinSymbol.

<dl>
<dt>Testing</dt> <dd>is a variable that allows development-level testing.  It should be set to false.  Setting it to true will keep the indicator from completing its initialization, and execution will terminate immediately after completing the tests. The default value is false.</dd>

<dt>PairOffsetWithinSymbol</dt>
<dd> should normally be 0, unless your broker adds a prefix to the symbol name to indicate a special account designation.  Most brokers simply return the pair name (e.g. "EURUSD") as the symbol, but some either prepend or append some designator to the pair name to indicate something characteristic of the account or trade (e.g. 'm' to denote a mini account).  If such a designator is post-fixed to the symbol (e.g. "EURUSDm"), it gets handled automatically, but if it is prefixed (e.g., "mEURUSD", we need to know how many characters to take off the front of the symbol in order to get the pair name. The default value is 0.</dd>

</dl>
## PATITradingAssistant:

There are numerous configuration variable for the Trading Assistant in order to allow configuration of the different actions according to your preferences.
<dl>
<dt>Testing</dt> <dd>Same function and description as under NewTradeIndicator.</dd>

<dt>PairOffsetWithinSymbol</dt> <dd>Same function and description as under NewTradeIndicator.</dd>

<dt>DefaultStopPips</dt> <dd> For any pair not listed in the Exceptions variable (see below) this variable gives the number of pips away from the entry that the stop loss will be set. Default value is 12.</dd>

<dt>Exceptions</dt>  <dd>This is a string variable that lists any pairs that have a different stop loss from the Default.  The format is a list of one or more pair names separated by commas, then followed by forward slash ('/') and the number of pips that becomes the stop loss for that pair.  This can then be followed by a semicolon and another list and value.  The default value is  "EURUSD/8;AUDUSD,GBPUSD,EURJPY,USDJPY,USDCAD/10", which will set an 8 pip stop for the EURUSD, a 10 pip stop for the AUDUSD, GBPUSD, EURJPY, USDJPY, and USDCAD.  All other pairs will use he value of DefaultStopPips (12).  This is in keeping with the current PATI rules. If you choose to trade other pairs, or the set of pairs traded by PATI is modified after the trading assistant is released, you may want to modify this value.</dd>

<dt>UseNextLevelTPRule</dt> <dd>this is a boolean (true/false) variable that determines whether or not to set a Take Profit (TP) that implements the "Exit at the next level" PATI objective take profit setting. (See also MinRewardRatio.) Default value is true.</dd>

<dt>ShowNoEntryZone</dt> <dd>this is a boolean variable that determines whether or not to display the "NoEntry" rectangle following an exit that loses pips.  The NoExitZone will be a rectangle extending from the current time to the end of the day, and from the "next level" above and below the trade entry. (See also MinNoEntryPad and NoEntryZoneColor.) Default value is true.</dd>

<dt>ShowEntry</dt> <dd>this is a boolean variable that determines whether or not to show an arrow indicator at the entry point to a trade.  The arrow will be blue. (See also EntryIndicator.) The default value is true.</dd>

<dt>ShowInitialStop</dt> <dd>this is a boolean variable that determines whether or not to show an arrow (a small red dash) at the level of the initial stop setting.  The default value is true.</dd>

<dt>ShowExit</dt> <dd>this is a boolean variable that determines whether or not to show an arrow indicating the exit price and time when a trade closes.  (See also EntryIndicator, WinningExitColor, and LosingExitColor.) The default value is true.</dt>

<dt>ShowTradeTrendLine</dt> <dd>this is a boolean variable that determines whether or not draw a trendline from the entry point to the exit point upon exiting a trade. (See also TradeTrendLineColor.) The default is true.</dd>

<dt>SendSLandTPToBroker</dt> <dd>this is a boolean variable that determines whether or not to actually send the calculated values for stop loss and takeprofit to the broker automatically. If true, an order modification is sent with the calculated values using the "OrderReliable" package that will detect retryable errors and retry up to ten times if an error occurs.  The default value is true.</dd>

<dt>AlertOnTrade</dt> <dd>this is a boolean variable that determines whether to raise an alert on detecting a trade entry and trade exit. The alert was originally put in as a debugging feature during development, but I decided I rather liked it as confirmation. Note also that the message displayed in the alert on trade exit includes the actual gain/loss in pips.  I recognized that it may get annoying though, so you have the capability to turn it off.  Default value is true.</dd>

<dt>MinNoEntryPad</dt> <dd>This a double value that represents the minimum distance in pips that the entry price has to be away from the "next level" when establishing the "NoEntryZone".  If the entry price is closer than that to a level, the "next level" chosen for the NoEntry rectangle will be one level beyond that. As an example, if you have a losing trade in the EURUSD with an entry price of 1.0612, which is 8 pips from the next level up of 1.0620, and the MinNoEntryPad is set at the default of 15, then the top of the NoEntry rectangle will not be at 1.0620, but at the next level, 1.0650.  Default value is 15 pips. If ShowNoEntryZone is false, this value has no effect.</dd>

<dt>EntryIndicator</dt> <dd>This is an integer variable that gives the MQL4 arrow code to use for entry (and exit by implication) arrows, if used. The only values that I have found that make sense are 2 (the default), and 5. 2 will draw a small right-facing arrow at the entry, while 5 will draw "Left Price Label" arrow with the numeric price shown in the arrow.  For the exit arrow, the next higher arrow code is used (3 or 6). 3 will draw a small left-facing arrow to the right of the exit point, while 6 will draw a "Right Price Label" arrow with the exit price shown in the arrow box. ShowEntry and/or ShowExit are false, this value has no effect.The default value is 2</dd>

<dt>MinRewardRatio</dt> <dd>When setting the "Next Level" take profit price, it makes no sense to set it so close to the entry that there is not sufficient reward-to-risk ratio.  For example, if you have entered a long trade on the EURUSD at 1.0618, technically, the next level would be 1.0620.  But that would only result in a 2 pip profit, compared to a 8 pip risk.  That is hardly the recipe for a profitable strategy.  This variable takes the stop loss pips that is used for the pair, multiplies that by this factor, and sets that as the minimum take profit target. If the "next level" is less than this value, it sets the TP target one more level up.  Thus, in our example, since EURUSD uses an 8 pip stop (by default), using the default MinRewardRatio, we would be looking for minimum TP target of 12 pips, 1.0630.  The next level above this is 1.0650, which is where the TP would be set. The default value is 1.5. If UseNextLevelTPRule is false, this value has no effect.</dd>

<dt>NoEntryZoneColor</dt> <dd>This is a color variable that sets the color that the NoEntryZone will be drawn in.  The default is DarkGray. If ShowNoEntryZone is false, this value has no effect.</dd>

<dt>WinningExitColor</dt> <dd>This is a color variable that set the color that tne Exit trade indicator will be drawn in if the trade resulted in positive pips.  The default is Green.  If ShowExit is false, the value has no effect.</dd>

<dt>LosingExitColor</dt> <dd>This is a color variable that sets the color that the Exit trade indicator will be drawn in fi the trade resulted in negative pips.  The default is Red. If ShowExit is false, the value has no effect.</dd>

<dt>TradeTrendLineColor</dt> <dd>This is a color variable that set the color that the TradeTrendLine will be drawn in. The default is Blue.  If ShowTradeTrendLine is false, this value has no effect.</dd>

<dt>SaveConfiguration</dt> <dd>I have often found, when using an EA, that there are a few values that I consistently want to set different from the default values.  Unless I have access to the source code (and want to go to the trouble of rebuilding the EA), I have no choice but to enter those values every time I start the EA. Setting this variable to true will copy out each of the configuration variables to a file in the Terminal's Files area.  On subsequent startups, this configuration file will be read and those values used in place of whatever is set in the settings dialog. If you want to start without using the configuration file after you have saved it, simply go into the Files area (by using the File -> Open Data Folder menu item, then navigating down the MQL\Files.  The file is named "PTA_&lt;symbol>_Configuration.txt".  You can delete that file (in which case you will have to save the configuration again if you want to use it), or rename it to something else (in which case you can rename it back the next time you want to use it). Since the file is an editable text file, you can also edit and change the values in the file itself.</dd>

<dt>EndOfDayOffsetHours</dt> <dd>Added in version 0.33, this variable alters the time at which the trading assistant will "clean up" the various graphic elements it may have added to the chart (arrows, boxes, trendlines, etc.)  It also adjusts the right edge the "No Entry Zone" rectangle if that is in use.</dd>

<dt>SetLimitsOnPendingOrders</dt> <dd> Added in version 0.33, this boolean variable determines whether or not the trading assistant will modify a pending order by adding stop loss and take profit limits to the order.  If false, the order is left unmodified.  Default is true. </dd>

<dt>AdjustStopOnTriggeredPendingOrders</dt> <dd>Added in version 0.33. When a pending order is entered, stop loss and take profit points are calculated based on the trigger price of the pending order.  When the order is actually triggered, the entry price may be different, sometimes substantially different, than the trigger price.  If this variable is true, the trading assistant will modify the order and send new stop loss and take profit points based on the actual entry price. Default is true
</dl>


#Limitations

In my use, PATI Trading Assistant (PTA) has worked exactly as expected 99% of the time. However, there are a couple limitations that you need to understand to avoid some surprises.

~~The first is that the New Trade Indicator (NTI), which feeds the trade data into PTA, can only track one open trade per pair at a time, including pending orders. If you have a pending order for a pair, and then decide to enter an order manually before cancelling the pending order, then the new order won't be seen, and PTA won't act on it.~~  [This limitation has been removed in version 0.32 and later of NTI]


~~This happens to me occasionally when I get caught up in responding to a sudden change.~~ If NTI should fail to recognize an order for some reason,   there is a way to tell PTA about the trade manually.  NTI communicates trades to PTA through MT4 Global Variables, which are accessible using the Tools -> Global Variables menu of the MT4 platform. Follow this procedure:

1. ~~Cancel the pending order if it is still open.~~

2. Open the Tools -> Global Variables menu, and locate the variable corresponding to the pair you are trading.  (It will be named "NTI_&lt;symbol>LastOrderId", for example, NTIEURUSDLastOrderId). Double-click the Value column for that variable.

3. Locate the trade in your terminal, and type the Order number for that trade in to the Global Variable value. Hit enter, and PTA should "see" the trade and act on it.

Another consequence of this limitation is that, if you enter add-on orders to an open position, they will not be handled by PTA, and will have to be handled manually.

The second limitation is based on the design of NTI. In order to reduce network traffic and the load on the CPU, NTI queries the server every second and says, in effect, "How many open orders are there for this account?" As long as that number comes back the same as it was the last time it was asked, then NTI assumes no new orders have been entered or closed. And 99.9% of the time that is true.

However, if it were to happen that you entered a new order in the same second that an open position was closed, then it is possible that the new order might be missed.  I have never seen this happen, but it's theoretically possible.
