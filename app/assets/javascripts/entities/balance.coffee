@Lunchiatto.module 'Entities', (Entities, App, Backbone, Marionette, $, _) ->
  Entities.Balance = Backbone.Model.extend({})

  Entities.Balances = Backbone.Collection.extend
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
