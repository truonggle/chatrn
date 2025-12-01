MODEL_CONFIGS = {
    "microsoft/DialoGPT-medium": {
        "generation_config": {
            "max_length": 100,
            "temperature": 0.8,
            "top_p": 0.7,
            "top_k": 100,
            "do_sample": True,
            "repetition_penalty": 1.2,
            "no_repeat_ngram_size": 3,
        },
        "optional_params": ["top_k", "no_repeat_ngram_size"],
    },
}

def get_model_config(model_name: str) -> dict:
    return MODEL_CONFIGS.get(model_name, MODEL_CONFIGS["microsoft/DialoGPT-medium"])