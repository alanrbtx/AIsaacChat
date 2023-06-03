from Siamese_nn.configuration_siamese import SiameseConfig
from Siamese_nn.modeling_siamese import SiamseNNModel
from transformers import AutoModel

SiameseConfig.register_for_auto_class()
SiamseNNModel.register_for_auto_class("AutoModel")

siamese_config = SiameseConfig()
model = SiamseNNModel(siamese_config)

model.push_to_hub('AlanRobotics/aisaac-siamese')

#second_model = AutoModel.from_pretrained('AlanRobotics/aisaac-siamese', trust_remote_code=True)