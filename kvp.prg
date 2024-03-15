*!*	Clear
*!*	do f:\desarrollo\github\jsonfox\jsonfox.app

*!*	Cd f:\desarrollo\github\kvpreader\
*!*	Local loKvp

*!*	loKvp = CreateObject("kvp", FullPath('test.kvp'))
*!*	If !Empty(loKvp.cLastError)
*!*		? loKvp.cLastError
*!*		Release loKvp
*!*		return
*!*	EndIf
*!*	loUsuarios = loKvp('usuarios')
*!*	For each loUsuario in loUsuarios
*!*		? loUsuario.name
*!*	EndFor

*!*	* JSON
*!*	?loKvp('persona').nombre
*!*	?loKvp('persona').edad
*!*	?loKvp('persona').casado
*!*	?loKvp('persona').soltero
*!*	?loKvp('persona').dirvorciado
*!*	For each lcLenguaje in loKvp('persona').lenguajes
*!*		?lcLenguaje
*!*	endfor

*!*	Release loKvp

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


Define Class Kvp as collection
	Hidden oScript, oTokens
	cLastError = ''
	bShowErrors = .f.
	
	Procedure init(tcConfigFile)	
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
		nodefault
		If Empty(this.count) or Empty(tvIndexOrKey) or !InList(Type('tvIndexOrKey'), 'N', 'C')
			Return Space(1)
		EndIf
		
		Local lnIndex, loItem
		lnIndex = 0
		loItem = Space(1)
		If Type('tvIndexOrKey') == 'C'
			lnIndex = this.GetKey(Lower(tvIndexOrKey))
		Else
			lnIndex = tvIndexOrKey
		EndIf
		If !Between(lnIndex, 1, this.Count)
			Return loItem
		EndIf
		Return this.Item(lnIndex)
	EndFunc
	
	procedure parse(tcConfigFile as memo)
		If Empty(tcConfigFile)
			Return
		EndIf
		this.cLastError = ''
		Try
			Local lcContent, i, lcKey, lcValue, lcLine, lvValue, loSubMatch, loGroups, lcGroupValue, loExpressions

			lcContent = Iif(File(tcConfigFile), Strconv(Filetostr(tcConfigFile),11), tcConfigFile)
			this.oTokens = CreateObject("Collection")
			this.oScript = Createobject([MSScriptcontrol.scriptcontrol.1])
			this.oScript.Language = "JScript"
			*this.oScript.AddCode(strconv(filetostr('F:\Desarrollo\GitHub\kvpReader\scanner.js'),11))
			this.oScript.AddCode(this.loadScript())

			this.oScript.AddObject("oKvp", this)
			this.oScript.Run("parse", lcContent, .f.)
			loExpressions = CreateObject("Collection")
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
				EndIf
				If loToken.cType == 'EXPRESSION'
					loExpressions.Add(loToken, lcKey)
					lvValue = .null.
				EndIf

				If loToken.cType == 'BUILTIN'
					lvValue = this.parseBuiltin(loToken)
				Else
					* Extract scalar value
					lvValue = loToken.cValue
				EndIf				

				If !Empty(lcKey)
					If this.GetKey(lcKey) > 0
						this.Remove(this.GetKey(lcKey))
					EndIf
					this.Add(lvValue, lcKey)
					Store '' to lvValue, lcKey
				EndIf
			EndFor
			* Evaluate expressions
			For i=1 to loExpressions.count
				lcKey = loExpressions.GetKey(i)
				loExp = loExpressions.Item(i)
				this.Remove(lcKey)
				this.Add(this.parseValue(loExp), lcKey)
			EndFor
		Catch to loEx
			this.cLastError = loEx.Message
			If this.bShowErrors
				MessageBox(this.cLastError, 16, "KVP Reader error")
			EndIf
		EndTry
	endproc

	Hidden function parseBuiltin(toToken)
		Local lcFuncName, loParams, lcParam, loResult
		lcFuncName = Lower(GetWordNum(toToken.cValue,1,'('))
		*loParams = this.parseParameters(toToken.cValue)
		lcParam  = Substr(toToken.cValue, At('(', toToken.cValue)+1)
		lcParam  = Substr(lcParam, 1, Len(lcParam)-1)
		If InList(Left(lcParam,1), '"', "'")
			lcParam = Substr(lcParam,2, Len(lcParam)-2)
		EndIf
		loResult = .null.
		Do case
		Case lcFuncName == 'get'
			If !"VFPRESTCLIENT"$Upper(Set("Procedure"))
				this.cLastError = 'Third party lib not found: VFPRESTCLIENT'
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return loResult
			EndIf
			If Empty(lcParam)
				this.cLastError = 'No parameters found.'
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return loResult
			EndIf
			Local loRest
			loRest = CreateObject("Rest")
			loRest.ShowErrors = .F.
			loRest.AddRequest("GET", lcParam)
			loRest.Send()			
			If !Empty(loRest.LastErrorText)
				this.cLastError = loRest.LastErrorText
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return loResult
			EndIf
			If loRest.status != 200
				this.cLastError = "Status code: " + Transform(loRest.status)
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf				
				Return loResult
			EndIf

			If "application/json"$loRest.GetResponseHeader('Content-Type')
				loResult = this.parseJson(loRest.responsetext)
			EndIf
			Release loRest
			Return loResult
		Case lcFuncName == 'json'
			If Empty(lcParam)
				this.cLastError = 'No parameters found.'
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return loResult
			EndIf
			Return this.parseJson(lcParam)
		Case lcFuncName == 'decode'
			If Empty(lcParam)
				this.cLastError = 'No parameters found.'
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return loResult
			EndIf
			Return strconv(lcParam, 14)
		Case lcFuncName == 'encode'
			If Empty(lcParam)
				this.cLastError = 'No parameters found.'
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return loResult
			EndIf
			Return strconv(lcParam, 13)
		Otherwise
			this.cLastError = 'Unknown builtin function: '+lcFuncName
			If this.bShowErrors
				MessageBox(this.cLastError, 16, "KVP Reader error")
			EndIf
		endcase		
	EndFunc

	Hidden function parseJson(tcJson)	
		If Type('_screen.json') != 'O'
			If !File('JSONFox.app')
				this.cLastError = 'Third party lib not found: JSONFox.app'
				If this.bShowErrors
					MessageBox(this.cLastError, 16, "KVP Reader error")
				EndIf
				Return .null.
			EndIf
			Do JsonFox.app
		EndIf
		Local loResult, loArray
		loResult = _screen.json.parse(tcJson)
		If Type('loResult', 1) == 'A'
			loArray = CreateObject('Collection')
			Local i
			For i = 1 to Alen(loResult, 1)
				loArray.Add(loResult[i])
			endfor
			return loArray
		Else
			return loResult
		EndIf
	endfunc
	
	Hidden function parseParameters(tcParameters)
		Local loParams, lcParams
		loParams = CreateObject('Collection')
		lcParams = Substr(tcParameters, At('(', tcParameters)+1)
		lcParams = Substr(lcParams, Len(lcParams)-1)
		For i=1 to GetWordCount(lcParams,',')
			
		EndFor
		Return loParams
	EndFunc

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
    // Builtin functions
    [/^\w+\((.*?)\)/, 'BUILTIN'],

    // --------------------------------------
    [/^\[/, 'LBRACKET'],
    [/^\]/, 'RBRACKET'],
    [/^,/, 'COMMA'],

    // --------------------------------------
    // Key
    [/[a-zA-Z_αινσϊ \-_\.#]+/, 'IDENT']
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
}
/*
var source = `
deportes = ["Baloncesto", .T., .F., $(this.'nombre largo')]
usuarios = get("http://localhost:8080/users")
personas = json('{"nombre": "Irwin"}')
`;
parse(source, true);
*/
		endtext
		return lcScript
	EndProc

EndDefine