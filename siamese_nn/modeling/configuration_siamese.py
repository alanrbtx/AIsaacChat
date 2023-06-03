from transformers import PretrainedConfig


class SiameseConfig(PretrainedConfig):
    model_type = "siamese"

    def __init__(
        self,
        **kwargs):
        super().__init__(**kwargs)


siamese_config = SiameseConfig()
siamese_config.save_pretrained('siamse_nn')