@Lunchiatto.module 'Balance', (Balance, App, Backbone, Marionette, $, _) ->
  Balance.Balance = Marionette.ItemView.extend
    className: 'balance-box'
    template: 'balances/balance'

    templateHelpers: ->
      formattedBalance: @formattedBalance()
      formattedPendingBalance: @formattedPendingBalance()
      formattedTotalBalance: @formattedTotalBalance()
      totalBalance: @totalBalance()
      amountClass: @amountClass()
      transferLink: @transferLink(@model.get('balance'))
      transferLinkIncludingPendingBalance: @transferLink(@totalBalance())
      adequateUser: @_adequateUser()
      pendingOrdersCount: App.currentUser.get('pending_orders_count')

    amountClass: ->
      return unless @model.get('balance')
      modifier = if +@model.get('balance') >= 0 then 'positive' else 'negative'
      "money-box--#{modifier}"

    totalBalance: ->
      parseFloat(@model.get('pending_balance')) +
      parseFloat(@model.get('balance'))

    formattedTotalBalance: ->
      "#{@totalBalance()} PLN"

    formattedBalance: ->
      account_balance = @model.get('balance')
      account_balance && "#{account_balance} PLN" || 'N/A'

    formattedPendingBalance: ->
      account_pending_balance = @model.get('pending_balance')
      account_pending_balance && "#{account_pending_balance} PLN" || 'N/A'

    transferLink: (amount) ->
      "/transfers/new?to_id=#{@model.get('user_id')}\
        &amount=#{-amount}"

    _adequateUser: ->
      @model.get('user')
