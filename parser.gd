@tool
extends EditorScript

const path: String = "res://testcode.txt"

var token_stream: Array = []

enum TokenType {
	Comment,
	Identifier,
	StringLiteral,
	NumericValue,
	Symbol,
	For,
	Next,
	Function,
	While,
	If,
	Elif,
	Else,
	EndIf,
	NewLine,
	Operator,
	Then,
	Null,
	Local,
	Select,
	OpenParenthesis,
	CloseParenthesis,
	Type,
	Typer,
	Pointer,
	Comma,
	End,
	EndFunc,
	Bool,
	Break,
	Default,
	New,
	InitObj
}

func _run() -> void:
	var timer: int = Time.get_ticks_msec()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var current_token: Token = Token.new()
	var current_type: TokenType

	if file.eof_reached():
		print("Empty file")
		return

	var chr: String = char(file.get_8())

	while chr:
		if chr == ';':
			current_token = get_comment(file)
			token_stream.append(current_token)
			var token: Token = Token.new()
			token.type = TokenType.NewLine
			token_stream.append(token)

		elif chr in '0123456789':
			step_back(file)
			current_token = get_numeric(file)
			step_back(file)
			token_stream.append(current_token)

		elif chr in '$%.#,\n=+-*)/\\(><':
			current_token = Token.new()
			current_token.type = TokenType.Symbol
			current_token.value = chr
			token_stream.append(current_token)

		elif chr == '"':
			current_token = get_string(file)
			token_stream.append(current_token)

		elif chr.to_lower() in 'abcdefghijklmnopqrstuvwxyz':
			step_back(file)
			current_token = get_identifier(file)
			step_back(file)
			token_stream.append(current_token)

		chr = get_char(file)

	scan_keywords()
	clean_newlines()
	split_lines()

	var token_count: int = 0
	for line in token_stream:
		if line is not Array:
			continue

		if contains_token(line, TokenType.Pointer):
			join_pointers(line)
		if contains_token(line, TokenType.Type):
			get_parameters(line)
		if contains_token(line, TokenType.Function):
			join_endfunc(line)
			get_func_sigs(line)
		if contains_token(line, TokenType.New):
			join_new(line)

		token_count += line.size()
		print(line)

	print('Token Count: %s' % token_count)
	print('Data usage: %s KiB' % (var_to_bytes(token_stream).size()/1000.0))
	print('Parsing time: %s msec' % (Time.get_ticks_msec() - timer))

func split_lines() -> void:
	var lines: Array = []

	var last_cursor: int = 0
	var cursor: int = 0

	while cursor < token_stream.size() - 1:
		cursor += 1

		var token: Token = token_stream[cursor] as Token
		if !token:
			continue

		if token.type != TokenType.NewLine:
			continue

		lines.append(token_stream.slice(last_cursor + 1, cursor))
		last_cursor = cursor

	token_stream = lines

func contains_token(array: Array, type: TokenType) -> bool:
	var counter: int = -1

	while counter < array.size() - 1:
		counter += 1
		var token: Token = array[counter] as Token

		if !token:
			continue

		if token.type == type:
			return true
	return false

func join_new(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: Token = line[cursor] as Token
		if !token:
			continue

		if token.type != TokenType.New:
			continue

		var ident: Token = line[cursor + 1] as Token
		if !ident or ident.type != TokenType.Identifier:
			continue

		token.type = TokenType.InitObj
		token.value = ident.value
		line.remove_at(cursor + 1)

func join_pointers(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: RawToken = line[cursor] as Token
		if !token:
			return

		if token.type == TokenType.Pointer:
			var a: Token = line[cursor - 1] as Token
			var b: Token = line[cursor + 1] as Token

			if !(a and b):
				printerr('A or B is not an identifier')
				return

			token.type = TokenType.Identifier
			token.value = '%s.%s' % [a.value, b.value]
			line.remove_at(cursor + 1)
			line.remove_at(cursor - 1)
			cursor -= 1

func join_variable_declarations() -> void:
	pass

func scan_keywords() -> void:
	for token: RawToken in token_stream:
		token = token as Token
		if !token:
			continue

		if token.type not in [TokenType.Identifier, TokenType.Symbol]:
			continue

		match token.value:
			'Function': token.type = TokenType.Function
			'\n': token.type = TokenType.NewLine
			'If': token.type = TokenType.If
			'ElseIf': token.type = TokenType.Elif
			'Else': token.type = TokenType.Else
			'EndIf': token.type = TokenType.EndIf
			'End': token.type = TokenType.End
			'(': token.type = TokenType.OpenParenthesis
			')': token.type = TokenType.CloseParenthesis
			'\\': token.type = TokenType.Pointer
			'.': token.type = TokenType.Typer
			',': token.type = TokenType.Comma
			'New': token.type = TokenType.New
			'Default': token.type = TokenType.Default
			'True', 'False':
				token.type = TokenType.Bool
				continue
			'$', '#', '%':
				token.type = TokenType.Type
				token.value = {
					'$': 'str',
					'%': 'int',
					'#': 'float'
				}[token.value]
				continue
			'=', '+', '-', '*', '/':
				token.type = TokenType.Operator
				continue
			'And':
				token.type = TokenType.Operator
				token.value = '&'
				continue
			'Or':
				token.type = TokenType.Operator
				token.value = '|'
				continue
			'Null': token.type = TokenType.Null
			'Then': token.type = TokenType.Then
			'Local': token.type = TokenType.Local
			'Select': token.type = TokenType.Select
			'For': token.type = TokenType.For
			'Next': token.type = TokenType.Next
			'Exit': token.type = TokenType.Break

			_:
				continue

		token.value = ''

func join_endfunc(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: Token = line[cursor] as Token
		if !token or token.type != TokenType.End:
			continue

		var next: Token = line[cursor + 1] as Token
		if !next or next.type != TokenType.Function:
			continue

		token.type = TokenType.EndFunc
		line.remove_at(cursor + 1)

func get_func_sigs(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: Token = line[cursor] as Token
		if !token or token.type != TokenType.Function:
			continue

		var func_pos: int = cursor

		var ident: Token = line[cursor + 1] as Token

		if !ident or ident.type != TokenType.Identifier:
			continue

		var paren: Token = line[cursor + 2] as Token
		if !paren or paren.type != TokenType.OpenParenthesis:
			continue

		cursor += 2
		var params: Array[ParameterToken] = []
		var current_token: ParameterToken = ParameterToken.new()
		while current_token.type != TokenType.CloseParenthesis:
			cursor += 1
			current_token = line[cursor] as ParameterToken
			if !current_token: break
			if current_token is ParameterToken:
				params.append(current_token)

		var function: FuncSigToken = FuncSigToken.new()
		function.name = ident.value
		function.params = params

		line[func_pos] = function
		for i: int in range(cursor, func_pos, -1):
			line.remove_at(i)
		cursor = func_pos

func get_parameters(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			return

		var token: Token = line[cursor] as Token
		if !token: continue

		if token.type == TokenType.Type:
			var ident: Token = line[cursor - 1] as Token
			if !ident or ident.type != TokenType.Identifier: return

			var new_token: ParameterToken = ParameterToken.new()
			new_token.name = ident.value
			new_token.data_type = token.value
			line[cursor] = new_token
			line.remove_at(cursor - 1)
			cursor -= 1

func clean_newlines() -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == token_stream.size():
			return

		var token: Token = token_stream[cursor] as Token
		if !token:
			continue

		if token.type == TokenType.NewLine:
			if cursor == token_stream.size() - 1:
				return
			var next: Token = token_stream[cursor + 1] as Token
			if !next:
				continue

			if next.type == TokenType.NewLine:
				token_stream.remove_at(cursor + 1)
				cursor -= 1

func step_back(file: FileAccess) -> void:
	file.seek(file.get_position() - 1)

func get_token(file: FileAccess, type: TokenType, error: String, filter: Callable) -> Token:
	var token: Token = Token.new()
	token.type = type

	var current_char: String = get_char(file)
	while filter.call(current_char):
		token.value += current_char
		current_char = get_char(file)

		if file.eof_reached():
			if error:
				print(error)
			break

	return token

func get_identifier(file: FileAccess) -> Token:
	return get_token(
		file, TokenType.Identifier, "",
		func(chr: String) -> bool:
			return chr.to_lower() in 'abcdefghijklmnopqrstuvwxyz_0123456789'
	)

func get_string(file: FileAccess) -> Token:
	return get_token(
		file, TokenType.StringLiteral, "Missing closing \"",
		func(chr: String) -> bool: return chr != '"'
	)

func get_numeric(file: FileAccess) -> Token:
	return get_token(
		file, TokenType.NumericValue, "",
		func(chr: String) -> bool: return chr in '0123456789.'
	)

func get_comment(file: FileAccess) -> Token:
	return get_token(
		file, TokenType.Comment, "",
		func(chr: String) -> bool: return chr != '\n'
	)

func get_char(file: FileAccess) -> String:
	if !file.eof_reached():
		return char(file.get_8())
	else:
		return ''

class RawToken:
	var type: TokenType

enum DataType {
	Int,
	Float,
	Str
}

class FuncSigToken:
	var name: String
	var params: Array[ParameterToken]

	func _to_string() -> String:
		return '<funcsig name: %s, params: %s>' % [name, params]

class ParameterToken extends RawToken:
	var name: String
	var data_type: String

	func _to_string() -> String:
		return '<param name: %s, type: %s>' % [name, data_type]

class VarDecToken:
	var name: String
	var data_type: DataType
	var value: String

	func _to_string() -> String:
		return '<VarDec name: %s, type: %s, value: %s>' % [name, data_type, value]

class Token extends RawToken:
	var value: String

	func _to_string() -> String:
		match type:
			TokenType.Comment: return '<Comment>'
			TokenType.NumericValue: return '<%s>' % value
			TokenType.Function: return '<func>'
			TokenType.For: return '<for>'
			TokenType.While: return '<while>'
			TokenType.NewLine: return '<nl>'
			TokenType.If: return '<if>'
			TokenType.Then: return '<then>'
			TokenType.Elif: return '<elif>'
			TokenType.Else: return '<else>'
			TokenType.EndIf: return '<endif>'
			TokenType.Null: return '<null>'
			TokenType.Operator: return '<%s>' % value
			TokenType.Local: return '<local>'
			TokenType.Select: return '<select>'
			TokenType.StringLiteral: return '"%s"' % value
			TokenType.OpenParenthesis: return '<(>'
			TokenType.CloseParenthesis: return '<)>'
			TokenType.Type: return '<type: %s>' % value
			TokenType.Pointer: return '->'
			TokenType.Typer: return '<ty>'
			TokenType.Comma: return '<,>'
			TokenType.End: return '<End>'
			TokenType.Bool: return '<%s>' % value.to_lower()
			TokenType.Next: return '<continue>'
			TokenType.Break: return '<break>'
			TokenType.EndFunc: return '<endfunc>'
			TokenType.Default: return '<default>'
			TokenType.New: return '<new>'
			TokenType.InitObj: return '<init type: %s>' % value

		return '<%s, %s>' % ['cisny'[type], value if value != '\n' else 'N']
