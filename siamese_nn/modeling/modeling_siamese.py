from transformers import PreTrainedModel, BertModel
import torch
from .configuration_siamese import SiameseConfig

checkpoint = 'cointegrated/rubert-tiny'

class Lambda(torch.nn.Module):
    def __init__(self, lambd):
        super().__init__()
        self.lambd = lambd
    
    def forward(self, x):
         return self.lambd(x)


class SiameseNN(torch.nn.Module):
    def __init__(self):
        super(SiameseNN, self).__init__()
        l1_norm = lambda x: 1 - torch.abs(x[0] - x[1])
        self.encoder = BertModel.from_pretrained(checkpoint)
        self.merged = Lambda(l1_norm)
        self.fc1 = torch.nn.Linear(312, 2)
        self.softmax = torch.nn.Softmax()

    
    def forward(self, x):
        first_encoded = self.encoder(**x[0]).pooler_output
        second_encoded = self.encoder(**x[1]).pooler_output
        l1_distance = self.merged([first_encoded, second_encoded])
        fc1 = self.fc1(l1_distance)
        return self.softmax(fc1)

second_model = SiameseNN()
second_model.load_state_dict(torch.load('siamese_state'))

class SiamseNNModel(PreTrainedModel):
    config_class = SiameseConfig
    def __init__(self, config):
        super().__init__(config)
        self.model = second_model

    
    def forward(self, tensor, labels=None):
        logits = self.model(tensor)
        if labels is not None:
            loss_fn = torch.nn.CrossEntropyLoss()
            loss = loss_fn(logits, labels)
            return {'loss': loss, 'logits': logits}
        return {'logits': logits}