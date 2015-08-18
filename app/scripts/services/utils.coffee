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
      ordered = list.slice().sort (a, b) -> a[rankProp] - b[rankProp]
      if order == 'DESC' then ordered.reverse()

      rank: (ordered.indexOf item) + 1  # +1 because it's 1-indexed
      total: filtered.length
