@Lunchiatto.module 'Order', (Order, App, Backbone, Marionette, $, _) ->
  Order.HistoryItem = Marionette.ItemView.extend
    template: 'orders/history_item'
    tagName: 'li'
    className: 'hover-pointer'

    triggers:
      'click': 'show:order'

    behaviors:
      Animateable:
        types: ['fadeIn']

    templateHelpers: ->
      machineStatus: @model.get('status').replace('_', '-')
      humanStatus: @model.get('status').replace('_', ' ')

    onShowOrder: ->
      App.router.navigate("/orders/#{@model.id}", {trigger: true})
