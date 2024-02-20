*!*	Clear
*!*	Cd f:\desarrollo\github\kvpreader\
*!*	Local loKvp
*!*	loKvp = CreateObject("kvp", FullPath('test.kvp'))
*!*	?loKvp.Get('nombre largo')
*!*	?loKvp.Get('apellidos')
*!*	?loKvp.Get('edad')
*!*	?loKvp.Get('domicilio')
*!*	?loKvp.Get('casado')
*!*	?loKvp.Get('millonario')
*!*	?loKvp.Get('viudo')
*!*	?loKvp.Get('salario')
*!*	o = loKvp.Get('deportes')
*!*	For each deporte in o
*!*		?deporte
*!*	EndFor 
*!*	?loKvp.Get('clave')
*!*	?loKvp.Get('fullname')
*!*	?loKvp.Get('b')
*!*	?loKvp.Get('expresion')
*!*	?loKvp.Get('fecha')
*!*	Release loKvp

Define Class Kvp as collection
	Hidden cLastError, bShowErrors, oRegExp, oScript, oTokens
	
	Procedure init(tcConfigFile)
		this.oRegExp = Createobject("VBScript.RegExp")
		this.oRegExp.Global = .T.
		this.oRegExp.IgnoreCase = .T.
		
		If !Empty(tcConfigFile)
			this.Parse(tcConfigFile)
		EndIf
	endproc

	Procedure AddToken(tcType as String, tcValue as memo)
		Local oToken
		oToken = CreateObject("Empty")
		AddProperty(oToken, "cType", tcType)
		AddProperty(oToken, "cValue", tcValue)
		this.oTokens.Add(oToken)
	endproc
	
	Function Get(tvIndexOrKey)
		If Empty(this.count) or Empty(tvIndexOrKey) or !InList(Type('tvIndexOrKey'), 'N', 'C')
			Return Space(1)
		EndIf
		
		Local lnIndex
		lnIndex = 0
		If Type('tvIndexOrKey') == 'C'
			lnIndex = this.GetKey(Lower(tvIndexOrKey))
		Else
			lnIndex = tvIndexOrKey
		EndIf
		If !Between(lnIndex, 1, this.Count)
			Return Space(1)
		EndIf

		Return this.Item(lnIndex)
	EndFunc
	
	procedure parse(tcConfigFile as memo)
		If Empty(tcConfigFile)
			Return
		EndIf
		Try
			Local lcContent, i, lcKey, lcValue, lcLine, lvValue, loSubMatch, loGroups, lcGroupValue

			lcContent = Iif(File(tcConfigFile), Strconv(Filetostr(tcConfigFile),11), tcConfigFile)
			this.oTokens = CreateObject("Collection")
			this.oScript = Createobject([MSScriptcontrol.scriptcontrol.1])
			this.oScript.Language = "JScript"
			*this.oScript.AddCode(strconv(filetostr('F:\Desarrollo\GitHub\kvpReader\scanner.js'),11))
			this.oScript.AddCode(this.loadScript())
			
			this.oScript.AddObject("oKvp", this)
			this.oScript.Run("parse", lcContent, .f.)

			Local i, j, loToken, lcKey, lvValue
			i = 0
			For i=1 to this.oTokens.count
				loToken = this.oTokens(i)

				If loToken.cType == 'EOF'
					Exit
				EndIf

				If loToken.cType == 'ASSIGN'
					Loop
				EndIf				
				
				If this.oTokens(i+1).cType == 'ASSIGN'
					lcKey = Lower(Alltrim(loToken.cValue))
					Loop
				EndIf

				If loToken.cType == 'LBRACKET'
					i = i + 1 && skip LBRACKET ([)
					lvValue = CreateObject("Collection")
					If this.oTokens(i).cType != 'RBRACKET'
						loToken = this.oTokens(i)
						lvValue.Add(this.parseValue(loToken))
						i = i + 1
						Do while this.oTokens(i).cType == 'COMMA'
							i = i + 1
							loToken = this.oTokens(i)
							lvValue.Add(this.parseValue(loToken))
							i = i + 1
						EndDo
					EndIf
					i = i + 1 && skip RBRACKET (])					
				Else
					lvValue = this.parseValue(loToken)
				EndIf
								
				If !Empty(lcKey)
					this.Add(lvValue, lcKey)
					Store '' to lvValue, lcKey
				EndIf
			EndFor
		Catch to loEx
			this.cLastError = loEx.Message
			If this.bShowErrors
				MessageBox(this.cLastError, 16, "KVP Reader error")
			EndIf
		EndTry
	endproc

	Hidden function parseValue(toToken)
		Local lvValue
		Do case
		Case toToken.cType == 'EXPRESSION'
			Try
				lvValue = Evaluate(toToken.cValue)
			Catch to loEx
				lvValue = "ERROR: " + loEx.message
			EndTry								
		Otherwise
			lvValue = toToken.cValue
		EndCase
		Return lvValue
	endfunc

	function getLastError
		Return this.cLastError
	EndFunc
	
	Procedure setShowErrors(tbShowErrors)
		this.bShowErrors = tbShowErrors
	endproc

	Function loadScript
		Local lcScript
		Text to lcScript noshow
			/********************************************************************
			* TOKENIZER
			********************************************************************/
			// Tokenizer spec.
			var Spec = [
				// --------------------------------------
				// Whitespace:
				[/^\s+/, null],
			
				// --------------------------------------
				// Comments:
			
				// Skip single-line comments:
				[/^\-\-.*/, null],
			
				// --------------------------------------
				// Assignment operators: =, *=, /=, +=, -=
				[/^=/, 'ASSIGN'],
			
				// --------------------------------------
				// Keywords
				[/^\.[T]\./, 'TRUE'],
				[/^\.[F]\./, 'FALSE'],
				[/^\.NULL\./, 'NULL'],
			
				// --------------------------------------
				// Numbers:
				[/^\d+([\.\,]\d+)*/, 'NUMBER'],
			
				// --------------------------------------
				// Triple quoted String:
				[/^"""([\s\S]*?)"""/, 'TQ_STRING'],
			
				// --------------------------------------
				// Single quoted String:
				[/^'[^']*'/, 'SQ_STRING'],
			
				// --------------------------------------
				// Double quoted String:    
				[/^"[^"]*"/, 'DQ_STRING'],
			
				// --------------------------------------
				// Backticked String:
				//[/^`[^`]*`/, 'BT_STRING'],
			
				// --------------------------------------
				// Expressions
				[/^\$\(.+\)/,'EXPRESSION'],
			
				// --------------------------------------
				[/^\[/, 'LBRACKET'],
				[/^\]/, 'RBRACKET'],
				[/^,/, 'COMMA'],
			
				// --------------------------------------
				// Key
				[/[a-zA-Z_αινσϊ ]+/, 'IDENT']
			];
		
			var _scannerString;
			var _scannerCursor;
			
			function _scanTokens(source) {
				_scannerString = source;
				_scannerCursor = 0; // track the position of each character
			
				var tokens = [];
			
				while (true) {
					var token = _getNextToken();
					if (token == null) {
						break;
					}
					tokens.push(token);
				}
			
				tokens.push({
					type: 'EOF',
					value: null
				});
			
				return tokens;
			}
			
			/*
			* Obtains next token.
			*/
			function _getNextToken() {
				if (_scannerCursor >= _scannerString.length) {
					return null;
				}
				var string = _scannerString.slice(_scannerCursor);
			
				for (var i = 0; i < Spec.length; i++) {
					var regexp = Spec[i][0];
					var tokenType = Spec[i][1];        
					var tokenValue = _matchRegEx(regexp, string);
			
					if (tokenValue == null) {
						continue;
					}
			
					if (tokenType == null) {
						return _getNextToken();
					}
			
					var literal;
					switch (tokenType) {
						case 'NUMBER':
							literal = Number(tokenValue);
							break;
						case 'SQ_STRING':
						case 'DQ_STRING':
						case 'BT_STRING':
							literal = tokenValue.slice(1, -1);
							break;
						case 'TQ_STRING':
							literal = tokenValue.slice(3, -3);
							break;
						case 'TRUE':
							literal = true;
							break;
						case 'FALSE':
							literal = false;
							break;
						case 'NULL':
							literal = null;
							break;
						case 'EXPRESSION':
							var matchCollection;
							var replaceWith;
							literal = tokenValue.slice(2, -1);
							while ((matchCollection = /this\.(\w+|(["'])([^"']*)\2)/.exec(literal)) !== null) {
								if (/^["']/.test(matchCollection[1])) {
									replaceWith = matchCollection[1].slice(1, -1);
								} else {
									replaceWith = matchCollection[1];
								}
								literal = literal.replace(matchCollection[0], '.Get("' + replaceWith + '")');
							}
							literal = literal.replace(new RegExp('.Get','g'), 'this.Get');                
							break;
						default:
							literal = tokenValue;
							break;
					}
					
					return {
						type: tokenType,
						value: literal
					};
				}
			
				throw new SyntaxError('Unexpected token: "' + string[0] + '"');
			}
			
			/*
			* Matches a token for a regular expression.
			*/
			function _matchRegEx(regexp, string) {
				var matched = regexp.exec(string);
				if (matched == null) {
					return null;
				}
				_scannerCursor += matched[0].length;
				return matched[0];
			}
			
			/********************************************************************
			* PARSER
			********************************************************************/
			function parse(source, debug) {
				var tokens = _scanTokens(source);
					
				for (var i = 0; i < tokens.length; i++) {
					if (debug) {
						console.log(tokens[i]);
					} else {
						oKvp.AddToken(tokens[i].type, tokens[i].value);
					}
				}
				
				//return tokens;
			}
			/*
			var source = `
			deportes = ["Baloncesto", .T., .F., $(this.'nombre largo')]
			`;
			console.log(parse(source, true));
			*/
		endtext
		return lcScript
	EndProc

EndDefine