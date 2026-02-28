<script setup>
/**
 * COMPONENTE: GestionRoles.vue
 * Descripción: Mantenimiento de roles de acceso utilizando códigos de texto (ADMIN, PROF, etc.)
 */
import { ref, onMounted } from 'vue'

const roles = ref([])
// Modelo inicializado con campos vacíos y zusuario
const nuevoRol = ref({
    id: '', // Se ingresará manualmente como código (ej: 'GESTOR')
    nombre: '',
    nivel_privilegio: 1,
    descripcion: '',
    zusuario: 'DC4'
})
const rolEditando = ref(null)

/**
 * Carga de roles desde la API
 */
const cargarRoles = async () => {
    try {
        const respuesta = await fetch('http://44.207.19.239:3000/roles?zusuario=DC4')
        const data = await respuesta.json()
        // Ordenamos alfabéticamente por el código ID
        roles.value = data.sort((a, b) => a.id.localeCompare(b.id))
    } catch (error) {
        console.error("Error cargando roles:", error)
    }
}

/**
 * Registro de un nuevo Rol (POST)
 */
const guardarRol = async () => {
    // Verificamos si el código ya existe para evitar errores de clave primaria
    const existe = roles.value.find(r => r.id.toUpperCase() === nuevoRol.value.id.toUpperCase());
    if (existe) {
        alert("El código de Rol (ID) ya existe. Prueba con otro.");
        return;
    }

    // Payload limpio enviando el ID en mayúsculas
    const datosFinales = {
        id: nuevoRol.value.id.toUpperCase(),
        nombre: nuevoRol.value.nombre,
        nivel_privilegio: Number(nuevoRol.value.nivel_privilegio),
        descripcion: nuevoRol.value.descripcion,
        zusuario: 'DC4'
    };

    try {
        const respuesta = await fetch('http://44.207.19.239:3000/roles?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert("Rol creado correctamente.");
            nuevoRol.value = { id: '', nombre: '', nivel_privilegio: 1, descripcion: '', zusuario: 'DC4' };
            await cargarRoles();
        } else {
            const err = await respuesta.json();
            alert("Error: " + (err.error || "No se pudo crear"));
        }
    } catch (e) {
        alert("Error de conexión con la API.");
    }
}

/**
 * Actualización de Rol existente (PUT)
 */
const actualizarRol = async () => {
    const datosFinales = {
        ...rolEditando.value,
        nivel_privilegio: Number(rolEditando.value.nivel_privilegio),
        zusuario: 'DC4'
    };

    try {
        await fetch(`http://44.207.19.239:3000/roles/${rolEditando.value.id}?zusuario=DC4`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });
        rolEditando.value = null;
        await cargarRoles();
    } catch (e) {
        alert("Error al actualizar.");
    }
}

const borrarRol = async (id) => {
    if (confirm(`¿Eliminar el rol ${id}?`)) {
        await fetch(`http://44.207.19.239:3000/roles/${id}?zusuario=DC4`, { method: 'DELETE' });
        await cargarRoles();
    }
}

const iniciarEdicion = (rol) => { rolEditando.value = { ...rol }; }
const cancelarEdicion = () => { rolEditando.value = null; }

onMounted(cargarRoles);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Roles y Privilegios (H11)</h3>
        </header>

        <form @submit.prevent="rolEditando ? actualizarRol() : guardarRol()" class="form-grid">
            <input v-if="!rolEditando" v-model="nuevoRol.id" placeholder="Código ID (ej. GESTOR)" required>
            <input v-else v-model="rolEditando.id" disabled>

            <input v-if="!rolEditando" v-model="nuevoRol.nombre" placeholder="Nombre Visible" required>
            <input v-else v-model="rolEditando.nombre" placeholder="Nombre Visible" required>

            <div class="input-group">
                <label>Nivel de Privilegio (1-10)</label>
                <input v-if="!rolEditando" v-model="nuevoRol.nivel_privilegio" type="number" min="1" max="10" required>
                <input v-else v-model="rolEditando.nivel_privilegio" type="number" min="1" max="10" required>
            </div>

            <input v-if="!rolEditando" v-model="nuevoRol.descripcion" placeholder="Descripción de permisos"
                class="full-width">
            <input v-else v-model="rolEditando.descripcion" placeholder="Descripción" class="full-width">

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ rolEditando ? 'Guardar Cambios' : 'Registrar Rol' }}
                </button>
                <button v-if="rolEditando" type="button" @click="cancelarEdicion" class="btn-sec">Cancelar</button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Código</th>
                        <th>Nombre</th>
                        <th>Nivel</th>
                        <th>Descripción</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="rol in roles" :key="rol.id">
                        <td><strong>{{ rol.id }}</strong></td>
                        <td>{{ rol.nombre }}</td>
                        <td><span class="badge">Nivel {{ rol.nivel_privilegio }}</span></td>
                        <td>{{ rol.descripcion || 'Sin descripción' }}</td>
                        <td class="td-actions">
                            <button @click="iniciarEdicion(rol)" class="btn-accent">Editar</button>
                            <button @click="borrarRol(rol.id)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
/* Manteniendo tu estilo corporativo DAW */
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

.input-group {
    display: flex;
    flex-direction: column;
}

.input-group label {
    font-size: 0.7rem;
    color: #7f8c8d;
    margin-bottom: 2px;
}

input {
    padding: 12px;
    border-radius: 4px;
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
    padding: 14px;
    border: none;
    border-radius: 4px;
    font-weight: bold;
    cursor: pointer;
    flex: 2;
}

.btn-sec {
    background: #95a5a6;
    color: white;
    padding: 14px;
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

.badge {
    background: #ecf0f1;
    color: #2c3e50;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: bold;
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