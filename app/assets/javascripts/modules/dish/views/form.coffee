@Lunchiatto.module 'Dish', (Dish, App, Backbone, Marionette, $, _) ->
  Dish.Form = Marionette.ItemView.extend
    ERROR_MESSAGE: (maxDebt) ->
      "Since your debt is larger than #{maxDebt} PLN, you cannot \
       order any new dishes. Make appropriate transfers before continuing."

    template: 'dishes/form'

    ui:
      priceInput: '.price'
      nameInput: '.name'

    behaviors:
      Errorable:
        fields: ['name', 'price']
      Submittable: {}
      Animateable:
        types: ['fadeIn']
      Titleable: {}

    onFormSubmit: ->
      @model.save
        name: @ui.nameInput.val()
        price: @ui.priceInput.val().replace(',', '.')
      ,
        success: (model) ->
          App.router.navigate(model.successPath(), {trigger: true})

        error: (_, data) =>
          if data.responseJSON.error.dish &&
             confirm(@ERROR_MESSAGE(data.responseJSON.error.dish.limit))
              App.router.navigate("/you", {trigger: true})

    _htmlTitle: ->
      return 'Edit Dish' if @model.get('id')
      'Add Dish'
