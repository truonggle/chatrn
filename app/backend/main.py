import os
import ray
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from google.cloud import storage
from datetime import datetime
import logging
from ray import serve
from typing import Optional
from ray.serve.handle import DeploymentHandle

logger = logging.getLogger(__name__)

app = FastAPI(title="Chat!!", root_path="/api")

ray.init(address="ray://ray-service-raycluster-8qxqd-head-svc.default.svc.cluster.local:10001")
# ray.init(address=os.getenv("RAY_ADDRESS"))
# ray.init(address="auto", ignore_reinit_error=True)
# logger.info(f"Ray connected? {ray.is_initialized()}")

# ray.util.connect("ray://ray-service-head-svc.default.svc.cluster.local:10001")
# ray.util.connect("ray://localhost:10001")

chat_model_handle = serve.get_deployment_handle("ChatModel", app_name="app1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Store conversation history in-memory
conversations = {}

# Get handle to Ray Serve model deployment
# chat_model_handle: Optional[DeploymentHandle] = None

class ChatRequest(BaseModel):
    message: str
    conversation_id: str = "default"

class ChatResponse(BaseModel):
    response: str
    conversation_id: str

def get_model_handle():
    """
    Kind of a lazy initialization. Attempt to connect on demand only.
    Probably need to be optimized...
    """
    global chat_model_handle
    if chat_model_handle is None:
        try:
            chat_model_handle = serve.get_deployment_handle(
                "ChatModel",
                app_name="app1"
            )
            logger.info("Connected to Ray Serve ChatModel")
        except Exception as e:
            logger.error(f"Failed to connect to Ray Serve: {e}")
            raise HTTPException(
                status_code=503,
                detail="Model service not available. Ensure Ray Serve is running."
            )
    return chat_model_handle

@app.get("/health")
async def health():
    try:
        get_model_handle()
        return {"status": "healthy", "ray_serve_connected": True}
    except HTTPException:
        return {"status": "degraded", "ray_serve_connected": False}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    handle = get_model_handle()

    try:
        # Manage conversation history locally
        if request.conversation_id not in conversations:
            conversations[request.conversation_id] = []

        conversations[request.conversation_id].append(request.message)
        history = " ".join(conversations[request.conversation_id][-5:])

        # Call Ray Serve model via handle (offloads to Ray cluster)
        response_text = await handle.generate_response.remote(history)

        # Add bot response to history
        conversations[request.conversation_id].append(response_text)

        logger.info(f"[{request.conversation_id}] User: {request.message}")
        logger.info(f"[{request.conversation_id}] Bot: {response_text}")

        return ChatResponse(
            response=response_text,
            conversation_id=request.conversation_id
        )

    except Exception as e:
        logger.error(f"Error processing chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/chat/{conversation_id}")
async def reset_conversation(conversation_id: str):
    if conversation_id in conversations:
        del conversations[conversation_id]
        logger.info(f"Conversation {conversation_id} reset")
        return {"message": "Conversation reset successfully"}
    return {"message": "Conversation not found"}

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    try:
        storage_client = storage.Client()
        bucket_name = "dev-ops-0-dev-data-bucket"
        bucket = storage_client.bucket(bucket_name)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{file.filename}"

        blob = bucket.blob(filename)
        content = await file.read()
        blob.upload_from_string(content, content_type=file.content_type)

        logger.info(f"File uploaded successfully: {filename}")
        return {
            "success": True,
            "message": "File uploaded successfully",
            "filename": filename,
            "bucket": bucket_name
        }
    except Exception as e:
        logger.error(f"Upload failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {
        "message": "Chatbot API is running",
        "docs": "/docs",
        "health": "/health"
    }