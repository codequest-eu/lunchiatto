@Lunchiatto.module 'Order', (Order, App, Backbone, Marionette, $, _) ->
  Order.Show = Marionette.LayoutView.extend
    DELETE_MESSAGE: 'This will permanently delete the order and
                     ALL THE DISHES. Are you sure?'
    template: 'orders/show'

    ui:
      dishesSection: '.dishes-section'
      orderButton: '.order-button'
      changeStatus: '.change-status-button'
      deleteOrder: '.destroy-order-button'
      orderTotal: '.title-total'

    regions:
      dishes: '@ui.dishesSection'

    triggers:
      'click @ui.changeStatus': 'change:status'
      'click @ui.deleteOrder': 'delete:order'

    behaviors:
      Animateable:
        types: ['fadeIn']
      Titleable: {}

    modelEvents:
      'change': 'render'

    templateHelpers: ->
      machineStatus: @model.get('status').replace('_', '-')
      humanStatus: @model.get('status').replace('_', ' ')

    initialize: ->
      @listenTo(@model.get('dishes'), 'add remove', @_hideOrderButton)
      @listenTo(@model.get('dishes'), 'add remove', @_recalculateTotal)

    onRender: ->
      @_showDishes()
      @_hideOrderButton()

    onChangeStatus: ->
      @model.changeStatus()

    onDeleteOrder: ->
      if confirm(@DELETE_MESSAGE)
        @model.destroy
          success: ->
            App.router.navigate('/orders/today', {trigger: true})

    _showDishes: ->
      dishes = new Order.Dishes
        collection: @model.get('dishes')
      @dishes.show(dishes)

    _hideOrderButton: ->
      @ui.orderButton.toggleClass('hide', @model.currentUserOrdered())

    _recalculateTotal: ->
      @ui.orderTotal.text(@model.total())

    _htmlTitle: ->
      @model.get('from')
