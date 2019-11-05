# Clickbank Data Analysis

__My plan is to find out, what are promising products to promote on Clickbank.__

## Metrics

__Initial Earnings Per Sale:__
Average net amount earned per affiliate per referred sale. Note that this is the net earned per actual sale, and so it is impacted by refunds, chargebacks, and sales taxes. (Effective 28 July 2005, unfunded sales, such as returned checks, do not impact this number.)

__Average Percent Per Sale:__
Average percentage commission earned per affiliate per referred sale. This number should only vary if the publisher has changed their payout percentage over time

__Referred:__ Fraction of publisher's total sales that are referred by affiliates

__Gravity:__ Number of distinct affiliates who earned a commission by referring a paying customer to the publisher's products. This is a weighted sum and not an actual total. For each affiliate paid in the last 8 weeks we add an amount between 0.1 and 1.0 to the total. The more recent the last referral, the higher the value added.

__Commision:__ The fixed payout percentage per referred affiliate sale