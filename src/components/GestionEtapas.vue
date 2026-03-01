<script setup>
/**
 * COMPONENTE: GestionEtapas.vue
 * Descripción: Mantenimiento de las etapas educativas del centro.
 */
import { ref, onMounted } from 'vue'

const listaEtapas = ref([]) //ARRAY DE ETAPAS
const etapaEnEdicion = ref(null) //BOOLEANO DE EDICION

// MODELO BASICO DE ETAPA
const modeloEtapa = ref({ id: '', nombre: '', descripcion: '', zusuario: 'DC4' })

/**
 * CARGA LAS ETAPAS DESDE LA API
 */
const sincronizarEtapas = async () => {
    try {
        const respuesta = await fetch('http://44.207.19.239:3000/etapas?zusuario=DC4')
        const datos = await respuesta.json()
        // Ordenamos alfabéticamente por el codigo ID
        listaEtapas.value = datos.sort((a, b) => a.id.localeCompare(b.id))
    } catch (error) {
        console.error("Fallo al sincronizar etapas:", error);
    }
}

/**
 * PROCESA EL FORMULARIO Y DECIDE SI USAR PUT PARA ACTUALIZAR O POST PARA ENVIAR
 */
const procesarFormulario = async () => {
    const esEdicion = !!etapaEnEdicion.value;
    const origen = esEdicion ? etapaEnEdicion.value : modeloEtapa.value;

    // ID CON LETRAS MAYUSCULAS
    //VALIDACION DE DUPLICIDAD DE ID'S
    const duplicado = listaEtapas.value.find(a => a.id === modeloEtapa.value.id);
    if (duplicado) {
        alert("El ID ya existe.");
        return;
    }
    const datosParaEnviar = {
        id: origen.id.toUpperCase(), // MAYUSCULAS PARA EL CODIGO
        nombre: origen.nombre,
        descripcion: origen.descripcion,
        zusuario: 'DC4'
    };
    //A PARTIR DE AQUI SE DECIDE SI SE VA A EDITAR UN REGISTRO O INSERTAR UNO NUEVO
    //CUANDO SE PULSA EL BOTON DE EDICION, SE ELIGE EL METODO PUT, Y SINO SE HA PULSADO SERA POST POR DEFECTO
    const metodo = esEdicion ? 'PUT' : 'POST';
    const url = esEdicion
        ? `http://44.207.19.239:3000/etapas/${origen.id}?zusuario=DC4`
        : 'http://44.207.19.239:3000/etapas?zusuario=DC4';
    //ENVIAMOS EL METODO A LA API
    try {
        const respuesta = await fetch(url, {
            method: metodo,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosParaEnviar)
        });

        if (respuesta.ok) {
            //DEPENDIENDO DE SI ES EDICION O NO SE MUESTRA UN ALERT PERSONALIZADO Y SE CANCELA LA EDICION
            alert(esEdicion ? "Etapa actualizada correctamente" : "Etapa registrada con éxito");
            cancelarAccion();
            await sincronizarEtapas();
        } else {
            const errorData = await respuesta.json();
            alert("Error de la API: " + (errorData.error || "No se pudo procesar"));
        }
    } catch (error) {
        alert("Error de comunicación con el servidor.");
    }
}

/**
 * ELIMINACION DE ETAPAS CON CONFIRMACION
 */
const eliminarRegistro = async (id) => {
    if (confirm(`¿Seguro que quieres borrar la etapa ${id}?`)) {
        // SI SE CONFIRMA MANDAMOS UN METODO DELETE
        try {
            const respuesta = await fetch(`http://44.207.19.239:3000/etapas/${id}?zusuario=DC4`, { method: 'DELETE' });

            if (respuesta.ok) {
                await sincronizarEtapas();
            } else {
                alert("Acción denegada: Probablemente existen cursos vinculados a esta etapa.");
            }
        } catch (error) {
            console.error("Fallo en el borrado:", error);
        }
    }
}

// --- METODOS PARA LA GESTION DE LA INTERFAZ EN EDICION ---
const prepararEdicion = (etapa) => { etapaEnEdicion.value = { ...etapa }; }
const cancelarAccion = () => {
    etapaEnEdicion.value = null;
    modeloEtapa.value = { id: '', nombre: '', descripcion: '', zusuario: 'DC4' };
}

onMounted(sincronizarEtapas);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Etapas Educativas (H8)</h3>
        </header>

        <form @submit.prevent="procesarFormulario" class="form-grid">
            <input v-if="!etapaEnEdicion" v-model="modeloEtapa.id" placeholder="Código ID (ej. DAW)" required>
            <input v-else v-model="etapaEnEdicion.id" disabled>

            <input v-if="!etapaEnEdicion" v-model="modeloEtapa.nombre" placeholder="Nombre (ej. Desarrollo App Web)"
                required>
            <input v-else v-model="etapaEnEdicion.nombre" placeholder="Nombre" required>

            <input v-if="!etapaEnEdicion" v-model="modeloEtapa.descripcion" placeholder="Descripción de la etapa"
                class="full-width" required>
            <input v-else v-model="etapaEnEdicion.descripcion" placeholder="Descripción" class="full-width" required>

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ etapaEnEdicion ? 'Guardar Cambios' : 'Registrar Etapa' }}
                </button>
                <button v-if="etapaEnEdicion" type="button" @click="cancelarAccion" class="btn-sec">
                    Cancelar
                </button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Código</th>
                        <th>Nombre</th>
                        <th>Descripción</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="et in listaEtapas" :key="et.id">
                        <td><strong>{{ et.id }}</strong></td>
                        <td>{{ et.nombre }}</td>
                        <td>{{ et.descripcion }}</td>
                        <td class="action-buttons">
                            <button @click="prepararEdicion(et)" class="btn-accent">Editar</button>
                            <button @click="eliminarRegistro(et.id)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
/* Estilos corporativos oscuros */
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
    margin-bottom: 25px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.full-width {
    grid-column: span 2;
}

input {
    padding: 12px;
    border: 1px solid #ccc;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
}

input:disabled {
    background: #34495e;
    color: #bdc3c7;
}

.btn-success {
    background: #27ae60;
    color: white;
    padding: 12px;
    border-radius: 4px;
    font-weight: bold;
    cursor: pointer;
    flex: 2;
    border: none;
}

.btn-sec {
    background: #95a5a6;
    color: white;
    padding: 12px;
    border-radius: 4px;
    cursor: pointer;
    flex: 1;
    border: none;
}

.btn-accent {
    background: #f39c12;
    color: white;
    padding: 8px 15px;
    border-radius: 4px;
    cursor: pointer;
    border: none;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    padding: 8px 15px;
    border-radius: 4px;
    cursor: pointer;
    border: none;
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
    padding: 14px;
    text-align: left;
    border-bottom: 1px solid #f1f1f1;
}

th {
    background: #f9f9f9;
    text-transform: uppercase;
    font-size: 0.8rem;
    color: #7f8c8d;
}

.action-buttons {
    display: flex;
    gap: 8px;
}
</style>