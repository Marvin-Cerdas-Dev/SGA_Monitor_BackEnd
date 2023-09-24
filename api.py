from flask import Flask, request, jsonify
import cx_Oracle

app = Flask(__name__)

# variable global DB
DB_CONNECTION = None

# conexion a la DB
def conectarDB():
    try:
        global DB_CONNECTION
        DB_CONNECTION = cx_Oracle.connect(
        user='sys',
        password='123',
        dsn='localhost:1521/xe',
        encoding='UTF-8',
        mode = cx_Oracle.SYSDBA
        )   
        print("Conexion con la DB exitosa:", DB_CONNECTION.version)
    except Exception as ex:
        raise Exception("Error al conectar con la DB", ex)

#desconectar de la DB    
def desconectarDB():
    global DB_CONNECTION
    if DB_CONNECTION is not None:
        DB_CONNECTION.close()
        DB_CONNECTION = None
        print("La conexión a la DB ha finalizado")

# default route
@app.route("/")
def home():
    return "Home"

# GET example
@app.route("/getData/<id>")
def getData(id):
    data = {
        "id": id
    }
    return jsonify(data), 200


# consulta ejemplo
@app.route("/consultaEjemplo")
def consulta1():
    try:
        conectarDB()
        cursor = DB_CONNECTION.cursor()
        cursor.execute("select * from clientes")
        clientes = cursor.fetchall()
        cursor.close()
        desconectarDB()

         # Convert the results to a list of dictionaries
        list = []
        for cliente in clientes:
            list.append({
                'id': cliente[0],
                'nombre': cliente[1],
                'saldo': cliente[2],
            })
        return jsonify(list), 200
    except Exception as ex:
        print("ERROR:", ex)

#Consulta a traffic-memory-state devuelve la información de todos registros realizados
@app.route("/traffic-memory-state")
def check_states():
    try:
        conectarDB()
        cursor = DB_CONNECTION.cursor()
        cursor.execute("SELECT * FROM traffic_memory_state")
        memory_states = cursor.fetchall()
        cursor.close()
        desconectarDB()

        state_list = []
        for memory_state in memory_states:
            state_dict = {
                'id': memory_state[0],
                'date': memory_state[1],
                'time': memory_state[2],
                'total_memory_used': memory_state[3],
                'memory_percentage': memory_state[4]
            }
            state_list.append(state_dict)

        return jsonify(state_list), 200
    except Exception as ex:
        print("ERROR:", ex)

#Consulta a event_info devuelve la información de todos registros que superaron el limite establesido 
@app.route("/event_info")
def check_info():
    try:
        conectarDB()
        cursor = DB_CONNECTION.cursor()
        cursor.execute("SELECT * FROM event_info")
        events_info = cursor.fetchall()
        cursor.close()
        desconectarDB()

        event_list = [] 
        for event_info in events_info:
            event_dict = {
                'event_id': event_info[0],
                'event_date': event_info[1],
                'trafic_memory_state_id': event_info[2],
                'process_id': event_info[3],
                'user_name': event_info[4],
                'user_query': event_info[5],
                'memory_percentage': event_info[6]                
            }
            event_list.append(event_dict)
        
        return jsonify(event_list), 200  #Debe estar una linea abajo para evitar errores.
    except Exception as ex:
        print("ERROR:", ex)

#obtener datos de los tablespace
@app.route("/tablespaces_volumetria")
def tablespaces_volumetria():
    try:
        conectarDB()
        cursor = DB_CONNECTION.cursor()

        # Definir un parámetro de cursor de salida
        output_cursor = cursor.var(cx_Oracle.CURSOR)

        # Llamar al procedimiento almacenado que recibe el cursor
        cursor.callproc("tablespaces_volumetria", (output_cursor,))

        # Recuperar los resultados del cursor de salida
        result = output_cursor.getvalue()

        tablespace_list = [] 
        for row in result:
            print(row)
            tablespace = {
                'tablespace': row[0],
                'estado': row[1],
                'MB tamano': row[2],
                'MB usados': row[3],
                'MB libres': row[4],
                #'incremento': row[5],
                'fichero de datos': row[6]                
            }
            tablespace_list.append(tablespace)

        cursor.close()
        desconectarDB()
        return jsonify(tablespace_list), 200
    except Exception as ex:
        print("ERROR:", ex)

# main
if __name__ == "__main__":
    app.run(debug=True)
