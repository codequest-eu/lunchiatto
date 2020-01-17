@Lunchiatto.module 'Company', (Company, App, Backbone, Marionette, $, _) ->
  Company.Member = Marionette.ItemView.extend
    DELETE_MESSAGE: 'Are you sure?'

    template: 'companies/member'

    behaviors:
      Animateable:
        types: ['fadeIn']

    ui:
      deleteButton: '.delete-member'

    triggers:
      'click @ui.deleteButton': 'delete:member'

    onDeleteMember: ->
      if confirm(@DELETE_MESSAGE)
        @$el.addClass('animate__fade-out')
        setTimeout =>
          @model.destroy()
        , App.animationDurationMedium
