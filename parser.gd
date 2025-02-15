extends Node

const path: String = "res://testcode.txt"

var token_stream: Array = []

enum KeyWord {
	Function,
	Then,
	Local,
	Select
}

enum Symbol {
	And,
	Or,
	Equals,
}

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
	EndSelect,
	NewLine,
	Operator,
	Then,
	Null,
	Local,
	Select,
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
	LessThan,
	GreaterThan,
	NotEqual,
	Literal,
	OpenBracket,
	ClosedBracket
}

func _ready() -> void:
	var timer: int = Time.get_ticks_msec()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	var current_token: RawToken = Token.new()
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

		elif chr in '$%.#,\n=+-*)/\\(><[]':
			match chr:
				'&': current_token = TypeToken.new(&'str')
				'%': current_token = TypeToken.new(&'int')
				'#': current_token = TypeToken.new(&'float')

				'(': current_token = ContainerSide.new(ContainerType.Parenthesis, true)
				')': current_token = ContainerSide.new(ContainerType.Parenthesis, false)

				_:
					current_token = null #SymbolToken.new(Symbol.Or)
					#current_token.value = chr
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

		if contains_token(line, TokenType.New):
			join_new(line)
		if contains_token(line, TokenType.LessThan):
			join_ne(line)
		if contains_type(line, &"ContainerSide"):
			pass #join_containers(line)
		if contains_token(line, TokenType.Function):
			get_func_sigs(line)

		token_count += line.size()
		print(line)

	print()

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

		cursor += 1


func scan_keywords() -> void:
	var cursor: int = -1
	while true:
		cursor += 1

		if cursor == token_stream.size():
			break

		var token: IdentifierToken = token_stream[cursor] as IdentifierToken

		if !token:
			continue

		match token.name:
			'Function': token_stream[cursor] = KeyWordToken.new(KeyWord.Function)
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
				token_stream[cursor] = SymbolToken.new(Symbol.And)
			'Or':
				token_stream[cursor] = SymbolToken.new(Symbol.Or)
			'Null': token_stream[cursor] = NullToken.new()
			'Then': token_stream[cursor] = KeyWordToken.new(KeyWord.Then)
			'Local': token_stream[cursor] = KeyWordToken.new(KeyWord.Local)
			'Select': token_stream[cursor] = KeyWordToken.new(KeyWord.Select)
			'For': token.type = TokenType.For
			'Next': token.type = TokenType.Next
			'Exit': token.type = TokenType.Break

			_:
				continue

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

		var container: TokenContainer = line[cursor + 2] as TokenContainer
		if !container or container.container_type != ContainerType.Parenthesis:
			print(container.container_type != ContainerType.Parenthesis)
			continue

		var params: Array[ParameterToken] = []
		for param: IdentifierToken in container.content:
			var typed_param: ParameterToken = param as ParameterToken

			if !typed_param:
				typed_param = ParameterToken.new()
				typed_param.data_type = ''
				typed_param.name = param.name

			params.append(typed_param)

		var function: FuncSigToken = FuncSigToken.new()
		function.name = ident.value
		function.params = params

		line[func_pos] = function
		for i: int in range(2):
			line.remove_at(func_pos + 1)

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

func get_identifier(file: FileAccess) -> IdentifierToken:
	var token: Token =  get_token(
		file, TokenType.Identifier, "",
		func(chr: String) -> bool:
			return chr.to_lower() in 'abcdefghijklmnopqrstuvwxyz_0123456789'
	)

	var ident: IdentifierToken = IdentifierToken.new()
	ident.name = token.value
	return ident

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
		file, TokenType.NumericValue, "",
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

class KeyWordToken extends RawToken:
	var keyword: KeyWord
	func _init(keyword: KeyWord) -> void:
		self.keyword = keyword

	func _to_string() -> String:
		return '<%s>' % [
			'func', 'then', 'local', 'select'
		][keyword]

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

class IdentifierToken extends RawToken:
	var name: String

	func _to_string() -> String:
		return '<i name: %s>' % name

class ParameterToken extends IdentifierToken:
	var data_type: String

	func _to_string() -> String:
		return '<param name: %s, type: %s>' % [name, data_type]

class VarDecToken:
	var name: String
	var data_type: DataType
	var value: String

	func _to_string() -> String:
		return '<VarDec name: %s, type: %s, value: %s>' % [name, data_type, value]

class TypeToken extends RawToken:
	var type_name: StringName

	func _init(type: StringName) -> void:
		type_name = type

	func _to_string() -> String:
		return '<type: %s>' % type_name

class ValueToken extends Token:
	var data_type: String

	func _to_string() -> String:
		return '<lit type: %s, value: %s>' % [data_type, value]

class ExprToken extends ValueToken:
	pass

enum Operators {
	Add,
	Sub,
	Mult,
	Div
}

class SymbolToken extends RawToken:
	var value: Symbol

	func _init(symbol: Symbol) -> void:
		value = symbol

	func _to_string() -> String:
		return '<%s>' % '&|='[value]

class OperationToken extends ExprToken:
	var a: Token
	var b: Token
	var operation: Operators

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
			TokenType.LessThan: return '<<>'
			TokenType.GreaterThan: return '<>>'
			TokenType.NotEqual: return '<!=>'
			TokenType.EndSelect: return '<endselect>'

		return '<%s, %s>' % ['cisny'[type], value if value != '\n' else 'N']
