do (App = @Lunchiatto) ->
  App.Controller =
    ordersToday: (orderId) ->
      App.Today.Controller.today(orderId)

    editDish: (orderId, dishId) ->
      dish = new App.Entities.Dish
        order_id: orderId
        id: dishId
        user_id: App.currentUser.id
      dish.fetch
        success: (dish) ->
          App.Dish.Controller.form(dish)

    newDish: (orderId) ->
      dish = new App.Entities.Dish
        order_id: orderId
        user_id: App.currentUser.id
        price: '0.00'
        user_ids: ''
      App.Dish.Controller.form(dish)

    newOrder: ->
      order = new App.Entities.Order(shipping: '0.00')
      App.Order.Controller.form(order)

    showOrder: (orderId) ->
      order = new App.Entities.Order(id: orderId)
      order.fetch
        success: (order) ->
          App.Order.Controller.show(order)

    editOrder: (orderId) ->
      order = new App.Entities.Order(id: orderId)
      order.fetch
        success: (order) ->
          App.Order.Controller.form(order)

    ordersIndex: ->
      orders = new App.Entities.Orders
      orders.fetch
        success: (orders) ->
          App.Order.Controller.list(orders)

    ordersHistory: ->
      orders = new App.Entities.OrdersHistory
      orders.fetch
        success: (orders) ->
          App.Order.Controller.history(orders)

    yourBalances: ->
      App.Balance.Controller.you()

    othersBalances: ->
      App.Balance.Controller.others()

    accountNumbers: ->
      App.Dashboard.Controller.accounts()

    settings: ->
      App.currentUser.fetch
        success: (user) ->
          App.Dashboard.Controller.settings(user)

    transfersIndex: ->
      App.Transfer.Controller.index()

    newTransfer: ->
      App.Transfer.Controller.form()

    companyMembers: ->
      App.Company.Controller.members()

    editCompany: ->
      App.Company.Controller.edit()
