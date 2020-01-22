@Lunchiatto.module 'Order', (Order, App, Backbone, Marionette, $, _) ->
  Order.Controller =
    form: (order) ->
      orderForm = new Order.Form(model: order)
      App.root.content.show(orderForm)

    list: (orders) ->
      ordersList = new Order.List(collection: orders)
      App.root.content.show(ordersList)

    show: (order) ->
      orderView = new App.Order.Show(model: order)
      App.root.content.show(orderView)

    history: (orders) ->
      ordersHistory = new Order.History(collection: orders)
      App.root.content.show(ordersHistory)
