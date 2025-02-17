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
	To,
	Step,
	Next,
	Function,
	While,
	If,
	Elif,
	Else,
	EndIf,
	EndSelect,
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
	InitObj,
	Return,
	Case,
	SwitchCase,
	LessThan,
	GreaterThan,
	NotEqual,
	Literal,
	OpenBracket,
	ClosedBracket,
	FuncCall,
	ArrayAccess
}

func _run() -> void:
	var timer: int = Time.get_ticks_msec()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var current_token: Token = Token.new()

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

		elif chr in '$%.#,\n=+-*)/\\(><[]:':
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
		if contains_token(line, TokenType.Typer):
			join_typing(line)
		if contains_token(line, TokenType.Type):
			get_parameters(line)
		if contains_token(line, TokenType.End):
			join_endfunc(line)
			join_endif(line)
			join_endselect(line)
		if contains_token(line, TokenType.Function):
			get_func_sigs(line)
		if contains_token(line, TokenType.New):
			join_new(line)
		if contains_token(line, TokenType.Case):
			join_case(line)
		if contains_token(line, TokenType.LessThan):
			join_ne(line)
		if contains_type(line, &"ContainerSide"):
			join_containers(line)
		if contains_type(line, &"TokenContainer"):
			join_func_calls(line)

		token_count += line.size()
		print(line)
		print()

	print()

	print('Token Count: %s' % token_count)
	print('Data usage: %s KiB' % (var_to_bytes(token_stream).size()/1000.0))
	print('Parsing time: %s msec' % (Time.get_ticks_msec() - timer))

func join_case(line: Array) -> void:
	if (line[0] as RawToken).type != TokenType.Case:
		return

	var case: CaseToken = CaseToken.new()
	case.case = line[1]
	line.remove_at(1)
	line[0] = case

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

func contains_type(line: Array, type: StringName) -> bool:
	for token: RawToken in line:
		if str(inst_to_dict(token)['@subpath']) == type:
			return true
	return false

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

func join_endif(line: Array) -> void:
	join_end(line, TokenType.If, TokenType.EndIf)

func join_endselect(line: Array) -> void:
	join_end(line, TokenType.Select, TokenType.EndSelect)

func join_end(line: Array, type: TokenType, result: TokenType) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: Token = line[cursor] as Token
		if !token:
			continue

		if token.type != TokenType.End:
			continue

		var ident: Token = line[cursor + 1] as Token
		if !ident or ident.type != type:
			continue

		token.type = result
		line.remove_at(cursor + 1)

func join_typing(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: Token = line[cursor] as Token
		if !token:
			continue

		if token.type != TokenType.Typer:
			continue

		var ident: Token = line[cursor + 1] as Token
		if !ident or ident.type != TokenType.Identifier:
			continue

		token.type = TokenType.Type
		token.value = ident.value
		line.remove_at(cursor + 1)

func join_ne(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var token: Token = line[cursor] as Token
		if !token:
			continue

		if token.type != TokenType.LessThan:
			continue

		var ident: Token = line[cursor + 1] as Token
		if !ident or ident.type != TokenType.GreaterThan:
			continue

		token.type = TokenType.NotEqual
		line.remove_at(cursor + 1)

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

		var token: Token = line[cursor] as Token
		if !token:
			continue

		if token.type == TokenType.Pointer:
			var a: Token = line[cursor - 1] as Token
			var b: Token = line[cursor + 1] as Token

			if !(a and b):
				continue

			token.type = TokenType.Identifier
			token.value = '%s.%s' % [a.value, b.value]
			line.remove_at(cursor + 1)
			line.remove_at(cursor - 1)
			cursor -= 1

func join_variable_declarations() -> void:
	pass

func join_containers(line: Array) -> void:
	var sides: PackedInt32Array = []
	var cursor: int = 0

	while cursor < line.size():
		var token: ContainerSide = line[cursor] as ContainerSide
		if token and token.is_open:
			get_container(token.container_type, line, cursor + 1)

		cursor += 1

func get_container(type: ContainerType, line: Array, position: int) -> void:
	var cursor: int = position

	while cursor < line.size():

		var token: ContainerSide = line[cursor] as ContainerSide
		if !token:
			cursor += 1
			continue

		if token.is_open:
			cursor += 1
			get_container(token.container_type, line, cursor)

		if token.container_type == type:
			var container: TokenContainer = TokenContainer.new()
			container.container_type = type
			container.content = line.slice(position, cursor)
			line[position - 1] = container

			for i: int in range(position, cursor):
				line.remove_at(position)
			if position < line.size():
				line.remove_at(position)

			if type == ContainerType.Bracket:
				join_array_access(line)

		cursor += 1

func scan_keywords() -> void:
	var cursor: int = -1
	while true:
		cursor += 1

		if cursor == token_stream.size():
			break

		var token: Token = token_stream[cursor] as Token
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
			'Shl':
				token.type = TokenType.Operator
				token.value = '<<'
				continue
			'Shr':
				token.type = TokenType.Operator
				token.value = '>>'
				continue
			'End': token.type = TokenType.End
			'Return': token.type = TokenType.Return
			'(': token_stream[cursor] = ContainerSide.new(ContainerType.Parenthesis, true)
			')': token_stream[cursor] = ContainerSide.new(ContainerType.Parenthesis, false)
			'[': token_stream[cursor] = ContainerSide.new(ContainerType.Bracket, true)
			']': token_stream[cursor] = ContainerSide.new(ContainerType.Bracket, false)
			'{': token_stream[cursor] = ContainerSide.new(ContainerType.Braces, true)
			'}': token_stream[cursor] = ContainerSide.new(ContainerType.Braces, false)
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
			'<': token.type = TokenType.LessThan
			'>': token.type = TokenType.GreaterThan
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
			'Null':
				token_stream[cursor] = NullToken.new()
			'Then': token.type = TokenType.Then
			'Local': token.type = TokenType.Local
			'Select': token.type = TokenType.Select
			'For': token.type = TokenType.For
			'To': token.type = TokenType.To
			'Step': token.type = TokenType.Step
			'Next': token.type = TokenType.Next
			'Exit': token.type = TokenType.Break
			'Case': token.type = TokenType.Case

			_:
				continue

		token.value = ''

func join_array_access(line: Array) -> void:
	var cursor: int = -1

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var cont: TokenContainer = line[cursor] as TokenContainer
		if !cont or cont.container_type != ContainerType.Bracket:
			continue

		var ident: Token = line[cursor - 1] as Token
		if !ident or ident.type != TokenType.Identifier:
			continue

		cursor -= 1
		var arr: ArrayToken = ArrayToken.new()
		arr.ident = ident.value
		arr.index = cont.content
		arr.type = TokenType.ArrayAccess
		line[cursor] = arr
		line.remove_at(cursor + 1)

func join_func_calls(line: Array) -> void:
	var cursor: int = 0

	while true:
		cursor += 1
		if cursor == line.size():
			break

		var cont: TokenContainer = line[cursor] as TokenContainer
		if !cont or cont.container_type != ContainerType.Parenthesis:
			continue

		var ident: Token = line[cursor - 1] as Token
		if !ident or ident.type != TokenType.Identifier:
			continue

		cursor -= 1
		var call: FuncCallToken = FuncCallToken.new()
		call.function = ident.value
		call.args = cont.content
		call.type = TokenType.FuncCall
		line[cursor] = call
		line.remove_at(cursor + 1)
		join_func_calls(call.args)

func join_endfunc(line: Array) -> void:
	join_end(line, TokenType.Function, TokenType.EndFunc)

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

func get_string(file: FileAccess) -> StringToken:
	var token: Token = get_token(
		file, TokenType.StringLiteral, "Missing closing \"",
		func(chr: String) -> bool: return chr != '"'
	)

	var lit_token: StringToken = StringToken.new()
	lit_token.value = token.value

	return lit_token

func get_numeric(file: FileAccess) -> NumberToken:
	var token: Token = get_token(
		file, TokenType.NumericValue, "Missing closing \"",
		func(chr: String) -> bool: return chr in '0123456789.'
	)

	var lit_token: NumberToken = NumberToken.new()
	lit_token.value = token.value

	return lit_token

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

enum ContainerType {
	Parenthesis,
	Bracket,
	Braces
}

class ContainerSide extends RawToken:

	var container_type: ContainerType
	var is_open: bool

	func _init(type: ContainerType, is_open: bool) -> void:
		container_type = type
		self.is_open = is_open

	func _to_string() -> String:
		return '<%s>' % ['()', '[]', '{}'][container_type][int(!is_open)]

class ArrayToken extends RawToken:
	var ident: StringName
	var index: Array

	func _to_string() -> String:
		return '<array name: %s, index: %s>' % [ident, index]

class FuncCallToken extends RawToken:
	var function: StringName
	var args: Array

	func _to_string() -> String:
		return '<call func: %s, args: %s>' % [function, args]

class TokenContainer extends RawToken:
	static var containers: Array[TokenContainer] = []
	var container_type: ContainerType
	var content: Array = []

	func _init() -> void:
		containers.append(self)

	func _to_string() -> String:
		return '<cont type: %s, content: %s>' % ['pbc'[container_type], content]

class FuncSigToken:
	var name: String
	var params: Array[ParameterToken]

	func _to_string() -> String:
		return '<funcsig name: %s, params: %s>' % [name, params]

class CaseToken extends RawToken:
	var case: RawToken

	func _to_string() -> String:
		return '<case pattern: %s>' % case

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

class ValueToken extends Token:
	var data_type: String

	func _to_string() -> String:
		return '<lit type: %s, value: %s>' % [data_type, value]

class ExprToken extends ValueToken:
	pass


class StringToken extends ValueToken:

	func _to_string() -> String:
		return '<str>'

class NumberToken extends ValueToken:
	func _to_string() -> String:
		return '<number>'

class NullToken extends ValueToken:
	func _to_string() -> String:
		return '<null>'

class Token extends RawToken:
	var value: String

	func _to_string() -> String:
		match type:
			TokenType.Comment: return '<Comment>'
			TokenType.NumericValue: return '<%s>' % value
			TokenType.Function: return '<func>'
			TokenType.For: return '<for>'
			TokenType.To: return '<to>'
			TokenType.Step: return '<step>'
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
			TokenType.Pointer: return '<ref>'
			TokenType.Typer: return '<ty>'
			TokenType.Comma: return '<,>'
			TokenType.End: return '<end>'
			TokenType.Bool: return '<%s>' % value.to_lower()
			TokenType.Next: return '<continue>'
			TokenType.Break: return '<break>'
			TokenType.EndFunc: return '<endfunc>'
			TokenType.Default: return '<default>'
			TokenType.New: return '<new>'
			TokenType.InitObj: return '<init type: %s>' % value
			TokenType.Return: return '<return>'
			TokenType.Case: return '<case>'
			TokenType.LessThan: return '<lt>'
			TokenType.GreaterThan: return '<gt>'
			TokenType.NotEqual: return '<!=>'
			TokenType.EndSelect: return '<endselect>'

		return '<%s, %s>' % ['cisny'[type], value if value != '\n' else 'N']
