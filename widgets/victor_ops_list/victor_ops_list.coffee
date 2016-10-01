class Dashing.VictorOpsList extends Dashing.Widget
  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
    else
      $(@node).find('ul').remove()

  color: ->
    data = @get('items')
    # Find out if there's unacked incidents
    switch data.reduce @worstReduce, null
      when 'TRIGGERED' then '#ff0000'
      when 'ACKED' then '#ffcc00'
      else '#33cc33'

  onData: (data) ->
    console.dir data.items
    switch data.items.reduce @worstReduce, null
      when 'TRIGGERED'
        $(@get('node')).removeClass('acked').addClass('triggered')
      when 'ACKED'
        $(@get('node')).removeClass('triggered').addClass('acked')

  worstReduce: (memo, curr) ->
    if curr['phase'] == 'TRIGGERED'
      'TRIGGERED'
    else if curr['phase'] == 'ACKED' && memo != 'TRIGGERED'
      'ACKED'
    else
      null

