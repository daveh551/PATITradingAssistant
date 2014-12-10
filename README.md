PATITradingAssistant
====================

A MQL4  (forex) expert adviser to assist with some bookkeeping after entering a trade

When entering a trade in a fast moving forex market, I often found that taking the time to execute several "bookkeeping" actions that needed to be done right after a trade was entered often took my attention away from other potential setups.

This trading assistant will monitor open trades on your account.  When it detects a new trade, it will do the following:
1) Set your stop loss the appropriate number of pips (according to the PATI rules).
2) Add an arrow at your entry point
3) Set your take profit at the next level.

In addition, on detecting that a trade has been closed, it will
4) Add a right arrow at the exit, and draw a line between entry and exit arrows
5) If the trade resulted in a loss, it will add a "no-entry" rectangle, indicating the zone in which you cannot make a new entry.

All these actions are configurable.
