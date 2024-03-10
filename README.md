# Manual de Uso de la Clase Kvp en Visual FoxPro

¡Bienvenido al uso de la clase Kvp en Visual FoxPro (VFP)! 
Esta clase te permitirá trabajar con un formato de configuración sencillo y versátil para tus aplicaciones. A continuación, te proporcionaré una guía paso a paso para aprovechar al máximo esta herramienta.

This library is part of the [VFPX](https://github.com/VFPX) project.
![](vfpxmember_large.gif)

## For English translation please refer to [README_EN.md](README_EN.md)

### 1. Introducción a Kvp

La clase Kvp *(Clave-Valor)* facilita la lectura y manipulación de archivos de configuración en formato KVP. Este formato es una alternativa ligera y fácil de entender a otros como JSON, TOML o YAML.

### 2. Estructura de los Archivos Kvp

Los archivos Kvp siguen una estructura simple de clave y valor, permitiendo comentarios y evaluación de expresiones.

#### Ejemplo de Archivo Kvp:

```SQL
-- Configuración de la Aplicación --
nombre  = "Mi Aplicación"
version = "1.0"
entorno = "desarrollo"
debug   = .T.
ruta    = $(IIF(this.entorno == "desarrollo","C:\Desarrollo\","C:\Produccion\"))
```

## 3. Instanciación de la Clase Kvp

Para comenzar, carga el fichero `kvp.prg` en memoria.
```xBase
SET PROCEDURE TO "kvp" ADDITIVE
```
Luego puedes crear una instancia de la clase KVP opcionalmente indicando el fichero Kvp que deseas cargar en memoria. 
```xBase
loKvp = CREATEOBJECT("kvp", "c:\mi-fichero.kvp")
```
Como te dije, la carga del fichero es opcional en la creación de la instancia, de modo que puedes dejarla vacía y cargar el fichero a posteriori usando el método `Parse()`.

```xBase
loKvp = CREATEOBJECT("kvp")
loKvp.Parse("c:\mi-fichero.kvp")
```

## 4. Acceso a los Valores

Utiliza el método `Get` para obtener los valores de configuración:
```xBase
? loKvp.Get("nombre")   && Devuelve "Mi Aplicación"
? loKvp.Get("version")  && Devuelve "1.0"
```

## 5. Expresiones y Variables

Aprovecha la capacidad de evaluación de expresiones y variables:
```xBase
? loKvp.Get("ruta_archivos")  && Devuelve la ruta según el entorno
```

## 6. Trabajo con Arrays

En tu fichero de configuración, puedes cargar un array con valores escalares que serán cargados como un objeto `Collection` 
```SQL
-- EJEMPLO DE ARRAY --
bases-de-datos = ["SQL Server", "MySQL", "SQLite", "Firebird", "Postgres"]
```
Guarda el contenido en un fichero llamado `test.kvp` y a continuación lo cargamos:
```xBase
loKvp = CREATEOBJECT("kvp", "c:\test.kvp")
loBasesDeDatos = loKvp.Get("bases-de-datos")
?loBasesDeDatos(1) && SQL Server
```

## 7. Manejo de Errores

Si ocurren errores durante la lectura del archivo, puedes acceder al mensaje de error:
```xBase
? loKvp.GetLastError()  && Muestra el último mensaje de error
```
## 8. Consideraciones Finales

Con la clase Kvp, simplificarás la gestión de configuración en tus aplicaciones VFP. Este formato legible y versátil proporciona una alternativa eficiente a otros estándares más complejos.
