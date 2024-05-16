import json

# Leer el archivo 'arborado.json'
with open('assets/arbolesFuente.json', 'r') as f:
    data = json.load(f)

# Crear una nueva lista para almacenar los datos transformados
new_data = []

# Iterar sobre los datos y crear un nuevo diccionario con la estructura requerida
for item in data['features']:
    new_item = {
        "Id": item['properties']['Codigo_Arb'],
        "nombre": item['properties']['Nombre_Esp'],
        "alto": str(item['properties']['Altura_Tot']),
        "lng": str(item['properties']['Longitud']),
        "lat": str(item['properties']['Latitud'])
    }
    new_data.append(new_item)

# Escribir los datos transformados en el archivo 'arboles.json'
with open('assets/arboles.json', 'w') as f:
    json.dump(new_data, f, ensure_ascii=False)