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
	Default
}

func _run() -> void:
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

		elif chr in '0123456789':
			step_back(file)
			current_token = get_numeric(file)
			step_back(file)
			token_stream.append(current_token)

		elif chr in '$%.#,\n=+-*)/\\(':
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
	join_pointers()
	join_endfunc()
	get_parameters()
	get_func_sigs()
	print(token_stream)
	print('Token Count: %s' % token_stream.size())
	print('Data usage: %s KiB' % (var_to_bytes(token_stream).size()/1000.0))

func join_pointers() -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == token_stream.size():
			break

		var token: RawToken = token_stream[cursor] as Token
		if !token:
			return

		if token.type == TokenType.Pointer:
			var a: Token = token_stream[cursor - 1] as Token
			var b: Token = token_stream[cursor + 1] as Token

			if !(a and b):
				printerr('A or B is not an identifier')
				return

			token.type = TokenType.Identifier
			token.value = '%s.%s' % [a.value, b.value]
			token_stream.remove_at(cursor + 1)
			token_stream.remove_at(cursor - 1)
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

func join_endfunc() -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == token_stream.size():
			break

		var token: Token = token_stream[cursor] as Token
		if !token or token.type != TokenType.End:
			continue

		var next: Token = token_stream[cursor + 1] as Token
		if !next or next.type != TokenType.Function:
			continue

		token.type = TokenType.EndFunc
		token_stream.remove_at(cursor + 1)

func get_func_sigs() -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == token_stream.size():
			break

		var token: Token = token_stream[cursor] as Token
		if !token or token.type != TokenType.Function:
			continue

		var func_pos: int = cursor

		var ident: Token = token_stream[cursor + 1] as Token

		if !ident or ident.type != TokenType.Identifier:
			continue

		var paren: Token = token_stream[cursor + 2] as Token
		if !paren or paren.type != TokenType.OpenParenthesis:
			continue

		cursor += 2
		var params: Array[ParameterToken] = []
		var current_token: ParameterToken = ParameterToken.new()
		while current_token.type != TokenType.CloseParenthesis:
			cursor += 1
			current_token = token_stream[cursor] as ParameterToken
			if !current_token: break
			if current_token is ParameterToken:
				params.append(current_token)

		var function: FuncSigToken = FuncSigToken.new()
		function.name = ident.value
		function.params = params

		token_stream[func_pos] = function
		for i: int in range(cursor, func_pos, -1):
			token_stream.remove_at(i)
		cursor = func_pos
		DisplayServer.clipboard_set(str(inst_to_dict(function)))

func get_parameters() -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == token_stream.size():
			return

		var token: Token = token_stream[cursor] as Token
		if !token: continue

		if token.type == TokenType.Type:
			var ident: Token = token_stream[cursor - 1] as Token
			if !ident or ident.type != TokenType.Identifier: return

			var new_token: ParameterToken = ParameterToken.new()
			new_token.name = ident.value
			new_token.data_type = token.value
			token_stream[cursor] = new_token
			token_stream.remove_at(cursor - 1)
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
			TokenType.StringLiteral: return '<str>'
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

		return '<%s, %s>' % ['cisny'[type], value if value != '\n' else 'N']
