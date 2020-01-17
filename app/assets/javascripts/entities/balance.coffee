@Lunchiatto.module 'Entities', (Entities, App, Backbone, Marionette, $, _) ->
  Entities.Balance = Backbone.Model.extend
    createPayment: (amount, payer_id) =>
      $.ajax
        type: 'POST'
        url: '/api/payments'
        data:
          balance: amount
          payer_id: payer_id
      success: (data) =>
        @set(data)

  Entities.Balances = Backbone.Collection.extend
    model: Entities.Balance
    url: ->
      '/api/balances'

    total: ->
      @reduce((memo, balance) ->
        memo + parseFloat(balance.get('balance'))
      , 0).toFixed(2)

    totalIncludingPendingBalance: ->
      @reduce((memo, balance) ->
        memo + parseFloat(balance.get('balance')) +
        parseFloat(balance.get('pending_balance'))
      , 0).toFixed(2)
