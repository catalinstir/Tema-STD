<template>
  <div class="speech-to-text-container">
    <h2>Speech to Text Converter</h2>
    
    <div class="upload-section">
      <div class="drop-zone" 
           @dragover.prevent="isDragging = true" 
           @dragleave.prevent="isDragging = false"
           @drop.prevent="onDrop"
           :class="{ 'active': isDragging }">
        <div v-if="!selectedFile">
          <p>Drag & drop your audio file here</p>
          <p>or</p>
          <button @click="triggerFileInput" class="upload-btn">Select File</button>
        </div>
        <div v-else>
          <p>{{ selectedFile.name }}</p>
          <button @click="selectedFile = null" class="remove-btn">Remove</button>
        </div>
        <input type="file" ref="fileInput" @change="onFileSelected" accept="audio/*" style="display: none" />
      </div>
      
      <button @click="uploadFile" class="process-btn" :disabled="!selectedFile || isUploading">
        <span v-if="isUploading">Processing...</span>
        <span v-else>Convert to Text</span>
      </button>
    </div>
    
    <div v-if="currentResult" class="result-section">
      <h3>Current Result</h3>
      <div class="result-card">
        <div class="result-header">
          <span class="filename">{{ currentResult.fileName }}</span>
          <span class="timestamp">{{ formatDate(currentResult.timestamp || new Date()) }}</span>
        </div>
        <div class="result-content">
          <p>{{ currentResult.transcription }}</p>
        </div>
      </div>
    </div>
    
    <div class="history-section">
      <h3>Processing History</h3>
      <div v-if="history.length === 0" class="no-history">
        <p>No previous transcriptions</p>
      </div>
      <div v-else class="history-list">
        <div v-for="(item, index) in history" :key="index" class="history-item">
          <div class="history-header">
            <span class="filename">{{ item.filename }}</span>
            <span class="timestamp">{{ formatDate(new Date(item.timestamp)) }}</span>
          </div>
          <div class="history-content">
            <p>{{ item.transcription }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      selectedFile: null,
      isDragging: false,
      isUploading: false,
      currentResult: null,
      history: []
    }
  },
  mounted() {
    this.fetchHistory();
  },
  methods: {
    triggerFileInput() {
      this.$refs.fileInput.click();
    },
    onFileSelected(event) {
      const file = event.target.files[0];
      if (file) {
        this.selectedFile = file;
      }
    },
    onDrop(event) {
      this.isDragging = false;
      const file = event.dataTransfer.files[0];
      if (file && file.type.startsWith('audio/')) {
        this.selectedFile = file;
      }
    },
    async uploadFile() {
      if (!this.selectedFile) return;
      
      this.isUploading = true;
      
      const formData = new FormData();
      formData.append('audioFile', this.selectedFile);
      
      try {
        // For Docker Compose testing, use localhost:92 directly
        const apiUrl = 'http://localhost:92';
        const response = await fetch(`${apiUrl}/api/upload`, {
          method: 'POST',
          body: formData
        });
        
        if (!response.ok) {
          throw new Error('Failed to process file');
        }
        
        const result = await response.json();
        this.currentResult = {
          fileName: result.fileName,
          blobUrl: result.blobUrl,
          transcription: result.transcription,
          timestamp: new Date()
        };
        
        // Add to history and refetch from server
        this.fetchHistory();
        
        // Clear selected file
        this.selectedFile = null;
      } catch (error) {
        console.error('Error uploading file:', error);
        alert('Failed to process file. Please try again.');
      } finally {
        this.isUploading = false;
      }
    },
    async fetchHistory() {
      try {
        // For Docker Compose testing, use localhost:92 directly
        const apiUrl = 'http://localhost:92';
        const response = await fetch(`${apiUrl}/api/history`);
        
        if (!response.ok) {
          throw new Error('Failed to fetch history');
        }
        
        this.history = await response.json();
      } catch (error) {
        console.error('Error fetching history:', error);
      }
    },
    formatDate(date) {
      return new Date(date).toLocaleString();
    }
  }
}
</script>

<style scoped>
.speech-to-text-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

h2 {
  color: #333;
  margin-bottom: 20px;
  text-align: center;
}

.upload-section {
  margin-bottom: 30px;
}

.drop-zone {
  border: 2px dashed #ccc;
  border-radius: 5px;
  padding: 30px;
  text-align: center;
  margin-bottom: 20px;
  transition: all 0.3s;
}

.drop-zone.active {
  border-color: #4CAF50;
  background-color: rgba(76, 175, 80, 0.1);
}

.upload-btn, .process-btn, .remove-btn {
  padding: 10px 20px;
  cursor: pointer;
  border: none;
  border-radius: 4px;
  margin: 5px;
  font-weight: bold;
}

.upload-btn {
  background-color: #2196F3;
  color: white;
}

.process-btn {
  background-color: #4CAF50;
  color: white;
  width: 100%;
  padding: 12px;
  font-size: 16px;
}

.process-btn:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.remove-btn {
  background-color: #f44336;
  color: white;
}

.result-section, .history-section {
  margin-top: 30px;
}

h3 {
  color: #555;
  border-bottom: 1px solid #eee;
  padding-bottom: 10px;
  margin-bottom: 15px;
}

.result-card, .history-item {
  border: 1px solid #eee;
  border-radius: 5px;
  padding: 15px;
  margin-bottom: 15px;
  background-color: #f9f9f9;
}

.result-header, .history-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  font-size: 14px;
}

.filename {
  font-weight: bold;
  color: #2196F3;
}

.timestamp {
  color: #888;
}

.result-content, .history-content {
  background-color: white;
  padding: 15px;
  border-radius: 5px;
  border: 1px solid #eee;
}

.no-history {
  text-align: center;
  color: #888;
  padding: 20px;
}
</style>
