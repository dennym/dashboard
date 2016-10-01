class Dashing.VictorOpsList extends Dashing.Widget
  ready: ->
    if @get('unordered')
      $(@node).find('ol').remove()
    else
      $(@node).find('ul').remove()

  onData: (data) ->
    switch data.items.reduce @worstReduce, null
      when 'TRIGGERED'
        $(@get('node')).removeClass('acked').addClass('triggered')
      when 'ACKED'
        $(@get('node')).removeClass('triggered').addClass('acked')

  worstReduce: (memo, curr) ->
    if curr['phase'] == 'UNACKED'
      'TRIGGERED'
    else if curr['phase'] == 'ACKED' && memo != 'TRIGGERED'
      'ACKED'
    else
      null

