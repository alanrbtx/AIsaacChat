from flask import Flask, request, jsonify, send_file, Response
from celery.result import AsyncResult
import time
from celery import Celery
import torch
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler
from transformers import AutoTokenizer, MarianMTModel, T5ForConditionalGeneration


app = Flask(__name__)
app.config['CELERY_BROKER_URL'] = 'pyamqp://alan:1402@localhost:5672/4200'
app.config['result_backend'] = 'rpc://'

celery_app = Celery(app.name, backend=app.config['result_backend'], broker=app.config['CELERY_BROKER_URL'])
celery_app.conf.update(app.config)


#image generation
image_generation_checkpoint = "stabilityai/stable-diffusion-2-1-base"
pipe = StableDiffusionPipeline.from_pretrained(image_generation_checkpoint, torch_dtype=torch.float16)
pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
pipe = pipe.to("cuda")


#conversation
conversation_checkpoint = 'AlanRobotics/instruct-T5'
conversation_tokenizer = AutoTokenizer.from_pretrained(conversation_checkpoint)
conversation_model = T5ForConditionalGeneration.from_pretrained(conversation_checkpoint)


#translation
translator_checkpoint = 'Helsinki-NLP/opus-mt-ru-en'
translator_tokenizer = AutoTokenizer.from_pretrained(translator_checkpoint)
translator = MarianMTModel.from_pretrained(translator_checkpoint)
    

@celery_app.task
def process_task(arg1, arg2):
    result = arg1 + arg2
    return result

@celery_app.task
def generate_image(prompt):
    #translate input prompt
    tokenized_sentence = translator_tokenizer(prompt, return_tensors='pt', truncation=True)
    res = translator.generate(**tokenized_sentence)
    translated_prompt = translator_tokenizer.decode(res[0], skip_special_tokens=True)

    #image generation
    image = pipe(translated_prompt).images[0]
    image.save('generated.png')
    return "success"


@celery_app.task
def conversation(prompt):
    tokenized_sentence = conversation_tokenizer(prompt, return_tensors='pt', truncation=True)
    res = conversation_model.generate(**tokenized_sentence, num_beams=2, max_length=100)
    return conversation_tokenizer.decode(res[0], skip_special_tokens=True)


@app.route('/process', methods=['POST'])
def process():
    arg1 = request.json.get('arg1')
    arg2 = request.json.get('arg2')

    
    task = process_task.delay(arg1, arg2)
    task_id = task.id
    print(task.ready(), task.state)

    return jsonify({'task_id': task_id})


@app.route('/result/<task_id>', methods=['GET'])
def get_result(task_id):
    task = AsyncResult(task_id, app=celery_app)
    return jsonify({'id': task.result})


@app.route('/generate', methods=['POST'])
def generate_function():
    res = request.get_json()
    prompt = res['data']['value']

    if "Нарисуй" in prompt:
        prompt = prompt.replace('Нарисуй', '')
        res = generate_image.delay(prompt)
        print(res)
        task_id = res.get()
        return send_file('generated.png', mimetype='image/gif')
    else:
        res = conversation.delay(prompt)
        answer = res.get()
        return Response(answer, mimetype='text')



if __name__ == '__main__':
    app.run(port=5000)