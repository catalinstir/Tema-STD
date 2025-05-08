<template>
  <div class="chat-container">
    <div class="chat-messages" ref="messagesContainer">
      <div v-for="(msg, index) in messages" :key="index" class="message">
        <span class="username">{{ msg.username }}:</span>
        <span class="text">{{ msg.message }}</span>
        <span class="timestamp">{{ formatTime(msg.timestamp) }}</span>
      </div>
    </div>
    <div class="chat-input">
      <input v-model="newMessage" @keyup.enter="sendMessage" placeholder="Type your message..." />
      <button @click="sendMessage">Send</button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      username: 'User_' + Math.floor(Math.random() * 1000),
      messages: [],
      newMessage: '',
      socket: null
    }
  },
  mounted() {
    this.connectWebSocket();
  },
  methods: {
    connectWebSocket() {
      // For Docker Compose testing, use localhost:88 instead of window.location.hostname
      this.socket = new WebSocket('ws://localhost:88/chat');
      
      this.socket.onopen = () => {
        console.log('WebSocket connected');
      };
      
      this.socket.onmessage = (event) => {
        const message = JSON.parse(event.data);
        this.messages.push(message);
        this.$nextTick(() => {
          this.scrollToBottom();
        });
      };
      
      this.socket.onclose = () => {
        console.log('WebSocket disconnected');
        setTimeout(() => {
          this.connectWebSocket();
        }, 1000);
      };
    },
    sendMessage() {
      if (this.newMessage.trim() === '') return;
      
      const message = {
        username: this.username,
        message: this.newMessage,
        timestamp: new Date().toISOString()
      };
      
      this.socket.send(JSON.stringify(message));
      this.newMessage = '';
    },
    scrollToBottom() {
      const container = this.$refs.messagesContainer;
      container.scrollTop = container.scrollHeight;
    },
    formatTime(timestamp) {
      const date = new Date(timestamp);
      return date.toLocaleTimeString();
    }
  }
}
</script>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  border: 1px solid #ccc;
  border-radius: 4px;
  overflow: hidden;
}

.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 10px;
  background-color: #f9f9f9;
}

.message {
  margin-bottom: 10px;
}

.username {
  font-weight: bold;
  margin-right: 5px;
}

.timestamp {
  font-size: 0.8em;
  color: #888;
  margin-left: 10px;
}

.chat-input {
  display: flex;
  padding: 10px;
  background-color: #fff;
  border-top: 1px solid #eee;
}

input {
  flex: 1;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  margin-right: 10px;
}

button {
  padding: 8px 16px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:hover {
  background-color: #45a049;
}
</style>
