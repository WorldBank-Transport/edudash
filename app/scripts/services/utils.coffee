'use strict'

###*
 # @ngdoc service
 # @name utils
 # @description
 # # Utility functions
 # All the miscellaneous pure functions you could ever want...
###
angular.module('edudashAppSrv').service 'utils', ->

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
      ordered = filtered.slice().sort (a, b) -> a[rankProp] - b[rankProp]
      if order == 'DESC' then ordered.reverse()

      rank: (ordered.indexOf item) + 1  # +1 because it's 1-indexed
      total: ordered.length


  ###*
  # Get a filter function that filters objects by a numerical prop value
  # @param {string} prop Property to check for filtering
  # @param {number} min Inclusive lower bound of acceptable `prop` values
  # @param {number} max Inclusive upper bound of acceptable `prop` values
  # @returns {function} suitable for passing to Array.prototype.filter
  ###

  rangeFilter: (prop, min, max) ->
    unless typeof prop == 'string'
      throw new Error "param `prop` must be a string. Got '#{typeof prop}'"
    unless typeof min == 'number'
      throw new Error "param `min` must be a number. Got '#{typeof min}'"
    unless typeof max == 'number'
      throw new Error "param `max` must be a number. Got '#{typeof max}'"
    unless max >= min
      throw new Error "invalid range [#{min}, #{max}]"

    (s) -> if s[prop]? then (min <= s[prop] <= max) else true
