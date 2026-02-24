<!-- BLOQUE DE LOGICA -->
<script setup>
import { ref } from 'vue'
//IMPORTAMOS LOS 2 COMPONENTES ESENCIALES QUE QUEREMOS MOSTRAR
import Login from './components/Login.vue'
import AdminPanel from './components/AdminPanel.vue'

//ESTA VARIABLE GUARDA QUE USUARIO ESTA LOGEADO, INICIALMENTE ES NULL PORQUE NO HAY NADIE LOGEADO
const usuarioActivo = ref(null)

/**
 * Recibe el testigo del componente Login.
 * datos del servidor me da el usuario que ha hecho login correctamente
 */
//RECIBE LO ENVIADO DEL COMPONENTE LOGIN
//datosDelServidor ME DA EL USUARIO QUE SE HA LOGEADO
const iniciarSesion = (datosDelServidor) => {
  console.log("Sesión iniciada para:", datosDelServidor.login)
  usuarioActivo.value = datosDelServidor
}

//PONEMOS EL USUARIO A NULL Y POR TANTO NOS SACA OTRA VEZ AL MENU
const cerrarSesion = () => {
  //USAMOS CONFIRMACION POR SI HA CLICKADO SIN QUERER
  if (confirm("¿Seguro que quieres salir?")) {
    usuarioActivo.value = null
  }
}
</script>

<template>
  <main class="main-wrapper">
    <!-- MUESTRA EL COMPONENTE DEL LOGIN SI NO HAY UN USUARIOACTIVO -->
    <!-- RECOGEMOS EL EVENTO QUE HEMOS CREADO CON EMIT PARA EJECUTAR LA FUNCION DE INICIO DE SESION -->
    <Login v-if="!usuarioActivo" @login-exitoso="iniciarSesion" />
    <!-- MUESTRA EL COMPONENTE DEL PANEL SI HAY UN USUARIO LOGEADO -->
    <!-- REGOGEMOS EL EVENTO Y VICEVERSA -->
    <AdminPanel v-else :usuario="usuarioActivo" @logout="cerrarSesion" />

  </main>
</template>

<style>
:root {
  --primary: #2c3e50;
  --bg-dark: #1e1e1e;
  --text-light: #f5f5f5;
}

body {
  margin: 0;
  padding: 0;
  background-color: var(--bg-dark);
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  color: var(--text-light);
}

.main-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 1rem;
  box-sizing: border-box;
}

.main-wrapper>* {
  transition: all 0.3s ease;
}
</style>