import ray
from ray import serve
from model_deployment import chat_model
import logging
import yaml

from model_deployment import ChatModel

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

ray.init(
    #address="auto",
    ignore_reinit_error=True,
    dashboard_host="0.0.0.0",
    dashboard_port=8265,
)

logger.info(f"Ray initialized? {ray.is_initialized()}")
logger.info(f"CPUs: {ray.cluster_resources().get('CPU', 0)}")
logger.info(f"GPUs: {ray.cluster_resources().get('GPU', 0)}")

serve.start(
    detached=True,
    http_options={
        "host": "0.0.0.0",
        "port": 8000
    }
)

with open("serve_config.yaml") as f:
    config = yaml.safe_load(f)

# config = yaml.safe_load(open("serve_config.yaml"))
#runtime_env
user_config = config["applications"][0].get("user_config", {})
serve.run(
    ChatModel.options(
        user_config=user_config
    ).bind(),
    # chat_model,
    name="ChatModel",
    route_prefix="/model",
    blocking=False
)

logger.info("Ray Serve deployment is up and running.")
logger.info("Dashboard: http://localhost:8265")
logger.info("Access the API at: http://localhost:8000")
logger.info("Docs available at: http://localhost:8000/docs")

try:
    import time
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    logger.info("Shutting down...")
    serve.shutdown()
    ray.shutdown()