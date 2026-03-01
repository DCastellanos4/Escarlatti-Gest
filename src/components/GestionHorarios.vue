<script setup>
import { ref, onMounted } from 'vue'

const franjas = ref([]) //ARRAY DE HORARIOS
const turnos = ref([]) // ARRAY DE TURNOS
const franjaEnEdicion = ref(null) //BOOLEANO DE EDICION
//MODELO PARA EL HORARIO
const modeloFranja = ref({
    id: '',
    nombre: '',
    hora_inicio: '',
    hora_fin: '',
    turno_id: '',
    zusuario: 'DC4'
})
//FUNCION PARA CARGAR DATOS
const cargarDatos = async () => {
    try {
        const [resFra, resTur] = await Promise.all([
            fetch('http://44.207.19.239:3000/horarios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/turnos?zusuario=DC4')
        ]);

        const datosFra = await resFra.json();

        //ORDENAMOS LA LISTA EN ORDEN DEL ID
        franjas.value = datosFra.sort((a, b) => {
            const numA = Number(a.id.toString().replace(/\D/g, '')) || 0;
            const numB = Number(b.id.toString().replace(/\D/g, '')) || 0;
            return numA - numB;
        });

        turnos.value = await resTur.json();
    } catch (error) {
        console.error("Error al cargar franjas horarias:", error);
    }
}
//ELECCION DE METODO, PUT/POST
const procesarFormulario = async () => {
    const esEdicion = !!franjaEnEdicion.value;
    const origen = esEdicion ? franjaEnEdicion.value : modeloFranja.value;

    // GENERACIÓN DE ID MANUAL
    let finalId = origen.id;
    if (!esEdicion) {
        const idsExistentes = franjas.value.map(f => Number(f.id) || 0);
        let maxId = idsExistentes.length > 0 ? Math.max(...idsExistentes) : 0;
        finalId = maxId + 1;

        // BUCLE EXTRA ADICIONAL PARA EVITAR ERRORES DE DOBLE ID
        while (idsExistentes.includes(finalId)) {
            finalId++;
        }
    }

    // FORMATEAO DE HORA EN H:M:S
    const formatearHora = (h) => (h && h.length === 5) ? `${h}:00` : h;

    // OBJETO A ENVIAR
    const datosFinales = {
        id: Number(finalId),
        nombre: origen.nombre,
        hora_inicio: formatearHora(origen.hora_inicio),
        hora_fin: formatearHora(origen.hora_fin),
        turno_id: origen.turno_id,
        zusuario: 'DC4'
    };
    //ELECCION DEL METODO A ENVIAR
    const metodo = esEdicion ? 'PUT' : 'POST';
    const url = esEdicion
        ? `http://44.207.19.239:3000/horarios/${finalId}?zusuario=DC4`
        : 'http://44.207.19.239:3000/horarios?zusuario=DC4';
    //ENVIAMOS EL METODO
    try {
        const respuesta = await fetch(url, {
            method: metodo,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert(esEdicion ? "Franja actualizada" : `Registrada con ID #${finalId}`);
            cancelarAccion();
            await cargarDatos();
        } else {
            //ERRORSERVER PARA DEBUG
            const errorServer = await respuesta.json();
            alert("Error de la API: " + (errorServer.error || "Revisa los datos"));
        }
    } catch (e) {
        alert("Error de red.");
    }
}
//ELIMINAR HORARIO CON CONFIRMACION PARA EVITAR MISSCLICK
const eliminarFranja = async (id) => {
    if (confirm(`¿Eliminar la franja ${id}?`)) {
        await fetch(`http://44.207.19.239:3000/horarios/${id}?zusuario=DC4`, { method: 'DELETE' });
        await cargarDatos();
    }
}
//CONTROL DE UI DE EDICION
const iniciarEdicion = (f) => { franjaEnEdicion.value = { ...f }; }
const cancelarAccion = () => {
    franjaEnEdicion.value = null;
    modeloFranja.value = { id: '', nombre: '', hora_inicio: '', hora_fin: '', turno_id: '', zusuario: 'DC4' };
}

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Configuración de Franjas Horarias (H14)</h3>
        </header>

        <form @submit.prevent="procesarFormulario" class="form-grid">
            <input v-if="!franjaEnEdicion" v-model="modeloFranja.nombre" placeholder="Nombre (ej. 1ª Hora)" required>
            <input v-else v-model="franjaEnEdicion.nombre" placeholder="Nombre">

            <select v-if="!franjaEnEdicion" v-model="modeloFranja.turno_id" required>
                <option value="" disabled>-- Seleccionar Turno --</option>
                <option v-for="t in turnos" :key="t.id" :value="t.id">{{ t.nombre }}</option>
            </select>
            <select v-else v-model="franjaEnEdicion.turno_id" required>
                <option v-for="t in turnos" :key="t.id" :value="t.id">{{ t.nombre }}</option>
            </select>

            <div class="input-group">
                <label>Hora Inicio</label>
                <input v-if="!franjaEnEdicion" v-model="modeloFranja.hora_inicio" type="time" required>
                <input v-else v-model="franjaEnEdicion.hora_inicio" type="time" required>
            </div>

            <div class="input-group">
                <label>Hora Fin</label>
                <input v-if="!franjaEnEdicion" v-model="modeloFranja.hora_fin" type="time" required>
                <input v-else v-model="franjaEnEdicion.hora_fin" type="time" required>
            </div>

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ franjaEnEdicion ? 'Actualizar Franja' : 'Registrar Franja' }}
                </button>
                <button v-if="franjaEnEdicion" type="button" @click="cancelarAccion" class="btn-sec">Cancelar</button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Denominación</th>
                        <th>Rango</th>
                        <th>Turno</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="f in franjas" :key="f.id">
                        <td><strong>{{ f.id }}</strong></td>
                        <td>{{ f.nombre }}</td>
                        <td>{{ f.hora_inicio }} - {{ f.hora_fin }}</td>
                        <td><span class="badge">{{turnos.find(t => t.id === f.turno_id)?.nombre || f.turno_id}}</span>
                        </td>
                        <td class="td-actions">
                            <button @click="iniciarEdicion(f)" class="btn-accent">Editar</button>
                            <button @click="eliminarFranja(f.id)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
/* Estilo corporativo DAW oscuro */
.seccion-header {
    border-left: 5px solid #e67e22;
    padding-left: 15px;
    margin-bottom: 20px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    background: #fff;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.input-group {
    display: flex;
    flex-direction: column;
}

.input-group label {
    font-size: 0.7rem;
    color: #7f8c8d;
    margin-bottom: 2px;
}

input,
select {
    padding: 10px;
    border-radius: 4px;
    color: #fff;
    background: #2c3e50;
    border: 1px solid #ccc;
}

.form-actions {
    grid-column: span 2;
    display: flex;
    gap: 10px;
}

.btn-success {
    flex: 2;
    background: #27ae60;
    color: white;
    padding: 12px;
    border: none;
    font-weight: bold;
    cursor: pointer;
    border-radius: 4px;
}

.btn-sec {
    flex: 1;
    background: #95a5a6;
    color: white;
    padding: 12px;
    border: none;
    cursor: pointer;
    border-radius: 4px;
}

.badge {
    background: #fdf2e9;
    color: #e67e22;
    padding: 2px 8px;
    border-radius: 4px;
    font-weight: bold;
    font-size: 0.8rem;
}

.table-container {
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
    margin-top: 25px;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th,
td {
    padding: 12px;
    text-align: left;
    border-bottom: 1px solid #eee;
}

th {
    text-transform: uppercase;
    font-size: 0.75rem;
    color: #7f8c8d;
}

.td-actions {
    display: flex;
    gap: 8px;
}

.btn-accent {
    background: #f39c12;
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
}
</style>