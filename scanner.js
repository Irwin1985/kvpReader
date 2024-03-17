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

var source = `
--************************************************--
-- Datos de conexión --
-- Base de datos: MySQL / MariaDB
-- NOTA: los datos sensibles están encriptados.
-- si desea cambiar de motor, cambie el valor
-- de engine a: MySQL, MariaDB, MSSQL, SQLite
-- PostGreSQL, Firebird
--************************************************--

current_engine = "mysql" -- cambiar aquí el motor

-- CONFIGURACIÓN PARA MYSQL --
mysql.engine = "MySQL"
mysql.driver = "MySQL ODBC 5.1 Driver"
mysql.server = decode("bG9jYWxob3N0")
mysql.database = decode("c2lzdGVtYV9hZA==")
mysql.user = decode("cm9vdA==")
mysql.password = decode("MTIzNA==")
mysql.port = decode("MzMwNg==")
--FIN DE LA CONFIGURACIÓN PARA MYSQL--

-- CONFIGURACIÓN PARA MARIADB --
mariadb.engine = "MariaDB"
mariadb.driver = "MariaDB ODBC 3.1 Driver"
mariadb.server = decode("bG9jYWxob3N0")
mariadb.database = decode("c2lzdGVtYV9hZA==")
mariadb.user = decode("cm9vdA==")
mariadb.password = decode("MTIzNA==")
mariadb.port = decode("MzMwOQ==")
--FIN DE LA CONFIGURACIÓN PARA MARIADB--

--CONFIGURACIÓN PARA SQL SERVER--
mssql.engine = "MSSQL"
mssql.driver = "SQL Server Native Client 11.0"
mssql.server = decode("UEMtSVJXSU5cU1FMSVJXSU4=")
mssql.database = decode("c2lzdGVtYV9hZA==")
mssql.user = decode("c2E=")
mssql.password = decode("U3ViaWZvcjIwMTI=")
--FIN DE LA CONFIGURACIÓN PARA MSSQL--

-- CONFIGURACIÓN PARA LOS ÍNDICES --

-- USUARIOS --
usuarios.index1.expression = clave
usuarios.index1.tag = clave

usuarios.index1.expression = usuario
usuarios.index1.tag = usuario

-- CLIENTES --
clientes.index1.expression = folio
clientes.index1.tag = folio

clientes.index2.expression = ncompleto
clientes.index2.tag = ncompleto

clientes.index3.expression = fecha_alta
clientes.index3.tag = fecha_alta

-- MOROSOS --
morosos.index1.expression = folioc
morosos.index1.tag = folioc

-- PAGOS --
pagos.index1.expression = cajero
pagos.index1.tag = cajero

pagos.index2.expression = fecha
pagos.index2.tag = fecha

pagos.index3.expression = folioc
pagos.index3.tag = folioc

pagos.index4.expression = recibo
pagos.index4.tag = recibo

pagos.index5.expression = fpago
pagos.index5.tag = fpago

-- DINERO --
dinero.index1.expression = fecha
dinero.index1.tag = fecha

dinero.index2.expression = fecha1
dinero.index2.tag = fecha1

dinero.index3.expression = tipo_entra
dinero.index3.tag = tipo_entra

-- MES --
mes.index1.expression = tipo
mes.index1.tag = tipo

mes.index2.expression = num
mes.index2.tag = num
`;
parse(source, true);
