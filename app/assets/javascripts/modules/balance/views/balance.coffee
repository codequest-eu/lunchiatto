@Lunchiatto.module 'Balance', (Balance, App, Backbone, Marionette, $, _) ->
  Balance.Balance = Marionette.ItemView.extend
    className: 'balance-box'
    template: 'balances/balance'

    templateHelpers: ->
      formattedBalance: @formattedBalance()
      amountClass: @amountClass()
      transferLink: @transferLink()
      adequateUser: @_adequateUser()

    amountClass: ->
      return unless @model.get('balance')
      modifier = if +@model.get('balance') >= 0 then 'positive' else 'negative'
      "money-box--#{modifier}"

    formattedBalance: ->
      account_balance = @model.get('balance')
      account_balance && "#{account_balance} PLN" || 'N/A'

    transferLink: ->
      "/transfers/new?to_id=#{@model.get('user_id')}\
        &amount=#{-@model.get('balance')}"

    _adequateUser: ->
      @model.get('user')
