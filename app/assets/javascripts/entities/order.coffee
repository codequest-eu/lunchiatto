@CodequestManager.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->
  Entities.Order = Backbone.Model.extend

    urlRoot: ->
      "/orders"

    parse: (data) ->
      data.dishes = new Entities.Dishes data.dishes
      data.dishes.order = this
      data

    currentUserOrdered: ->
      @get('dishes').where(user_id: App.currentUser.id).length isnt 0

    changeStatus: ->
      $.ajax
        type: 'PUT'
        url: "#{@url()}/change_status"
        success: (data) =>
          @set({status: data.status})
          App.vent.trigger 'reload:current:user' if data.status is 'delivered'
          @get('dishes').reset(data.dishes, parse: true)

  Entities.Orders = Backbone.Collection.extend
    model: Entities.Order
    url: '/orders'
