<script setup>
/**
 * COMPONENTE: GestionProfesores.vue
 * Descripción: Módulo para el mantenimiento de la plantilla docente.
 * Incluye carga de departamentos y roles para la integridad de datos.
 */
import { ref, onMounted } from 'vue'

const listaProfesores = ref([]) //ARRAY DE PROFESORES
const listaDepartamentos = ref([]) //ARRAY DE DEPARTAMENTOS
const listaRoles = ref([]) //ARRAY DE ROLES

const editandoDNI = ref(null); //BOOLEANO DE EDICION

// MODELO DE PROFESOR INICIAL
const modeloProfesor = ref({
    dni_nie: '',
    nombre: '',
    apellidos: '',
    correo_institucional: '',
    departamento_id: '',
    rol_id: "PROF", //ROL POR DEFECTO DE PROFESOR
    password_hash: '',
    zfecha: new Date().toISOString(),
    zusuario: "DC4"
})

/**
 * CARGAMOS TODO CON PROMISE ALL PARA MEJORAR LOS TIEMPOS DE CARGA
 */
const sincronizarBaseDeDatos = async () => {
    try {
        const [resProf, resDep, resRoles] = await Promise.all([
            fetch('http://44.207.19.239:3000/profesores?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/departamentos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/roles?zusuario=DC4')
        ]);

        listaProfesores.value = await resProf.json();
        listaDepartamentos.value = await resDep.json();
        listaRoles.value = await resRoles.json();
    } catch (error) {
        console.error("Fallo crítico al sincronizar tablas maestros:", error);
    }
}

/**
 * CONTROL DE INTERFAZ PARA LA EDICION DE UN PROFESOR
 */
const iniciarEdicion = (profe) => {
    editandoDNI.value = profe.dni_nie;
    // COPIA PARA NO MODIFICAR LA TABLA REAL ANTES DE GUARDAR
    modeloProfesor.value = { ...profe };
}

/**
 * LIMPIA EL FORMULARIO Y SALE DEL MODO EDICION
 */
const cancelarEdicion = () => {
    editandoDNI.value = null;
    modeloProfesor.value = {
        dni_nie: '', nombre: '', apellidos: '',
        correo_institucional: '', departamento_id: '',
        rol_id: 2, password_hash: ''
    };
}

/**
 * REGISTRAMOS O EDITAMOS UN PROFESOR
 */
const guardarProfesor = async () => {
    // SINO ESTAMOS EDITANDO COMPROBAMOS EL DNI Y EL CORREO
    if (!editandoDNI.value) {
        const existe = listaProfesores.value.find(p =>
            p.dni_nie === modeloProfesor.value.dni_nie ||
            p.correo_institucional === modeloProfesor.value.correo_institucional
        );
        if (existe) {
            alert("ERROR: Ya existe un docente con ese DNI o correo institucional.");
            return;
        }
    }

    try {
        // ELEGIMOS EL METODO A USAR
        const metodo = editandoDNI.value ? 'PUT' : 'POST';
        const url = editandoDNI.value
            ? `http://44.207.19.239:3000/profesores/${editandoDNI.value}?zusuario=DC4`
            : 'http://44.207.19.239:3000/profesores';
        //HACEMOS LA PETICION CON ESE METODO
        const respuesta = await fetch(url, {
            method: metodo,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(modeloProfesor.value)
        });

        if (respuesta.ok) {
            alert(editandoDNI.value ? "Profesor actualizado correctamente." : "Profesor registrado correctamente.");
            cancelarEdicion();
            await sincronizarBaseDeDatos();
        }
    } catch (error) {
        alert("No se pudo conectar con el servidor.");
    }
}

/**
 * BORRADO CON CONFIRMACION 
 */
const eliminarDocente = async (dni) => {
    const confirmacion = confirm(`¿Estás seguro de que quieres dar de baja al profesor con DNI: ${dni}?`);

    if (confirmacion) {
        try {
            const respuesta = await fetch(`http://44.207.19.239:3000/profesores/${dni}?zusuario=DC4`, {
                method: 'DELETE'
            });

            if (respuesta.ok) {
                alert("Registro eliminado con éxito.");
                await sincronizarBaseDeDatos();
            } else {
                const errorServidor = await respuesta.text();
                alert("La API denegó el borrado: " + errorServidor);
            }
        } catch (error) {
            console.error("Error de red en DELETE:", error);
        }
    }
};

onMounted(sincronizarBaseDeDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="header-seccion">
            <h3>{{ editandoDNI ? 'Editando Profesor' : 'Gestión de Profesores (H3)' }}</h3>
        </header>

        <form @submit.prevent="guardarProfesor" class="form-grid">
            <!-- SI ESTAMOS EDITANDO EL DNI NO LO MODIFICAMOS PORQUE ES PK -->
            <input v-model="modeloProfesor.dni_nie" placeholder="DNI / NIE" :disabled="editandoDNI" required>
            <input v-model="modeloProfesor.nombre" placeholder="Nombre" required>
            <input v-model="modeloProfesor.apellidos" placeholder="Apellidos" required>
            <input v-model="modeloProfesor.correo_institucional" type="email" placeholder="Correo Institucional"
                required>

            <select v-model="modeloProfesor.departamento_id" required>
                <option value="" disabled>-- Selecciona Departamento --</option>
                <option v-for="dep in listaDepartamentos" :key="dep.id" :value="dep.id">
                    {{ dep.nombre }}
                </option>
            </select>

            <input v-model="modeloProfesor.password_hash" type="password" placeholder="Contraseña de acceso" required>

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ editandoDNI ? 'Guardar Cambios' : 'Añadir Docente al Sistema' }}
                </button>
                <button v-if="editandoDNI" type="button" @click="cancelarEdicion" class="btn-sec">
                    Cancelar
                </button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Nombre y Apellidos</th>
                        <th>Identificación</th>
                        <th>Departamento</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="profe in listaProfesores" :key="profe.dni_nie">
                        <td><strong>{{ profe.nombre }} {{ profe.apellidos }}</strong></td>
                        <td>{{ profe.dni_nie }}</td>
                        <td>
                            {{listaDepartamentos.find(d => d.id == profe.departamento_id)?.nombre || 'Sin asignar'}}
                        </td>
                        <td class="td-actions">
                            <button @click="iniciarEdicion(profe)" class="btn-accent">Editar</button>
                            <button @click="eliminarDocente(profe.dni_nie)" class="btn-danger">Eliminar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
/* Estilos extra para la edición */
.td-actions {
    display: flex;
    gap: 8px;
}

.form-actions {
    grid-column: span 2;
    display: flex;
    gap: 10px;
}

.btn-accent {
    background: #f39c12;
    color: white;
    border: none;
    padding: 8px 15px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: bold;
}

.btn-sec {
    background: #95a5a6;
    color: white;
    border: none;
    padding: 15px;
    border-radius: 4px;
    cursor: pointer;
    flex: 1;
    font-weight: bold;
}

.header-seccion {
    margin-bottom: 20px;
    border-left: 5px solid #27ae60;
    padding-left: 15px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    background: #fff;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

select,
input {
    padding: 12px;
    border: 1px solid #ccc;
    border-radius: 4px;
    color: #fff;
    background: #2c3e50;
    font-size: 0.95rem;
}

/* Evitar que parezca que se puede escribir en DNI bloqueado */
input:disabled {
    background: #34495e;
    color: #95a5a6;
    cursor: not-allowed;
}

input::placeholder {
    color: #bdc3c7;
}

input:focus {
    border-color: #27ae60;
    outline: none;
}

.btn-success {
    flex: 2;
    background: #27ae60;
    color: white;
    border: none;
    padding: 15px;
    cursor: pointer;
    font-weight: bold;
    border-radius: 4px;
    transition: background 0.3s;
}

.btn-success:hover {
    background: #219150;
}

.table-container {
    margin-top: 30px;
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
    overflow-x: auto;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th,
td {
    padding: 15px;
    text-align: left;
    border-bottom: 1px solid #ecf0f1;
}

th {
    background: #f9f9f9;
    text-transform: uppercase;
    font-size: 0.8rem;
    color: #7f8c8d;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    padding: 8px 15px;
    cursor: pointer;
    border: none;
    border-radius: 4px;
    font-size: 0.85rem;
    transition: transform 0.2s;
}

.btn-danger:hover {
    transform: scale(1.05);
    background: #c0392b;
}
</style>