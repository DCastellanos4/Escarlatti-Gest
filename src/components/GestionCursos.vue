<script setup>
/**
 * COMPONENTE: GestionCursos.vue
 * Descripción: Mantenimiento de grupos/cursos del centro. 
 * Maneja relaciones con Etapas, Turnos, Profesores (Tutores) y Espacios.
 */
import { ref, onMounted } from 'vue'

// --- ESTADO REACTIVO ---
const cursos = ref([]) //TABLA CURSOS
const profesores = ref([]) //TABLA PROFESORES
const etapas = ref([]) //TABLA ETAPAS
const turnos = ref([]) //TABLA TURNOS
const alumnos = ref([]) //TABLA ALUMNOS
const espacios = ref([])//TABLA ESPACIOS

// CONTROL DE INTERFAZ PARA VER EL CUADRO DE ALUMNOS POR CURSO
const cursoVerAlumnos = ref(null)
const mostrarModalAlumnos = ref(false)

// MODELO PARA EL CURSO
const nuevoCurso = ref({
    id: '',
    nombre_curso: '',
    etapa_id: '',
    grupo: '',
    turno_id: '',
    anio_academico: '',
    tutor_id: '',
    aula_id: '',
    zfecha: new Date().toISOString(),
    zusuario: "DC4"
})

/**
 * CARGA INICIAL DE DATOS
 * USAMOS PROMISE ALL PARA TRAER TODAS LAS TABLAS DE GOLPE
 */
const cargarDatos = async () => {
    try {
        const [resCur, resProf, resEt, resTur, resAlu, resEsp] = await Promise.all([
            fetch('http://44.207.19.239:3000/cursos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/profesores?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/etapas?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/turnos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/alumnos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/espacios?zusuario=DC4')
        ]);

        cursos.value = await resCur.json();
        profesores.value = await resProf.json();
        etapas.value = await resEt.json();
        turnos.value = await resTur.json();
        alumnos.value = await resAlu.json();
        espacios.value = await resEsp.json();
    } catch (error) {
        console.error("Fallo al sincronizar datos del servidor:", error);
    }
}


/**
 * REGISTRA UN NUEVO CURSO CON LOGICA DE VALIDACION 
 */
const guardarCurso = async () => {
    // 1. CÁLCULO MANUAL DEL ID (PROBLEMAS CON BBDD)
    const nuevoId = (Math.max(0, ...cursos.value.map(c => Number(c.id) || 0)) + 1);

    // VALIDACION DE TUTOR UNICO
    const tutorOcupado = cursos.value.find(c =>
        Number(c.tutor_id) === Number(nuevoCurso.value.tutor_id) &&
        c.anio_academico === nuevoCurso.value.anio_academico
    );

    if (tutorOcupado) {
        alert(`Ojo: Este profesor ya es tutor de otro grupo en ${nuevoCurso.value.anio_academico}.`);
        return;
    }

    //CONSTRUCCIÓN DEL OBJETO 
    const datosFinales = {
        id: nuevoId,
        nombre_curso: nuevoCurso.value.nombre_curso,
        etapa_id: nuevoCurso.value.etapa_id,
        grupo: nuevoCurso.value.grupo,
        turno_id: nuevoCurso.value.turno_id,
        anio_academico: nuevoCurso.value.anio_academico,
        tutor_id: nuevoCurso.value.tutor_id,
        aula_id: nuevoCurso.value.aula_id,
        zusuario: "DC4" // Requisito de tu API en el body
    };
    //LO ENVIAMOS CON POST
    try {
        const respuesta = await fetch('http://44.207.19.239:3000/cursos?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert(`Curso creado con éxito (ID asignado: ${nuevoId})`);

            // RESET DEL FORMULARIO
            nuevoCurso.value = {
                id: '', nombre_curso: '', etapa_id: '', grupo: '',
                turno_id: '', anio_academico: '', tutor_id: '', aula_id: '',
                zfecha: new Date().toISOString(), zusuario: "DC4"
            };

            // ACTUALIZAMOS LA VISUAL DE LA TABLA
            await cargarDatos();
        } else {
            const errorData = await respuesta.json();
            alert("Error de la API: " + (errorData.error || "No se pudo crear el curso"));
        }
    } catch (e) {
        alert("Error de red: No se ha podido contactar con la API.");
    }
}

/**
 * INFORMACION DE LOS ALUMNOS DE UN CURSO
 */
const verAlumnos = (curso) => {
    cursoVerAlumnos.value = curso;
    mostrarModalAlumnos.value = true;
};

/**
 * BORRADO CON PROTECTION DE FK
 */
const intentarBorrarCurso = async (id) => {
    //NO PERMITE BORRAR SI EL CURSO TIENE ALUMNOS
    const tieneAlumnos = alumnos.value.some(a => Number(a.curso_id) === Number(id));

    if (tieneAlumnos) {
        alert("Acción bloqueada: No puedes borrar un curso que tiene alumnos matriculados.");
        return;
    }

    if (confirm("¿Estás seguro de que quieres eliminar este curso permanentemente?")) {
        await fetch(`http://44.207.19.239:3000/cursos/${id}?zusuario=DC4`, { method: 'DELETE' });
        await cargarDatos();
    }
}

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Cursos (H5)</h3>
        </header>

        <form @submit.prevent="guardarCurso" class="form-grid">
            <input v-model="nuevoCurso.nombre_curso" placeholder="Nombre (ej. 2º DAW)" required>
            <input v-model="nuevoCurso.grupo" placeholder="Grupo (ej. A)" required>
            <input v-model="nuevoCurso.anio_academico" placeholder="Año Académico (ej. 2025-2026)" required>

            <select v-model="nuevoCurso.etapa_id" required>
                <option value="" disabled>-- Seleccionar Etapa --</option>
                <option v-for="e in etapas" :key="e.id" :value="e.id">{{ e.nombre }}</option>
            </select>

            <select v-model="nuevoCurso.turno_id" required>
                <option value="" disabled>-- Seleccionar Turno --</option>
                <option v-for="t in turnos" :key="t.id" :value="t.id">{{ t.nombre }}</option>
            </select>

            <select v-model="nuevoCurso.aula_id" required>
                <option value="" disabled>-- Asignar Aula/Espacio --</option>
                <option v-for="es in espacios" :key="es.id" :value="es.id">{{ es.nombre }}</option>
            </select>

            <select v-model="nuevoCurso.tutor_id" required>
                <option value="" disabled>-- Asignar Tutor/a --</option>
                <option v-for="p in profesores" :key="p.id" :value="p.dni_nie">
                    {{ p.nombre }} {{ p.apellidos }}
                </option>
            </select>

            <button type="submit" class="btn-success">Registrar Nuevo Curso</button>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Curso y Grupo</th>
                        <th>Año</th>
                        <th>Tutor Asignado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="c in cursos" :key="c.id">
                        <td><strong>#{{ c.id }}</strong></td>
                        <td>{{ c.nombre_curso }} - {{ c.grupo }}</td>
                        <td>{{ c.anio_academico }}</td>
                        <td>
                            {{profesores.find(p => p.dni_nie == c.tutor_id)?.nombre || 'S/T'}}
                            {{profesores.find(p => p.dni_nie == c.tutor_id)?.apellidos || ''}}
                        </td>
                        <td class="td-actions">
                            <button @click="verAlumnos(c)" class="btn-accent">Ver Alumnos</button>
                            <button @click="intentarBorrarCurso(c.id)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <!-- FILTRO REAL DE ALUMNOS SOLO MUESTRA LOS ALUMNOS QUE ESTAN LINKEADOS A UN CURSO -->
        <div v-if="mostrarModalAlumnos" class="modal-overlay">
            <div class="modal-box">
                <h4>Alumnos matriculados en {{ cursoVerAlumnos?.nombre_curso }}</h4>
                <div class="lista-scroll">
                    <!-- AL HACER CLICK EN VER ALUMNOS, SE MUESTRA LA LISTA DE ALUMNOS EN TIEMPO REAL QUE EL IDCURSO = CURSOSELECCIONADO -->
                    <ul v-if="alumnos.filter(a => Number(a.curso_id) === Number(cursoVerAlumnos?.id)).length > 0">
                        <li v-for="a in alumnos.filter(a => Number(a.curso_id) === Number(cursoVerAlumnos?.id))"
                            :key="a.id">
                            {{ a.nombre }} {{ a.apellidos }} <small>({{ a.nia }})</small>
                        </li>
                    </ul>
                    <p v-else class="empty-msg">No hay alumnos registrados en este grupo.</p>
                </div>
                <button @click="mostrarModalAlumnos = false" class="btn-sec">Cerrar Ventana</button>
            </div>
        </div>
    </div>
</template>

<style scoped>
.seccion-header {
    margin-bottom: 20px;
    border-left: 5px solid #f39c12;
    padding-left: 15px;
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

/* Inputs oscuros con texto blanco como pediste */
select,
input {
    padding: 12px;
    border: 1px solid #ddd;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
}

option {
    background: #2c3e50;
    color: #fff;
}

.btn-success {
    grid-column: span 2;
    background: #27ae60;
    color: white;
    border: none;
    padding: 14px;
    cursor: pointer;
    border-radius: 6px;
    font-weight: bold;
    transition: background 0.3s;
}

.btn-success:hover {
    background: #219150;
}

.table-container {
    margin-top: 25px;
    background: white;
    padding: 20px;
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
    padding: 14px;
    text-align: left;
    border-bottom: 1px solid #f0f0f0;
}

th {
    background: #f9f9f9;
    color: #7f8c8d;
    font-size: 0.8rem;
    text-transform: uppercase;
}

.td-actions {
    display: flex;
    gap: 8px;
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

.btn-sec {
    background: #95a5a6;
    color: white;
    border: none;
    padding: 10px 25px;
    border-radius: 4px;
    cursor: pointer;
    margin-top: 20px;
}

/* Estilos del Modal */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
}

.modal-box {
    background: white;
    padding: 35px;
    border-radius: 12px;
    max-width: 500px;
    width: 90%;
    color: #333;
    text-align: center;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.lista-scroll {
    max-height: 300px;
    overflow-y: auto;
    margin: 20px 0;
    border: 1px solid #eee;
    border-radius: 6px;
    padding: 10px;
}

.lista-scroll ul {
    list-style: none;
    padding: 0;
    text-align: left;
}

.lista-scroll li {
    padding: 8px 0;
    border-bottom: 1px solid #f9f9f9;
    font-size: 0.95rem;
}

.empty-msg {
    color: #95a5a6;
    font-style: italic;
}
</style>