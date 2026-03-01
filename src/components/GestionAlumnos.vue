<script setup>
/**
 * COMPONENTE: GestionAlumnos.vue
 * Descripción: CRUD de alumnos con integración de estados por código (ACT, BAJ, etc.)
 */
import { ref, onMounted } from 'vue'

const listaAlumnos = ref([]) //CARGAMOS LOS ALUMNOS QUE YA ESTAN
const listaCursos = ref([]) //CARGAMOS LOS CURSOS PARA MOSTRARLOS EN EL SELECT
const listaEstados = ref([]) // CARGAMOS LOS ESTADAOS PARA MOSTRARLOS EN EL SELECT
const cargando = ref(false) //BOOLEANO DE CARGA

const mostrarModalBorrado = ref(false) //BOOLEANO PARA MOSTRAR LA CONFIRMACION DE ELIMINACION
const alumnoSeleccionado = ref(null) //SELECCION DEL OBJETO ALUMNO PARA PODER BORRARLO

//MODELO BASICO DE ALUMNO, CON REACTIVIDAD
const modeloAlumno = ref({
    nia: '',
    nombre: '',
    apellidos: '',
    curso_id: '',
    correo_electronico: '',
    tutor_legal_contacto: '',
    estado_id: 'ACT',
    zfecha: new Date().toISOString(),
    zusuario: "DC4"
})

/**
 * CARGA DE DATOS DE ALUMNOS, CURSOS Y ESTADOS
 */
const cargarInformacion = async () => {
    cargando.value = true
    try {
        //PROMISE ALL LANZA LAS 3 PETICIONES A LA VEZ AHORRANDO TIEMPO
        const [resAlu, resCur, resEst] = await Promise.all([
            fetch('http://44.207.19.239:3000/alumnos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/cursos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/estados_usuario?zusuario=DC4')
        ]);

        const alumnosBrutos = await resAlu.json();
        //ORDENAMOS LA LISTA DE ALUMNOS EN FUNCION DEL NIA(MEJORA VISUAL)
        listaAlumnos.value = alumnosBrutos.sort((a, b) => a.nia.localeCompare(b.nia, undefined, { numeric: true }));

        listaCursos.value = await resCur.json();
        listaEstados.value = await resEst.json();
    } catch (error) {
        console.error("Error de sincronización:", error);
    } finally {

        cargando.value = false
    }
}

/**
 * ALTERNAR ESTADOS DE ALUMNOS 
 */
const conmutarEstado = async (alumno) => {
    //TOGGLE DE ESTADO ENTRE ACTIVO Y BAJA
    const nuevoEstado = alumno.estado_id === 'ACT' ? 'BAJ' : 'ACT';
    //RECONSTRUIMOS EL OBJETO ALUMNO CON EL ESTADO ACTUALIZADO
    const datosActualizados = {
        nia: alumno.nia,
        nombre: alumno.nombre,
        apellidos: alumno.apellidos,
        curso_id: alumno.curso_id,
        correo_electronico: alumno.correo_electronico,
        tutor_legal_contacto: alumno.tutor_legal_contacto,
        estado_id: nuevoEstado,
        zusuario: "DC4"
    };

    try {
        //LO ENVIAMOS A LA API CON EL METODO PUT
        const res = await fetch(`http://44.207.19.239:3000/alumnos/${alumno.nia}?zusuario=DC4`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosActualizados)
        });

        if (res.ok) await cargarInformacion();
    } catch (error) {
        console.error("Error al cambiar estado:", error);
    }
}

/**
 * REGISTRO DE ALUMNO CON VALIDACION
 */
const registrarAlumno = async () => {
    //VALIDACION DE NIA, SI ENCUENTRA ALGUN ALUMNO CON EL MISMO NIA SE DETIENE LA FUNCION
    const duplicado = listaAlumnos.value.find(a => a.nia === modeloAlumno.value.nia);
    if (duplicado) {
        alert("El NIA ya existe.");
        return;
    }
    //VALIDACION DE CORREO ELECTRONIO, SI ENCUENTRA ALGUNO IGUAL PARA LA FUNCION
    const correoDuplicado = listaAlumnos.value.find(a => a.correo_electronico === modeloAlumno.value.correo_electronico);
    if (correoDuplicado) {
        alert("El correo ya existe.");
        return;
    }
    //OPERADOR DE PROPAGACION, SOLO AÑADO EL ZUSUARIO
    const datosFinales = {
        ...modeloAlumno.value,
        zusuario: "DC4"
    };

    try {
        //MANDO EL POST PARA GUARDAR EL NUEVO USUARIO
        const res = await fetch('http://44.207.19.239:3000/alumnos?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (res.ok) {
            //SI LO HA INTRODUCIDO RESETEO EL FORMULARIO
            modeloAlumno.value = {
                nia: '', nombre: '', apellidos: '', curso_id: '',
                correo_electronico: '', tutor_legal_contacto: '',
                estado_id: 'ACT', zusuario: "DC4"
            };
            await cargarInformacion();
            alert("Alumno registrado.");
        } else {
            const errorData = await respuesta.json();
            console.log("Error de la API: " + (errorData.error || "No se pudo crear el curso"));
        }
    } catch (error) {
        alert("Error de conexión.");
    }
}

const borrarDefinitivamente = async () => {
    //BORRADO MEDIANTE EL NIA DEL ALUMNO(PK), 
    await fetch(`http://44.207.19.239:3000/alumnos/${alumnoSeleccionado.value.nia}?zusuario=DC4`, { method: 'DELETE' });
    mostrarModalBorrado.value = false;
    await cargarInformacion();
}

onMounted(cargarInformacion);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Alumnado (H4)</h3>
        </header>
        <!-- FORM-GRID PARA TENER 2 COLUMNAS -->
        <form @submit.prevent="registrarAlumno" class="form-grid">
            <input v-model="modeloAlumno.nia" placeholder="NIA" required>
            <input v-model="modeloAlumno.nombre" placeholder="Nombre" required>
            <input v-model="modeloAlumno.apellidos" placeholder="Apellidos" required>
            <input v-model="modeloAlumno.correo_electronico" type="email" placeholder="Email" required>
            <input v-model="modeloAlumno.tutor_legal_contacto" placeholder="Email Tutor Legal" required>
            <!-- MOSTRAMOS EL SELECT CON LOS CURSOS DISPONIBLES PARA DAR DE ALTA -->
            <select v-model="modeloAlumno.curso_id" required>
                <option value="" disabled>Seleccionar Curso...</option>
                <option v-for="c in listaCursos" :key="c.id" :value="c.id">{{ c.nombre_curso }}</option>
            </select>

            <!-- <select v-model="modeloAlumno.estado_id" required>
                <option v-for="est in listaEstados" :key="est.id" :value="est.id">
                    {{ est.nombre }}
                </option>
            </select> -->

            <button type="submit" class="btn-success">Añadir Alumno</button>
        </form>
        <!-- MOSTRAMOS LOS ALUMNOS -->
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>NIA</th>
                        <th>Nombre</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="alu in listaAlumnos" :key="alu.nia">
                        <td><strong>{{ alu.nia }}</strong></td>
                        <td>{{ alu.nombre }} {{ alu.apellidos }}</td>
                        <td>
                            <!-- CLASE EN FUNCION SI ESTA ACTIVO O NO PARA CAMBIAR EL COLOR DE LAS LETRAS(MEJORA VISUAL) -->
                            <span :class="alu.estado_id === 'ACT' ? 'status-active' : 'status-inactive'">
                                {{listaEstados.find(e => e.id === alu.estado_id)?.nombre || alu.estado_id}}
                            </span>
                        </td>
                        <td class="td-actions">
                            <!-- BOTON PARA CAMBIAR EL ESTADO DEL ALUMNO -->
                            <button @click="conmutarEstado(alu)"
                                :class="alu.estado_id === 'ACT' ? 'btn-warn' : 'btn-ok'">
                                {{ alu.estado_id === 'ACT' ? 'Dar de Baja' : 'Activar' }}
                            </button>
                            <!-- BOTON PARA MOSTRAR EL CUADRO DE BORRADO DEL ALUMNO -->
                            <button @click="alumnoSeleccionado = alu; mostrarModalBorrado = true"
                                class="btn-danger">Eliminar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div v-if="mostrarModalBorrado" class="modal-overlay">
            <div class="modal-box">
                <h4>Confirmar Borrado</h4>
                <p>¿Borrar a {{ alumnoSeleccionado.nombre }}?</p>
                <div class="modal-actions">
                    <button @click="borrarDefinitivamente" class="btn-danger">Eliminar</button>
                    <button @click="mostrarModalBorrado = false" class="btn-sec">Cancelar</button>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
/* Estilos mantenidos según tu diseño oscuro DAW */
select,
input {
    padding: 12px;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
    border: 1px solid #ddd;
    margin-bottom: 5px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    background: #fff;
    padding: 20px;
    border-radius: 8px;
}

.btn-success {
    grid-column: span 2;
    background: #27ae60;
    color: white;
    padding: 14px;
    border: none;
    cursor: pointer;
    font-weight: bold;
    border-radius: 6px;
}

.status-active {
    color: #27ae60;
    font-weight: bold;
}

.status-inactive {
    color: #e74c3c;
    font-weight: bold;
}

.table-container {
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
    margin-top: 20px;
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

.td-actions {
    display: flex;
    gap: 10px;
}

.btn-warn {
    background: #f39c12;
    color: white;
    border: none;
    padding: 6px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-ok {
    background: #27ae60;
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
}

.modal-box {
    background: white;
    padding: 30px;
    border-radius: 12px;
    text-align: center;
    color: #333;
}
</style>