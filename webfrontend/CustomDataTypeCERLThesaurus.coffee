class CustomDataTypeCERLThesaurus extends CustomDataTypeWithCommonsAsPlugin

  #######################################################################  
  # return the prefix for localization for this data type.  
  # Note: This function is supposed to be deprecated, but is still used   
  # internally and has to be used here as a workaround because the   
  # default generates incorrect prefixes for camelCase class names 
  getL10NPrefix: ->
    'custom.data.type.cerlthesaurus'

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-cerlthesaurus.cerlthesaurus"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.cerlthesaurus.name")

  #######################################################################
  # support geostandard in frontend?
  supportsGeoStandard: ->
    return false
    

  #######################################################################
  # configure used facet
  getFacet: (opts) ->
    opts.field = @
    new CustomDataTypeCERLThesaurusFacet(opts)

  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5?.loca?.getLanguage()
    if desiredLanguage
      desiredLanguage = desiredLanguage.split('-')
      desiredLanguage = desiredLanguage[0]
    else
      desiredLanguage = false

    desiredLanguage


  #######################################################################
  # returns markup to display in expert search
  #######################################################################
  renderSearchInput: (data) ->
      that = @
      if not data[@name()]
          data[@name()] = {}

      form = @renderEditorInput(data, '', {})

      CUI.Events.listen
            type: "data-changed"
            node: form
            call: =>
                CUI.Events.trigger
                    type: "search-input-change"
                    node: form

      form.DOM
   
  #######################################################################
  # make searchfilter for expert-search
  #######################################################################
  getSearchFilter: (data, key=@name()) ->
      that = @

      # search for empty values
      if data[key+":unset"]
          filter =
              type: "in"
              fields: [ @fullName()+".conceptName" ]
              in: [ null ]
          filter._unnest = true
          filter._unset_filter = true
          return filter

      # find all records which
      #   - have the uri as conceptURI

      filter =
          type: "complex"
          search: [
              type: "in"
              bool: "must"
              fields: [ "_objecttype" ]
              in: [ @path() ]
            ,
              type: "match"
              mode: "token"
              bool: "must",
              phrase: false
              fields: [@path() + '.' + @name() + ".conceptURI" ]
          ]

      if ! data[@name()]
          filter.search[1].string = null
      else if data[@name()]?.conceptURI
          givenURI = data[@name()].conceptURI
          givenURIParts = givenURI.split('/')
          givencerlthesaurusID = givenURIParts.pop()
          uri = 'https://data.cerl.org/thesaurus/' + givencerlthesaurusID

          filter.search[1].string = uri
      else
          filter = null

      filter

  #######################################################################
  # make tag for expert-search
  #######################################################################
  getQueryFieldBadge: (data) ->
      if ! data[@name()]
          value = $$("field.search.badge.without")
      else if ! data[@name()]?.conceptURI
          value = $$("field.search.badge.without")
      else
          value = data[@name()].conceptName

      name: @nameLocalized()
      value: value

  #######################################################################
  # get more info about record
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr) ->
    that = @
    # extract cerlthesaurusID from uri
    cerlthesaurusID = decodeURIComponent(uri)
    cerlthesaurusID = cerlthesaurusID.split "/"
    cerlthesaurusID = cerlthesaurusID.pop()
    if extendedInfo_xhr.xhr != undefined
      # abort eventually running request
      extendedInfo_xhr.xhr.abort()
    # start new request
    requestUrl = 'https://ws.gbv.de/suggest/cerl_thesaurus/?searchstring=' + cerlthesaurusID + '&type=placename&count=1'
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: requestUrl)
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      if data.length == 0
        return

      data = data[0]

      htmlContent = '<span style="padding: 10px 10px 0px 10px; font-weight: bold">' + $$('custom.data.type.cerlthesaurus.config.parameter.mask.infopop.info.label') + '</span>'

      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'

      if data.displayName
        htmlContent += '<tr><td>' + $$('custom.data.type.cerlthesaurus.config.parameter.mask.infopop.displayName.label') + ':</td><td>' + data.displayName + '</td></tr>'

      if data.cerlID
        htmlContent += '<tr><td>' + $$('custom.data.type.cerlthesaurus.config.parameter.mask.infopop.cerlID.label') + ':</td><td>' + data.cerlID + '</td></tr>'

      if data.geoNote
        htmlContent += '<tr><td>' + $$('custom.data.type.cerlthesaurus.config.parameter.mask.infopop.geoNote.label') + ':</td><td>' + data.geoNote + '</td></tr>'

      if data.bioData
          htmlContent += '<tr><td>' + $$('custom.data.type.cerlthesaurus.config.parameter.mask.infopop.bioData.label') + ':</td><td>' + data.bioData + '</td></tr>'

      if data.variantForms
        variants = []
        for variantName, variantNameKey in data.variantForms
          variants.push variantName
        variantsString = variants.join ('<br />')
      if variants.length > 0
        htmlContent += '<tr><td>' + $$('custom.data.type.cerlthesaurus.config.parameter.mask.infopop.variantForms.label') + ':</td><td>' + variantsString + '</td></tr>'

      #tooltip.getPane().replace(htmlContent, "center")
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return

  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, data, cdata, layout, opts) ->
    that = @

    suggest_Menu

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }

    # set default value for count of suggestions
    cdata.countOfSuggestions = 10
    cdata_form = new CUI.Form
      class: 'cdtFormWithPadding'
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        # if featureclass- & featurecodes-dropdown are visible
        if @getCustomMaskSettings().config_featureclasses?.value && @getCustomMaskSettings().config_featurecodes?.value
          # if featureclass changed, update featurecodes-dropdown
          if elem.opts.name == 'cerlthesaurusSelectFeatureClasses'
            # if featureclass is '', show all featurecodes
            featureclassParameter = ''
            if data?.cerlthesaurusSelectFeatureClasses != '' && data?.cerlthesaurusSelectFeatureClasses != null
              featureclassParameter = data.cerlthesaurusSelectFeatureClasses
            # reset the featurecode-element-value (in data + cdata)
            data.cerlthesaurusSelectFeatureCodes = null
            cdata.cerlthesaurusSelectFeatureCodes = null
            cdata_form.getFieldsByName("cerlthesaurusSelectFeatureCodes")[0]?.setValue(null)
            defaultText = cdata_form.getFieldsByName("cerlthesaurusSelectFeatureCodes")[0].default_opt.text

            cdata_form.getFieldsByName("cerlthesaurusSelectFeatureCodes")[0].reload()
            cdata_form.getFieldsByName("cerlthesaurusSelectFeatureCodes")[0]?.setText('test')
        @__updateResult(cdata, layout, opts)
        @__setEditorFieldStatus(cdata, layout)
        @__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout, opts)
    .start()

    # init suggestmenu
    suggest_Menu = new CUI.Menu
        element: cdata_form.getFieldsByName("searchbarInput")[0]
        use_element_width_as_min_width: true
        class: "customDataTypeCommonsMenu"

    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      pane:
        # titel of popovers
        header_left: new CUI.Label(text: $$('custom.data.type.commons.popover.choose.label'))
        content: cdata_form
    .show()


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        cerlthesaurus_searchterm = searchstring
        cerlthesaurus_countSuggestions = 10

        # init searchtype
        if that.getCustomMaskSettings()?.allow_corporatename?.value == true
          cerlthesaurus_type = 'corporatename'
        else if that.getCustomMaskSettings()?.allow_imprintname?.value == true
          cerlthesaurus_type = 'imprintname'
        else if that.getCustomMaskSettings()?.allow_placename?.value == true
          cerlthesaurus_type = 'placename'
        else
          cerlthesaurus_type = 'personalname'

        expandQuery = ''

        if (cdata_form)
          cerlthesaurus_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
          cerlthesaurus_type = cdata_form.getFieldsByName("cerlthesaurusSelectType")[0]?.getValue()
          if cerlthesaurus_type == undefined || cerlthesaurus_type == null
              cerlthesaurus_type = ''

          cerlthesaurus_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

        if cerlthesaurus_searchterm.length == 0
            return

        extendedInfo_xhr = { "xhr" : undefined }

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()
        # start new request
        requestUrl = 'https://ws.gbv.de/suggest/cerl_thesaurus/?searchstring=' + cerlthesaurus_searchterm + '&type=' + cerlthesaurus_type + '&count=' + cerlthesaurus_countSuggestions
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: requestUrl)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->
            # create new menu with suggestions
            menu_items = []
            # the actual Featureclass
            for suggestion, key in data
              do(key) ->
                item =
                  text: suggestion.displayName
                  value: 'https://data.cerl.org/thesaurus/' + suggestion.cerlID
                  tooltip:
                    markdown: true
                    placement: "e"
                    content: (tooltip) ->
                      that.__getAdditionalTooltipInfo('https://data.cerl.org/thesaurus/' + data[key].cerlID, tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: "lade Informationen")
                menu_items.push item

            # set new items to menu
            itemList =
              keyboardControl: true
              onClick: (ev2, btn) ->
                  # lock in save data
                  cdata.conceptURI = btn.getOpt("value")
                  cdata.conceptName = btn.getText()
                  cdata._fulltext = {}
                  cdata._standard = {}
                  cdata._fulltext.text = cdata.conceptName
                  cdata._standard.text = cdata.conceptName

                  # extract cerlthesaurus-id from URI
                  cerlthesaurusID = cdata.conceptURI
                  cerlthesaurusID = cerlthesaurusID.replace('https://data.cerl.org/thesaurus/', '')
                  # build url for cerlthesaurus-api
                  requestUrl = 'https://ws.gbv.de/suggest/cerl_thesaurus/?searchstring=' + cerlthesaurusID + '&type=placename&count=1'
                  dataEntry_xhr = new (CUI.XHR)(url: requestUrl)
                  dataEntry_xhr.start().done((data, status, statusText) ->

                    data = data[0]
                    cdata.conceptName = CERLThesaurusUtil.getConceptNameFromObject data
                    cdata.conceptURI = CERLThesaurusUtil.getConceptURIFromObject data

                    # _standard & _fulltext
                    cdata._fulltext = CERLThesaurusUtil.getFullTextFromObject data, false
                    cdata._standard = CERLThesaurusUtil.getStandardTextFromObject that, data, cdata, false

                    # update the layout in form
                    that.__updateResult(cdata, layout, opts)
                    # hide suggest-menu
                    suggest_Menu.hide()
                    # close popover
                    if that.popover
                      that.popover.hide()
                  )

              items: menu_items

            # if no hits set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: "kein Treffer"
                  value: undefined
                ]

            suggest_Menu.setItemList(itemList)

            suggest_Menu.show()

        )
    ), delayMillisseconds


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
  __getEditorFields: (cdata) ->
    that = @
    fields = [
      {
        type: CUI.Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.cerlthesaurus.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 ' + $$('custom.data.type.cerlthesaurus.modal.form.text.count_short')
          )
          (
              value: 20
              text: '20 ' + $$('custom.data.type.cerlthesaurus.modal.form.text.count_short')
          )
          (
              value: 50
              text: '50 ' + $$('custom.data.type.cerlthesaurus.modal.form.text.count_short')
          )
          (
              value: 100
              text: '100 ' + $$('custom.data.type.cerlthesaurus.modal.form.text.count_short')
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.cerlthesaurus.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.cerlthesaurus.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }
      ]

    # offer types as dropdown (at least one must be configured)
    typesOptions = []

    if that.getCustomMaskSettings()?.allow_corporatename?.value == true
      newType = (
              value: 'corporatename'
              text: $$('custom.data.type.cerlthesaurus.config.parameter.mask.allow_corporatename.value.label')
            )
      typesOptions.push newType
    if that.getCustomMaskSettings()?.allow_imprintname?.value == true
      newType = (
              value: 'imprintname'
              text: $$('custom.data.type.cerlthesaurus.config.parameter.mask.allow_imprintname.value.label')
            )
      typesOptions.push newType
    if that.getCustomMaskSettings()?.allow_personalname?.value == true
      newType = (
              value: 'personalname'
              text: $$('custom.data.type.cerlthesaurus.config.parameter.mask.allow_personalname.value.label')
            )
      typesOptions.push newType
    if that.getCustomMaskSettings()?.allow_placename?.value == true
      newType = (
              value: 'placename'
              text: $$('custom.data.type.cerlthesaurus.config.parameter.mask.allow_placename.value.label')
            )
      typesOptions.push newType

    # if no type given, add personalname
    if typesOptions.length == 0
      newType = (
              value: 'personalname'
              text: $$('custom.data.type.cerlthesaurus.config.parameter.mask.allow_personalname.value.label')
            )
      typesOptions.push newType

    field = {
      type: CUI.Select
      undo_and_changed_support: false
      form:
          label: $$('custom.data.type.cerlthesaurus.modal.form.text.type')
      options: typesOptions
      name: 'cerlthesaurusSelectType'
      class: 'commonPlugin_Select'
    }

    fields.unshift(field)

    fields



  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->

    that = @

    # when status is empty or invalid --> message
    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.cerlthesaurus.edit.no_cerlthesaurus")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.cerlthesaurus.edit.no_valid_cerlthesaurus")).DOM

    # if status is ok
    cdata.conceptURI = CUI.parseLocation(cdata.conceptURI).url

    extendedInfo_xhr = { "xhr" : undefined }

    # output Button with Name of picked entry and URI
    new CUI.HorizontalLayout
      maximize: false
      left:
        content:
          new CUI.Label
            centered: false
            multiline: true
            text: cdata.conceptName
      center:
        content:
          # output Button with Name of picked Entry and Url to the Source
          new CUI.ButtonHref
            appearance: "link"
            href: cdata.conceptURI
            target: "_blank"
            tooltip:
              markdown: true
              placement: 'n'
              content: (tooltip) ->
                that.__getAdditionalTooltipInfo(cdata.conceptURI, tooltip, extendedInfo_xhr)
                new CUI.Label(icon: "spinner", text: "lade Informationen")
            text: ' '
      right: null
    .DOM



  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    tags


CustomDataType.register(CustomDataTypeCERLThesaurus)
