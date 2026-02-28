<script setup>
/**
 * COMPONENTE: GestionDepartamentos.vue
 * Descripción: Mantenimiento de departamentos usando códigos ID (INF, MAT, etc.)
 */
import { ref, onMounted } from 'vue'

const departamentos = ref([])
const profesores = ref([])

// Modelo ajustado a tu captura: id (texto), nombre, ubicacion, correo_contacto
const nuevoDep = ref({
    id: '',
    nombre: '',
    ubicacion: '',
    correo_contacto: '',
    zusuario: 'DC4'
})
const depEditando = ref(null)

const cargarDatos = async () => {
    try {
        const [resDep, resProf] = await Promise.all([
            fetch('http://44.207.19.239:3000/departamentos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/profesores?zusuario=DC4')
        ]);

        const dataDep = await resDep.json();
        // Ordenamos por el código ID alfabéticamente
        departamentos.value = dataDep.sort((a, b) => a.id.localeCompare(b.id));
        profesores.value = await resProf.json();
    } catch (error) {
        console.error("Error cargando departamentos:", error);
    }
}

const guardarDepartamento = async () => {
    // Verificamos si el código ya existe
    const existe = departamentos.value.find(d => d.id.toUpperCase() === nuevoDep.value.id.toUpperCase());
    if (existe) {
        alert("El código de Departamento ya existe.");
        return;
    }

    const datosFinales = {
        id: nuevoDep.value.id.toUpperCase(),
        nombre: nuevoDep.value.nombre,
        ubicacion: nuevoDep.value.ubicacion,
        correo_contacto: nuevoDep.value.correo_contacto,
        zusuario: 'DC4'
    };

    try {
        const respuesta = await fetch('http://44.207.19.239:3000/departamentos?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert("Departamento registrado con éxito.");
            nuevoDep.value = { id: '', nombre: '', ubicacion: '', correo_contacto: '', zusuario: 'DC4' };
            await cargarDatos();
        }
    } catch (e) {
        alert("Error al conectar con la API.");
    }
}

const actualizarDepartamento = async () => {
    const datosFinales = {
        ...depEditando.value,
        zusuario: 'DC4'
    };

    try {
        const res = await fetch(`http://44.207.19.239:3000/departamentos/${depEditando.value.id}?zusuario=DC4`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (res.ok) {
            depEditando.value = null;
            await cargarDatos();
        }
    } catch (e) {
        alert("Error en la actualización.");
    }
}

const borrarDepartamento = async (id) => {
    // Comprobamos si hay profesores vinculados al código de departamento
    const tieneProfesores = profesores.value.some(p => p.departamento_id === id);

    if (tieneProfesores) {
        alert("Acción bloqueada: No puedes borrar un departamento que tiene profesores asignados.");
        return;
    }

    if (confirm(`¿Eliminar el departamento ${id}?`)) {
        await fetch(`http://44.207.19.239:3000/departamentos/${id}?zusuario=DC4`, { method: 'DELETE' });
        await cargarDatos();
    }
}

const iniciarEdicion = (dep) => { depEditando.value = { ...dep }; }
const cancelarEdicion = () => { depEditando.value = null; }

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Departamentos (H10)</h3>
        </header>

        <form @submit.prevent="depEditando ? actualizarDepartamento() : guardarDepartamento()" class="form-grid">
            <input v-if="!depEditando" v-model="nuevoDep.id" placeholder="Código ID (ej. INF)" required>
            <input v-else v-model="depEditando.id" disabled>

            <input v-if="!depEditando" v-model="nuevoDep.nombre" placeholder="Nombre (ej. Informática)" required>
            <input v-else v-model="depEditando.nombre" placeholder="Nombre" required>

            <input v-if="!depEditando" v-model="nuevoDep.ubicacion" placeholder="Ubicación (ej. Ala Norte)" required>
            <input v-else v-model="depEditando.ubicacion" placeholder="Ubicación" required>

            <input v-if="!depEditando" v-model="nuevoDep.correo_contacto" placeholder="Correo de contacto"
                class="full-width" required>
            <input v-else v-model="depEditando.correo_contacto" placeholder="Correo" class="full-width" required>

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ depEditando ? 'Guardar Cambios' : 'Registrar Departamento' }}
                </button>
                <button v-if="depEditando" type="button" @click="cancelarEdicion" class="btn-sec">Cancelar</button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Código</th>
                        <th>Nombre</th>
                        <th>Ubicación</th>
                        <th>Contacto</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="d in departamentos" :key="d.id">
                        <td><strong>{{ d.id }}</strong></td>
                        <td>{{ d.nombre }}</td>
                        <td>{{ d.ubicacion || 'No especificada' }}</td>
                        <td>{{ d.correo_contacto || 'Sin correo' }}</td>
                        <td class="td-actions">
                            <button @click="iniciarEdicion(d)" class="btn-accent">Editar</button>
                            <button @click="borrarDepartamento(d.id)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
.seccion-header {
    border-left: 5px solid #27ae60;
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
    margin-bottom: 20px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.full-width {
    grid-column: span 2;
}

input {
    padding: 12px;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
    border: 1px solid #ccc;
}

input:disabled {
    background: #34495e;
    color: #bdc3c7;
}

.btn-success {
    background: #27ae60;
    color: white;
    padding: 12px;
    border: none;
    border-radius: 4px;
    font-weight: bold;
    cursor: pointer;
    flex: 2;
}

.btn-sec {
    background: #95a5a6;
    color: white;
    padding: 12px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    flex: 1;
}

.btn-accent {
    background: #f39c12;
    color: white;
    border: none;
    padding: 8px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    border: none;
    padding: 8px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.td-actions {
    display: flex;
    gap: 8px;
}

.table-container {
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
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
    font-size: 0.8rem;
    text-transform: uppercase;
}
</style>