'use strict'

###*
 # @ngdoc service
 # @name edudashApp.WorldBankApi
 # @description
 # # WorldBankApi
 # Service in the edudashApp.
###
angular.module('edudashAppSrv').service 'bracketsSrv', ($q, utils) ->

  AVG_GPA_MIN = 3
  AVG_GPA_MAX = 4.2
  PASS_RATE_MIN = 0
  PASS_RATE_MID1 = 41
  PASS_RATE_MID2 = 59
  PASS_RATE_MAX = 100
  PUPIL_TEACHER_RATIO_MIN = 0
  PUPIL_TEACHER_RATIO_MID1 = 35
  PUPIL_TEACHER_RATIO_MID2 = 50
  PUPIL_TEACHER_RATIO_MAX = 100

  getBrackets: (metric) ->
    switch metric
      when 'AVG_MARK' then throw new Error "AVG_MARK shall not be bracket"
      when 'AVG_GPA' then [AVG_GPA_MIN, AVG_GPA_MAX]
      when 'PASS_RATE' then [PASS_RATE_MIN, PASS_RATE_MID1, PASS_RATE_MID2, PASS_RATE_MAX]
      when 'PUPIL_TEACHER_RATIO' then [PUPIL_TEACHER_RATIO_MIN, PUPIL_TEACHER_RATIO_MID1, PUPIL_TEACHER_RATIO_MID2, PUPIL_TEACHER_RATIO_MAX]

  getBracket: (val, metric) ->
    unless typeof val in ['number', 'undefined', 'string']
      throw new Error "val must be a number. Got: '#{val}' which is '#{typeof val}'"
    if isNaN val  # NaN or undefined
      'UNKNOWN'
    else
      if typeof val is 'string' # this is a hack since the negative come as string values
        val = parseInt val

      switch metric

        when 'AVG_MARK' then throw new Error "AVG_MARK shall not be bracket"

        # According to Mark we don't have to validate GPA ranges
        when 'AVG_GPA' then switch
          when val <= AVG_GPA_MIN then 'POOR'
          when AVG_GPA_MIN < val <= AVG_GPA_MAX then 'MEDIUM'
          when val > AVG_GPA_MAX then 'GOOD'  # what's the upper limit?

        when 'CHANGE_PREVIOUS_YEAR' then switch
          when val < 0 then 'POOR'
          when val == 0 then 'MEDIUM'
          when val > 0 then 'GOOD'

        when 'CHANGE_PREVIOUS_YEAR_PASSRATE' then switch
          when val < 0 then 'POOR'
          when val == 0 then 'MEDIUM'
          when val > 0 then 'GOOD'

        when 'CHANGE_PREVIOUS_YEAR_GPA' then switch
          when val < 0 then 'GOOD'
          when val == 0 then 'MEDIUM'
          when val > 0 then 'POOR'
          # `when`s are exhaustive: tested typeof === number and !isNaN

        when 'PASS_RATE' then switch
          when PASS_RATE_MIN <= val < PASS_RATE_MID1 then 'POOR'
          when PASS_RATE_MID1 <= val <= PASS_RATE_MID2 then 'MEDIUM'
          when PASS_RATE_MID2 < val <= PASS_RATE_MAX then 'GOOD'
          else 'UNKNOWN'

        when 'PUPIL_TEACHER_RATIO' then switch
          when PUPIL_TEACHER_RATIO_MIN < val < PUPIL_TEACHER_RATIO_MID1 then 'MEDIUM'
          when PUPIL_TEACHER_RATIO_MID1 <= val <= PUPIL_TEACHER_RATIO_MID2 then 'GOOD'
          when val > PUPIL_TEACHER_RATIO_MID2 then 'POOR'
          else 'UNKNOWN'

        when 'LOCATION_IS_APPROXIMATE' then switch
          when val == 0 then 'GOOD'
          else 'UNKNOWN'

        else throw new Error "Unknown metric: '#{metric}'"

  hasBadge: (badge, schoolType, school, allSchools) ->
    unless allSchools? and typeof allSchools.then == 'function'
      throw new Error "param `rankedSchools` must be a Promise. Got '#{typeof allSchools}'"
    qualify = (prop, order, limit) ->
      allSchools.then (schools) ->
        unless schools instanceof Array
          return $q (_, reject) -> reject "`rankedSchools` promise must resolve to an Array. Got '#{typeof schools}'"
        rank = utils.rank(school, schools, prop, null, order).rank
        $q.when switch
          when 1 <= rank <= limit then true
          when rank > limit then false
          else null  # maybe warn?

    switch schoolType
      when 'primary' then switch badge
        when 'top-100' then qualify 'AVG_MARK', 'DESC', 100
        when 'most-improved' then qualify 'CHANGE_PREVIOUS_YEAR', 'DESC', 300
        else throw new Error "Unknown primary badge '#{badge}'"
      when 'secondary' then switch badge
        when 'top-100' then qualify 'AVG_GPA', 'DESC', 100
        when 'most-improved' then qualify 'CHANGE_PREVIOUS_YEAR_GPA', 'DESC', 100
        else throw new Error "Unknown secondary badge '#{badge}'"
      else throw new Error "Unknown schoolType '#{schoolType}'"

  getVisMetric: (visMode) ->
    switch visMode
      when 'passrate' then 'PASS_RATE'
      when 'ptratio' then 'PUPIL_TEACHER_RATIO'
      when 'gpa' then 'AVG_GPA'
      when 'combined' then 'PASS_RATE'
      when 'locaccuracy' then 'LOCATION_IS_APPROXIMATE'
      else throw new Error "Unknown vis mode '#{visMode}'"

  getSortMetric: (schoolType, criteria, inverse) ->
    unless schoolType in ['primary', 'secondary']
      throw new Error "Unknown school type '#{schoolType}'"
    unless criteria in ['performance', 'improvement']
      throw new Error "Unknown criteria '#{criteria}'"
    order = if inverse? and inverse then 'ASC' else 'DESC'
    switch schoolType
      when 'primary' then switch criteria
        when 'performance' then ['AVG_MARK', order]
        when 'improvement' then ['CHANGE_PREVIOUS_YEAR', order]
      when 'secondary' then switch criteria
        when 'performance' then ['AVG_GPA', order]
        when 'improvement' then ['CHANGE_PREVIOUS_YEAR_GPA', order]

  getRank: (schoolType) ->
    unless schoolType in ['primary', 'secondary']
      throw new Error "Unknown school type '#{schoolType}'"
    switch schoolType
      when 'primary' then ['AVG_MARK', 'DESC'] # AVG_MARK is sum of 5 exam from 0-50, greater the better, order desc
      when 'secondary' then ['AVG_GPA', 'DESC'] # AVG_GPA greater the better. order desc

  getLimit: (schoolType, criteria) ->
    unless schoolType in ['primary', 'secondary']
      throw new Error "Unknown school type '#{schoolType}'"
    unless criteria in ['performance', 'improvement']
      throw new Error "Unknown criteria '#{criteria}'"
    if schoolType is 'primary' and criteria is 'improvement' then 300 else 100

  getMarkStyle: (school, visMode, options, color) ->
    unless school?
      throw new Error "Unknown school '#{school}'"
    if visMode in ['ptratio', 'locaccuracy']
      if color is '#aaa'
        options.fillColor = color
      else 
        options.fillColor = '#05a2dc'
    else
      options.fillColor = color
    if visMode in ['combined', 'ptratio']
      options.radius = switch this.getBracket school.PUPIL_TEACHER_RATIO, 'PUPIL_TEACHER_RATIO'
        when 'MEDIUM' then 4
        when 'GOOD' then 6
        when 'POOR' then 8
        else 
          if visMode is 'combined'
            options.color = options.fillColor
            options.fill = false
            options.weight = 2
          4
    if visMode is 'locaccuracy'
      options.radius = 4

    options
