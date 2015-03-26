#
# FormValidate is a validation class for a form with the following elements.
# inputs, textareas, selects, checkbox, passwords, phone numbers, emails. 
# 
# @author jbillings
#

class FormValidate

	constructor:(params) ->
		#
		# Options
		# @param form: ID of the form this validation should be used on.
		# @param ajax: Pass in true if you want to use AJAX to submit the form
		# @param ajaxResponses: pass in a custom Method you want called no submit 
		# of this form. Mostly incase you want to do your own AJAX type thing.
		#
		@options = 
			form: $j('body').find 'form'
			ajaxCallBack: false

		if params then @options[option] = value for option, value of params

		# Submit button of the form. Must be either input or button with type=submit.
		@_submitButton = @options.form.find 'input[type="submit"], button[type="submit"]'
		
		# Instantiate the form element object
		@_FormElements = {}

		# Cache form elements
		@_initFormElements()
		
		# Calls the blur listeners for form elements.
		@_validateOnBlur()

		# Calls the submit listener, validates and then submits if valid.
		@_validateOnSubmit()
	
	
	# Stores form elements into suited groups and caches them
	_initFormElements:() ->
		
		#
		# Cache all form elements into grouped objects.
		# Note - we are only interested in elements with a required attribute, all other 
		# elements are optional. 
		#
		@_FormElements._Inputs = @options.form.find('input[type="text"][required]:not([name="email"], [name="phone"])')
		@_FormElements._TextAreas = @options.form.find 'textarea[required]'
		@_FormElements._Emails = @options.form.find 'input[name="email"][required]'
		@_FormElements._Phones = @options.form.find 'input[name="phone"][required]'
		@_FormElements._Passwords = @options.form.find 'input[type="password"][required]'
		@_FormElements._Selects =  @options.form.find 'select[required]'
		@_FormElements._CheckBoxes = @options.form.find 'input[type="checkbox"][required]'
		@_FormElements._Radios = @options.form.find 'input[type="radio"][required]'
		return


	#
	# Set blur listeners to each type of form element for validation
	# on blur
	#
	_validateOnBlur:() ->
		
		if @_FormElements._Inputs.length > 0
			# Sets blur listner for input fields
			$j(@_FormElements._Inputs).on 'blur', (event) => 
				@_validateFields $j(event.target), 'input', false, true
				return

		if @_FormElements._TextAreas.length > 0
			# Sets blur listner for Text Areas
			$j(@_FormElements._TextAreas).on 'blur', (event) => 
				@_validateFields $j(event.target), 'textarea', false, true
				return

		if @_FormElements._Emails.length > 0
			# Sets blur listner for email fields
			$j(@_FormElements._Emails).on 'blur', (event) => 
				@_validateFields $j(event.target), 'email', false, true
				return

		if @_FormElements._Phones.length > 0
			# Sets blur listner for phone fields
			$j(@_FormElements._Phones).on 'blur', (event) => 
				@_validateFields $j(event.target), 'phone', false, true
				return

		if @_FormElements._Passwords.length > 0
			# Sets blur listner for password fields
			$j(@_FormElements._Passwords).on 'blur', (event) => 
				@_validateFields $j(event.target), 'password', false, true
				return

		if @_FormElements._Selects.length > 0
			# Sets change listner for select fields
			$j(@_FormElements._Selects).on 'change', (event) => 
				@_validateFields $j(event.target), 'select', true, true
				return

		if @_FormElements._CheckBoxes.length > 0
			# Sets change listner for checkbox fields
			$j(@_FormElements._CheckBoxes).on 'change', (event) => 
				@_validateFields $j(event.target), 'checkbox', false, true
				return

		if @_FormElements._Radios.length > 0
			# Sets change listner for radio buttons
			$j(@_FormElements._Radios).on 'change', (event) => 
				@_validateFields $j(event.target), 'radio', false, true
				return

		return


	_validateOnSubmit:() ->
		# Listens for the form submit button to be clicked to fire the submit 
		@_submitButton.on 'click', (event) =>
			event.preventDefault();
			@options.form.submit();
		
		# Sets the submit listener for the form and calls the validation logic.
		@options.form.on 'submit', (event) =>
			#
			# On submit initialize form elements again to check against any new
			# dynamically injected elements that were not cached on page load.
			#
			@_initFormElements()
			
			if @_validateAll()
				# console.log 'validate'
				if @options.ajaxCallBack
					event.preventDefault()
					@_ajaxSubmit()
				# If not ajax and no ajaxResponses, just proceed with submit
				else 
					true
			
			# Form doesn't validate so abort submit
			else
				false


	#
	# On form submit we call the validation methods for each
	# type of field and store an array of errors (badFields)
	# if any. We then check the array for errors and then assign
	# the appropriate Boolean to return for form completion.
	#
	_validateAll:() ->
		#
		# Merge the returned results from each validation type
		# into badFields array.
		#
		badFields = []
		$j.extend(
			badFields = [], 
			@_validateFields(@_FormElements._Inputs, 'input'), 
			@_validateFields(@_FormElements._Emails, 'email'), 
			@_validateFields(@_FormElements._Phones, 'phone'), 
			@_validateFields(@_FormElements._Selects, 'select', true), 
			@_validateFields(@_FormElements._Passwords, 'password'),
			@_validateFields(@_FormElements._CheckBoxes, 'checkbox'),
			@_validateFields(@_FormElements._TextAreas, 'textarea'),
			@_validateFields(@_FormElements._Radios, 'radio')
			)

		#
		# Check the length of badFields to determine final
		# form validation
		#
		if badFields.length is 0
			# Return form validation boolean
			valid = true
		else
			valid = false
			


	#
	# Central validation method
	# @param fields: Form element or object of grouped form elements
	# @param fieldType: Form group type. e.g select, input, password etc...
	# @param jsDropDown: Javascript based form element such as a jquery UI select menu
	# @param blur: Is this a blur event, otherwise it will be submit.
	#
	_validateFields:(fields, fieldType, jsDropDown=false, blur=false) ->
		# Initate array to collect errors
		error = []
		#
		# loop through element. Incase of a blur there will only be one
		# but this helps to reduce code for submit functionality as groups
		# of elements are sent in at once.
		#
		for field in fields
			# Check to see if the current element is a password field 
			if fieldType == 'password'
				error = @_validatePassword(fieldType, field, jsDropDown, error)
			# Otherwise call the general validation
			else
				error = @_validateField(fieldType, field, jsDropDown, error)
			#
			# if this is a blur and user hasn't put in any value then dont show
			# ANY validation UI. This is less annoying for the user when they select a
			# field and then click off of it.
			#
			if blur
				if $j(field).val().replace(/\s/g, '') == ''
					$j(field).parent().removeClass('error success error-js success-js')
		# return error Array
		return error

	
	#
	# Validate a password
	# @param fields: Form element or object of grouped form elements
	# @param fieldType: Form group type. e.g select, input, password etc...
	# @param jsDropDown: Javascript based form element such as a jquery UI select menu
	# @param error: array of errors being collected for each field
	#
	_validatePassword:(fieldType, field, jsDropDown, error) ->

		# Check if this is the second password so we can match the two
		if field == @_FormElements._Passwords[1] 
			# check if there is a match between the two passwords
			if !match = @_passwordsMatch(@_FormElements._Passwords[0], field)
				# Display the string error for mismatched passwords
				@stringError field, true
				# Display cross for unmatched field
				@_validateUI field, jsDropDown, false, true
				# push error into error array
				error.push($j(field))
			else 
				# Hide the string error message
				@stringError field, false
				# Password match so go through normal validation process
				error = @_validateField(fieldType, field, jsDropDown, error)
				
		else
			# It's the first password so go through normal validation method.
			error = @_validateField(fieldType, field, jsDropDown, error)

		return error

	#
	# Default validation method
	# @param fields: Form element or object of grouped form elements
	# @param fieldType: Form group type. e.g select, input, password etc...
	# @param jsDropDown: Javascript based form element such as a jquery UI select menu
	# @param error: array of errors being collected for each field
	#
	_validateField:(fieldType, field, jsDropDown, error) ->
		# check validation boolean based on field type
		valid = @_fieldTypeCheck(field, fieldType)
		# check if valid
		if valid
			# Display valid UI feedback
			@_validateUI field, jsDropDown, true
		else
			# Display invalid UI feedback
			@_validateUI field, jsDropDown, false
			# push error into error array
			error.push($j(field))


		return error

	#
	# Tests a value passed to it to validate depending on it's input type.
	# @param fields: Form element or object of grouped form elements
	# @param fieldType: Form group type. e.g select, input, password etc...
	#
	_fieldTypeCheck:(field, fieldType) ->
		# Cache field as jquery object
		element = $j(field)
		# Test the field type being passed in
		switch fieldType
			# Test for a valid email format
			when 'email' then /\S+@\S+\.\S+/.test element.val().replace(/\s/g, '')
			# Tests for numeric and special characters only
			when 'phone' then /[0-9]|\./.test element.val().replace(/\s/g, '')
			# Tests for a checkbox being checked
			when 'checkbox' 
				if field.checked then true else false
			# Tests password for minimum of 6 characters and both letters and numbers
			when 'radio' 
				if field.checked then true else false
			# Tests password for minimum of 6 characters and both letters and numbers
			when 'password' 
				if element.val().length < 6 || element.val().search(/[a-z]/i) < 0 || element.val().search(/[0-9]/) < 0
					false
				else 
					true
			# Test that field is not emtpy
			when 'input' 
				if element.val().replace(/\s/g, '') != '' then true else false
			# Test that field is not emtpy
			when 'select' 
				if element.val().replace(/\s/g, '') != '' then true else false
			# Test that field is not emtpy
			when 'textarea' 
				if element.val().replace(/\s/g, '') != '' then true else false
			# default to false
			else
				false

	#
	# Purely cosmetic method that displays UI type validation 
	# @param field: Form element
	# @param jsDropDown: Javascript based form element such as a jquery UI select menu
	# @param validate: boolean which states whether to hide or show validation UI
	#
	_validateUI:(field, jsDropDown=false, valid=false) ->
		# If valid show success UI display
		if valid
			# If javascript based element use different CSS classes for these elements
			# as the HTML stucture is slightly different.
			if !jsDropDown
				$j(field).parent().removeClass('error').addClass('success')
			else
				$j(field).parent().removeClass('error-js').addClass('success-js')
	
		# If invalid show error UI display
		else
			if !jsDropDown
				$j(field).parent().removeClass('success').addClass('error')
			else
				$j(field).parent().removeClass('success-js').addClass('error-js')
		return

	#
	# Purely cosmetic method that displays a UI error string 
	# @param field: Form element
	# @param show: boolean which states whether to hide or show validation UI string
	#
	stringError:(field, show=false) ->
		# show then show error string.
		if show
			$j(field).next().css('display', 'block')
		else
			$j(field).next().hide()
		return
	
	#
	# Check to see if passwords match
	# @param first: First password entered
	# @param second: Second password entered.
	#
	_passwordsMatch: (first, second) ->
		if ($j(first).val() == $j(second).val()) then true else false

	#
	# Can make an ajax request and call a method
	# passed into the class on instantiation when different
	# ajax event are fired, e.g .done, .always. 
	# This allows us to use the form class on any form but 
	# with custom ajax request and behavior for each.
	#
	_ajaxSubmit: () ->
		$j.ajax(
			type: 'get'
			url: @options.form.attr('action')
			dataType: 'text',
			data: @options.form.serialize()

			beforeSend: (xhr, response) =>
				@options.ajaxCallBack 'beforeSend'
			).done( (data) =>
				@options.ajaxCallBack 'done', data
			).always( (data) =>
				@options.ajaxCallBack 'always', data
			).fail( (data) =>
				@options.ajaxCallBack 'fail', data
			)
		return


exports.FormValidate = FormValidate;




