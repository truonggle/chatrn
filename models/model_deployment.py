from ray import serve
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch
import logging
from typing import Dict, Any
from models.models_config import get_model_config # TODO

logger = logging.getLogger(__name__)

@serve.deployment(
    num_replicas=1,
    ray_actor_options={"num_cpus": 2, "num_gpus": 0},
)
class ChatModel:
    def __init__(self):
        self.tokenizer = None
        self.model = None

        self.model_name = "microsoft/DialoGPT-medium"
        # self.generation_config = {
        #     "max_length": 1000,
        #     "temperature": 0.8,
        #     "top_p": 0.7,
        #     "do_sample": True,
        #     "repetition_penalty": 1.2 # new stuff
        # }
        # self.optional_params = ["top_k", "no_repeat_ngram_size"]
        config = get_model_config(self.model_name)
        self.generation_config = config["generation_config"]
        self.optional_params = config["optional_params"]

        self.load_model()

    def load_model(self):
        try:
            logger.info(f"Loading model: {self.model_name}")

            # model_name = "microsoft/DialoGPT-medium"
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_name,
                torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32 # new stuff
            )

            if self.tokenizer.pad_token is None:
                self.tokenizer.pad_token = self.tokenizer.eos_token
                logger.info(f"Set pad_token to eos_token: {self.tokenizer.eos_token}")
            if torch.cuda.is_available():
                self.model = self.model.to("cuda")
            self.model.eval()

            logger.info("Model loaded successfully!")
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            raise

    def _validate_generation_config(self):
        """Check which generation params the model actually supports"""
        try:
            model_gen_config = self.model.generation_config
            validated_config = {}
            for key, value in self.generation_config.items():
                if hasattr(model_gen_config, key) or key not in self.optional_params:
                    validated_config[key] = value
                    logger.info(f"Parameter '{key}' is added to generation config.")
                else:
                    logger.warning(f"Parameter '{key}' not supported by {self.model_name}, skipping.")

            self.generation_config = validated_config
            logger.info(f"Validated generation config: {list(self.generation_config.keys())}")

        except Exception as e:
            logger.warning(f"Could not validate generation config: {e}")

    def reconfigure(self, config: Dict[str, Any]):
        """Handle config updates from serve_config.yaml"""
        logger.info(f"Reconfiguring model with new config: {config}")

        new_model_name = config.get("model_name", self.model_name)
        if new_model_name != self.model_name:
            logger.info(f"Model name changed: {self.model_name} -> {new_model_name}")
            self.model_name = new_model_name
            self.load_model()

        if "generation_config" in config:
            self.generation_config.update(config["generation_config"])
            self._validate_generation_config()
            logger.info(f"Updated generation config: {self.generation_config}")

        if "optional_params" in config:
            self.optional_params = config["optional_params"]
            logger.info(f"Updated optional params: {self.optional_params}")

    async def generate_response(self, history: str) -> str:
        """ML inference only - called via DeploymentHandle"""
        if not self.model or not self.tokenizer:
            raise RuntimeError("Model not loaded")

        input_ids = self.tokenizer.encode(
            history + self.tokenizer.eos_token,
            return_tensors='pt'
        )

        if torch.cuda.is_available():
            input_ids = input_ids.to("cuda")

        generation_kwargs = {
            **self.generation_config,
            "pad_token_id": self.tokenizer.eos_token_id # follow the old code for now
        }

        try:
            with torch.no_grad():
                output = self.model.generate(
                    input_ids,
                    **generation_kwargs
                )

            # output = self.model.generate(
            #     input_ids,
            #     max_length=1000,
            #     pad_token_id=self.tokenizer.eos_token_id,
            #     no_repeat_ngram_size=3,
            #     do_sample=True,
            #     top_k=100,
            #     top_p=0.7,
            #     temperature=0.8
            # )

            response = self.tokenizer.decode(
                output[:, input_ids.shape[-1]:][0],
                skip_special_tokens=True
            )
            return response
        except Exception as e:
            logger.error(f"Generation failed: {e}")
            raise

chat_model = ChatModel.bind()