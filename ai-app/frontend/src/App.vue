<template>
  <div id="app">
    <SpeechToText />
  </div>
</template>

<script>
import SpeechToText from './components/SpeechToText.vue'

export default {
  name: 'App',
  components: {
    SpeechToText
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  margin: 0;
  padding: 0;
  height: 100vh;
}

html, body {
  height: 100%;
  margin: 0;
  padding: 0;
}
</style>
