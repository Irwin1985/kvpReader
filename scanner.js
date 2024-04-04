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
    [/[a-zA-Z_0-9áéíóúÁÉÍÓÚ \-_\.#]+/, 'IDENT']
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
                while ((matchCollection = /[Tt][Hh][Ii][Ss]\.(\w+|(["'])([^"']*)\2)/.exec(literal)) !== null) {
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
var source = `
-------------------- PROPIEDADES AUXILIARES --------------------
TOP = $(_SCREEN.UTILIDADES.EJECUTARSBSCRIPT("ALTO-DISPONIBLE"))
UBICACION = $(P_DIRECTO + '\GRAFICO\')
----------------------------------------------------------------

-- LISTADO DE LOGOS ADICIONALES
LOGO1.NOMBRE    = "logo-kit-digital-1.png"
LOGO1.UBICACION = $(THIS.UBICACION)
LOGO1ANCHO      = 300
LOGO1.ALTO      = 97
LOGO1.LEFT      = 0
LOGO1.TOP       = $(THIS.TOP)

LOGO2.NOMBRE    = "logo-kit-digital-2.png"
LOGO2.UBICACION = $(THIS.UBICACION)
LOGO2.ANCHO     = 336
LOGO2.ALTO      = 189
LOGO2.LEFT      = $(THIS.LOGO1ANCHO)
LOGO2.TOP       = $(THIS.TOP)
`;
parse(source, true);