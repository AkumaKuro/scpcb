@tool
extends EditorScript

const path: String = "res://testcode.txt"

var token_stream: Array[Token] = []

enum TokenType {
	Comment,
	Identifier,
	StringLiteral,
	NumericValue,
	Symbol,
	For,
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
	Comma
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
	print(token_stream)

func scan_keywords() -> void:
	for token: Token in token_stream:
		if token.type not in [TokenType.Identifier, TokenType.Symbol]:
			continue

		match token.value:
			'Function': token.type = TokenType.Function
			'\n': token.type = TokenType.NewLine
			'If': token.type = TokenType.If
			'ElseIf': token.type = TokenType.Elif
			'Else': token.type = TokenType.Else
			'EndIf': token.type = TokenType.EndIf
			'(': token.type = TokenType.OpenParenthesis
			')': token.type = TokenType.CloseParenthesis
			'\\': token.type = TokenType.Pointer
			'.': token.type = TokenType.Typer
			',': token.type = TokenType.Comma
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

			_:
				continue

		token.value = ''

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

class Token:
	var type: TokenType
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

		return '<%s, %s>' % ['cisny'[type], value if value != '\n' else 'N']
