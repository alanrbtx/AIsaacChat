import flask
from flask import Flask, request, jsonify, send_file
import torch
from transformers import AutoTokenizer, MarianMTModel, T5ForConditionalGeneration
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler


#translation
translator_checkpoint = 'Helsinki-NLP/opus-mt-ru-en'
translator_tokenizer = AutoTokenizer.from_pretrained(translator_checkpoint)
translator = MarianMTModel.from_pretrained(translator_checkpoint)


def translate_function(example):
    tokenized_sentence = translator_tokenizer(example, return_tensors='pt', truncation=True)
    res = translator.generate(**tokenized_sentence)
    return translator_tokenizer.decode(res[0], skip_special_tokens=True)


# model_id = "stabilityai/stable-diffusion-2-1-base"
# pipe = StableDiffusionPipeline.from_pretrained(model_id, torch_dtype=torch.float16)
# pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
# pipe = pipe.to("cuda")


#conversation
conversation_checkpoint = 'AlanRobotics/instruct-T5'
conversation_tokenizer = AutoTokenizer.from_pretrained(conversation_checkpoint)
conversation_model = T5ForConditionalGeneration.from_pretrained(conversation_checkpoint)


def get_answer(example):
    tokenized_sentence = conversation_tokenizer(example, return_tensors='pt', truncation=True)
    res = conversation_model.generate(**tokenized_sentence, num_beams=2)
    return conversation_tokenizer.decode(res[0], skip_special_tokens=True)


def setup_rest_api(conductor):

    def _corsify(response):
        """ adds CORS headers to response """
        response.headers.add('Access-Control-Allow-Origin', '*')
        if request.method == 'OPTIONS':
            response.headers.add('Access-Control-Allow-Methods', '*')
            headers = request.headers.get('Access-Control-Request-Headers')
            if headers is not None:
                response.headers.add('Access-Control-Allow-Headers', headers)
        return response



    @conductor.app.errorhandler(400)
    def _bad_request(msg=None):
        """ bad request """
        response = conductor.templates['http_resp'].copy()
        response['action'] = f"{request}"
        response['code'] = '400'
        response['message'] = 'Bad request'
        if msg is not None:
            response['message'] += f': {msg}'
        return _corsify(jsonify(response)), 400


    @conductor.app.errorhandler(404)
    def _page_not_found(exception=None):
        """ page not found """
        response = conductor.templates['http_resp'].copy()
        response['action'] = f"{exception}"
        response['code'] = '404'
        response['message'] = f"Available endpoints: {','.join(conductor.list_endpoints())}"
        return jsonify(response), 404


    @conductor.app.route('/')
    @conductor.app.route('/about')
    def index():
        return "Home"


    @conductor.app.route('/stable_diffusion', methods=['POST'])
    def generate_image():
        # prompt = "реалистичный закат в лесу, высокое разрешение"
        res = request.get_json()
        prompt = res['data']['value']
        context = ""
        prompt = context + prompt
        answer = get_answer(prompt)
        print(res)
        #translated_prompt = translate_function(prompt)
        # print(prompt)
        # image = pipe(prompt).images[0]
        
        # image.save("generated.png")
        
        # return send_file('/Users/alanbarsag/Desktop/stable-diffusion-app/RestAPI/t5-lulu.png', mimetype='image/gif')
        #return translated_prompt
        return answer
        
    
    @conductor.app.route('/about')
    def about():
        return "About" 