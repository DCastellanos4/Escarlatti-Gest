<script setup>
/**
 * COMPONENTE: CrearIncidencias.vue
 * Descripción: Permite a los usuarios logeados reportar fallos técnicos.
 */
import { ref, onMounted } from 'vue'

// Recibimos la sesión desde el AdminPanel
const props = defineProps(['usuario']);

const listaEspacios = ref([]); //GUARDA LAS AULAS DESDE EL ENDPOINT DE ESPACIOS
const listaIncidencias = ref([]); //RECUPERA LAS INCIDENCIAS PARA PODER MOSTRARLAS
const isLoading = ref(false); //BOOLEANO DE CARGA PARA PODER DESHABILITAR EL BOTON

const modeloIncidencia = ref({ //ESTRUCTURA BASICA DE UNA INCIDENCIA
    espacio_id: '',
    descripcion_problema: '',
    zusuario: 'DC4'
});

/**
 * Carga de datos necesarios
 */
const cargarDatos = async () => {
    try {
        const [resEsp, resInc] = await Promise.all([
            fetch('http://44.207.19.239:3000/espacios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/incidencias?zusuario=DC4')
        ]);
        listaEspacios.value = await resEsp.json();
        listaIncidencias.value = await resInc.json();
    } catch (error) {
        console.error("Error al cargar datos de incidencias:", error);
    }
}

/**
 * Registro de nueva incidencia
 */
const registrarIncidencia = async () => {
    //PONEMOS EL BOOLEANO A TRUE PARA QUE MIENTRAS SE HAGAN LAS PETICIONES DESHABILITAR EL BOTON
    isLoading.value = true;

    // GENERACION DE ID MANUAL, ERROR EN LA BASE DE DATOS
    // Buscamos el ID más alto y le sumamos 1. 
    // Si la lista está vacía, empezamos en 1.
    const nuevoId = Math.max(0, ...listaIncidencias.value.map(i => Number(i.id))) + 1;


    // CREAMOS LA ESTRUCTURA DE LA INCIDENCIA
    const datosFinales = {
        id: nuevoId,                                     //
        espacio_id: modeloIncidencia.value.espacio_id,   //
        usuario_login: props.usuario.usuario,           // USUARIO LOGEADO
        descripcion_problema: modeloIncidencia.value.descripcion_problema, //
        estado_incidencia_id: 'ABI',                // SE CREA ABIERTA POR DEFECTO
        responsable_resolucion_id: null,                // VACIO AL CREAR
        comentarios_resolucion: null,                   // VACIO AL CREAR
        fecha_resolucion: null,                         // VACIO AL CREAR
        zfecha: new Date().toISOString(),               //
        zusuario: 'DC4'                                 //
    };

    try {
        //ENVIAMOS LA PETICION MEDIANTE POST
        const respuesta = await fetch('http://44.207.19.239:3000/incidencias?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            //LIMPIAMOS EL FORMULARIO Y SE MUESTRA UN ALERT DE EXITO
            alert(`Incidencia #${nuevoId} enviada al equipo TIC.`);
            modeloIncidencia.value.descripcion_problema = '';
            modeloIncidencia.value.espacio_id = '';
            //REFRESCAMOS LA LISTA PARA PODER CALCULAR EL ID AUTOINCREMENTABLE
            await cargarDatos();
        } else {
            const errorData = await respuesta.json();
            alert("Error al enviar: " + (errorData.error || "Datos no válidos"));
        }
    } catch (e) {
        alert("Fallo de conexión con el servidor.");
    } finally {
        //AUNQUE DE ERROR DEVOLVEMOS EL BOOLEANO PARA QUE MUESTRE EL BOTON OTRA VEZ
        isLoading.value = false;
    }
}
onMounted(cargarDatos);
</script>

<template>
    <div class="incidencias-container">
        <header class="seccion-header">
            <h3>Reportar Incidencia TIC</h3>
            <!-- MUESTRA EL USUARIO LOGEADO -->
            <p>Usuario: <strong>{{ props.usuario.nombre }}</strong></p>
        </header>

        <form @submit.prevent="registrarIncidencia" class="incidencia-form">
            <div class="input-group">
                <label>Aula o Espacio afectado</label>
                <select v-model="modeloIncidencia.espacio_id" required>
                    <option value="" disabled>-- Seleccionar ubicación --</option>
                    <!-- V-FOR PARA MOSTRAR TODAS LAS AULAS DEL ARRAY LISTAESPACIOS -->
                    <option v-for="e in listaEspacios" :key="e.id" :value="e.id">
                        {{ e.nombre }}
                    </option>
                </select>
            </div>

            <div class="input-group">
                <label>Descripción detallada del problema</label>
                <textarea v-model="modeloIncidencia.descripcion_problema"
                    placeholder="Ej: El proyector no enciende o falta un cable HDMI..." rows="4" required></textarea>
                    <!-- OBLIGATORIO LA DESCRIPCION PARA SABER QUE HAY QUE RESOLVER -->
            </div>

            <button type="submit" class="btn-enviar" :disabled="isLoading">
                {{ isLoading ? 'Enviando...' : 'Enviar Incidencia' }}
            </button>
        </form>

        <div class="info-footer">
            <small>Las incidencias se crean automáticamente en estado <strong>ABIERTA</strong>.</small>
        </div>
    </div>
</template>

<style scoped>
.incidencias-container {
    max-width: 600px;
    margin: 0 auto;
    background: white;
    padding: 25px;
    border-radius: 12px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

.seccion-header {
    border-bottom: 2px solid #f1f5f9;
    margin-bottom: 20px;
    padding-bottom: 10px;
}

.incidencia-form {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.input-group {
    display: flex;
    flex-direction: column;
    gap: 5px;
    text-align: left;
}

.input-group label {
    font-size: 0.85rem;
    font-weight: 600;
    color: #475569;
}

select,
textarea {
    padding: 12px;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    background: #f8fafc;
    font-family: inherit;
}

.btn-enviar {
    background: #ef4444;
    /* Rojo para alertas/incidencias */
    color: white;
    padding: 14px;
    border: none;
    border-radius: 8px;
    font-weight: bold;
    cursor: pointer;
    transition: background 0.2s;
}

.btn-enviar:hover {
    background: #dc2626;
}

.btn-enviar:disabled {
    background: #94a3b8;
}

.info-footer {
    margin-top: 20px;
    color: #64748b;
    font-style: italic;
}
</style>