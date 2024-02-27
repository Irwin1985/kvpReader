
# # Usage Manual for the Kvp Class in Visual FoxPro

Welcome to using the Kvp class in Visual FoxPro (VFP)! 
This class allows you to work with a simple and versatile configuration file format for your applications. Below, I'll provide you with a step-by-step guide to make the most of this tool.


### 1. Introduction to Kvp

The Kvp (Key-Value Pair) class facilitates the reading and manipulation of configuration files in the KVP format. This format is a lightweight and easy-to-understand alternative to others like JSON, TOML, or YAML.

### 2. Structure of Kvp Files

Kvp files follow a simple key-value structure, allowing comments and expression evaluation.

#### Example of Kvp File:

```SQL
-- Application Configuration --
name  = "My Application"
version = "1.0"
environment = "development"
debug   = .T.
path    = $(IIF(this.environment == "development","C:\Development\","C:\Production\"))
```

## 3. Instantiation of the Kvp Class

To begin, load the `kvp.prg` file into memory.
```xBase
SET PROCEDURE TO "kvp" ADDITIVE
```
Then you can create an instance of the KVP class, optionally specifying the Kvp file you want to load into memory.
```xBase
loKvp = CREATEOBJECT("kvp", "c:\my-file.kvp")
```
As mentioned, loading the file is optional when creating the instance, so you can leave it empty and load the file later using the `Parse()` method.

```xBase
loKvp = CREATEOBJECT("kvp")
loKvp.Parse("c:\my-file.kvp")
```

## 4. Accessing Values

Use the `Get` method to retrieve configuration values:
```xBase
? loKvp.Get("name")   && Returns "My Application"
? loKvp.Get("version")  && Returns "1.0"
```

## 5. Expressions and Variables

Take advantage of expression and variable evaluation:
```xBase
? loKvp.Get("path")  && Returns the path based on the environment
```

## 6. Working with Arrays

In your configuration file, you can load an array with scalar values that will be treated as a `Collection` object.
```SQL
-- ARRAY EXAMPLE --
databases = ["SQL Server", "MySQL", "SQLite", "Firebird", "Postgres"]
```
Save the content in a file named `test.kvp` and then load it:
```xBase
loKvp = CREATEOBJECT("kvp", "c:\test.kvp") 
loDatabases = loKvp.Get("databases") 
?loDatabases(1) && SQL Server
```

## 7. Error Handling

If errors occur during the file reading, you can access the error message:
```xBase
? loKvp.GetLastError()  && Displays the last error message
```
## 8. Final Considerations

With the Kvp class, you will simplify the management of configuration in your VFP applications. This readable and versatile format provides an efficient alternative to more complex standards.
