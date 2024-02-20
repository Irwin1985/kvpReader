var regExp = /(\w+\s*)=\s*("""([\s\S]*?)""")*((?:(?!""").)*)/;
var source = `
nombre = Irwin Alfredo
apellidos = Rodríguez Gimenez
edad = 38
domicilio = 
"""Lorem ipsum es el texto que se usa habitualmente en diseño gráfico en demostraciones de tipografías o de borradores de diseño para probar el diseño visual antes de insertar el texto final.

Aunque no posee actualmente fuentes para justificar sus hipótesis, el profesor de filología clásica Richard McClintock asegura que su uso se remonta a los impresores de comienzos del siglo xvi.1​ Su uso en algunos editores de texto muy conocidos en la actualidad ha dado al texto lorem ipsum nueva popularidad.

El texto en sí no tiene sentido aparente, aunque no es aleatorio, sino que deriva de un texto de Cicerón en lengua latina, a cuyas palabras se les han eliminado sílabas o letras. El significado del mismo no tiene importancia, ya que solo es una demostración o prueba.
"""
casado = .F.
millonario = .T.
viudo = .NULL.
salario = 1250.25
fullname = $(this.nombre + this.apellido)
`;

var matched = regExp.exec(source);
if (matched === null) {
    console.log('Sin valores');
    return;
}

console.log(matched);
