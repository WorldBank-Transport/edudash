'use strict'

###*
 # @ngdoc service
 # @name utils
 # @description
 # # Utility functions
 # All the miscellaneous pure functions you could ever want...
###
angular.module('edudashAppSrv').service 'utils', ($timeout, $q) ->

  schoolSort = (objs, prop, order) ->
    sorted = objs
      .filter (o) -> o[prop]?
      .sort (a, b) -> a[prop] - b[prop]
    if order == 'DESC'
      sorted.reverse()
    sorted

  ###*
  # Rank an object (1-indexed!!!) from a list of objects by a property
  # @param {object} item The object whose rank we want to know
  # @param {object[]} list What item is to be ranked against
  # @param {string} rankProp The property we should use to rank
  # @param {string} [groupProp=undefined] Filter the list to objects matching this prop
  # @param {strong} [order='ASC'] set to 'DESC' to sort descending
  # @returns {object} with keys `rank`, the item's 1-indexed rank; and `total`
  ###
  rank: (item, list, rankProp, groupProp, order) ->
    unless typeof item == 'object'
      throw new Error "param `item` must be an object. Got '#{typeof item}'"
    unless list instanceof Array
      throw new Error "param `list` must be an Array. Got '#{typeof list}'"
    unless typeof rankProp == 'string'
      throw new Error "param `rankProp` must be a string. Got '#{typeof rankProp}'"
    unless not order? or order in ['ASC', 'DESC']
      throw new Error "param `order` must be 'ASC' or 'DESC'. Got #{typeof order} '#{order}'"
    unless (list.indexOf item) != -1
      throw new Error "`item` must be in `list`"

    filtered = if groupProp? then (
      if item[groupProp]? then (
        list.filter (el) -> el[groupProp] == item[groupProp]
      ) else []
    ) else list

    # cases where we can't determine a rank
    if not item[rankProp]? or (groupProp? and not item[groupProp]?)
      rank: undefined
      total: filtered.length

    else
      ordered = schoolSort filtered, rankProp, order
      rank: (ordered.indexOf item) + 1  # +1 because it's 1-indexed
      total: ordered.length

  ###*
  # Sort a list of schools promise by a [prop, desc] metric
  # @param {Promise<Array>} listP The array of schools
  # @param {Array} metric The criteria for ranking
  # @param {string} metric[0] The property we should use to rank
  # @param {string} metric[1] Sort 'ASC' or 'DESC'
  # @returns {Promise<Array>} The schools, sorted
  ###
  rankAll: (listP, [prop, order]) ->
    unless listP? and typeof listP.then == 'function'
      throw new Error "param `listP` must be a Promise. Got '#{typeof listP}'"
    unless typeof prop == 'string'
      throw new Error "param `metric[0]` must a string. Got '#{typeof prop}'"
    unless order in ['ASC', 'DESC']
      throw new Error "param `metric[1]` must be a 'ASC' or 'DESC'. Got '#{order}'"

    listP.then (list) -> $q (resolve, reject) ->
      unless list instanceof Array
        reject "listP promise must resolve to an Array. Got '#{typeof list}'"
      else
        resolve schoolSort list, prop, order

  ###*
  # Sort a list of schools promise by a [prop, desc] metric
  # @param {Promise<Array>} listP The array of schools
  # @param {Array} metric The criteria for ranking
  # @param {string} metric[0] The property we should use to rank
  # @param {string} metric[1] limit
  # @returns {Promise<Array>} The schools, sorted
  ###
  rankTop: (listP, [prop, order], limit) ->
    unless listP? and typeof listP.then == 'function'
      throw new Error "param `listP` must be a Promise. Got '#{typeof listP}'"
    unless typeof prop == 'string'
      throw new Error "param `metric[0]` must a string. Got '#{typeof prop}'"
    unless typeof limit == 'number'
      throw new Error "param `metric[1]` must be a number. Got '#{limit}'"

    listP.then (list) -> $q (resolve, reject) ->
      unless list instanceof Array
        reject "listP promise must resolve to an Array. Got '#{typeof list}'"
      else
        best = schoolSort list, prop, 'ASC'
        worst = schoolSort list, prop, 'DESC'
        resolve (best.slice 0, limit).concat (worst.slice 0, limit)

  ###*
  # Get a filter function that filters objects by a numerical prop value
  # @param {string} prop Property to check for filtering
  # @param {number} min Inclusive lower bound of acceptable `prop` values
  # @param {number} max Inclusive upper bound of acceptable `prop` values
  # @returns {function} suitable for passing to Array.prototype.filter
  ###
  rangeFilter: (prop, min, max, minLimit, maxLimit) ->
    unless typeof prop == 'string'
      throw new Error "param `prop` must be a string. Got '#{typeof prop}'"
    unless typeof min == 'number'
      throw new Error "param `min` must be a number. Got '#{typeof min}'"
    unless typeof max == 'number'
      throw new Error "param `max` must be a number. Got '#{typeof max}'"
    unless max >= min
      throw new Error "invalid range [#{min}, #{max}]"

    (s) -> 
      if min == minLimit and max == maxLimit  # No Filters
        true
      else if min != minLimit and max == maxLimit  # No Max Filter selected
        s[prop] >= min
      else if min == minLimit and max != maxLimit  # No Min Filter selected
        s[prop] <= max
      else
        (min <= s[prop] <= max)


  ###*
  # Wait to call a function until it has stopped being called for some time
  # @param {wait} int
  # @param {fn} function To call after the specified timeout since last call
  # @returns {function} that will eventually proxy calls back to `fn`
  ###
  debounce: (wait, fn) ->
    unless typeof wait == 'number'
      throw new Error  "param `wait` must be a number. Got '#{typeof wait}'"
    unless wait == (wait|0)  # cast to int
      throw new Error "param `wait` must be an integer. Got #{wait}"
    unless typeof fn == 'function'
      throw new Error "param 'fn' must be a function. Got '#{typeof fn}'"

    timer = null

    (args...) ->
      $timeout.cancel timer
      timer = $timeout (-> fn args...), wait


  ###*
  # Async look up a mapping by ID, for finding schools or polygons
  # @param {Promise<object>} mapP promise of the map to find from
  # @param {string} id of the object to find
  # @returns {Promise<object|null>} that will be the found object
  ###
  lookup: (mapP, id) ->
    unless mapP? and typeof mapP.then == 'function'
      throw new Error "param `mapP` must be a Promise. Got '#{typeof mapP}'"
    unless typeof id == 'string'
      throw new Error "param `id` must be a string. Got '#{typeof id}'"

    mapP.then (mapObj) -> $q (resolve, reject) ->
      unless typeof mapObj == 'object'
        reject "Promise `mapP` must resolve to an object. Got '#{typeof mapObj}'"
      else if mapObj == null
        reject "Promise `mapP` must resolve to an object. Got 'null'"
      else
        resolve mapObj[id] or null

  max: (allSchoolsPromise, prop, defaultMax) ->
    unless typeof prop == 'string'
      throw new Error "param `prop` must be a string. Got '#{typeof prop}'"
    unless typeof defaultMax == 'number'
      throw new Error "param `defaultMax` must be a number. Got '#{typeof defaultMax}'"
    $q (resolve, reject) ->
      unless allSchoolsPromise?
        resolve defaultMax
      else
        allSchoolsPromise.then ((schools) ->
          ratios = schools
            .map (s) -> s[prop]
            .filter (s) -> not isNaN s
          maxRatio = Math.max defaultMax, ratios...
          resolve maxRatio
        ), reject
