@Lunchiatto.module 'Order', (Order, App, Backbone, Marionette, $, _) ->
  Order.History = Marionette.CompositeView.extend
    template: 'orders/history'
    childViewContainer: '.history-orders-list'
    getChildView: ->
      Order.HistoryItem

    behaviors:
      Pageable: {}
      Animateable:
        types: ['fadeIn']
