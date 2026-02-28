<script setup>
/**
 * COMPONENTE: GestionReservas.vue
 * Rework: Solo el autor anula su reserva y formato de fecha DD/MM/YYYY en tabla.
 */
import { ref, onMounted } from 'vue'
const props = defineProps(['usuario']);

const usuarioLogeado = ref({
    login: props.usuario.usuario, // Usamos la clave 'usuario' que viene de tu API
    rol_id: props.usuario.rol      // Usamos la clave 'rol' que viene de tu API
});
const listaReservas = ref([])
const listaEspacios = ref([])
const listaHorarios = ref([])
const listaUsuarios = ref([])

const modeloReserva = ref({
    id: '',
    espacio_id: '',
    horario_id: '',
    usuario_login: usuarioLogeado.value.login,
    fecha_reserva: new Date().toISOString().split('T')[0],
    motivo_reserva: '',
    zusuario: 'DC4'
})

const cargarDatos = async () => {
    try {
        const [resRes, resEsp, resHor, resUsr] = await Promise.all([
            fetch('http://44.207.19.239:3000/reservas?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/espacios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/horarios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/usuarios?zusuario=DC4')
        ]);

        listaReservas.value = await resRes.json();
        listaEspacios.value = await resEsp.json();
        listaHorarios.value = await resHor.json();
        listaUsuarios.value = await resUsr.json();
    } catch (error) {
        console.error("Error al sincronizar datos:", error);
    }
}

/**
 * Función para mostrar la fecha en formato DD/MM/YYYY en la tabla
 */
const formatearFechaVisual = (fecha) => {
    if (!fecha) return 'Sin fecha';

    // Limpiamos la fecha por si viene con la hora (ej: 2026-02-24T00:00:00)
    const fechaLimpia = fecha.split('T')[0];

    // Detectamos el separador (puede ser - o /)
    const partes = fechaLimpia.includes('-') ? fechaLimpia.split('-') : fechaLimpia.split('/');

    // Si la fecha viene como YYYY/MM/DD
    if (partes[0].length === 4) {
        return `${partes[2]}/${partes[1]}/${partes[0]}`;
    }
    // Si ya viene como DD/MM/YYYY la devolvemos tal cual
    return fechaLimpia;
};

/**
 * Registro de nueva reserva
 */
const guardarReserva = async () => {
    const existeOcupada = listaReservas.value.find(r =>
        r.espacio_id === modeloReserva.value.espacio_id &&
        r.horario_id == modeloReserva.value.horario_id && // Usamos == por si uno es string y otro number
        r.fecha_reserva.split(/[T ]/)[0] === modeloReserva.value.fecha_reserva
    );

    if (existeOcupada) {
        alert("ERROR: Este aula ya está reservada para el día y hora seleccionados.");
        return;
    }
    const rolesPermitidos = ['Administrador', 'Profesor'];
    if (!rolesPermitidos.includes(usuarioLogeado.value.rol_id)) {
        alert("Tu cuenta no tiene permisos para realizar reservas.");
        return;
    }

    // Cálculo dinámico de ID para evitar duplicados
    const idsExistentes = listaReservas.value.map(r => Number(r.id) || 0);
    let finalId = (idsExistentes.length > 0 ? Math.max(...idsExistentes) : 0) + 1;
    while (idsExistentes.includes(finalId)) { finalId++; }

    const datosFinales = {
        id: finalId,
        espacio_id: modeloReserva.value.espacio_id,
        horario_id: Number(modeloReserva.value.horario_id),
        usuario_login: usuarioLogeado.value.login,
        fecha_reserva: modeloReserva.value.fecha_reserva, // Se guarda como YYYY-MM-DD
        motivo_reserva: modeloReserva.value.motivo_reserva,
        zusuario: 'DC4'
    };

    try {
        const respuesta = await fetch('http://44.207.19.239:3000/reservas?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert(`Reserva #${finalId} creada correctamente.`);
            modeloReserva.value = {
                id: '', espacio_id: '', horario_id: '',
                usuario_login: usuarioLogeado.value.login,
                fecha_reserva: new Date().toISOString().split('T')[0],
                motivo_reserva: '', zusuario: 'DC4'
            };
            await cargarDatos();
        } else {
            const errorData = await respuesta.json();
            alert("Error: " + (errorData.error || "Datos no válidos"));
        }
    } catch (e) {
        alert("Fallo de red.");
    }
}

const eliminarReserva = async (reserva) => {
    // Verificamos: ¿Es Admin? O ¿El login de la reserva coincide con el logeado?
    const esDuenio = reserva.usuario_login === usuarioLogeado.value.login;
    const esAdmin = usuarioLogeado.value.rol_id === 'Administrador';

    if (esAdmin || esDuenio) {
        if (confirm(`¿Anular reserva #${reserva.id}?`)) {
            try {
                const res = await fetch(`http://44.207.19.239:3000/reservas/${reserva.id}?zusuario=DC4`, {
                    method: 'DELETE'
                });
                await cargarDatos();
                if (!res.ok) {
                    const errorData = await res.json();
                    console.log(errorData.error);
                }
            } catch (error) {

                alert("Error al intentar conectar con el servidor.");
            }
        }
    } else {
        alert("No tienes permiso para anular las reservas de otros profesores.");
    }
}

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Mis Reservas (Usuario: {{ usuarioLogeado.login }})</h3>
        </header>

        <form @submit.prevent="guardarReserva" class="form-grid">
            <div class="input-labeled">
                <label>Aula o Instalación</label>
                <select v-model="modeloReserva.espacio_id" required>
                    <option value="" disabled>-- Seleccionar --</option>
                    <option v-for="e in listaEspacios" :key="e.id" :value="e.id">
                        {{ e.nombre }}
                    </option>
                </select>
            </div>

            <div class="input-labeled">
                <label>Horario Disponible</label>
                <select v-model="modeloReserva.horario_id" required>
                    <option value="" disabled>-- Seleccionar Franja --</option>
                    <option v-for="h in listaHorarios" :key="h.id" :value="h.id">
                        {{ h.nombre }}: {{ h.hora_inicio }} - {{ h.hora_fin }}
                    </option>
                </select>
            </div>

            <div class="input-labeled">
                <label>Fecha</label>
                <input v-model="modeloReserva.fecha_reserva" type="date" required>
            </div>

            <div class="input-labeled">
                <label>Motivo</label>
                <input v-model="modeloReserva.motivo_reserva" placeholder="¿Para qué la necesitas?" required>
            </div>

            <button type="submit" class="btn-success full-width">Realizar Reserva</button>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Espacio</th>
                        <th>Fecha</th>
                        <th>Horario</th>
                        <th>Reservado por</th>
                        <th>Acción</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="res in listaReservas" :key="res.id">
                        <td>{{listaEspacios.find(e => e.id === res.espacio_id)?.nombre || 'N/A'}}</td>
                        <td>{{ formatearFechaVisual(res.fecha_reserva) }}</td>
                        <td>
                            <span class="horario-tag">
                                {{listaHorarios.find(h => h.id == res.horario_id)?.nombre || 'Desconocido'}}
                            </span>
                        </td>
                        <td><span class="user-tag">{{ res.usuario_login }}</span></td>
                        <td>
                            <button
                                v-if="props.usuario.rol == 'Administrador' || res.usuario_login == usuarioLogeado.login"
                                @click="eliminarReserva(res)" class="btn-danger">
                                Anular
                            </button>
                            <span v-else class="lock-icon">🔒</span>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
/* Estilos corporativos DAW */
.seccion-header {
    border-left: 5px solid #9b59b6;
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
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.input-labeled {
    display: flex;
    flex-direction: column;
    gap: 5px;
    text-align: left;
}

.input-labeled label {
    font-size: 0.75rem;
    color: #7f8c8d;
    font-weight: bold;
}

input,
select {
    padding: 12px;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
    border: 1px solid #ccc;
}

.full-width {
    grid-column: span 2;
}

.btn-success {
    background: #27ae60;
    color: white;
    padding: 14px;
    border: none;
    border-radius: 4px;
    font-weight: bold;
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

.lock-icon {
    font-size: 1rem;
    opacity: 0.5;
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
    color: #7f8c8d;
    text-transform: uppercase;
    font-size: 0.75rem;
}

.horario-tag {
    background: #e8f8f5;
    color: #16a085;
    padding: 2px 8px;
    border-radius: 12px;
    font-size: 0.8rem;
    font-weight: bold;
}

.user-tag {
    font-weight: bold;
    color: #2980b9;
}
</style>