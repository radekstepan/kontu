# kontu

1. Handle `difference` for each account so we can adjust its initial or susequent amount.
1. Each transaction is in currency and amount, transfers then are in account currency they are applied to saved with an exchange rate auto-provide by the API.
1. If a user has currency GBP set as default, translate current account amounts to this currency based on the latest exchange rate.