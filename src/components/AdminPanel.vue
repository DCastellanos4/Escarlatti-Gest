<script setup>
/**
 * COMPONENTE: AdminPanel.vue
 * Control de acceso basado en IDs de rol de la base de datos ("1", "2", "3", "4").
 */
import { ref, onMounted } from 'vue'
import Profesores from './GestionProfesores.vue'
import Alumnos from './GestionAlumnos.vue'
import Cursos from './GestionCursos.vue'
import Espacios from './GestionEspacios.vue'
import Etapas from './GestionEtapas.vue'
import Turnos from './GestionTurnos.vue'
import Departamento from './GestionDepartamentos.vue'
import Roles from './GestionRoles.vue'
import Users from './GestionUsuarios.vue'
import Reservas from './GestionReservas.vue'
import Horarios from './GestionHorarios.vue'
import Incidencias from './GestionIncidencias.vue'
import Resolver from './resolverIncidencias.vue'

// Recibimos el objeto de autenticación completa
const props = defineProps(['usuario']);
const emit = defineEmits(['logout']);

const seccionActual = ref('menu');

onMounted(() => {
    // DEBUG
    console.log("--- RESPUESTA API RECIBIDA ---");
    console.log("Mensaje:", props.usuario.mensaje);
    console.log("Login:", props.usuario.usuario);
    console.log("Rol:", props.usuario.rol);
    console.log("Nombre:", props.usuario.nombre);
    console.log("Apellidos:", props.usuario.apellidos);
});

const irAMenu = () => seccionActual.value = 'menu';
</script>

<template>
    <div class="panel-container">
        <header>
            <div class="user-welcome">
                <h3>Bienvenid@, {{ usuario.nombre }} {{ usuario.apellidos }}</h3>
                <span class="badge-rol">{{ usuario.rol }}</span>
            </div>
            <div class="header-buttons">
                <button v-if="seccionActual !== 'menu'" @click="irAMenu" class="btn-primary">Volver al Panel</button>
                <button @click="$emit('logout')" class="logout-btn">Cerrar Sesión</button>
            </div>
        </header>

        <div v-if="seccionActual === 'menu'" class="acciones-grid">

            <section>
                <h4>Servicios Generales</h4>
                <button @click="seccionActual = 'incidencias'" class="btn-primary">Crear Incidencia</button>

            </section>

            <section v-if="['Administrador', 'Profesor'].includes(String(usuario.rol))">
                <h4>Gestión de Espacios</h4>
                <button @click="seccionActual = 'reservas'" class="btn-accent">Reservar espacio</button>

            </section>

            <section v-if="['Administrador', 'Responsable TIC'].includes(String(usuario.rol))">
                <h4>Mantenimiento TIC</h4>
                <button @click="seccionActual = 'resolver'" class="btn-success">Resolver Incidencias</button>

            </section>
            <!-- DEPENDE DEL BOTON QUE SE PULSE SE RENDERIZA UN COMPONENTE O OTRO -->
            <section v-if="usuario.rol == 'Administrador'" class="admin-zone">
                <h4>Mantenimiento de Tablas (Acceso Total)</h4>
                <div class="admin-buttons-container">
                    <button @click="seccionActual = 'profesores'">Profesores</button>
                    <button @click="seccionActual = 'alumnos'">Alumnos</button>
                    <button @click="seccionActual = 'cursos'">Cursos</button>
                    <button @click="seccionActual = 'espacios'">Espacios</button>
                    <button @click="seccionActual = 'etapas'">Etapas</button>
                    <button @click="seccionActual = 'turnos'">Turnos</button>
                    <button @click="seccionActual = 'departamentos'">Departamentos</button>
                    <button @click="seccionActual = 'roles'">Roles</button>
                    <button @click="seccionActual = 'users'">Usuarios</button>
                    <button @click="seccionActual = 'horarios'">Horarios</button>
                </div>
                <p class="admin-note">Como Administrador, tienes permisos para gestionar todos los módulos
                </p>
            </section>
        </div>
        <!-- LISTA DE COMPONENTES RENDERIZADOS -->
        <div v-else class="content-view">
            <component :is="{
                profesores: Profesores,
                alumnos: Alumnos,
                cursos: Cursos,
                espacios: Espacios,
                etapas: Etapas,
                turnos: Turnos,
                departamentos: Departamento,
                roles: Roles,
                users: Users,
                horarios: Horarios,
                reservas: Reservas,
                incidencias: Incidencias,
                resolver: Resolver
            }[seccionActual]" :usuario="usuario" />
        </div>
    </div>
</template>

<style scoped>
.panel-container {
    background: #f8fafc;
    padding: 30px;
    border-radius: 12px;
    color: #1e293b;
}

header {
    display: flex;
    justify-content: space-between;
    border-bottom: 1px solid #e2e8f0;
    padding-bottom: 20px;
    margin-bottom: 25px;
}

.badge-rol {
    background: #6366f1;
    color: white;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: bold;
}

.acciones-grid {
    display: grid;
    gap: 20px;
}

section {
    background: white;
    padding: 20px;
    border-radius: 10px;
    border: 1px solid #f1f5f9;
}

.admin-zone {
    border: 2px dashed #6366f1;
    background: #f5f3ff;
}

.admin-buttons-container {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    margin-top: 15px;
}

.admin-buttons-container button {
    background: #1e293b;
    color: white;
    border-radius: 6px;
}

.btn-primary {
    background: #3b82f6;
    color: white;
}

.btn-accent {
    background: #f59e0b;
    color: white;
}

.btn-success {
    background: #10b981;
    color: white;
}

.logout-btn {
    background: #94a3b8;
    color: white;
}
</style>