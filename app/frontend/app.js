const API_URL = '/api'; //'http://localhost:8081'

const chatBox = document.getElementById('chatBox');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const resetBtn = document.getElementById('resetBtn');

const conversationId = Math.random().toString(36).substring(7);

function addMessage(text, isUser) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${isUser ? 'user-message' : 'bot-message'}`;
    messageDiv.innerHTML = `<p>${text}</p>`;
    chatBox.appendChild(messageDiv);
    chatBox.scrollTop = chatBox.scrollHeight;
}

async function sendMessage() {
    const message = messageInput.value.trim();
    if (!message) return;

    addMessage(message, true);
    messageInput.value = '';
    sendBtn.disabled = true;

    try {
        const response = await fetch(`${API_URL}/chat`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: message,
                conversation_id: conversationId
            })
        });

        if (!response.ok) {
            throw new Error('Network response was not ok');
        }

        const data = await response.json();
        addMessage(data.response, false);
    } catch (error) {
        console.error('Error:', error);
        addMessage('Sorry, I encountered an error. Please try again.', false);
    } finally {
        sendBtn.disabled = false;
        messageInput.focus();
    }
}

async function resetConversation() {
    try {
        await fetch(`${API_URL}/chat/${conversationId}`, {
            method: 'DELETE'
        });

        chatBox.innerHTML = '';
        addMessage("Chat reset! How can I help you today?", false);
    } catch (error) {
        console.error('Error resetting conversation:', error);
    }
}

sendBtn.addEventListener('click', sendMessage);
resetBtn.addEventListener('click', resetConversation);

messageInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        sendMessage();
    }
});

// File Upload Functionality
const fileInput = document.getElementById('fileInput');
const fileInfo = document.getElementById('fileInfo');
const fileName = document.getElementById('fileName');
const uploadBtn = document.getElementById('uploadBtn');
const cancelBtn = document.getElementById('cancelBtn');

fileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
        fileName.textContent = `📄 ${e.target.files[0].name}`;
        fileInfo.style.display = 'flex';
    }
});

cancelBtn.addEventListener('click', () => {
    fileInput.value = '';
    fileInfo.style.display = 'none';
});

uploadBtn.addEventListener('click', async () => {
    const file = fileInput.files[0];
    if (!file) return;

    addMessage(`Uploading ${file.name}...`, 'bot', 'upload-notification');

    const formData = new FormData();
    formData.append('file', file);

    try {
        const response = await fetch(`${API_URL}/upload`, {
            method: 'POST',
            body: formData
        });

        const data = await response.json();

        if (response.ok) {
            addMessage(
                `File uploaded successfully: ${data.filename}`,
                'bot',
                'upload-success'
            );
        } else {
            addMessage(
                `Upload failed: ${data.detail}`,
                'bot',
                'upload-error'
            );
        }
    } catch (error) {
        addMessage(
            `Upload error: ${error.message}`,
            'bot',
            'upload-error'
        );
    } finally {
        fileInput.value = '';
        fileInfo.style.display = 'none';
    }
});

function addMessage(text, sender, customClass = '') {
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${sender}-message ${customClass}`;
    messageDiv.innerHTML = `<p>${text}</p>`;
    chatBox.appendChild(messageDiv);
    chatBox.scrollTop = chatBox.scrollHeight;
}