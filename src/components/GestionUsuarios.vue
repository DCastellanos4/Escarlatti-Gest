<script setup>
/**
 * COMPONENTE: GestionUsuarios.vue
 * Descripción: Mantenimiento de cuentas de acceso. 
 * Vincula identidades (DNI/NIE) con roles, estados y credenciales.
 */
import { ref, onMounted, computed } from 'vue'

// --- ESTADO REACTIVO ---
const usuarios = ref([])
const profesores = ref([])
const alumnos = ref([])
const roles = ref([])
const estados = ref([])
const usuarioEditando = ref(null)

const modeloUsuario = ref({
    login: '',
    password_hash: '',
    rol_id: '',
    ref_identidad_fk: '',
    estado_id: 'ACT',
    ultimo_acceso: null,
    zusuario: 'DC4'
})

/**
 * Carga masiva de datos para resolver las FK (Foreign Keys)
 */
const cargarDatos = async () => {
    try {
        const [resUsr, resProf, resAlu, resRol, resEst] = await Promise.all([
            fetch('http://44.207.19.239:3000/usuarios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/profesores?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/alumnos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/roles?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/estados_usuario?zusuario=DC4')
        ]);

        usuarios.value = await resUsr.json();
        profesores.value = await resProf.json();
        alumnos.value = await resAlu.json();
        roles.value = await resRol.json();
        estados.value = await resEst.json();
    } catch (error) {
        console.error("Error al sincronizar el módulo de usuarios:", error);
    }
}

/**
 * Lista combinada de identidades (DNI de profes + NIA de alumnos)
 * para el selector de ref_identidad_fk
 */
const listaIdentidades = computed(() => {
    const profesMap = profesores.value.map(p => ({ id: p.dni_nie, nombre: `[PROF] ${p.nombre} ${p.apellidos}` }));
    const alumnosMap = alumnos.value.map(a => ({ id: a.nia, nombre: `[ALUM] ${a.nombre} ${a.apellidos}` }));
    return [...profesMap, ...alumnosMap];
});

/**
 * Guardar o Actualizar Usuario
 */
const procesarFormulario = async () => {
    const esEdicion = !!usuarioEditando.value;
    const origen = esEdicion ? usuarioEditando.value : modeloUsuario.value;

    // PAYLOAD LIMPIO: Evitamos enviar campos basura a la API
    const datosFinales = {
        login: origen.login,
        password_hash: origen.password_hash,
        rol_id: origen.rol_id,
        ref_identidad_fk: origen.ref_identidad_fk,
        estado_id: origen.estado_id,
        ultimo_acceso: origen.ultimo_acceso, // Siempre null en creación
        zusuario: 'DC4'
    };

    const metodo = esEdicion ? 'PUT' : 'POST';
    const url = esEdicion
        ? `http://44.207.19.239:3000/usuarios/${origen.login}?zusuario=DC4`
        : 'http://44.207.19.239:3000/usuarios?zusuario=DC4';

    try {
        const res = await fetch(url, {
            method: metodo,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (res.ok) {
            alert(esEdicion ? "Usuario actualizado" : "Cuenta creada con éxito");
            cancelarAccion();
            await cargarDatos();
        } else {
            const err = await res.json();
            alert("Error: " + (err.error || "No se pudo procesar la solicitud"));
        }
    } catch (error) {
        alert("Fallo de red.");
    }
}

const borrarUsuario = async (login) => {
    if (confirm(`¿Eliminar la cuenta de ${login}?`)) {
        await fetch(`http://44.207.19.239:3000/usuarios/${login}?zusuario=DC4`, { method: 'DELETE' });
        await cargarDatos();
    }
}

const iniciarEdicion = (u) => { usuarioEditando.value = { ...u }; }
const cancelarAccion = () => {
    usuarioEditando.value = null;
    modeloUsuario.value = { login: '', password_hash: '', rol_id: '', ref_identidad_fk: '', estado_id: 'ACT', ultimo_acceso: null, zusuario: 'DC4' };
}

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Control de Acceso y Usuarios (H12)</h3>
        </header>

        <form @submit.prevent="procesarFormulario" class="form-grid">
            <input v-if="!usuarioEditando" v-model="modeloUsuario.login" placeholder="Login (ej. admin.david)" required>
            <input v-else v-model="usuarioEditando.login" disabled>

            <input v-if="!usuarioEditando" v-model="modeloUsuario.password_hash" type="password" placeholder="Password"
                required>
            <input v-else v-model="usuarioEditando.password_hash" type="password"
                placeholder="Nueva Password (opcional)">

            <select v-if="!usuarioEditando" v-model="modeloUsuario.rol_id" required>
                <option value="" disabled>-- Selecciona Rol --</option>
                <option v-for="r in roles" :key="r.id" :value="r.id">{{ r.nombre }}</option>
            </select>
            <select v-else v-model="usuarioEditando.rol_id" required>
                <option v-for="r in roles" :key="r.id" :value="r.id">{{ r.nombre }}</option>
            </select>

            <select v-if="!usuarioEditando" v-model="modeloUsuario.ref_identidad_fk" required>
                <option value="" disabled>-- Vincular con Persona --</option>
                <option v-for="idnt in listaIdentidades" :key="idnt.id" :value="idnt.id">{{ idnt.nombre }}</option>
            </select>
            <select v-else v-model="usuarioEditando.ref_identidad_fk" required>
                <option v-for="idnt in listaIdentidades" :key="idnt.id" :value="idnt.id">{{ idnt.nombre }}</option>
            </select>

            <select v-if="!usuarioEditando" v-model="modeloUsuario.estado_id" required>
                <option v-for="est in estados" :key="est.id" :value="est.id">{{ est.nombre }}</option>
            </select>
            <select v-else v-model="usuarioEditando.estado_id" required>
                <option v-for="est in estados" :key="est.id" :value="est.id">{{ est.nombre }}</option>
            </select>

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ usuarioEditando ? 'Guardar Cambios' : 'Crear Usuario' }}
                </button>
                <button v-if="usuarioEditando" type="button" @click="cancelarAccion" class="btn-sec">Cancelar</button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Login</th>
                        <th>Vinculado a</th>
                        <th>Rol</th>
                        <th>Estado</th>
                        <th>Último Acceso</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="u in usuarios" :key="u.login">
                        <td><strong>{{ u.login }}</strong></td>
                        <td><small>{{ u.ref_identidad_fk }}</small></td>
                        <td><span class="badge-rol">{{ u.rol_id }}</span></td>
                        <td>
                            <span :class="u.estado_id === 'ACT' ? 'st-ok' : 'st-err'">
                                {{estados.find(e => e.id === u.estado_id)?.nombre || u.estado_id}}
                            </span>
                        </td>
                        <td>{{ u.ultimo_acceso || 'Nunca' }}</td>
                        <td class="td-actions">
                            <button @click="iniciarEdicion(u)" class="btn-accent">Editar</button>
                            <button @click="borrarUsuario(u.login)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
/* Estilo corporativo oscuro DAW solicitado */
.seccion-header {
    border-left: 5px solid #3498db;
    padding-left: 15px;
    margin-bottom: 20px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    background: #fff;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

input,
select {
    padding: 10px;
    border-radius: 4px;
    color: #fff;
    background: #2c3e50;
    border: 1px solid #ccc;
    font-size: 0.9rem;
}

input:disabled {
    background: #34495e;
    color: #95a5a6;
}

.form-actions {
    grid-column: span 2;
    display: flex;
    gap: 10px;
    margin-top: 10px;
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
    padding: 6px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    border: none;
    padding: 6px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.td-actions {
    display: flex;
    gap: 6px;
}

.table-container {
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
    margin-top: 20px;
    overflow-x: auto;
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.9rem;
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

.badge-rol {
    background: #ebf5fb;
    color: #2980b9;
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: bold;
    font-size: 0.7rem;
}

.st-ok {
    color: #27ae60;
    font-weight: bold;
}

.st-err {
    color: #e74c3c;
    font-weight: bold;
}
</style>